Scriptname default2StateActivator extends ObjectReference Conditional
{ For any activator with standard open/close states. }

bool Property isOpen = False auto conditional
{ set to True to start open }

bool Property doOnce = False auto
{ set to True to open/close on first activation only }

bool Property isAnimating = False auto Hidden Conditional
{ is the activator currently animating from one state to another? }

string Property openAnim = "open" auto
{ animation to play when opening }

string Property closeAnim = "close" auto
{ animation to play when closing }

string Property openEvent = "opening" auto
{ open event name - waits for this event before considering itself "open" }

string Property closeEvent = "closing" auto
{ close event name - waits for this event before considering itself "closed"  }

string Property startOpenAnim = "opened" auto
{ OnLoad calls this if the object starts in the open state }

bool Property bAllowInterrupt = FALSE auto
{ Allow interrupts while animation? Default: FALSE }

bool Property zInvertCollision = FALSE auto
{
  Typically this will be False (DEFAULT).  The References LinkRef'd Chained with
  the TwoStateCollisionKeyword will typically be Enabled onOpen, and Disabled on
  Close.  If you want that functionality inverted set this to TRUE.
}

int Property myState = 1 auto hidden

keyword Property TwoStateCollisionKeyword auto

; True when static or animating
; 0 == open or opening
; 1 == closed or closing

;-----------------------------------------------------------
; Added by USLEEP 3.0.9 for Bug #21999
;-----------------------------------------------------------

bool Property USLEEP_IsOpenByDefault = False auto
{ Set to TRUE only if the editor-placed object is open. }

bool USLEEP_HasAlreadyLoaded = False

Auto State waiting

  Event OnActivate (ObjectReference triggerRef)

    SetOpen(!isOpen)

    If doOnce
      GoTostate("done")
    Endif

  EndEvent

EndState

State busy

    Event OnActivate (ObjectReference triggerRef)

      If bAllowInterrupt
        SetOpen(!isOpen)
      Endif

    EndEvent

EndState

State done

  Event OnActivate (ObjectReference triggerRef)
    ; Empty.
  EndEvent

EndState

Event OnLoad()

  ; USLEEP 3.0.9 Bug #21999: added a check for the tracking bool: This function should only run on first load and after a reset.
  If !USLEEP_HasAlreadyLoaded
    SetDefaultState()
    ; USLEEP 3.0.9 Bug #21999: set tracking bool to 'True' to prevent this function from being called again on reload:
    USLEEP_HasAlreadyLoaded = True
  Endif

EndEvent

Function SetDefaultState()

  If isOpen
    ; USLEEP 3.0.9 Bug #21999: added this check to prevent the 'open' animation from being called on references that are open already:
    If !USLEEP_IsOpenByDefault
      PlayAnimationandWait(startOpenAnim, openEvent)
    Endif

    If !zInvertCollision
      DisableLinkChain(TwoStateCollisionKeyword)
    Else
      EnableLinkChain(TwoStateCollisionKeyword)
    Endif

    myState = 0
  Else
    ; USLEEP 3.0.9 Bug #21999: added this check to prevent the 'close' animation from being called on references that are closed already:
    If USLEEP_IsOpenByDefault
      PlayAnimationandWait(closeAnim, closeEvent)
    Endif
      If !zInvertCollision
      EnableLinkChain(TwoStateCollisionKeyword)
    Else
      DisableLinkChain(TwoStateCollisionKeyword)
    Endif

    myState = 1
  EndIf

EndFunction

Function SetOpen(bool abOpen = true)

  While GetState() == "busy"
    Utility.Wait(1.0)
  EndWhile

  isAnimating = True

  If abOpen && !isOpen
    GoToState("busy")

    If bAllowInterrupt || !Is3DLoaded()
      PlayAnimation(openAnim)
    Else
      PlayAnimationandWait(openAnim, openEvent)
    Endif

    If !zInvertCollision
      DisableLinkChain(TwoStateCollisionKeyword)
    Else
      EnableLinkChain(TwoStateCollisionKeyword)
    Endif

    isOpen = True
    GoToState("waiting")
  ElseIf !abOpen && isOpen
    GoToState ("busy")

    If bAllowInterrupt || !Is3DLoaded()
      PlayAnimation(closeAnim)
    Else
      PlayAnimationandWait(closeAnim, closeEvent)
    Endif

    If !zInvertCollision
      EnableLinkChain(TwoStateCollisionKeyword)
    Else
      DisableLinkChain(TwoStateCollisionKeyword)
    Endif

    isOpen = False
    GoToState("waiting")
  Endif

  isAnimating = False

EndFunction
