scriptName CritterDragonFly extends Critter
{Main Behavior script for dragonfly};[USKP 2.0.1]
;!{Main Behavior script for fish schools}

import Utility
import form
import debug

; Constants
float Property fActorDetectionDistance = 300.0 auto
{The Distance at which an actor will trigger a flee behavior}
float Property fTranslationSpeedMean = 175.0 auto
{The movement speed when going from plant to plant, mean value}
float Property fTranslationSpeedVariance = 75.0 auto
{The movement speed when going from plant to plant, variance}
float Property fFleeTranslationSpeed = 500.0 auto
{The movement speed when fleeing from the player}
float Property fMinScale = 0.5 auto
{Minimum initial scale of the Firefly}
float Property fMaxScale = 0.8 auto
{Maximum initial scale of the Firefly}
float Property fSplineCurvature = 200.0 auto
{Spline curvature}
float Property fMinTimeNotMoving = 1.0 auto
float Property fMaxTimeNotMoving = 5.0 auto
float Property fMinFleeHeight = 2000.0 auto
float Property fMaxFleeHeight = 3000.0 auto
float property fMaxRotationSpeed = 540.0 auto
{Max rotation speed while mocing, default = 540 deg/s}

; Variables
Actor closestActor = none


; Called by the spawner to kick off the processing on this Firefly
Event OnStart()
	; Vary size a bit
	SetScale(RandomFloat(fMinScale, fMaxScale))
	
	; Play the hover animation
	PlayAnimation(PathStartGraphEvent)
	;PlayAnimation("WingsFlyingAnim")
	;PlayAnimation("FlightLoop")
	
	; test moved to Critter [indent retained] [USKP 2.0.1]
		WarpToRandomPoint()
; ; 		Debug.TraceConditional("DragonFly " + self + " registering for update", bCritterDebug); [USKP 2.0.1]
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

Event OnUpdate()
	; Is the player too far?
	if CheckViableDistance()
		; Check whether we should flee and move faster
		if (closestActor != none)
; 			;Debug.Trace(self + " Oh noes! there is an Actor " + closestActor + " nearby, Flee")
			; Move fast
			; Fly far far away
			FlyAway(fFleeTranslationSpeed)
		else
			; Move at regular speed
			float fspeed = RandomFloat(fTranslationSpeedMean - fTranslationSpeedVariance, fTranslationSpeedMean + fTranslationSpeedVariance)

			; Time to take off for another point
			GoToNewPoint(fspeed)
		endIf
		bCalculating = False; [USKP 2.0.4]
	endIf
	closestActor = none; [USKP 2.0.4]
endEvent

Event OnCritterGoalReached()
; 	traceConditional(self + " reached goal", bCritterDebug)
	if PlayerRef; interlock, but never delete during Translation [USKP 2.0.1]
		closestActor = Game.FindClosestActorFromRef(self, fActorDetectionDistance)
		if closestActor
			; There is an actor right there, trigger the update right away, so we'll flee
; ; 			Debug.TraceConditional("Firefly " + self + " registering for immediate update", bCritterDebug)
			RegisterForSingleUpdate(0.0)
		else
			; Wait at the plant, then take off again
; ; 			Debug.TraceConditional("Firefly " + self + " registering for update at plant", bCritterDebug)
			RegisterForSingleUpdate(RandomFloat(fMinTimeNotMoving, fMaxTimeNotMoving))
		endIf
	endIf
EndEvent


float fTargetX
float fTargetY
float fTargetZ
float fTargetAngleZ
float fTargetAngleX

;/
;	returns true on success [USKP 2.0.1]
/;
bool Function PickRandomPoint()

	; moved here from GoToNewPoint [USKP 2.0.1]
	; safety - make sure me and my spawner are both still loaded!
	if !(PlayerRef ;/&& CheckCellAttached(self) && Spawner && CheckCellAttached(Spawner)/;)
		return false
	endif

	; First find a random point within the radius
;/// [USKP 2.0.4] ///;
	Float fLength = RandomFloat(0.0, fLeashLength)
	fTargetAngleZ = RandomFloat(-180.0, 180.0)
	fTargetX = fSpawnerX + fLength * Math.Cos(fTargetAngleZ)
	fTargetY = fSpawnerY + fLength * Math.Sin(fTargetAngleZ)
;*** [USKP 2.0.4] ***
	
	; Now pick a random Z
	fTargetZ = fSpawnerZ + RandomFloat(0.0, fHeight)
	
	; Pick random target angle
	fTargetAngleZ = RandomFloat(-180.0, 180.0)
	fTargetAngleX = 0.0
	return (PlayerRef != None); check again after lengthy calculations [USKP 2.0.1]
	
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
	elseif !CheckViability()
		; And travel to it
		SplineTranslateTo(fTargetX, ftargetY, ftargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)
	endif
	
endFunction

;/
;	returns true on success [USKP 2.0.1]
/;
bool Function PickRandomPointOutsideLeash()

	; moved here from FlyAway [USKP 2.0.1]
	; safety - make sure me and my spawner are both still loaded!
	if !(PlayerRef ;/&& CheckCellAttached(self) && Spawner && CheckCellAttached(Spawner)/;)
		return false
	endif

	; Pick a random point far away
;/// [USKP 2.0.4] ///;
	Float fLength = RandomFloat(fMaxPlayerDistance, fMaxPlayerDistance * 2.0)
	fTargetAngleZ = RandomFloat(-180.0, 180.0)
	fTargetX = fSpawnerX + fLength * Math.Cos(fTargetAngleZ)
	fTargetY = fSpawnerY + fLength * Math.Sin(fTargetAngleZ)
	fTargetZ = fSpawnerZ + RandomFloat(fMinFleeHeight, fMaxFleeHeight)
;*** [USKP 2.0.4] ***
	
	fTargetAngleX = 0.0
;!	fTargetAngleZ = RandomFloat(-180.0, 180.0)
	return (PlayerRef != None); check again after lengthy calculations [USKP 2.0.1]

endFunction

Function FlyAway(float afSpeed)

	if !PickRandomPointOutsideLeash()
 	; ;	debug.trace("Tried to run FlyAway, but PickRandomPointOutsideLeash failed. "+self)
		bCalculating = False; [USKP 2.0.3]
		disableAndDelete()
	elseif !CheckViability()
		SplineTranslateTo(fTargetX, ftargetY, ftargetZ, fTargetAngleX, 0.0, fTargetAngleZ, fSplineCurvature, afSpeed, fMaxRotationSpeed)
	endif
	
endFunction
