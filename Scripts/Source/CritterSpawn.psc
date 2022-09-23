ScriptName CritterSpawn extends ObjectReference
{ Controller script for critter spawner.}

;===============================================================================
;
; PROPERTIES
;
;===============================================================================

GlobalVariable property GameHour auto
{ Make this point to the GameHour global. }

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
{ Whether this critter should spawn in rain or snow. }

;===============================================================================
;
; HIDDEN
;
;===============================================================================

int property iCurrentCritterCount = 0 auto hidden

Cell _ParentCell
Cell Property ParentCell hidden
  Cell Function Get()
    if _ParentCell == none
      _ParentCell = GetParentCell()
    endif
    return _ParentCell
  endFunction
endProperty

Actor _PlayerRef
Actor Property PlayerRef hidden
  Actor Function Get()
    if _PlayerRef == none
      _PlayerRef = Game.GetForm(0x14) as Actor
    endif
    return _PlayerRef
  endFunction
endProperty

;===============================================================================
;
; VARIABLES
;
;===============================================================================

float fCheckPlayerDistanceTime = 2.0

float fRandomizationInterval = 0.1

float fCheckConditionsGameTime = 0.25

float fPlayerDistanceScalingFactor = 0.001

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

  bool Function IsLoaded()
    { Override. }
    return false
  endFunction

endState

State PendingSpawnConditions

  Event OnBeginState()
    RegisterForSingleUpdateGameTime(fCheckConditionsGameTime + Utility.RandomFloat(fRandomizationInterval * -1.0, fRandomizationInterval))
  endEvent

  Event OnUpdate()
    { Override. }
  endEvent

  Event OnUpdateGameTime()
    GotoState("")
    RegisterForPlayerDistanceCheck()
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

State SpawningCritters

  Event OnUpdate()
    { Override. }
  endEvent

  Event OnUpdateGameTime()
    { Override. }
  endEvent

  Event OnCellAttach()
    { Override. }
  endEvent

  Event OnLoad()
    { Override. }
  endEvent

  Function TryToSpawnCritters()
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
  RegisterForPlayerDistanceCheck()
endEvent

Event OnLoad()
  GotoState("")
  RegisterForPlayerDistanceCheck()
endEvent

Event OnCellDetach()
  GotoState("DoneSpawningCritters")
endEvent

Event OnUnload()
  GotoState("DoneSpawningCritters")
endEvent

;===============================================================================
;
; FUNCTIONS
;
;===============================================================================

Function RegisterForPlayerDistanceCheck()
  RegisterForSingleUpdate(fCheckPlayerDistanceTime + Utility.RandomFloat(fRandomizationInterval * -1.0, fRandomizationInterval))
endFunction

Function TryToSpawnCritters()
  if IsLoaded()
    if IsActiveTime()
      float fPlayerDistance = PlayerRef.GetDistance(self)

      if fPlayerDistance <= fMaxPlayerDistance
        GotoState("SpawningCritters")
        SpawnInitialCritterBatch()
        GotoState("DoneSpawningCritters")
      else
        RegisterForSingleUpdate(fCheckPlayerDistanceTime + (fPlayerDistance - fMaxPlayerDistance) * fPlayerDistanceScalingFactor)
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
  return ParentCell != none && ParentCell.IsAttached() && Is3DLoaded()
endFunction
