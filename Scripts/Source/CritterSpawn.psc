ScriptName CritterSpawn extends ObjectReference
{ Controller script for critter spawner .}

;-------------------------------------------------------------------------------
;
; PROPERTIES
;
;-------------------------------------------------------------------------------

GlobalVariable property GameHour auto
{ Make this point to the GameHour global }

FormList property CritterTypes auto
{ The base object to create references of to spawn critters. }

int property iMaxCritterCount = 10 auto
{ The maximum number of critters this spawner can generate. }

float property fMaxPlayerDistance = 2000.0 auto
{ The distance from the player before the Spawner stops spawning critters. }

float property fStartSpawnTime = 6.0 auto
{ The Time after which this spawner can be active. }

float property fEndSpawnTime = 11.0 auto
{ The Time before which this spawner can be active. }

float property fFastSpawnInterval = 0.1 auto
{ When spawning critters, the interval between spawns. }

float property fSlowSpawnInterval = 5.0 auto
{ When spawning critters, the interval between spawns. }

float property fLeashLength = 500.0 auto
{ The distance that moths are allowed to be from this spawner. }

float property fLeashHeight = 50.0 auto
{ The distance that dragonflies are allowed to be from above spawner. }

float property fLeashDepth = 50.0 auto
{ The distance that fish are allowed to be from below spawner. }

float property fLeashOverride auto
{ Optional: Manually set roaming radius for critters spawned. }

bool property bSpawnInPrecipitation auto
{ Should this critter spawn in rain/snow? }

;-------------------------------------------------------------------------------
;
; HIDDEN
;
;-------------------------------------------------------------------------------

int property iCurrentCritterCount = 0 auto hidden

;-------------------------------------------------------------------------------
;
; VARIABLES
;
;-------------------------------------------------------------------------------

float fCheckPlayerDistanceTime = 2.0

float fCheckConditionsGameTime = 0.25

;-------------------------------------------------------------------------------
;
; STATES
;
;-------------------------------------------------------------------------------

State DoneSpawningCritters

  Event OnBeginState()
    { Override. }
  endEvent

  Event OnUpdate()
    { Override. }
  endEvent

  Event OnUpdateGameTime()
    { Override. }
  endEvent

  Event OnCellDetach()
    { Override. }
  endEvent

  Event OnUnload()
    { Override. }
  endEvent

  Function TryToSpawnCritters()
    { Override. }
  endFunction

  Function SpawnInitialCritterBatch()
    { Override. }
  endFunction

  Function SpawnCritterAtRef(ObjectReference arSpawnRef)
    { Override. }
  endFunction

endState

State PendingSpawnConditions

  Event OnBeginState()
    RegisterForSingleUpdateGameTime(fCheckConditionsGameTime)
  endEvent

  Event OnUpdate()
    { Override. }
    Debug.Trace(GetState() + " - OnUpdate - " + self)
  endEvent

  Event OnUpdateGameTime()
    Debug.Trace(GetState() + " - OnUpdateGameTime - " + self)
    GoToState("")
    RegisterForSingleUpdate(fCheckPlayerDistanceTime)
  endEvent

endState

;-------------------------------------------------------------------------------
;
; EVENTS
;
;-------------------------------------------------------------------------------

Event OnUpdate()
  Debug.Trace(GetState() + " - OnUpdate - " + self)
  TryToSpawnCritters()
endEvent

Event OnCellAttach()
  Debug.Trace(GetState() + " - OnCellAttach - " + self)
  GoToState("")
  RegisterForSingleUpdate(fCheckPlayerDistanceTime)
endEvent

Event OnCellDetach()
  Debug.Trace(GetState() + " - OnCellDetach - " + self)
  GoToState("DoneSpawningCritters")
endEvent

Event OnLoad()
  Debug.Trace(GetState() + " - OnLoad - " + self)
  GoToState("")
  RegisterForSingleUpdate(fCheckPlayerDistanceTime)
endEvent

Event OnUnload()
  Debug.Trace(GetState() + " - OnUnload - " + self)
  GoToState("DoneSpawningCritters")
endEvent

;-------------------------------------------------------------------------------
;
; FUNCTIONS
;
;-------------------------------------------------------------------------------

Function TryToSpawnCritters()
  Debug.Trace(GetState() + " - TryToSpawnCritters - " + self)
  if IsLoaded()
    if IsActiveTime()
      float fPlayerDistance = (Game.GetForm(0x14) as Actor).GetDistance(self)

      if fPlayerDistance <= fMaxPlayerDistance
        SpawnInitialCritterBatch()
        GoToState("DoneSpawningCritters")
      else
        RegisterForSingleUpdate(fCheckPlayerDistanceTime + (fPlayerDistance - fMaxPlayerDistance) * 0.001)
      endif
    else
      GoToState("PendingSpawnConditions")
    endif
  else
    GoToState("DoneSpawningCritters")
  endif
endFunction

Function SpawnInitialCritterBatch()
  Debug.Trace(GetState() + " - SpawnInitialCritterBatch - " + self)
  int crittersToSpawn = iMaxCritterCount - iCurrentCritterCount

  while crittersToSpawn > 0
    crittersToSpawn -= 1
    SpawnCritterAtRef(self)
  endWhile
endFunction

Function SpawnCritterAtRef(ObjectReference arSpawnRef)
  Debug.Trace(GetState() + " - SpawnCritterAtRef - " + self)
  Activator critterType = CritterTypes.GetAt(Utility.RandomInt(0, CritterTypes.GetSize() - 1)) as Activator

  if critterType == none
    return
  endif

  Critter spawnedCritter = none

  if IsLoaded()
    spawnedCritter = arSpawnRef.PlaceAtMe(critterType, 1, false, true) as Critter
  endif

  if spawnedCritter == none
    return
  endif

  spawnedCritter.SetInitialSpawnerProperties(fLeashLength, fLeashHeight, fLeashDepth, fMaxPlayerDistance + fLeashLength, self)
  iCurrentCritterCount += 1
endFunction

Function OnCritterDied()
  Debug.Trace(GetState() + " - OnCritterDied - " + self)
  if iCurrentCritterCount > 0
    iCurrentCritterCount -= 1
  else
    iCurrentCritterCount = 0
  endif
endFunction

bool Function IsActiveTime()
  Debug.Trace(GetState() + " - IsActiveTime - " + self)
  bool bInTimeRange = false

  if GameHour == none
    return false
  endif

  float fCurrentGameHour = GameHour.GetValue()

  if fEndSpawnTime >= fStartSpawnTime
    bInTimeRange = fCurrentGameHour >= fStartSpawnTime && fCurrentGameHour < fEndSpawnTime
  else
    bInTimeRange = fCurrentGameHour >= fStartSpawnTime || fCurrentGameHour < fEndSpawnTime
  endif

  bool bWeatherConditionsMet = bSpawnInPrecipitation || Weather.GetCurrentWeather() == none || Weather.GetCurrentWeather().GetClassification() < 2
  return bInTimeRange && bWeatherConditionsMet
endFunction

bool Function IsLoaded()
  Debug.Trace(GetState() + " - IsLoaded - " + self)
  Cell ParentCell = GetParentCell()
  return ParentCell && ParentCell.IsAttached() && Is3DLoaded()
endFunction
