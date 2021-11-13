Scriptname critterBird extends Critter

;===============================================================================
;
; PROPERTIES
;
;===============================================================================

FormList property perchTypeList auto
{Formlist of perches I look for.}

float property fMinScale = 0.5 auto
{How small can this thing get? Default=0.5.}

float property fMaxScale = 1.5 auto
{How big can it get? Default = 1.5.}

float property fMinHop = 8.0 auto
{Minimum distance to hop.  Default: 8.}

float property fMaxHop = 32.0 auto
{Max distance to hop.  Default:32.}

float property leashLength = 256.0 auto
{How far from home can I roam?  Treat like a radius. Default = 256.0.}

float property fSpeed = 150.0 auto
{Speed of base movement. Default= 150.}

;===============================================================================
;
; HIDDEN
;
;===============================================================================

string property sState auto hidden
{Deprecated - do not use.}

int property iEnergy = 50 auto hidden
{Internal energy value 1-100. Default at spawn: 50.}

ObjectReference property goalPerch auto hidden
{Internally track reserved perch reference.}

;===============================================================================
;
; STATES
;
;===============================================================================

;-------------------------------------------------------------------------------
; ON GROUND
;-------------------------------------------------------------------------------

State onGround

  Event OnUpdate()
    int iDecision = Utility.RandomInt(1, 3)

    if spawner && spawner.IsActiveTime() && GetDistance(spawner) > leashLength
      TakeFlight()
    elseif iDecision == 1
      PlayIdle()
    elseif iDecision == 2
      TakeFlight()
    else
      GroundHop()
    endif
  endEvent

  Event OnTranslationComplete()
    RegisterForSingleUpdate(Utility.RandomFloat(0.1, 2.0))
  endEvent

  Event OnEndState()
    PlayAnimationAndWait("takeOff", "end")
  endEvent

endState

;-------------------------------------------------------------------------------
; FLYING
;-------------------------------------------------------------------------------

State Flying

  Event OnUpdate()
    int iDecision = Utility.RandomInt(1, 2)

    if spawner && spawner.IsActiveTime() && GetDistance(spawner) > leashLength
      FlyTo(spawner)
    elseif iDecision == 1
      goalPerch = FindPerch()

      if goalPerch
        FlyTo(goalPerch)
      else
        RegisterForSingleUpdate(0.0)
      endif
    else
      FlyTo(PlayerRef)
    endif
  endEvent

endState

;-------------------------------------------------------------------------------
; FLYING TO PERCH
;-------------------------------------------------------------------------------

State flyingToPerch

  Event OnUpdate()
    if spawner && spawner.IsActiveTime() && GetDistance(spawner) > leashLength
      FlyTo(spawner)
    elseif goalPerch
      LandAtPerch(goalPerch)
    else
      GoToState("Flying")
      RegisterForSingleUpdate(0.0)
    endif
  endEvent

endState

;-------------------------------------------------------------------------------
; PERCHED
;-------------------------------------------------------------------------------

State perched

  Event OnUpdate()
    int iDecision = Utility.RandomInt(1, 2)

    if spawner && spawner.IsActiveTime() && GetDistance(spawner) > leashLength
      TakeFlight()
    elseif iDecision == 1
      PlayIdle()
    else
      TakeFlight()
    endif
  endEvent

  Event OnTranslationComplete()
    RegisterForSingleUpdate(Utility.RandomFloat(0.1, 2.0))
  endEvent

endState

;===============================================================================
;
; EVENTS
;
;===============================================================================

Event OnTranslationComplete()
  RegisterForSingleUpdate(0.0)
endEvent

;===============================================================================
;
; FUNCTIONS
;
;===============================================================================

Function OnStart()
  SetScale(Utility.RandomFloat(fMinScale, fMaxScale))
  Enable()

  if !CheckFor3D(self)
    DisableAndDelete(false)
    return
  endif

  SetMotionType(Motion_Keyframed, false)

  if spawner.fLeashOverride != 0
    leashLength = spawner.fLeashOverride
  endif

  GoToState("onGround")
  RegisterForSingleUpdate(0.0)
endFunction

Function PlayIdle()
  int iDecision = Utility.RandomInt(1, 2)

  if iDecision == 1
    PlayAnimationAndWait("StartGrndPeck", "StartGrndLook")
  else
    PlayAnimationAndWait("startGrndFlap", "StartGrndLook")
  endif
endFunction

Function GroundHop()
  float fAngleZ = GetfAngleZ()
  float fHopDistance = Utility.RandomFloat(fMinHop, fMaxHop)
  float NewX = X + fHopDistance * Math.Cos(fAngleZ)
  float NewY = Y + fHopDistance * Math.Sin(fAngleZ)

  if CheckViability()
    return
  endIf

  SplineTranslateTo(newX, newY, Z, 0.0, 0.0, fAngleZ, 300.0, fSpeed)
endFunction

Function TakeFlight()
  if CheckViability()
    return
  endIf

  GoToState("Flying")
  SplineTranslateTo(X, Y, Z + 64.0, 0.0, 0.0, GetAngleZ(), 50.0, fSpeed / 2)
endFunction

Function FlyTo(ObjectReference akGoal)
  if CheckViability()
    return
  endIf

  GoToState("Flying")
  SplineTranslateTo(akGoal.X, akGoal.Y, akGoal.Z + 64.0, 0.0, 0.0, GetAngleZ(), 200.0, fSpeed)
endFunction

Function LandAtPerch(objectReference akGoal)
  if CheckViability()
    return
  endIf

  GoToState("perched")
  SplineTranslateTo(akGoal.X, akGoal.Y, akGoal.Z, 0.0, 0.0, Utility.RandomFloat(0.0, 360.0), 300.0, fSpeed / 2.0)
endFunction

ObjectReference Function FindPerch()
  int iPerchTypesIndex = perchTypeList.GetSize()
  Form perchType = none
  critterPerch perch = none

  while !perch && iPerchTypesIndex > 0
    iPerchTypesIndex -= 1
    perchType = perchTypeList.GetAt(iPerchTypesIndex)
    perch = Game.FindRandomReferenceOfTypeFromRef(perchType, spawner, leashLength) as critterPerch

    if perch && !perch.reserved
      perch.reserved = true
      perch.incoming = self
    endif
  endWhile

  return perch
endFunction
