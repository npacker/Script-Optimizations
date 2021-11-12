ScriptName defaultActivateSelf extends ObjectReference
{Default script that simply activates itself when player enters trigger}

bool Property doOnce = True auto
{ Fire only once? }

bool Property disableWhenDone = True auto
{ Disable after activating? }

bool Property playerOnly = True auto
{ Only Player Triggers? }

bool Property playerAndAlliesOnly = False Auto
{
  Only player or Allies/Followers/Summons trigger? Overrides playerOnly if
  that's true as well.
}

int Property minLevel auto
{ Optional: If set, player must be >= minLevel to activate this. }

Faction Property PlayerFaction Auto

Faction Property CurrentFollowerFaction Auto

Package Property Follow Auto

Package Property FollowerPackageTemplate Auto

Auto State waiting

  Event OnTriggerEnter(objectReference triggerRef)

    Actor ActorRef = triggerRef as Actor
    Actor PlayerRef = Game.GetPlayer()

    If (ActorRef == PlayerRef) || (playerAndAlliesOnly && IsPlayerAlly(PlayerRef, ActorRef)) || (!playerOnly && !playerAndAlliesOnly)
      If minLevel == 0 || PlayerRef.GetLevel() >= minLevel
        If doOnce
          GoToState("allDone")
        Endif

        If disableWhenDone
          Disable()
        EndIf

        Activate(Self)
      Endif
    Endif

  EndEvent

EndState

State allDone

  ; Empty.

EndState

bool Function IsPlayerAlly(Actor PlayerRef, Actor ActorRef)

  If !ActorRef || ActorRef.GetFactionReaction(PlayerRef) == 1
    Return False
  EndIf

  Return ActorRef.IsCommandedActor() \
      || ActorRef.GetRelationshipRank(PlayerRef) > 0 \
      || ActorRef.IsInFaction(CurrentFollowerFaction) \
      || ActorRef.IsPlayerTeammate() \
      || ActorRef.GetCurrentPackage().GetTemplate() == Follow \
      || ActorRef.GetCurrentPackage().GetTemplate() == FollowerPackageTemplate

EndFunction
