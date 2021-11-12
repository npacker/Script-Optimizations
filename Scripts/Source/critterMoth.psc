ScriptName CritterMoth extends Critter
{Main Behavior script for moths and butterflies}

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

float property fBellShapePathHeight = 150.0 auto
{The height of the bell shaped path}

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

string property LandingMarkerPrefix = "LandingSmall0" auto
{Prefix of landing markers on plants, default="LandingSmall0"}

;===============================================================================
;
; VARIABLES
;
;===============================================================================

int iPlantTypeCount = 0

float fWaitingToDieTimer = 10.0

Actor closestActor

ObjectReference currentPlant

;===============================================================================
;
; STATES
;
;===============================================================================

State AtPlant

  Event OnUpdate()
    if CheckViableDistance()
      if Spawner && Spawner.IsActiveTime()
        float fspeed = 0.0

        if closestActor
          fspeed = fFleeTranslationSpeed
        else
          fspeed = Utility.RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance)
        endif

        GoToNewPlant(fspeed)
      else
        BellShapeTranslateToRefAtSpeedAndGotoState(Spawner, fBellShapePathHeight, fTranslationSpeedMean, fMaxRotationSpeed, "KillForTheNight")
      endif

      bCalculating = false
    endif

    closestActor = none
  endEvent

  Function OnCritterGoalReached()
    if PlayerRef
      closestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance)

      if closestActor
        RegisterForSingleUpdate(0.0)
      else
        RegisterForSingleUpdate(Utility.RandomFloat(fTimeAtPlantMin, fTimeAtPlantMax))
      endif
    endif
  endFunction

endState

State KillForTheNight

  Event OnUpdate()
    DisableAndDelete()
  endEvent

  Function OnCritterGoalReached()
    if PlayerRef
      RegisterForSingleUpdate(0.0)
    endif
  endFunction

endState

;===============================================================================
;
; FUNCTIONS
;
;===============================================================================

Function OnStart()
  iPlantTypeCount = PlantTypes.GetSize()
  SetScale(Utility.RandomFloat(fMinScale, fMaxScale))
  WarpToNewPlant()
  Enable()

  if CheckFor3D(self)
    SetMotionType(Motion_Keyframed, false)
    RegisterForSingleUpdate(0.0)
  else
    DisableAndDelete(false)
  endif
endFunction

Function TargetClear()
  currentPlant = none
endFunction

ObjectReference Function PickNextPlant()
  ObjectReference newPlant = none
  int iMaxTries = 10

  while PlayerRef && iMaxTries > 0
    newPlant = Game.FindRandomReferenceOfAnyTypeInList(PlantTypes, fSpawnerX, fSpawnerY, fSpawnerZ, fLeashLength)

    if newPlant != none \
        && newPlant != currentPlant \
        && !newPlant.IsDisabled() \
        && Game.FindClosestActorFromRef(newPlant, fActorDetectionDistance) == none \
        && CheckCellAttached(newPlant) \
        && CheckFor3D(newPlant)
      return newPlant
    endif

    iMaxTries -= 1
  endWhile

  return none
endFunction

Function GoToNewPlant(float afSpeed)
  ObjectReference newPlant = PickNextPlant()

  if newPlant
    currentPlant = newPlant
    string sLandingMarkerName = LandingMarkerPrefix + Utility.RandomInt(1, 3)

    if newPlant.HasNode(sLandingMarkerName)
      BellShapeTranslateToRefNodeAtSpeedAndGotoState(CurrentPlant, sLandingMarkerName, fBellShapePathHeight, afSpeed, fMaxRotationSpeed, "AtPlant")
    else
      string sFirstMarkerName = LandingMarkerPrefix + 1

      if newPlant.HasNode(sFirstMarkerName)
        BellShapeTranslateToRefNodeAtSpeedAndGotoState(CurrentPlant, sFirstMarkerName, fBellShapePathHeight, afSpeed, fMaxRotationSpeed, "AtPlant")
      else
        BellShapeTranslateToRefAtSpeedAndGotoState(CurrentPlant, fBellShapePathHeight, afSpeed, fMaxRotationSpeed, "AtPlant")
      endif
    endif
  else
    GoToState("KillForTheNight")
    RegisterForSingleUpdate(fWaitingToDieTimer)
  endif
endFunction

Function WarpToNewPlant()
  ObjectReference newPlant = PickNextPlant()

  if newPlant
    currentPlant = newPlant
    string sLandingMarkerName = LandingMarkerPrefix + Utility.RandomInt(1, 3)

    if newPlant.HasNode(sLandingMarkerName)
      WarpToRefNodeAndGotoState(CurrentPlant, sLandingMarkerName, "AtPlant")
    else
      string sFirstMarkerName = LandingMarkerPrefix + 1

      if newPlant.HasNode(sFirstMarkerName)
        WarpToRefNodeAndGotoState(CurrentPlant, sFirstMarkerName, "AtPlant")
      else
        WarpToRefAndGotoState(CurrentPlant, "AtPlant")
      endif
    endif
  else
    GoToState("KillForTheNight")
    RegisterForSingleUpdate(fWaitingToDieTimer)
  endif
endFunction

Function DoPathStartStuff()
  SetAnimationVariableFloat("fTakeOff", 1.0)
endFunction

Function DoPathendStuff()
  SetAnimationVariableFloat("fTakeOff", 0.0)
endFunction
