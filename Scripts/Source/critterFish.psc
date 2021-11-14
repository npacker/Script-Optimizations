ScriptName CritterFish extends Critter
{ Behavior script for fish. }

float Property fActorDetectionDistance = 300.0 auto
{The Distance at which an actor will trigger a flee behavior}

float Property fTranslationSpeedMean = 40.0 auto
{The movement speed when going from plant to plant, mean value}

float Property fTranslationSpeedVariance = 20.0 auto
{The movement speed when going from plant to plant, variance}

float Property fFleeTranslationSpeed = 70.0 auto
{The movement speed when fleeing from the player}

float Property fMinScale = 0.1 auto
{Minimum initial scale of the Fish}

float Property fMaxScale = 0.2 auto
{Maximum initial scale of the Fish}

float Property fMinDepth = 10.0 auto
{Minimum fish depth}

float Property fSplineCurvature = 200.0 auto

float property fMaxRotationSpeed = 360.0 auto

float Property fMinTimeNotMoving = 1.0 auto

float Property fMaxTimeNotMoving = 5.0 auto

float Property fSchoolingDistanceX = 25.0 auto

float Property fSchoolingDistanceY = 35.0 auto

int Property iPercentChanceSchooling = 50 auto

int Property iPercentChanceStopSchooling = 5 auto

bool Property bMoving = false auto hidden

float Property fMoving = 0.0 auto hidden

CritterFish TargetFish = none

bool bFoundClosestActor = false

float fTargetX

float fTargetY

float fTargetZ

float fTargetAngleX

float fTargetAngleY

float fTargetAngleZ

State RandomSwimming

  Event OnUpdate()
    if CheckViableDistance()
      float fspeed = fFleeTranslationSpeed

      if !bFoundClosestActor
        fspeed = Utility.RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance)
      endif

      if Utility.RandomInt(0, 100) < iPercentChanceSchooling
        if PickTargetFishForSchooling() && PickRandomPointBehindTargetFish()
          GotoState("Schooling")
          SchoolWithOtherFish(fspeed)
        else
          GoToNewPoint(fspeed)
        endif
      else
        GoToNewPoint(fspeed)
      endif
    endif
  endEvent

  Event OnCritterGoalAlmostReached()
    fMoving = 0.0

    if PlayerRef
      bFoundClosestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance) as bool
      RegisterForSingleUpdate(0.0)
    endif
  EndEvent

endState

State Schooling

  Event OnUpdate()
    if CheckViableDistance()
      if bFoundClosestActor
        GotoState("RandomSwimming")
        TargetClear()
        GoToNewPoint(fFleeTranslationSpeed)
      elseif Utility.RandomInt(0, 100) >= iPercentChanceStopSchooling && TargetFish as CritterFish && TargetFish.fMoving && PickRandomPointBehindTargetFish()
        SchoolWithOtherFish(TargetFish.fMoving)
      else
        GotoState("RandomSwimming")
        TargetClear()
        GoToNewPoint(Utility.RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance))
      endif
    endif
  endEvent

  Event OnCritterGoalAlmostReached()
    bFoundClosestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance) as bool
    RegisterForSingleUpdate(0.0)
  EndEvent

endState

Function FollowClear()
  float delay = 0.367879

  while TargetFish && delay < 2.943
    Utility.Wait(delay)
    delay += delay
  endWhile

  TargetFish = none
endFunction

Function TargetClear()
  if TargetFish
    TargetFish.Follower = none
  endif

  TargetFish = none
endFunction

Function OnStart()
  SetScale(Utility.RandomFloat(fMinScale, fMaxScale))
  GotoState("RandomSwimming")
  WarpToRandomPoint()
  Enable()

  if CheckViability()
    return
  endif

  SetMotionType(Motion_Keyframed, false)
  RegisterForSingleUpdate(0.0)
endFunction

Function PickRandomPoint()
  float fLength = Utility.RandomFloat(0.0, fLeashLength)
  fTargetAngleZ = Utility.RandomFloat(-180.0, 180.0)
  fTargetX = fSpawnerX + fLength * Math.Cos(fTargetAngleZ)
  fTargetY = fSpawnerY + fLength * Math.Sin(fTargetAngleZ)

  if fMinDepth < fDepth
    fTargetZ = fSpawnerZ - Utility.RandomFloat(fMinDepth, (fDepth - ((flength * (fDepth - fMinDepth)) / fLeashLength)))
  else
    fTargetZ = fSpawnerZ
  endif

  fTargetAngleX = 0.0
endFunction

bool Function PickTargetFishForSchooling()
  if Spawner && CheckCellAttached(Spawner)
    TargetFish = Game.FindRandomReferenceOfAnyTypeInList(Spawner.CritterTypes, fSpawnerX, fSpawnerY, fSpawnerZ, fLeashLength - fSchoolingDistanceY) as CritterFish

    if TargetFish && TargetFish != self && TargetFish.FollowSet(self as ObjectReference)
      return true
    endif

    TargetFish = none
  endif

  return false
endFunction

bool Function PickRandomPointBehindTargetFish()
  float ftargetFishX = targetFish.X - fSpawnerX
  float ftargetFishY = targetFish.Y - fSpawnerY
  fTargetZ = targetFish.Z
  fTargetAngleZ = targetFish.GetAngleZ()
  float fDistance = Utility.RandomFloat(fSchoolingDistanceX, fSchoolingDistanceY)
  float fDeltaAngle = fTargetAngleZ + Utility.RandomFloat(-fAngleVarianceZ, fAngleVarianceZ)
  fTargetX = ftargetFishX - fDistance * Math.Cos(fDeltaAngle)
  fTargetY = ftargetFishY - fDistance * Math.Sin(fDeltaAngle)
  float flength = Math.Sqrt(fTargetX * fTargetX + fTargetY * fTargetY)
  fTargetX += fSpawnerX
  fTargetY += fSpawnerY

  if flength < fLeashLength && fMinDepth < fDepth
    fTargetZ = fSpawnerZ - Utility.RandomFloat(fMinDepth, (fDepth - ((flength * (fDepth - fMinDepth)) / fLeashLength)))
  endif

  fTargetAngleX = 0.0
endFunction

Function WarpToRandomPoint()
  PickRandomPoint()

  if CheckViability()
    return
  endif

  SetPosition(fTargetX, fTargetY, fTargetZ)
  SetAngle(fTargetAngleX, 0.0, fTargetAngleZ)
endFunction

Function GoToNewPoint(float afSpeed)
  PickRandomPoint()
  fMoving = afSpeed

  if CheckViability()
    return
  endif

  SplineTranslateTo(fTargetX, ftargetY, ftargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)
endFunction

Function SchoolWithOtherFish(float afSpeed)
  fMoving = afSpeed

  if CheckViability()
    return
  endif

  SplineTranslateTo(fTargetX, ftargetY, ftargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)
endFunction

Event OnCellDetach()
  fMoving = 0.0
  parent.OnCellDetach()
endEvent
