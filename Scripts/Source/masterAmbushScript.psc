ScriptName masterAmbushScript extends Actor
{
  Script that lives on the actor and takes care of all instances of how an actor
  can come out of idle state while in ambush mode.
}

;-------------------------------------------------------------------------------
;
; PROPERTIES
;
;-------------------------------------------------------------------------------

Keyword property linkKeyword auto
{
  If this has a linkedRef with this keyword, we will activate it once when hit,
  activated, or on combat begin
}

bool property ambushOnTrigger = false auto
{
  By default, this is set to false. Set to true if you want encounter to come
  out of ambush when player enters trigger.
}

String property sActorVariable = "Variable01" auto hidden
{ By default, this property is set to Variable01. }

float property fActorVariable = 1.0 auto hidden
{ By default this property is set to 1. }

float property fActorVariableOnReset = 0.0 auto hidden
{ Value to assign to fActorVariable on reset. }

float property fAggression = 2.0 auto hidden
{
  By default this property is set to 2 (very aggressive).

    0 - Unaggressive - will not initiate combat
    1 - Aggressive - will attack enemies on sight
    2 - Very Aggressive - Will attack enemies and neutrals on sight
    3 - Frenzied - Will attack anyone else
}

float property fAggressionOnReset = 0.0 auto hidden
{ Aggression to assume after reset. Defaults to Unaggressive. }

;-------------------------------------------------------------------------------
;
; EVENTS
;
;-------------------------------------------------------------------------------

Event OnReset()
  SetAV(sActorVariable, fActorVariableOnReset)
  SetAv("Aggression", fAggressionOnReset)
  EvaluatePackage()
endEvent

;-------------------------------------------------------------------------------
;
; STATE waiting
;
;-------------------------------------------------------------------------------

auto State waiting

  Event OnActivate(ObjectReference TriggerRef)
    if ambushOnTrigger || (TriggerRef as Actor) == (Game.GetForm(0x14) as Actor)
      GoToState("allDone")
    else
      SetAV("Aggression", fAggression)
      EvaluatePackage()
    endif
  endEvent

  Event OnHit(ObjectReference akAggressor, Form akWeapon, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
    GoToState("allDone")
  endEvent

  Event OnGetUp(ObjectReference akFurniture)
    Cell ParentCell = GetParentCell()

    if ParentCell && ParentCell.IsAttached() && Is3DLoaded()
      GoToState("allDone")
    endif
  endEvent

  Event OnCombatStateChanged(Actor ActorRef, int CombatState)
    if CombatState != 0
      GoToState("allDone")
    endif
  endEvent

  Event OnEndState()
    ObjectReference LinkedRef = GetLinkedRef()

    if LinkedRef
      LinkedRef.Activate(self)
    endif

    LinkedRef = GetNthLinkedRef(1)

    if LinkedRef
      LinkedRef.Activate(self)
    endif

    LinkedRef = GetNthLinkedRef(2)

    if LinkedRef
      LinkedRef.Activate(self)
    endif

    LinkedRef = GetLinkedRef(linkKeyword)

    if LinkedRef
      LinkedRef.Activate(self)
    endif

    SetAV(sActorVariable, fActorVariable)
    SetAV("Aggression", fAggression)
    EvaluatePackage()
  endEvent

endState

;-------------------------------------------------------------------------------
;
; STATE allDone
;
;-------------------------------------------------------------------------------

State allDone

endState
