ScriptName CritterFish extends Critter
{ Behavior script for fish. }

;===============================================================================
;
; PROPERTIES
;
;===============================================================================

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

;===============================================================================
;
; HIDDEN
;
;===============================================================================

bool Property bMoving = false auto hidden

float Property fMoving = 0.0 auto hidden

;===============================================================================
;
; VARIABLES
;
;===============================================================================

CritterFish TargetFish = none

bool bFoundClosestActor = false

float fTargetX

float fTargetY

float fTargetZ

float fTargetAngleX

float fTargetAngleY

float fTargetAngleZ

;===============================================================================
;
; STATES
;
;===============================================================================

State RandomSwimming

  Event OnUpdate()
    { Override. }
    DoCritterBehavior()
  endEvent

  Function OnCritterGoalAlmostReached()
    { Override. }
    fMoving = 0.0
    bFoundClosestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance) as bool
    DoCritterBehavior()
  endFunction

  Function DoCritterBehavior()
    { Override. }
    if CheckViableDistance()
      float fSpeed = fFleeTranslationSpeed

      if !bFoundClosestActor
        fSpeed = Utility.RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance)
      endif

      if Utility.RandomInt(1, 100) <= iPercentChanceSchooling
        if PickTargetFishForSchooling() && PickRandomPointBehindTargetFish()
          GotoState("Schooling")
          SchoolWithOtherFish(fSpeed)
        else
          GotoNewPoint(fSpeed)
        endif
      else
        GotoNewPoint(fSpeed)
      endif
    endif
  endFunction

endState

State Schooling

  Event OnUpdate()
    { Override. }
    DoCritterBehavior()
  endEvent

  Function OnCritterGoalAlmostReached()
    { Override. }
    bFoundClosestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance) as bool
    DoCritterBehavior()
  endFunction

  Function DoCritterBehavior()
    { Override. }
    if CheckViableDistance()
      if bFoundClosestActor
        GotoState("RandomSwimming")
        TargetClear()
        GotoNewPoint(fFleeTranslationSpeed)
      elseif Utility.RandomInt(1, 100) > iPercentChanceStopSchooling && TargetFish as CritterFish && TargetFish.fMoving && PickRandomPointBehindTargetFish()
        SchoolWithOtherFish(TargetFish.fMoving)
      else
        GotoState("RandomSwimming")
        TargetClear()
        GotoNewPoint(Utility.RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance))
      endif
    endif
  endFunction

endState

State Initialized

  Event OnUpdate()
    { Override. }
    if CheckCellAttached(self)
      OnStart()
    else
      DisableAndDelete()
    endif
  endEvent

endState

;===============================================================================
;
; FUNCTIONS
;
;===============================================================================

Function OnStart()
  { Override. }
  SetScale(Utility.RandomFloat(fMinScale, fMaxScale))
  WarpToRandomPoint()
  Enable()
  SetMotionType(Motion_Keyframed, false)
  GotoState("RandomSwimming")
  DoCritterBehavior()
endFunction

Function FollowClear()
  { Override. }
  TargetFish = none
endFunction

Function TargetClear()
  { Override. }
  if TargetFish
    TargetFish.Follower = none
  endif

  TargetFish = none
endFunction

Function PickRandomPoint()
  float fLength = Utility.RandomFloat(0.0, fLeashLength)

  fTargetAngleZ = Utility.RandomFloat(-180.0, 180.0)
  fTargetX = fSpawnerX + fLength * Math.Cos(fTargetAngleZ)
  fTargetY = fSpawnerY + fLength * Math.Sin(fTargetAngleZ)

  if fMinDepth < fDepth
    fTargetZ = fSpawnerZ - Utility.RandomFloat(fMinDepth, fDepth - fLength * (fDepth - fMinDepth) / fLeashLength)
  else
    fTargetZ = fSpawnerZ
  endif

  fTargetAngleX = 0.0
endFunction

bool Function PickTargetFishForSchooling()
  TargetFish = Game.FindRandomReferenceOfAnyTypeInList(Spawner.CritterTypes, fSpawnerX, fSpawnerY, fSpawnerZ, fLeashLength - fSchoolingDistanceY) as CritterFish

  if TargetFish && TargetFish != self && TargetFish.FollowSet(self as ObjectReference)
    return true
  endif

  TargetFish = none
  return false
endFunction

bool Function PickRandomPointBehindTargetFish()
  float fTargetFishX = targetFish.X - fSpawnerX
  float fTargetFishY = targetFish.Y - fSpawnerY

  fTargetZ = targetFish.Z
  fTargetAngleZ = targetFish.GetAngleZ()

  float fDistance = Utility.RandomFloat(fSchoolingDistanceX, fSchoolingDistanceY)
  float fDeltaAngle = fTargetAngleZ + Utility.RandomFloat(fAngleVarianceZ * -1.0, fAngleVarianceZ)

  fTargetX = fTargetFishX - fDistance * Math.Cos(fDeltaAngle)
  fTargetY = fTargetFishY - fDistance * Math.Sin(fDeltaAngle)

  float fLength = Math.Sqrt(fTargetX * fTargetX + fTargetY * fTargetY)

  fTargetX += fSpawnerX
  fTargetY += fSpawnerY

  if fLength < fLeashLength && fMinDepth < fDepth
    fTargetZ = fSpawnerZ - Utility.RandomFloat(fMinDepth, fDepth - fLength * (fDepth - fMinDepth) / fLeashLength)
  endif

  fTargetAngleX = 0.0
endFunction

Function WarpToRandomPoint()
  PickRandomPoint()
  SetPosition(fTargetX, fTargetY, fTargetZ)
  SetAngle(fTargetAngleX, 0.0, fTargetAngleZ)
endFunction

Function GotoNewPoint(float afSpeed)
  PickRandomPoint()
  fMoving = afSpeed

  if CheckViability()
    return
  endif

  SplineTranslateTo(fTargetX, fTargetY, fTargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)
endFunction

Function SchoolWithOtherFish(float afSpeed)
  fMoving = afSpeed

  if CheckViability()
    return
  endif

  SplineTranslateTo(fTargetX, fTargetY, fTargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)
endFunction
