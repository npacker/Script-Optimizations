Scriptname dunProgressiveCombatScript extends ObjectReference
{
  Script for managing a large-scale ambush-based combat, keeping a fixed number
  of enemies active at once.
}

;-------------------------------------------------------------------------------
;
; PROPERTIES
;
;-------------------------------------------------------------------------------

ObjectReference Property BattleManager Auto
{The topmost enemy 'manager' in the chain.}

Keyword Property EnemyLinkKeyword Auto
{Keyword for the enemy links.}

Int Property simultaneousEnemies Auto
{Max number of simultaneous enemies to be active at a time.}

Bool Property isActive Auto
{Whether this ambush is active.}

Bool Property startsActive = false Auto
{Whether the first set of enemies should be activated on cell load. Otherwise, the battle begins when this ref is activated.}

Float Property delay = 0.0 Auto
{Insert this delay before each enemy activation beyond the first.}

Float Property updateTime = 1.0 Auto
{Update interval.}

ObjectReference Property refActivateOnComplete Auto
{Ref to activate when the battle is complete (all enemies activated and killed)}

Bool Property useSmallRandomDelay = True Auto
{Add a random delay to enemy activations to avoid synchronization.}

Int Property totalEnemies Auto Hidden

Bool Property doOnce Auto Hidden

Bool Property breakLoop Auto Hidden

Bool Property busy Auto Hidden

;-------------------------------------------------------------------------------
;
; VARIABLES
;
;-------------------------------------------------------------------------------

Int CurrentEnemyIndex = 0

Bool InitialEnemyActivated = False

;-------------------------------------------------------------------------------
;
; EVENTS
;
;-------------------------------------------------------------------------------

Event OnLoad()

  HandleLoad()

EndEvent

Event OnUnload()

  UnregisterForUpdate()

EndEvent

Event OnCellAttach()

  HandleLoad()

EndEvent

Event OnCellDetach()

  UnregisterForUpdate()

EndEvent

Event OnActivate(ObjectReference Object)

  isActive = True

  StartUpdating()

EndEvent

Event OnUpdate()

  If isActive
    RunUpdate()
    RegisterForSingleUpdate(1.0)
  EndIf

EndEvent

;-------------------------------------------------------------------------------
;
; FUNCTIONS
;
;-------------------------------------------------------------------------------

Function HandleLoad()

  If !doOnce
    isActive = startsActive
  EndIf

  StartUpdating()

EndFunction

Function StartUpdating()

  totalEnemies = BattleManager.CountLinkedRefChain()

  If isActive
    RunUpdate()
    RegisterForSingleUpdate(1.0)
  EndIf

EndFunction

Function RunUpdate()

  If EnemyLinkKeyword
    isActive = UpdateBattle()
  Else
    isActive = False
  EndIf

  If !isActive && refActivateOnComplete
    refActivateOnComplete.Activate(Self)
  EndIf

EndFunction

Bool Function UpdateBattle()

  If busy
    Return True
  EndIf

  busy = True

  While CountActiveEnemies(BattleManager, CurrentEnemyIndex) < simultaneousEnemies && CurrentEnemyIndex < totalEnemies
    If InitialEnemyActivated
      Utility.Wait(delay)
    Else
      InitialEnemyActivated = True
    EndIf

    If useSmallRandomDelay
      Utility.Wait(Utility.RandomFloat(0.0, 0.5))
    EndIf

    ActivateNextEnemy()
  EndWhile

  busy = False

  Return (CurrentEnemyIndex < totalEnemies)

EndFunction

Int Function CountActiveEnemies(ObjectReference Manager, Int LinksToCount)

  If LinksToCount > 0
    ObjectReference NextEnemy = Manager.GetLinkedRef(EnemyLinkKeyword)

    If !NextEnemy || (NextEnemy as Actor).IsDead()
      Return CountActiveEnemies(Manager.GetLinkedRef(), LinksToCount - 1)
    Else
      Return 1 + CountActiveEnemies(Manager.GetLinkedRef(), LinksToCount - 1)
    EndIf
  EndIf

  Return 0

EndFunction

ObjectReference Function ActivateNextEnemy()

  ObjectReference NextEnemy = BattleManager.GetNthLinkedRef(CurrentEnemyIndex).GetLinkedRef(EnemyLinkKeyword)

  CurrentEnemyIndex += 1

  If NextEnemy
    NextEnemy.Activate(Self)

    If (NextEnemy As Actor).IsDead()
      NextEnemy = None

      If CurrentEnemyIndex < totalEnemies
        NextEnemy = ActivateNextEnemy()
      EndIf
    EndIf
  EndIf

  Return NextEnemy

EndFunction

Function ActivateAllEnemies()

  While CurrentEnemyIndex < totalEnemies
    ActivateNextEnemy()
  EndWhile

EndFunction

Function ActivateAndKillAllEnemies()

  While CurrentEnemyIndex < totalEnemies
    ObjectReference NextEnemy = ActivateNextEnemy()

    If NextEnemy
      (NextEnemy as Actor).Kill()
    EndIf
  EndWhile

EndFunction
