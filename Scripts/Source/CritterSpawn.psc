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

  Event OnCellDetach()
    { Override. }
  endEvent

  Event OnUnload()
    { Override. }
  endEvent

  bool Function IsLoaded()
    { Override. }
    return false
  endFunction

endState

State PendingSpawnConditions

  Event OnBeginState()
    RegisterForSingleUpdateGameTime(fCheckConditionsGameTime + Utility.RandomFloat(fRandomizationInterval * -1.0, fRandomizationInterval))
  endEvent

  Event OnUpdateGameTime()
    GotoState("ReadyToSpawnCritters")
    RegisterForPlayerDistanceCheck()
  endEvent

  Event OnCellAttach()
    { Override. }
  endEvent

  Event OnLoad()
    { Override. }
  endEvent

endState

State ReadyToSpawnCritters

  Event OnBeginState()
    iCurrentCritterCount = 0
  endEvent

  Event OnUpdate()
    TryToSpawnCritters()
  endEvent

  Event OnCellAttach()
    { Override. }
  endEvent

  Event OnLoad()
    { Override. }
  endEvent

  Function TryToSpawnCritters()
    if IsLoaded()
      if IsActiveTime()
        float fPlayerDistance = (Game.GetForm(0x14) as Actor).GetDistance(self)

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

endState

State SpawningCritters

  Event OnCellAttach()
    { Override. }
  endEvent

  Event OnLoad()
    { Override. }
  endEvent

  Function SpawnInitialCritterBatch()
    int iCrittersToSpawn = iMaxCritterCount - iCurrentCritterCount

    while iCrittersToSpawn > 0
      iCrittersToSpawn -= 1

      if SpawnCritterAtRef(self)
        iCurrentCritterCount += 1
      endif
    endwhile
  endFunction

  bool Function SpawnCritterAtRef(ObjectReference arSpawnRef)
    Activator kCritterType = CritterTypes.GetAt(Utility.RandomInt(0, CritterTypes.GetSize() - 1)) as Activator

    if kCritterType == none
      return false
    endif

    Critter kSpawnedCritter = none

    if IsLoaded()
      kSpawnedCritter = arSpawnRef.PlaceAtMe(kCritterType, 1, false, true) as Critter
    endif

    if kSpawnedCritter == none
      return false
    endif

    kSpawnedCritter.SetInitialSpawnerProperties(fLeashLength, fLeashHeight, fLeashDepth, fMaxPlayerDistance + fLeashLength, self)
    return true
  endFunction

endState

;===============================================================================
;
; EVENTS
;
;===============================================================================

Event OnCellAttach()
  GotoState("ReadyToSpawnCritters")
  RegisterForPlayerDistanceCheck()
endEvent

Event OnLoad()
  GotoState("ReadyToSpawnCritters")
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
  { Empty. }
endFunction

Function SpawnInitialCritterBatch()
  { Empty. }
endFunction

bool Function SpawnCritterAtRef(ObjectReference arSpawnRef)
  { Empty. }
endFunction

Function OnCritterDied()
  if iCurrentCritterCount > 0
    iCurrentCritterCount -= 1
  else
    iCurrentCritterCount = 0
  endif
endFunction

bool Function IsLoaded()
  Cell kParentCell = GetParentCell()
  return kParentCell != none && kParentCell.IsAttached() && Is3DLoaded()
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

  Weather kCurrentWeather = Weather.GetCurrentWeather()

  bool bWeatherConditionsMet = bSpawnInPrecipitation || kCurrentWeather == none || kCurrentWeather.GetClassification() < 2
  return bInTimeRange && bWeatherConditionsMet
endFunction
