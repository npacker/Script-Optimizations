scriptName CritterFish extends Critter
{Main Behavior script for fish schools}

import Utility
import form
import debug

; Constants
float Property fActorDetectionDistance = 300.0 auto
{The Distance at which an actor will trigger a flee behavior}
float Property fTranslationSpeedMean = 40.0 auto
{The movement speed when going from plant to plant, mean value}
float Property fTranslationSpeedVariance = 20.0 auto
{The movement speed when going from plant to plant, variance}
float Property fFleeTranslationSpeed = 70.0 auto
{The movement speed when fleeing from the player}
float Property fMinScale = 0.1 auto
{Minimum initial scale of the Fish}
float Property fMaxScale = 0.2 auto
{Maximum initial scale of the Fish}
float Property fMinDepth = 10.0 auto
{Minimum fish depth}
float Property fSplineCurvature = 200.0 auto
{Spline curvature}
float Property fMinTimeNotMoving = 1.0 auto
float Property fMaxTimeNotMoving = 5.0 auto
float Property fSchoolingDistanceX = 25.0 auto
float Property fSchoolingDistanceY = 35.0 auto
int Property iPercentChanceSchooling = 50 auto
int Property iPercentChanceStopSchooling = 5 auto
float property fMaxRotationSpeed = 360.0 auto
{Max rotation speed while mocing, default = 360 deg/s}

; Hidden property for schooling
bool Property bMoving = false auto hidden
float Property fMoving = 0.0 auto hidden; [USKP 2.0.4]

; Variables
Actor closestActor = none
CritterFish TargetFish = none

;/ clear TargetObject [USKP 2.0.1]
/;
Function FollowClear()
	Float delay = 0.367879; 1/e
	while TargetFish && bCalculating && delay < 2.943; 3 times
		; avoid clearing during calculations [USKP 2.0.4]
		Wait(delay)
		delay += delay
	endWhile
	TargetFish = none
endFunction

;/ clear Leader and Follower and Target [USKP 2.0.1]
/;
Function TargetClear()
	if TargetFish
		TargetFish.Follower = none
	endIf
	TargetFish = none
endFunction

; Called by the spawner to kick off the processing on this Fish
Event OnStart()
	; Vary size a bit
	SetScale(RandomFloat(fMinScale, fMaxScale))
	
	; Start in the random swimming state
	GotoState("RandomSwimming")
	
	; test moved to Critter [indent retained] [USKP 2.0.1]
		WarpToRandomPoint()
; ; 		Debug.TraceConditional("Fish " + self + " registering for update", bCritterDebug)

		; Enable the critter
		Enable()

		if CheckFor3D(self)
			; Switch to keyframe state
			SetMotionType(Motion_Keyframed, false)

			; Get ready to start moving
			RegisterForSingleUpdate(0.0)
		else
			DisableAndDelete(false)
		endIf
endEvent

State RandomSwimming

	Event OnUpdate()
		; Is the player too far?
		if CheckViableDistance()
			; Good to update, check for close actors
;!			Actor closestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance)

			; Check whether we should flee and move faster
;!			float fspeed = 0.0
			float fspeed = fFleeTranslationSpeed
			if (closestActor != none)
; 				;Debug.Trace(self + " Oh noes! there is an Actor " + closestActor + " nearby, Flee")
				; Move fast
;!				fspeed = fFleeTranslationSpeed
			else
				; Move at regular speed
				fspeed = RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance)
			endIf

			; Time to take off for another plant
			if (RandomInt(0, 100) < iPercentChanceSchooling)
				if PickTargetFishForSchooling() && PickRandomPointBehindTargetFish()
					GotoState("Schooling")
					SchoolWithOtherFish(fspeed)
				else
					GoToNewPoint(fspeed)
				endIf
			else
				GoToNewPoint(fspeed)
			endIf
			bCalculating = False; [USKP 2.0.4]
		endIf
		closestActor = none; [USKP 2.0.4]
	endEvent

	Event OnCritterGoalAlmostReached()
; 		traceConditional(self + " reached goal", bCritterDebug)
		fMoving = 0.0
		if PlayerRef; interlock, but never delete during Translation [USKP 2.0.1]
			; pre-find for speed, match other critters [USKP 2.0.4]
			closestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance)
; ; 			Debug.TraceConditional("Fish " + self + " registering for immediate update", bCritterDebug)
			RegisterForSingleUpdate(0.0)
		endIf
	EndEvent
	
endState


State Schooling

	Event OnUpdate()
		if CheckViableDistance()
;!			if ((RandomInt(0, 100) < iPercentChanceStopSchooling) || TargetFish == none || TargetFish.IsDisabled() || !TargetFish.bMoving)
			if (closestActor != none); [USKP 2.0.4]
; 				;Debug.Trace(self + " Oh noes! there is an Actor " + closestActor + " nearby, Flee")
				GotoState("RandomSwimming")
				TargetClear()
				GoToNewPoint(fFleeTranslationSpeed)
			elseif (RandomInt(0, 100) >= iPercentChanceStopSchooling) && (TargetFish as CritterFish) && TargetFish.fMoving && PickRandomPointBehindTargetFish()
				; If the target fish is moving, follow it
;!				SchoolWithOtherFish(fFleeTranslationSpeed)
				SchoolWithOtherFish(TargetFish.fMoving); reduce twitching [USKP 2.0.4]
			else
				GotoState("RandomSwimming")
				TargetClear()
				GoToNewPoint(RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance))
			endIf
			bCalculating = False; [USKP 2.0.4]
		endIf
		closestActor = none; [USKP 2.0.4]
	endEvent

	Event OnCritterGoalAlmostReached()
; 		traceConditional(self + " about to reach goal", bCritterDebug)
		if PlayerRef; interlock, and match RandomSwimming [USKP 2.0.1]
			; pre-find for speed, match other critters [USKP 2.0.4]
			closestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance)
			RegisterForSingleUpdate(0.0)
		endIf
	EndEvent
	
endState


float fTargetX
float fTargetY
float fTargetZ
float fTargetAngleZ
float fTargetAngleX

;/
;	returns true on success [USKP 2.0.1]
/;
bool Function PickRandomPoint()

	; Pick a point inside the upside down cone of height fWaterDepth and radius fLeashLength
	; Since most ponds will look like a bowl, we don't want fish close to the edge to clip through the ground
	
	; make sure our spawner is loaded.
	if PlayerRef ;/&& CheckCellAttached(self) && Spawner && CheckCellAttached(Spawner)/;
		; First find a random point within the radius
;/// [USKP 2.0.4] ///;
		Float fLength = RandomFloat(0.0, fLeashLength)
		fTargetAngleZ = RandomFloat(-180.0, 180.0)
		fTargetX = fSpawnerX + fLength * Math.Cos(fTargetAngleZ)
		fTargetY = fSpawnerY + fLength * Math.Sin(fTargetAngleZ)
;*** [USKP 2.0.4] ***
		
		; Now pick a random Z based on the length.
		; If flength == fleashLength, then it must be -fMinDepth
		; If length == 0, then it can be -fDepth
		; fixed [USKP 2.0.4]
		if fMinDepth < fDepth
			fTargetZ = fSpawnerZ - RandomFloat(fMinDepth, (fDepth - ((flength * (fDepth - fMinDepth)) / fLeashLength)))
		else
			fTargetZ = fSpawnerZ
		endIf
		
		; Pick random target angle
;!		fTargetAngleZ = RandomFloat(-180.0, 180.0)
		fTargetAngleX = 0.0
		return (PlayerRef != None); check again after lengthy calculations [USKP 2.0.1]
	else
; 		debug.trace("Tried to run PickRandomPoint, but no valid TargetFish.  "+self)
		return false
	endif

endFunction

bool Function PickTargetFishForSchooling()
	if Spawner && CheckCellAttached(Spawner)
;!		TargetFish = Game.FindRandomReferenceOfAnyTypeInList(Spawner.CritterTypes, fSpawnerX, fSpawnerY, fSpawnerZ, fLeashLength - fSchoolingDistanceX) as CritterFish
		TargetFish = Game.FindRandomReferenceOfAnyTypeInList(Spawner.CritterTypes, fSpawnerX, fSpawnerY, fSpawnerZ, fLeashLength - fSchoolingDistanceY) as CritterFish
		; record TargetFish.Follower [USKP 2.0.1]
		if (TargetFish && TargetFish != self && TargetFish.FollowSet(self as ObjectReference))
			return true
		endif
		TargetFish = none
	endif
	return false
endFunction

;/
;	returns true on success [USKP 2.0.1]
/;
bool Function PickRandomPointBehindTargetFish()

	if PlayerRef && TargetFish && !TargetFish.IsDisabled() && CheckFor3D(TargetFish)
		; moved unchanged variables outside loop [USKP 2.0.1]
		float ftargetFishX = targetFish.X - fSpawnerX
		float ftargetFishY = targetFish.Y - fSpawnerY
		fTargetZ = targetFish.Z; default same as leader [USKP 2.0.4]
		fTargetAngleZ = targetFish.GetAngleZ()
;/// [USKP 2.0.4] ///;
		; vanilla formula dithers X and Y directly. Reduce calculations by
		; dithering angle vector instead.
		; reuse fSchoolingDistance[X|Y] as min and max distance from leader.
		float fDistance = RandomFloat(fSchoolingDistanceX, fSchoolingDistanceY)
		float fDeltaAngle = fTargetAngleZ + RandomFloat(-fAngleVarianceZ, fAngleVarianceZ)
		fTargetX = ftargetFishX - fDistance * Math.cos(fDeltaAngle)
		fTargetY = ftargetFishY - fDistance * Math.sin(fDeltaAngle)
		; variables above are 0,0 spawner relative
		float flength = Math.sqrt(fTargetX * fTargetX + fTargetY * fTargetY)
		fTargetX += fSpawnerX
		fTargetY += fSpawnerY
;*** [USKP 2.0.4] ***

		; Now pick a random Z
		; If flength == fleashLength, then it must be -fMinDepth
		; If length == 0, then it can be -fDepth
		; fixed [USKP 2.0.4]
		if flength < fLeashLength && fMinDepth < fDepth
			fTargetZ = fSpawnerZ - RandomFloat(fMinDepth, (fDepth - ((flength * (fDepth - fMinDepth)) / fLeashLength)))
		endIf
		
;!		fTargetAngleZ = targetFish.GetAngleZ()
		fTargetAngleX = 0.0
		return (PlayerRef != None); check again after lengthy calculations [USKP 2.0.1]
	else
; 		debug.trace("Tried to run PickRandomPointBehindTargetFish, but no valid TargetFish.  "+self)
		return false
	endif
	
endFunction

Function WarpToRandomPoint()
	
	; Pick a random point
	PickRandomPoint()

	; And warp to it
	SetPosition(fTargetX, fTargetY, fTargetZ)
	SetAngle(fTargetAngleX, 0.0, fTargetAngleZ)
	
endFunction

Function GoToNewPoint(float afSpeed)

	; Pick a random point
	if !PickRandomPoint()
 	; ;	debug.trace("Tried to run GoToNewPoint, but PickRandomPoint failed. "+self)
		bCalculating = False; [USKP 2.0.3]
		disableAndDelete()
	elseif CheckViability()
		return
	endif

	; And travel to it
	fMoving = afSpeed; [USKP 2.0.4]
	SplineTranslateTo(fTargetX, ftargetY, ftargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)

endFunction

Function SchoolWithOtherFish(float afSpeed)

	if !CheckViability()
		fMoving = afSpeed; [USKP 2.0.4]
		SplineTranslateTo(fTargetX, ftargetY, ftargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)
	endif
endFunction

EVENT onCellDetach()
	; Safety measure - when my cell is detached, for whatever reason, kill me.
; 	;debug.trace("Killing self due to onCellDetach() - "+self)
;!	DisableAndDelete()
	; kick the OnUpdate in hopes it will clean up. [USKP 2.0.1]
	bMoving = false
	fMoving = 0.0
	parent.onCellDetach()
endEVENT
