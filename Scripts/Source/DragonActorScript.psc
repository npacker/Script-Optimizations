Scriptname dragonActorSCRIPT extends Actor
{ Base Actor Script for all Dragons. }

;-------------------------------------------------------------------------------
;
; PROPERTIES
;
;-------------------------------------------------------------------------------

ImageSpaceModifier property dragonFOVfx auto
{ FX played for various impacts in dragon combat.}

float property deathFXrange = 1024.0 auto
{ Max range to play death FX on player. }

Quest property MQkillDragon auto
{ Used to invoke deathSequence() function in MQKillDragonScript.psc}

Actor property Player auto Hidden
{ For quick reference and clean-looking script}

float property FOVfalloff auto Hidden
{ Choosing not to expose this and clutter the prop list in CS, since it won't be touched often}

Sound property NPCDragonFlyby auto
{ Sound played when dragon passes by a target}

Explosion property knockBackExplosion auto
{ Explosion used to knock back enemies}

Armor property SnowDragonSkin auto
{ Deprecated - do not use. }

Armor property TundraDragonSkin auto
{ Deprecated - do not use. }

Armor property forestDragonSkin auto
{ Deprecated - do not use. }

int property dragonBreed = 0 auto
{ Deprecated - do not use. }

WIFunctionsScript property WI auto
{ Pointer to WIFunctionsScript on WI quest. Used to create script event to get nearby NPCs to react to the death of the dragon}

ImpactDataSet property FXDragonTakeoffImpactSet auto
{ Impact data set to use for the dragon takeoff}

ImpactDataSet property FXDragonLandingImpactSet auto
{ Impact data set to use for the dragon landing}

ImpactDataSet property FXDragonTailstompImpactSet auto
{ Impact data set to use for the tailstomp}

; ADDED FOR DLC2
Location property DLC2ApocryphaLocation auto

; ADDED FOR DLC2
WorldSpace property DLC2ApocryphaWorld auto

;-------------------------------------------------------------------------------
;
; VARIABLES
;
;-------------------------------------------------------------------------------

bool MiraakintroductionHappened

bool MiraakAppeared

;-------------------------------------------------------------------------------
;
; EVENTS
;
;-------------------------------------------------------------------------------

Event OnInit()
  ; Just initialize any variables, etc.
  FOVfalloff = 1600.0

  if deathFXrange == 0.0
    deathFXrange = 1024.0
  endif

  if !isDead() && IsGhost()
    ; Redundancy check to prevent invincible, "ghosted" dragons from
    ; respawning.
    SetGhost(false)
  endif

  GoToState("Alive")
endEvent

Event OnReset()
  ; If we're resetting a previously-killed dragon, make sure it's not a ghost.
  SetGhost(false)
endEvent

Event OnLoad()
  ; Block rewritten by USKP which fixes bug of respawned dragons not burning
  ; up or giving the player a soul.
  if !IsDead()
    if IsGhost()
      ; Redundancy check to prevent invincible, "ghosted" dragons from
      ; respawning.
      SetGhost(false)
    endif

    RegisterForAnimationEvent(self, "DragonLandEffect")
    RegisterForAnimationEvent(self, "DragonForcefulLandEffect")
    RegisterForAnimationEvent(self, "DragonTakeoffEffect")
    RegisterForAnimationEvent(self, "DragonBiteEffect")
    RegisterForAnimationEvent(self, "DragonTailAttackEffect")
    RegisterForAnimationEvent(self, "DragonLeftWingAttackEffect")
    RegisterForAnimationEvent(self, "DragonRightWingAttackEffect")
    RegisterForAnimationEvent(self, "DragonPassByEffect")
    RegisterForAnimationEvent(self, "flightCrashLandStart")
    RegisterForAnimationEvent(self, "DragonKnockbackEvent")

    GoToState("Alive")
  endif
endEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
  ; USED TO GET DIALOGUE CONDITIONED ON DRAGON HAVING ATTACKED A TOWN -- only
  ; happens if he lands on the ground in a location - ie death, or to land to
  ; fight (not on a perch) see also DragonPerchScript

  ; USKP 2.0.3 - So. Now it seems like you won't even call this out of here with
  ; a None? Ok.....
  if akNewLoc != None
    WI.RegisterDragonAttack(akNewLoc, self)
  endif

  if !isDead() && IsGhost()
    ; Redundancy check to prevent invincible, "ghosted" dragons from respawning.
    SetGhost(false)
  endif
endEvent

;-------------------------------------------------------------------------------
;
; ALIVE
;
;-------------------------------------------------------------------------------

State Alive

  Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
    if !isDead() && IsGhost()
      ; Redundancy check to prevent invincible, "ghosted" dragons from
      ; respawning.
      SetGhost(false)
    endif

    if akTarget == (Game.GetForm(0x14) as Actor)
      ; Used to prevent dragons from appearing too frequently.
      WI.updateWIDragonTimer()
    endif
  endEvent

  Event OnAnimationEvent(ObjectReference akSource, string EventName)
    if EventName == "DragonLandEffect"
      Game.ShakeCamera(self, 1.0)
      Game.ShakeController(95.0, 95.0, 2.0)
      KnockAreaEffect(1.0, GetLength())
      AnimateFOV()
      PlayImpactEffect(FXDragonTakeoffImpactSet, "NPC Pelvis")
    endif

    if EventName == "DragonForcefulLandEffect"
      PlayImpactEffect(FXDragonLandingImpactSet, "NPC Pelvis")
      KnockAreaEffect(1.0, 2.0 * GetLength())
    endif

    if EventName == "DragonTakeoffEffect"
      PlayImpactEffect(FXDragonTakeoffImpactSet, "NPC Tail8", 0.0, 0.0, -1.0, 2048.0)
    endif

    if EventName == "DragonTailAttackEffect"
      PlayImpactEffect(FXDragonTailstompImpactSet, "NPC Tail8")
    endif

    if EventName == "DragonLeftWingAttackEffect"
      PlayImpactEffect(FXDragonTailstompImpactSet, "NPC LHand")
    endif

    if EventName == "DragonRightWingAttackEffect"
      PlayImpactEffect(FXDragonTailstompImpactSet, "NPC RHand")
    endif

    if EventName == "DragonPassByEffect"
      NPCDragonFlyby.Play(self)
      Game.ShakeCamera(self, 0.85)
      Game.ShakeController(0.65, 0.65, 0.5)
    endif

    if EventName == "DragonKnockbackEvent"
      float fLength = GetLength()
      ; Dragon needs to stagger everyone in radius a bit larger than its length.
      KnockAreaEffect(1.0, 1.5 * fLength)
      AnimateFOV(1.5 * fLength)
    endif
  endEvent

  Event OnDeath(Actor akKiller)
    ; USKP 2.1.3 Bug #19214 - Dialogue in the quest has options that get skipped
    ; with this line below the GoToState call.
    ;
    ; Used to create a scene if any NPCs are nearby when the dragon dies. See
    ; WIFunctionsScript attached to WI quest which creates a story manager script
    ; event, and WIDragonKilled quest which handles the scene.
    WI.startWIDragonKillQuest(self)
    GoToState("DeadAndWaiting")
  endEvent

endState

;-------------------------------------------------------------------------------
;
; DEAD AND WAITING
;
;-------------------------------------------------------------------------------

State DeadAndWaiting

  Event OnBeginState()
    Actor PlayerRef = Game.GetForm(0x14) as Actor

    ; If in Apocrypha, this is the boss fight so do not wait for distance.
    if DLC2ApocryphaLocation && DLC2ApocryphaWorld && PlayerRef.GetWorldSpace() == DLC2ApocryphaWorld
      GoToState("DeadAndDisintegrated")
      (MQkillDragon as MQKillDragonScript).deathSequence(self)
    elseif (MQkillDragon as MQKillDragonScript).ShouldMiraakAppear(self) && !MiraakAppeared
      MiraakAppeared = true
      GoToState("DeadAndDisintegrated")
      (MQkillDragon as MQKillDragonScript).deathSequence(self, MiraakAppears = true)
    else
      if GetDistance(PlayerRef) > deathFXrange
        RegisterForSingleUpdate(1.0)
      else
        UnregisterForUpdate()
        GoToState("DeadAndDisintegrated")
        (MQkillDragon as MQKillDragonScript).deathSequence(self)
      endif
    endif
  endEvent

  Event OnUpdate()
    if GetDistance(Game.GetForm(0x14) as Actor) > deathFXrange
      RegisterForSingleUpdate(1.0)
    else
      UnregisterForUpdate()
      GoToState("DeadAndDisintegrated")
      (MQkillDragon as MQKillDragonScript).deathSequence(self)
    endif
  endEvent

endState

;-------------------------------------------------------------------------------
;
; DEAD AND DISINTEGRATED
;
;-------------------------------------------------------------------------------

State DeadAndDisintegrated

  Event OnBeginState()
    UnregisterForUpdate()
    UnregisterForAnimationEvent(self, "DragonLandEffect")
    UnregisterForAnimationEvent(self, "DragonForcefulLandEffect")
    UnregisterForAnimationEvent(self, "DragonTakeoffEffect")
    UnregisterForAnimationEvent(self, "DragonBiteEffect")
    UnregisterForAnimationEvent(self, "DragonTailAttackEffect")
    UnregisterForAnimationEvent(self, "DragonLeftWingAttackEffect")
    UnregisterForAnimationEvent(self, "DragonRightWingAttackEffect")
    UnregisterForAnimationEvent(self, "DragonPassByEffect")
    UnregisterForAnimationEvent(self, "flightCrashLandStart")
    UnregisterForAnimationEvent(self, "DragonKnockbackEvent")
  endEvent

  Event OnLoad()
    Cleanup()
  endEvent

  Event OnUnload()
    Cleanup()
  endEvent

endState

;-------------------------------------------------------------------------------
;
; FUNCTIONS
;
;-------------------------------------------------------------------------------

Function Cleanup()
  if (GetBaseObject() as ActorBase) != Game.GetFormFromFile(0x0030D8, "Dawnguard.esm")
    DispelAllSpells()
    SetCriticalStage(CritStage_Disintegrateend)
  endif
endFunction

Function AnimateFOV(float afFOVfalloff = 1600.0)
{
  Function that animates FOV with an ismod. Declaring here in case needed
  frequently.
}
  float fDistance = (Game.GetForm(0x14) as Actor).GetDistance(self)

  if fDistance < afFOVfalloff
    float fPower = 1.0 - (1.0 / (afFOVfalloff / fDistance))

    if fPower > 1.0
      fPower = 1.0
    endif

    dragonFOVfx.Apply(fPower)
  endif
endFunction
