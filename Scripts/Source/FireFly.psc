ScriptName Firefly extends Critter
{ Behavior script for firelies, bees, and other hovering insects. }

;===============================================================================
;
; PROPERTIES
;
;===============================================================================

FormList property PlantTypes auto
{ The list of plant types this firefly can be attracted to}

float Property fTimeAtPlantMin = 5.0 auto
{The Minimum time a Firefly stays at a plant}

float Property fTimeAtPlantMax = 10.0 auto
{The Maximum time a Firefly stays at a plant}

float Property fActorDetectionDistance = 300.0 auto
{The Distance at which an actor will trigger a flee behavior}

float Property fTranslationSpeedMean = 50.0 auto
{The movement speed when going from plant to plant, mean value}

float Property fTranslationSpeedVariance = 25.0 auto
{The movement speed when going from plant to plant, variance}

float Property fFleeTranslationSpeed = 100.0 auto
{The movement speed when fleeing from the player}

float Property fFlockPlayerXYDist = 100.0 auto
{When flocking the player, the XY random value to add to its location}

float Property fFlockPlayerZDistMin = 50.0 auto
{When flocking the player, the min Z value to add to its location}

float Property fFlockPlayerZDistMax = 200.0 auto
{When flocking the player, the max Z value to add to its location}

float Property fFlockTranslationSpeed = 300.0 auto
{When flocking the player, the speed at which to move}

float Property fMinScale = 0.3 auto
{Minimum initial scale of the Firefly}

float Property fMaxScale = 0.4 auto
{Maximum initial scale of the Firefly}

float property fMinTravel = 64.0 auto
{Minimum distance a wandering Firefly will travel}

float property fMaxTravel = 512.0 auto
{Maximum distance a wandering Firefly will travel}

float property fMaxRotationSpeed = 90.0 auto
{Max rotation speed while mocing, default = 90 deg/s}

;===============================================================================
;
; VARIABLES
;
;===============================================================================

ObjectReference currentPlant = none

float fWaitingToDieTimer = 10.0

bool bFoundClosestActor = false

int iGoToNewPlantChance = 20

;===============================================================================
;
; STATES
;
;===============================================================================

State AtPlant

  Event OnUpdate()
    if CheckViableDistance()
      if Spawner && Spawner.IsActiveTime()
        if bFoundClosestActor
          GoToNewPlant(fFleeTranslationSpeed)
        elseif Utility.RandomInt(1, 100) <= iGoToNewPlantChance
          GoToNewPlant(Utility.RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance))
        else
          HoverCloseBy()
        endIf
      else
        SplineTranslateToRefAtSpeedAndGotoState(Spawner, fTranslationSpeedMean, fMaxRotationSpeed, "KillForTheNight")
      endIf
    endIf
  endEvent

  Event OnCritterGoalReached()
    bFoundClosestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance) as bool

    if bFoundClosestActor
      RegisterForSingleUpdate(0.0)
    else
      RegisterForSingleUpdate(Utility.RandomFloat(fTimeAtPlantMin, fTimeAtPlantMax))
    endIf
  EndEvent

endState

State Hovering

  Event OnUpdate()
    if CheckViableDistance()
      if bFoundClosestActor
        GoToNewPlant(fFleeTranslationSpeed)
      elseif Utility.RandomInt(1, 100) <= iGoToNewPlantChance
        GoToNewPlant(Utility.RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance))
      else
        HoverCloseBy()
      endIf
    endIf
  EndEvent

  Event OnCritterGoalReached()
    bFoundClosestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance) as bool
    RegisterForSingleUpdate(0.0)
  EndEvent

endState

State KillForTheNight

  Event OnUpdate()
    DisableAndDelete()
  endEvent

  Event OnCritterGoalReached()
    RegisterForSingleUpdate(0.0)
  EndEvent

endState

;===============================================================================
;
; FUNCTIONS
;
;===============================================================================

Function OnStart()
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
  currentPlant = none
endFunction

Function HoverCloseBy()
  float ftargetX = X + Utility.RandomFloat(-20.0, 20.0)
  float ftargetY = Y + Utility.RandomFloat(-20.0, 20.0)
  float ftargetZ = Z + Utility.RandomFloat(-20.0, 20.0)
  float ftargetAngleZ = GetAngleZ() + Utility.RandomFloat(-20.0, 20.0)
  float ftargetAngleX = Utility.RandomFloat(-5.0, 5.0)

  if currentPlant && CheckFor3D(currentPlant) && fTargetZ < currentPlant.Z
    fTargetz = currentPlant.Z
  endif

  GotoState("Hovering")

  if CheckViability()
    return
  endIf

  TranslateTo(ftargetX, ftargetY, ftargetZ, ftargetAngleX, 0.0, ftargetAngleZ, Utility.RandomFloat(10, 30), fMaxRotationSpeed)
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
    endIf

  endWhile

  return none
endFunction

Function GoToNewPlant(float afSpeed)
  ObjectReference nextPlant = PickNextPlant()

  if nextPlant
    currentPlant = nextPlant
    SplineTranslateToRefAtSpeedAndGotoState(currentPlant, afSpeed, fMaxRotationSpeed, "AtPlant")
  else
    GoToState("KillForTheNight")
    RegisterForSingleUpdate(fWaitingToDieTimer)
  endIf
endFunction

Function WarpToNewPlant()
  ObjectReference nextPlant = PickNextPlant()

  if nextPlant
    currentPlant = nextPlant
    WarpToRefAndGotoState(CurrentPlant, "AtPlant")
  else
    GoToState("KillForTheNight")
    RegisterForSingleUpdate(fWaitingToDieTimer)
  endIf
endFunction
