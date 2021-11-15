ScriptName CritterMoth extends Critter
{  Behavior script for moths and butterflies. }

;===============================================================================
;
; PROPERTIES
;
;===============================================================================

FormList property PlantTypes auto
{ The list of plant types this moth can be attracted to}

float property fTimeAtPlantMin = 5.0 auto
{The Minimum time a Moth stays at a plant}

float property fTimeAtPlantMax = 10.0 auto
{The Maximum time a Moth stays at a plant}

float property fActorDetectionDistance = 300.0 auto
{The Distance at which an actor will trigger a flee behavior}

float property fTranslationSpeedMean = 150.0 auto
{The movement speed when going from plant to plant, mean value}

float property fTranslationSpeedVariance = 50.0 auto
{The movement speed when going from plant to plant, variance}

float property fFleeTranslationSpeed = 300.0 auto
{The movement speed when fleeing from the player}

float property fFlockPlayerXYDist = 100.0 auto
{When flocking the player, the XY random value to add to its location}

float property fFlockPlayerZDistMin = 50.0 auto
{When flocking the player, the min Z value to add to its location}

float property fFlockPlayerZDistMax = 200.0 auto
{When flocking the player, the max Z value to add to its location}

float property fFlockTranslationSpeed = 300.0 auto
{When flocking the player, the speed at which to move}

float property fMinScale = 0.5 auto
{Minimum initial scale of the Moth}

float property fMaxScale = 1.2 auto
{Maximum initial scale of the Moth}

float property fMinTravel = 64.0 auto
{Minimum distance a wandering moth/butterfly will travel}

float property fMaxTravel = 512.0 auto
{Maximum distance a wandering moth/butterfly will travel}

float property fMaxRotationSpeed = 90.0 auto
{Max rotation speed while mocing, default = 90 deg/s}

float property fBellShapePathHeight = 150.0 auto
{The height of the bell shaped path}

string property LandingMarkerPrefix = "LandingSmall0" auto
{Prefix of landing markers on plants, default="LandingSmall0"}

;===============================================================================
;
; VARIABLES
;
;===============================================================================

ObjectReference currentPlant = none

float fWaitingToDieTimer = 10.0

bool bFoundClosestActor = false

;===============================================================================
;
; STATES
;
;===============================================================================

State AtPlant

  Event OnUpdate()
    { Override .}
    if CheckViableDistance()
      if Spawner && Spawner.IsActiveTime()
        if bFoundClosestActor
          GotoNewPlant(fFleeTranslationSpeed)
        else
          GotoNewPlant(Utility.RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance))
        endif
      else
        BellShapeTranslateToRefAtSpeedAndGotoState(Spawner, fBellShapePathHeight, fTranslationSpeedMean, fMaxRotationSpeed, "KillForTheNight")
      endif
    endif
  endEvent

  Function OnCritterGoalReached()
    { Override .}
    bFoundClosestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance) as bool

    if bFoundClosestActor
      RegisterForSingleUpdate(0.0)
    else
      RegisterForSingleUpdate(Utility.RandomFloat(fTimeAtPlantMin, fTimeAtPlantMax))
    endif
  endFunction

endState

State KillForTheNight

  Function OnCritterGoalReached()
    { Override .}
    RegisterForSingleUpdate(0.0)
  endFunction

endState

;===============================================================================
;
; FUNCTIONS
;
;===============================================================================

Function OnStart()
  { Override .}
  SetScale(Utility.RandomFloat(fMinScale, fMaxScale))
  WarpToNewPlant()
  Enable()

  if CheckViability()
    return
  endif

  SetMotionType(Motion_Keyframed, false)
  RegisterForSingleUpdate(0.0)
endFunction

Function TargetClear()
  { Override .}
  currentPlant = none
endFunction

ObjectReference Function PickNextPlant()
  int iMaxTries = 10

  while iMaxTries > 0
    iMaxTries -= 1
    ObjectReference nextPlant = Game.FindRandomReferenceOfAnyTypeInList(PlantTypes, fSpawnerX, fSpawnerY, fSpawnerZ, fLeashLength)

    if nextPlant \
        && nextPlant != currentPlant \
        && !nextPlant.IsDisabled() \
        && Game.FindClosestActorFromRef(nextPlant, fActorDetectionDistance) == none \
        && CheckCellAttached(nextPlant) \
        && CheckFor3D(nextPlant)
      return nextPlant
    endif
  endwhile

  return none
endFunction

Function GotoNewPlant(float afSpeed)
  ObjectReference nextPlant = PickNextPlant()

  if nextPlant
    currentPlant = nextPlant
    string sLandingMarkerName = LandingMarkerPrefix + Utility.RandomInt(1, 3)

    if nextPlant.HasNode(sLandingMarkerName)
      BellShapeTranslateToRefNodeAtSpeedAndGotoState(currentPlant, sLandingMarkerName, fBellShapePathHeight, afSpeed, fMaxRotationSpeed, "AtPlant")
    else
      string sFirstMarkerName = LandingMarkerPrefix + 1

      if nextPlant.HasNode(sFirstMarkerName)
        BellShapeTranslateToRefNodeAtSpeedAndGotoState(currentPlant, sFirstMarkerName, fBellShapePathHeight, afSpeed, fMaxRotationSpeed, "AtPlant")
      else
        BellShapeTranslateToRefAtSpeedAndGotoState(currentPlant, fBellShapePathHeight, afSpeed, fMaxRotationSpeed, "AtPlant")
      endif
    endif
  else
    GotoState("KillForTheNight")
    RegisterForSingleUpdate(fWaitingToDieTimer)
  endif
endFunction

Function WarpToNewPlant()
  ObjectReference nextPlant = PickNextPlant()

  if nextPlant
    currentPlant = nextPlant
    string sLandingMarkerName = LandingMarkerPrefix + Utility.RandomInt(1, 3)

    if nextPlant.HasNode(sLandingMarkerName)
      WarpToRefNodeAndGotoState(currentPlant, sLandingMarkerName, "AtPlant")
    else
      string sFirstMarkerName = LandingMarkerPrefix + 1

      if nextPlant.HasNode(sFirstMarkerName)
        WarpToRefNodeAndGotoState(currentPlant, sFirstMarkerName, "AtPlant")
      else
        WarpToRefAndGotoState(currentPlant, "AtPlant")
      endif
    endif
  else
    GotoState("KillForTheNight")
    RegisterForSingleUpdate(fWaitingToDieTimer)
  endif
endFunction

Function DoPathStartStuff()
  SetAnimationVariableFloat("fTakeOff", 1.0)
endFunction

Function DoPathendStuff()
  SetAnimationVariableFloat("fTakeOff", 0.0)
endFunction
