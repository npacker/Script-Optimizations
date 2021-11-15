ScriptName CritterDragonFly extends Critter

;===============================================================================
;
; PROPERTIES
;
;===============================================================================

float Property fActorDetectionDistance = 300.0 auto
{The Distance at which an actor will trigger a flee behavior}

float Property fTranslationSpeedMean = 175.0 auto
{The movement speed when going from plant to plant, mean value}

float Property fTranslationSpeedVariance = 75.0 auto
{The movement speed when going from plant to plant, variance}

float Property fFleeTranslationSpeed = 500.0 auto
{The movement speed when fleeing from the player}

float Property fMinScale = 0.5 auto
{Minimum initial scale of the Dragonfly}

float Property fMaxScale = 0.8 auto
{Maximum initial scale of the Dragonfly}

float Property fSplineCurvature = 200.0 auto

float Property fMinTimeNotMoving = 1.0 auto

float Property fMaxTimeNotMoving = 5.0 auto

float Property fMinFleeHeight = 2000.0 auto

float Property fMaxFleeHeight = 3000.0 auto

float property fMaxRotationSpeed = 540.0 auto

;===============================================================================
;
; VARIABLES
;
;===============================================================================

bool bFoundClosestActor = false

float fLength

float fTargetX

float fTargetY

float fTargetZ

float fTargetAngleZ

float fTargetAngleX

;===============================================================================
;
; STATES
;
;===============================================================================

State Initalized

  Event OnUpdate()
    { Override .}
    GotoState("")

    if CheckCellAttached(self)
      OnStart()
    else
      DisableAndDelete()
    endif
  endEvent

endState

;===============================================================================
;
; EVENTS
;
;===============================================================================

Event OnUpdate()
  if CheckViableDistance()
    if bFoundClosestActor
      FlyAway(fFleeTranslationSpeed)
    else
      GotoNewPoint(Utility.RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance))
    endIf
  endIf
endEvent

;===============================================================================
;
; FUNCTIONS
;
;===============================================================================

Function OnStart()
  { Override .}
  SetScale(Utility.RandomFloat(fMinScale, fMaxScale))
  PlayAnimation(PathStartGraphEvent)
  WarpToRandomPoint()
  Enable()

  if CheckViability()
    return
  endif

  SetMotionType(Motion_Keyframed, false)
  RegisterForSingleUpdate(0.0)
endFunction

Function OnCritterGoalReached()
  { Override .}
  bFoundClosestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance) as bool

  if bFoundClosestActor
    RegisterForSingleUpdate(0.0)
  else
    RegisterForSingleUpdate(Utility.RandomFloat(fMinTimeNotMoving, fMaxTimeNotMoving))
  endIf
endFunction

Function WarpToRandomPoint()
  PickRandomPoint()
  SetPosition(fTargetX, fTargetY, fTargetZ)
  SetAngle(fTargetAngleX, 0.0, fTargetAngleZ)
endFunction

Function GotoNewPoint(float afSpeed)
  PickRandomPoint()

  if CheckViability()
    return
  endif

  SplineTranslateTo(fTargetX, ftargetY, ftargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)
endFunction

Function FlyAway(float afSpeed)
  PickRandomPointOutsideLeash()

  if CheckViability()
    return
  endif

  SplineTranslateTo(fTargetX, ftargetY, ftargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)
endFunction

Function PickRandomPoint()
  fLength = Utility.RandomFloat(0.0, fLeashLength)
  fTargetAngleZ = Utility.RandomFloat(-180.0, 180.0)
  fTargetX = fSpawnerX + fLength * Math.Cos(fTargetAngleZ)
  fTargetY = fSpawnerY + fLength * Math.Sin(fTargetAngleZ)
  fTargetZ = fSpawnerZ + Utility.RandomFloat(0.0, fHeight)
  fTargetAngleZ = Utility.RandomFloat(-180.0, 180.0)
  fTargetAngleX = 0.0
endFunction

Function PickRandomPointOutsideLeash()
  fLength = Utility.RandomFloat(fMaxPlayerDistance, fMaxPlayerDistance * 2.0)
  fTargetAngleZ = Utility.RandomFloat(-180.0, 180.0)
  fTargetX = fSpawnerX + fLength * Math.Cos(fTargetAngleZ)
  fTargetY = fSpawnerY + fLength * Math.Sin(fTargetAngleZ)
  fTargetZ = fSpawnerZ + Utility.RandomFloat(fMinFleeHeight, fMaxFleeHeight)
  fTargetAngleX = 0.0
endFunction
