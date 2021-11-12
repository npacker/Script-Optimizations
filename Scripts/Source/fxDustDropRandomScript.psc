Scriptname fxDustDropRandomSCRIPT extends ObjectReference
{ Randomly fires the dust drop effects. }

;-------------------------------------------------------------------------------
;
; PROPERTIES
;
;-------------------------------------------------------------------------------

Sound Property mySFX Auto
{ Sound to play when dust falls. }

Explosion Property FallingDustExplosion01 Auto
{ Explosion to place when dust falls. }

;-------------------------------------------------------------------------------
;
; VARIABLES
;
;-------------------------------------------------------------------------------

Int Selection

Float RandomWait

Float RandomWaitMin = 10.0

Float RandomWaitMax = 30.0

;-------------------------------------------------------------------------------
;
; STATES
;
;-------------------------------------------------------------------------------

; INACTIVE STATE

Auto State Inactive

  Event OnBeginState()
    UnregisterForUpdate()
  EndEvent

EndState

; ACTIVE STATE

State Active

  Event OnBeginState()
    UnregisterForUpdate()
    RandomWait = Utility.RandomFloat(RandomWaitMin, RandomWaitMax)
    RegisterForSingleUpdate(RandomWait)
  EndEvent

  Event OnUpdate()
    Selection = Utility.RandomInt(1, 3)

    If Selection == 1
      PlayAnimation("PlayAnim01")
      mySFX.Play(Self)
      Utility.Wait(0.5)
      ObjectReference ExplosionReference = PlaceAtMe(FallingDustExplosion01)
      Utility.Wait(2.5)

      If ExplosionReference
        ExplosionReference.Delete()
        ExplosionReference = None
      EndIf

      Utility.Wait(0.5)
      PlayAnimation("PlayAnim02")
    ElseIf Selection == 2
      PlayAnimation("PlayAnim02")
      mySFX.Play(Self)
    ElseIf Selection == 3
      PlayAnimation("PlayAnim03")
      mySFX.Play(Self)
    EndIf

    RandomWait = Utility.RandomFloat(RandomWaitMin, RandomWaitMax)
    RegisterForSingleUpdate(RandomWait)
  EndEvent

  ObjectReference Function PlaceAtMe(Form akFormToPlace, int aiCount = 1, bool abForcePersist = false, bool abInitiallyDisabled = false)
    ObjectReference Result = None

    If Is3DLoaded()
      Result = Parent.PlaceAtMe(akFormToPlace, aiCount, abForcePersist, abInitiallyDisabled)
    Else
      GoToState("Inactive")
    EndIf

    Return Result
  EndFunction

  Bool Function PlayAnimation(String Animation)
    Bool Result = False

    If Is3DLoaded()
      Result = Parent.PlayAnimation(Animation)
    Else
      GoToState("Inactive")
    EndIf

    Return Result
  EndFunction

  Function RegisterForSingleUpdate(Float afInterval)
    If Is3DLoaded()
      Parent.RegisterForSingleUpdate(afInterval)
    Else
      GoToState("Inactive")
    EndIf
  EndFunction

EndState

;-------------------------------------------------------------------------------
;
; EVENTS
;
;-------------------------------------------------------------------------------

Event OnLoad()

  GoToState("Active")

EndEvent

Event OnUnload()

  GoToState("Inactive")

EndEvent

Event OnCellAttach()

  GoToState("Active")

EndEvent

Event OnCellDetach()

  GoToState("Inactive")

EndEvent

;-------------------------------------------------------------------------------
;
; FUNCTIONS
;
;-------------------------------------------------------------------------------

ObjectReference Function PlaceAtMe(Form akFormToPlace, int aiCount = 1, bool abForcePersist = false, bool abInitiallyDisabled = false)

  Return None

EndFunction

Bool Function PlayAnimation(string asAnimation)

  Return False

EndFunction

Function RegisterForSingleUpdate(float afInterval)

  Return None

EndFunction
