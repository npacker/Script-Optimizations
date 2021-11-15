ScriptName CritterSpawn extends ObjectReference
{ Controller script for critter spawner .}

;===============================================================================
;
; PROPERTIES
;
;===============================================================================

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

;===============================================================================
;
; HIDDEN
;
;===============================================================================

int property iCurrentCritterCount = 0 auto hidden

;===============================================================================
;
; VARIABLES
;
;===============================================================================

float fCheckPlayerDistanceTime = 2.0

float fCheckConditionsGameTime = 0.25

;===============================================================================
;
; STATES
;
;===============================================================================

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
  endEvent

  Event OnUpdateGameTime()
    GotoState("")
    RegisterForSingleUpdate(fCheckPlayerDistanceTime)
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

;===============================================================================
;
; EVENTS
;
;===============================================================================

Event OnUpdate()
  TryToSpawnCritters()
endEvent

Event OnCellAttach()
  GotoState("")
  RegisterForSingleUpdate(fCheckPlayerDistanceTime)
endEvent

Event OnCellDetach()
  GotoState("DoneSpawningCritters")
endEvent

Event OnLoad()
  GotoState("")
  RegisterForSingleUpdate(fCheckPlayerDistanceTime)
endEvent

Event OnUnload()
  GotoState("DoneSpawningCritters")
endEvent

;===============================================================================
;
; FUNCTIONS
;
;===============================================================================

Function TryToSpawnCritters()
  if IsLoaded()
    if IsActiveTime()
      float fPlayerDistance = (Game.GetForm(0x14) as Actor).GetDistance(self)

      if fPlayerDistance <= fMaxPlayerDistance
        SpawnInitialCritterBatch()
        GotoState("DoneSpawningCritters")
      else
        RegisterForSingleUpdate(fCheckPlayerDistanceTime + (fPlayerDistance - fMaxPlayerDistance) * 0.001)
      endif
    else
      GotoState("PendingSpawnConditions")
    endif
  else
    GotoState("DoneSpawningCritters")
  endif
endFunction

Function SpawnInitialCritterBatch()
  int crittersToSpawn = iMaxCritterCount - iCurrentCritterCount

  while crittersToSpawn > 0
    crittersToSpawn -= 1
    SpawnCritterAtRef(self)
  endwhile
endFunction

Function SpawnCritterAtRef(ObjectReference arSpawnRef)
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
  if iCurrentCritterCount > 0
    iCurrentCritterCount -= 1
  else
    iCurrentCritterCount = 0
  endif
endFunction

bool Function IsActiveTime()
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
  Cell ParentCell = GetParentCell()
  return ParentCell && ParentCell.IsAttached() && Is3DLoaded()
endFunction
