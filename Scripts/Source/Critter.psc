ScriptName Critter extends ObjectReference
{ Base behavior script for critters. }

;===============================================================================
;
; PROPERTIES
;
;===============================================================================

float property fPositionVarianceX = 20.0 auto
{
  When picking a destination reference, how much variance in he X coordinate the
  critter to travel to.
}

float property fPositionVarianceY = 20.0 auto
{
  When picking a destination reference, how much variance in he Y coordinate the
  critter to travel to.
}

float property fPositionVarianceZMin = 50.0 auto
{
  When picking a destination reference, how much variance in he Z coordinate the
  critter to travel to, lower bound
}

float property fPositionVarianceZMax = 100.0 auto
{
  When picking a destination reference, how much variance in he Z coordinate the
  critter to travel to, upper bound
}

float property fAngleVarianceZ = 90.0 auto
{
  When picking a destination reference, how much variance from the ref's Z angle
  the critter can end at
}

float property fAngleVarianceX = 20.0 auto
{
  When picking a destination reference, how much variance from the ref's X angle
  the critter can end at
}

float property fPathCurveMean = 100.0 auto
{ When moving, how "curvy" the path can be, mean (see associated Variance). }

float property fPathCurveVariance = 200.0 auto
{ When moving, how "curvy" the path can be, variance (see associated Mean). }

float property fBellShapedWaypointPercent = 0.2 auto
{
  When moving on a bell-shaped path, how far along the path to place the bell
  waypoint (so that the critter doesn't go straight up, but up and forward)
}

string property PathStartGraphEvent = "" auto
{ Animation event to send when starting a path. }

float property fPathStartAnimDelay = 1.0 auto
{
  Duration of the path start animation (delay used before the critter actually
  moves)
}

string property PathEndGraphEvent = "" auto
{ Animation event to send when ending a path. }

float property fPathEndAnimDelay = 1.0 auto
{
  Duration of the path end animation (delay used before the critter returns path
  complete)
}

Ingredient property lootable auto
{ Ingredient gathered from this critter. }

FormList property nonIngredientLootable auto
{ Optional: If our loot item is not an ingredient, use this instead. }

FormList property fakeCorpse auto
{ Optional: If we want to leave a fake "Corpse" behind, point to it here. }

bool property bPushOnDeath = false auto
{ Apply a small push on death to add english to ingredients?  Default: false. }

Explosion property deathPush auto
{ A small explosion force to propel wings on death. }

int property lootableCount = 1 auto
{ How many lootables do I drop on Death? Default: 1. }

bool property bIncrementsWingPluckStat = false auto
{ Do I count towards the wings plucked misc stat?  will be false for majority. }

Static property LandingMarkerForm auto
{ What landing marker to use to compute offsets from landing position. }

float property fLandingSpeedRatio = 0.33 auto
{
  The speed percentage to use when landing, Default = 0.33 (or 33% of flight
  speed)
}

string property ApproachNodeName = "ApproachSmall01" auto
{
  The name of the approach node in the landing marker, Default=ApproachSmall01.
}

bool property reserved auto hidden
{ Whether this object should be invalidated for searches. }

;===============================================================================
;
; HIDDEN
;
;===============================================================================

ObjectReference property hunter auto hidden
{ The hunter, if being hunted. }

float property fLeashLength auto hidden
{ The distance from the spawner this critter can be. }

float property fMaxPlayerDistance auto hidden
{ The distance from the player this critter can be. }

float property fHeight auto hidden
{
  The Height above the spawner that critters be move to (when applicable:
  dragonfly).
}

float property fDepth auto hidden
{
  The Depth below the spawner that critters be move to (when applicable: fish).
}

CritterSpawn property Spawner auto hidden
{ The spawner that owns this critter. }

bool property bCritterDebug = false auto hidden
{ For debugging only. }

Actor property PlayerRef auto hidden
{ Set by SetSpawnerProperties, cleared by DisableAndDelete. }

ObjectReference property Follower auto hidden
{ The follower, if being followed. }

float property fSpawnerX auto hidden
{ set by SetSpawnerProperties. }

float property fSpawnerY auto hidden
{ set by SetSpawnerProperties. }

float property fSpawnerZ auto hidden
{ set by SetSpawnerProperties. }

bool property bCalculating = false auto hidden
{ Deprecated - do not use. }

;===============================================================================
;
; VARIABLES
;
;===============================================================================

ObjectReference landingMarker

ObjectReference dummyMarker

string CurrentTargetState

string CurrentTargetNode

bool bDisabled = false

;-------------------------------------------------------------------------------
; B-Spline translation.
;-------------------------------------------------------------------------------

ObjectReference BellShapeTarget

float fBellShapeSpeed

float fBellShapeMaxRotationSpeed

float fBellShapeStartX

float fBellShapeStartY

float fBellShapeStartZ

float fBellShapeStartLandingPointX

float fBellShapeStartLandingPointY

float fBellShapeStartLandingPointZ

float fBellShapeTargetPointX

float fBellShapeTargetPointY

float fBellShapeTargetPointZ

float fBellShapeTargetAngleX

float fBellShapeTargetAngleY

float fBellShapeTargetAngleZ

float fBellShapeDeltaX

float fBellShapeDeltaY

float fBellShapeDeltaZ

float fBellShapeHeight

;-------------------------------------------------------------------------------
; Linear translation.
;-------------------------------------------------------------------------------

float fStraightLineTargetX

float fStraightLineTargetY

float fStraightLineTargetZ

float fStraightLineTargetAngleX

float fStraightLineTargetAngleY

float fStraightLineTargetAngleZ

float fStraightLineSpeed

float fStraightLineMaxRotationSpeed

;===============================================================================
;
; STATES
;
;===============================================================================

State Deleted

  Event OnUpdate()
    { Override. }
  endEvent

  Event OnCellDetach()
    { Override. }
  endEvent

  Event OnUnload()
    { Override. }
  endEvent

  Event OnActivate(ObjectReference akActionRef)
    { Override. }
  endEvent

  Event OnHit(ObjectReference akAggressor, Form akWeapon, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
    { Override. }
  endEvent

  Event OnMagicEffectApply(ObjectReference akCaster, MagicEffect akEffect)
    { Override. }
  EndEvent

  Function Die()
    { Override. }
  endFunction

  bool Function CheckViability()
    { Override. }
    return true
  endFunction

  bool Function CheckViableDistance()
    { Override. }
    return false
  endFunction

  Function RegisterForSingleUpdate(float afInterval)
    { Override. }
  endFunction

endState

State Deleting

  Event OnBeginState()
    RegisterForSingleUpdate(2.0)
  endEvent

  Event OnUpdate()
    { Override. }
    GotoState("Deleted")
    TargetClear()

    if Follower
      Critter FollowedBy = Follower as Critter

      if FollowedBy
        FollowedBy.FollowClear()
      endif
    endif

    if landingMarker && !bDisabled
      landingMarker.Delete()
    endif

    if dummyMarker && !bDisabled
      dummyMarker.Delete()
    endif

    Spawner = none
    BellShapeTarget = none
    Follower = none
    landingMarker = none
    dummyMarker = none
    PlayerRef = None
    UnregisterForUpdate()
    UnregisterForUpdateGameTime()
    Delete()
  endEvent

  Event OnCellDetach()
    { Override. }
  endEvent

  Event OnUnload()
    { Override. }
  endEvent

  Event OnActivate(ObjectReference akActionRef)
    { Override. }
  endEvent

  Event OnHit(ObjectReference akAggressor, Form akWeapon, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
    { Override. }
  endEvent

  Event OnMagicEffectApply(ObjectReference akCaster, MagicEffect akEffect)
    { Override. }
  EndEvent

  Event OnTranslationAlmostComplete()
    { Override. }
  endEvent

  Event OnTranslationComplete()
    { Override. }
  endEvent

  Event OnTranslationFailed()
    { Override. }
  endEvent

  Function Die()
    { Override. }
  endFunction

  bool Function CheckViability()
    { Override. }
    return true
  endFunction

  bool Function CheckViableDistance()
    { Override. }
    return false
  endFunction

endState

State Initialized

  Event OnUpdate()
    { Override. }
    GotoState("")
    landingMarker = PlaceAtMe(LandingMarkerForm)
    dummyMarker = PlaceAtMe(LandingMarkerForm)

    if landingMarker && dummyMarker && CheckCellAttached(self)
      OnStart()
    else
      DisableAndDelete()
    endif
  endEvent

endState

State BellShapeGoingUp

  Event OnTranslationAlmostComplete()
    { Override. }
  endEvent

  Event OnTranslationComplete()
    { Override. }
    GotoState("BellShapeGoingAcross")

    float fsecondWaypointPercent = 1.0 - fBellShapedWaypointPercent
    float fSecondWaypointX = fBellShapeStartX + fBellShapeDeltaX * fsecondWaypointPercent
    float fSecondWaypointY = fBellShapeStartY + fBellShapeDeltaY * fsecondWaypointPercent
    float fSecondWaypointZ = fBellShapeStartZ + fBellShapeDeltaZ * fsecondWaypointPercent + fBellShapeHeight

    if CheckViability()
      return
    endif

    SplineTranslateTo(fSecondWaypointX, fSecondWaypointY, fSecondWaypointZ, GetAngleX(), GetAngleY(), GetAngleZ(), fPathCurveMean, fBellShapeSpeed, fBellShapeMaxRotationSpeed)
  endEvent

endState

State BellShapeGoingAcross

  Event OnTranslationAlmostComplete()
    { Override. }
  endEvent

  Event OnTranslationComplete()
    { Override. }
    GotoState("BellShapeGoingDown")

    if CheckViability()
      return
    endif

    SplineTranslateTo(fBellShapeStartLandingPointX, fBellShapeStartLandingPointY, fBellShapeStartLandingPointZ, fBellShapeTargetAngleX, fBellShapeTargetAngleY, fBellShapeTargetAngleZ, fPathCurveMean, fBellShapeSpeed, fBellShapeMaxRotationSpeed)
  endEvent

endState

State BellShapeGoingDown

  Event OnTranslationAlmostComplete()
    { Override. }
  endEvent

  Event OnTranslationComplete()
    { Override. }
    GotoState("BellShapeLanding")
    DoPathEndStuff()

    float fSpeed = fBellShapeSpeed * fLandingSpeedRatio

    if CheckViability()
      return
    endif

    TranslateTo(fBellShapeTargetPointX, fBellShapeTargetPointY, fBellShapeTargetPointZ, fBellShapeTargetAngleX, fBellShapeTargetAngleY, fBellShapeTargetAngleZ, fSpeed, fBellShapeMaxRotationSpeed)
  endEvent

endState

State BellShapeLanding

  Event OnTranslationComplete()
    { Override. }
    if CurrentTargetState
      GotoState(CurrentTargetState)
    endif

    CurrentTargetState = ""
    BellShapeTarget = none
    OnCritterGoalReached()
  endEvent

endState

State Translation

  Event OnTranslationComplete()
    { Override. }
    if CurrentTargetState
      GotoState(CurrentTargetState)
    else
      GotoState("")
    endif

    CurrentTargetState = ""
    DoPathEndStuff()
    OnCritterGoalReached()
  endEvent

endState

State SplineTranslation

  Event OnTranslationAlmostComplete()
    { Override. }
  endEvent

  Event OnTranslationComplete()
    { Override. }
    GotoState("StraightLineLanding")
    DoPathEndStuff()

    float fTangentMagnitude = Utility.RandomFloat(fPathCurveMean - fPathCurveVariance, fPathCurveMean + fPathCurveVariance)
    float fSpeed = fStraightLineSpeed * fLandingSpeedRatio

    if CheckViability()
      return
    endif

    SplineTranslateTo(fStraightLineTargetX, fStraightLineTargetY, fStraightLineTargetZ, fStraightLineTargetAngleX, fStraightLineTargetAngleY, fStraightLineTargetAngleZ, fTangentMagnitude, fSpeed, fStraightLineMaxRotationSpeed)
  endEvent

endState

State StraightLineLanding

  Event OnTranslationComplete()
    { Override. }
    if CurrentTargetState
      GotoState(CurrentTargetState)
    else
      GotoState("")
    endif

    CurrentTargetState = ""
    OnCritterGoalReached()
  endEvent

endState

;===============================================================================
;
; EVENTS
;
;===============================================================================

Event OnUpdate()
  DisableAndDelete()
endEvent

Event OnCellAttach()
  DisableAndDelete(false)
endEvent

Event OnCellDetach()
  DisableAndDelete(false)
endEvent

Event OnUnload()
  DisableAndDelete(false)
endEvent

Event OnActivate(ObjectReference akActionRef)
  DisableAndDelete(false)

  if nonIngredientLootable
    int iLootableIndex = NonIngredientLootable.GetSize()

    while iLootableIndex > 0
      iLootableIndex -= 1
      akActionRef.AddItem(NonIngredientLootable.GetAt(iLootableIndex), lootableCount)
    endwhile
  else
    akActionRef.AddItem(lootable, lootableCount)
  endif

  if bIncrementsWingPluckStat
    Game.IncrementStat("Wings Plucked", lootableCount)
  endif
endEvent

Event OnHit(ObjectReference akAggressor, Form akWeapon, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
  Die()
endEvent

Event OnMagicEffectApply(ObjectReference akCaster, MagicEffect akEffect)
  Die()
EndEvent

Event OnTranslationAlmostComplete()
  OnCritterGoalAlmostReached()
endEvent

Event OnTranslationComplete()
  OnCritterGoalReached()
endEvent

Event OnTranslationFailed()
  OnCritterGoalFailed()
endEvent

;===============================================================================
;
; FUNCTIONS
;
;===============================================================================

Function OnStart()
  Enable()
endFunction

Function OnCritterGoalAlmostReached()
  ; Empty.
endFunction

Function OnCritterGoalReached()
  ; Empty.
endFunction

Function OnCritterGoalFailed()
  RegisterForSingleUpdate(0.0)
endFunction

Function DoPathStartStuff()
  ; Empty.
endFunction

Function DoPathEndStuff()
  ; Empty.
endFunction

Function DoCritterBehavior()
  ; Empty.
endFunction

Function FollowClear()
  ; Empty.
endFunction

Function TargetClear()
  ; Empty.
endFunction

bool Function FollowSet(ObjectReference akFollowing)
  if !Follower && !IsDisabled()
    Follower = akFollowing
    return true
  endif

  return false
endFunction

Function SetInitialSpawnerProperties(float afRadius, float afHeight, float afDepth, float afMaxPlayerDistance, CritterSpawn arSpawner)
  fLeashLength = afRadius
  fHeight = afHeight
  fDepth = afDepth
  fMaxPlayerDistance = afMaxPlayerDistance
  Spawner = arSpawner
  fSpawnerX = Spawner.X
  fSpawnerY = Spawner.Y
  fSpawnerZ = Spawner.Z
  PlayerRef = Game.GetForm(0x14) as Actor
  GotoState("Initialized")
  RegisterForSingleUpdate(0.0)
endFunction

Function Die()
  DisableAndDelete(false)

  ObjectReference ItemDrop = none
  int iLootableIndex = lootableCount

  while iLootableIndex > 0
    iLootableIndex -= 1

    if fakeCorpse
      int iCorpseIndex = fakeCorpse.GetSize()

      while iCorpseIndex > 0
        iCorpseIndex -= 1
        ItemDrop = PlaceAtMe(fakeCorpse.GetAt(iCorpseIndex), 1)
      endwhile
    else
      ItemDrop = PlaceAtMe(lootable, 1)
    endif

    float Width = GetWidth()
    float Height = GetHeight()
    float afXOffset = Utility.RandomFloat(Width, Width * 2.0)
    float afYOffset = Utility.RandomFloat(Width, Width * 2.0)
    float afZOffset = Utility.RandomFloat(Height, Height * 2.0) * -1.0

    ItemDrop.MoveTo(ItemDrop, afXOffset, afYOffset, afZOffset, false)
  endwhile

  if bPushOnDeath
    PlaceAtMe(deathPush)
  endif
endFunction

Function DisableAndDelete(bool abFadeOut = true)
  GotoState("Deleting")
  bDisabled = IsDisabled()

  if Spawner && !bDisabled
    Spawner.OnCritterDied()
  endif

  if abFadeOut
    Disable(true)
  else
    DisableNoWait()
  endif

  if CheckCellAttached(self)
    StopTranslation()
  endif
endFunction

bool Function PlaceLandingMarker(ObjectReference arTarget, string asTargetNode)
  if !CheckFor3D(landingMarker) || !CheckFor3D(arTarget)
    return true
  endif

  if asTargetNode == ""
    float fPositionX = arTarget.X + Utility.RandomFloat(fPositionVarianceX * -1.0, fPositionVarianceX)
    float fPositionY = arTarget.Y + Utility.RandomFloat(fPositionVarianceY * -1.0, fPositionVarianceY)
    float fPositionZ = arTarget.Z + Utility.RandomFloat(fPositionVarianceZMin, fPositionVarianceZMax)

    landingMarker.SetPosition(fPositionX, fPositionY, fPositionZ)

    float fAngleX = arTarget.GetAngleX() + Utility.RandomFloat(fAngleVarianceX * -1.0, fAngleVarianceX)
    float fAngleY = arTarget.GetAngleY()
    float fAngleZ = arTarget.GetAngleZ() + Utility.RandomFloat(fAngleVarianceZ * -1.0, fAngleVarianceZ)

    landingMarker.SetAngle(fAngleX, fAngleY, fAngleZ)
  else
    landingMarker.MoveToNode(arTarget, asTargetNode)
  endif

  return false
endFunction

bool Function PlaceDummyMarker(ObjectReference arTarget, string asTargetNode)
  if !CheckFor3D(dummyMarker) || !CheckFor3D(arTarget)
    return true
  endif

  dummyMarker.MoveToNode(arTarget, asTargetNode)
  return false
endFunction

Function SplineTranslateToRefAtSpeed(ObjectReference arTarget, float afSpeed, float afMaxRotationSpeed)
  if CheckViability()
    return
  endif

  SetMotionType(Motion_Keyframed, false)
  DoPathStartStuff()

  if PlaceLandingMarker(arTarget, CurrentTargetNode) || PlaceDummyMarker(landingMarker, ApproachNodeName)
    DisableAndDelete(false)
    return
  endif

  if !CheckFor3D(dummyMarker)
    DisableAndDelete(false)
    return
  endif

  CurrentTargetNode = ""
  fStraightLineTargetX = dummyMarker.X
  fStraightLineTargetY = dummyMarker.Y
  fStraightLineTargetZ = dummyMarker.Z
  fStraightLineTargetAngleX = dummyMarker.GetAngleX()
  fStraightLineTargetAngleY = dummyMarker.GetAngleY()
  fStraightLineTargetAngleZ = dummyMarker.GetAngleZ()
  fStraightLineSpeed = afSpeed
  fStraightLineMaxRotationSpeed = afMaxRotationSpeed

  float fdeltaX = fStraightLineTargetX - X
  float fdeltaY = fStraightLineTargetY - Y
  float fdeltaZ = fStraightLineTargetZ - Z
  float ftargetX = X + fdeltaX * 0.9
  float ftargetY = Y + fdeltaY * 0.9
  float ftargetZ = Z + fdeltaZ * 0.9
  float fTangentMagnitude = Utility.RandomFloat(fPathCurveMean - fPathCurveVariance, fPathCurveMean + fPathCurveVariance)

  if CheckViability()
    return
  endif

  GotoState("SplineTranslation")
  SplineTranslateTo(ftargetX, ftargetY, ftargetZ, fStraightLineTargetAngleX, fStraightLineTargetAngleY, fStraightLineTargetAngleZ, fTangentMagnitude, afSpeed, afMaxRotationSpeed)
endFunction

Function SplineTranslateToRefNodeAtSpeed(ObjectReference arTarget, string arNode, float afSpeed, float afMaxRotationSpeed)
  CurrentTargetNode = arNode
  SplineTranslateToRefAtSpeed(arTarget, afSpeed, afMaxRotationSpeed)
endFunction

Function SplineTranslateToRefAtSpeedAndGotoState(ObjectReference arTarget, float afSpeed, float afMaxRotationSpeed, string arTargetState)
  CurrentTargetState = arTargetState
  SplineTranslateToRefAtSpeed(arTarget, afSpeed, afMaxRotationSpeed)
endFunction

Function SplineTranslateToRefNodeAtSpeedAndGotoState(ObjectReference arTarget, string arNode, float afSpeed, float afMaxRotationSpeed, string arTargetState)
  CurrentTargetState = arTargetState
  CurrentTargetNode = arNode
  SplineTranslateToRefAtSpeed(arTarget, afSpeed, afMaxRotationSpeed)
endFunction

Function TranslateToRefAtSpeed(ObjectReference arTarget, float afSpeed, float afMaxRotationSpeed)
  if CheckViability()
    return
  endif

  SetMotionType(Motion_Keyframed, false)
  DoPathStartStuff()

  if PlaceLandingMarker(arTarget, CurrentTargetNode) || PlaceDummyMarker(landingMarker, ApproachNodeName)
    DisableAndDelete(false)
    return
  endif

  if !CheckFor3D(dummyMarker)
    DisableAndDelete(false)

    return
  endif

  CurrentTargetNode = ""
  fStraightLineTargetX = dummyMarker.X
  fStraightLineTargetY = dummyMarker.Y
  fStraightLineTargetZ = dummyMarker.Z
  fStraightLineTargetAngleX = dummyMarker.GetAngleX()
  fStraightLineTargetAngleY = dummyMarker.GetAngleY()
  fStraightLineTargetAngleZ = dummyMarker.GetAngleZ()
  fStraightLineSpeed = afSpeed

  float fdeltaX = fStraightLineTargetX - X
  float fdeltaY = fStraightLineTargetY - Y
  float fdeltaZ = fStraightLineTargetZ - Z
  float ftargetX = X + fdeltaX * 0.9
  float ftargetY = Y + fdeltaY * 0.9
  float ftargetZ = Z + fdeltaZ * 0.9

  if CheckViability()
    return
  endif

  GotoState("Translation")
  TranslateTo(ftargetX, ftargetY, ftargetZ, fStraightLineTargetAngleX, fStraightLineTargetAngleY, fStraightLineTargetAngleZ, afSpeed, afMaxRotationSpeed)
endFunction

Function TranslateToRefNodeAtSpeed(ObjectReference arTarget, string arNode, float afSpeed, float afMaxRotationSpeed)
  CurrentTargetNode = arNode
  TranslateToRefAtSpeed(arTarget, afSpeed, afMaxRotationSpeed)
endFunction

Function TranslateToRefAtSpeedAndGotoState(ObjectReference arTarget, float afSpeed, float afMaxRotationSpeed, string arTargetState)
  CurrentTargetState = arTargetState
  TranslateToRefAtSpeed(arTarget, afSpeed, afMaxRotationSpeed)
endFunction

Function TranslateToRefNodeAtSpeedAndGotoState(ObjectReference arTarget, string arNode, float afSpeed, float afMaxRotationSpeed, string arTargetState)
  CurrentTargetState = arTargetState
  CurrentTargetNode = arNode
  TranslateToRefAtSpeed(arTarget, afSpeed, afMaxRotationSpeed)
endFunction

Function BellShapeTranslateToRefAtSpeed(ObjectReference arTarget, float afBellHeight, float afSpeed, float afMaxRotationSpeed)
  if CheckViability()
    return
  endif

  SetMotionType(Motion_Keyframed, false)
  DoPathStartStuff()

  if PlaceLandingMarker(arTarget, CurrentTargetNode) || PlaceDummyMarker(landingMarker, ApproachNodeName)
    DisableAndDelete(false)
    return
  endif

  if !CheckFor3D(dummyMarker)
    DisableAndDelete(false)
    return
  endif

  CurrentTargetNode = ""
  fBellShapeStartLandingPointX = dummyMarker.X
  fBellShapeStartLandingPointY = dummyMarker.Y
  fBellShapeStartLandingPointZ = dummyMarker.Z
  fBellShapeTargetPointX = landingMarker.X
  fBellShapeTargetPointY = landingMarker.Y
  fBellShapeTargetPointZ = landingMarker.Z
  fBellShapeTargetAngleX = landingMarker.GetAngleX()
  fBellShapeTargetAngleY = landingMarker.GetAngleY()
  fBellShapeTargetAngleZ = landingMarker.GetAngleZ()
  fBellShapeStartX = X
  fBellShapeStartY = Y
  fBellShapeStartZ = Z
  fBellShapeDeltaX = fBellShapeTargetPointX - fBellShapeStartX
  fBellShapeDeltaY = fBellShapeTargetPointY - fBellShapeStartY
  fBellShapeDeltaZ = fBellShapeTargetPointZ - fBellShapeStartZ
  fBellShapeHeight = afBellHeight
  BellShapeTarget = arTarget
  fBellShapeSpeed = afSpeed
  fBellShapeMaxRotationSpeed = afMaxRotationSpeed

  float fFirstWaypointX = fBellShapeStartX + fBellShapeDeltaX * fBellShapedWaypointPercent
  float fFirstWaypointY = fBellShapeStartY + fBellShapeDeltaY * fBellShapedWaypointPercent
  float fFirstWaypointZ = fBellShapeStartZ + fBellShapeDeltaZ * fBellShapedWaypointPercent + fBellShapeHeight

  if CheckViability()
    return
  endif

  GotoState("BellShapeGoingUp")
  SplineTranslateTo(fFirstWaypointX, fFirstWaypointY, fFirstWaypointZ, GetAngleX(), GetAngleY(), GetAngleZ(), fPathCurveMean, fBellShapeSpeed, afMaxRotationSpeed)
endFunction

Function BellShapeTranslateToRefNodeAtSpeed(ObjectReference arTarget, string arNode, float afBellHeight, float afSpeed, float afMaxRotationSpeed)
  CurrentTargetNode = arNode
  BellShapeTranslateToRefAtSpeed(arTarget, afBellHeight, afSpeed, afMaxRotationSpeed)
endFunction

Function BellShapeTranslateToRefAtSpeedAndGotoState(ObjectReference arTarget, float afBellHeight, float afSpeed, float afMaxRotationSpeed, string arTargetState)
  CurrentTargetState = arTargetState
  BellShapeTranslateToRefAtSpeed(arTarget, afBellHeight, afSpeed, afMaxRotationSpeed)
endFunction

Function BellShapeTranslateToRefNodeAtSpeedAndGotoState(ObjectReference arTarget, string arNode, float afBellHeight, float afSpeed, float afMaxRotationSpeed, string arTargetState)
  CurrentTargetState = arTargetState
  CurrentTargetNode = arNode
  BellShapeTranslateToRefAtSpeed(arTarget, afBellHeight, afSpeed, afMaxRotationSpeed)
endFunction

Function WarpToRefAndGotoState(ObjectReference arTarget, string asState)
  if PlaceLandingMarker(arTarget, "")
    DisableAndDelete(false)
    return
  endif

  MoveTo(landingMarker)
  GotoState(asState)
endFunction

Function WarpToRefNodeAndGotoState(ObjectReference arTarget, string asNode, string asState)
  if PlaceLandingMarker(arTarget, asNode)
    DisableAndDelete(false)
    return
  endif

  MoveTo(landingMarker)
  GotoState(asState)
endFunction

Function FlyAroundSpawner(float afMinTravel, float afMaxTravel, float afSpeed, float afMaxRotationSpeed, bool abFlyBelowSpawner = false)
  float fMinHeight = fSpawnerZ
  float fMaxheight = fMinHeight + fLeashLength * 0.5
  float newX = X + Utility.RandomFloat(afMinTravel, afMaxTravel)
  float newY = Y + Utility.RandomFloat(afMinTravel, afMaxTravel)
  float newZ = Z + Utility.RandomFloat(afMinTravel, afMaxTravel)

  if CheckViability()
    return
  endif

  DoPathStartStuff()

  if newX > fSpawnerX
    if newX > (fSpawnerX + fLeashLength)
      newX = fSpawnerX + fLeashLength
    endif
  elseif newX < (fSpawnerX - fLeashLength)
    newX = fSpawnerX - fLeashLength
  endif

  if newY > fSpawnerY
    if newY > (fSpawnerY + fLeashLength)
      newY = fSpawnerY + fLeashLength
    endif
  elseif newY < (fSpawnerY - fLeashLength)
    newY = fSpawnerY - fLeashLength
  endif

  if abFlyBelowSpawner
    if newZ < fMinHeight
      newZ = fMinHeight
    endif

    if newZ > fMaxHeight
      newZ = fMaxHeight
    endif
  endif

  if CheckViability()
    return
  endif

  TranslateTo(newX, newY, newZ, GetAngleX(), GetAngleY(), GetAngleZ(), afSpeed, afMaxRotationSpeed)
endFunction

bool Function CheckViability()
  if CheckCellAttached(self) && CheckFor3D(self)
    return false
  endif

  DisableAndDelete()
  return true
endFunction

bool Function CheckViableDistance()
  if CheckCellAttached(self) && CheckFor3D(self) && PlayerRef.GetDistance(self) <= fMaxPlayerDistance
    return true
  endif

  DisableAndDelete()
  return false
endFunction

bool Function CheckCellAttached(ObjectReference akObject)
  Cell ParentCell = akObject.GetParentCell()
  return ParentCell && ParentCell.IsAttached()
endFunction

bool Function CheckFor3D(ObjectReference akObject)
  bool bLoaded = akObject && akObject.Is3DLoaded()
  bool bWaiting = true
  float fMaxWaitingTime = 10.0
  float fBaseWaitingTime = 0.01
  float fTimeWaited = 0.0

  while bWaiting && !bLoaded
    Utility.Wait(fBaseWaitingTime)
    fTimeWaited += fBaseWaitingTime
    bWaiting = fTimeWaited < fMaxWaitingTime
    bLoaded = akObject.Is3DLoaded()
  endwhile

  return bLoaded
endFunction
