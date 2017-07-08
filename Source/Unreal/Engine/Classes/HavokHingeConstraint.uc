// Havok Hinge constraint. This enforces a postional constraint 
// about the pivot and reduces the freedom of the object further
// by only allowing rotation about the given primary axis.

class HavokHingeConstraint extends HavokConstraint
	native
	placeable;

cpptext
{
#ifdef UNREAL_HAVOK
	virtual bool HavokInitActor();
	virtual void UpdateConstraintDetails();
#endif
}

var(HavokConstraint) enum EHavokHingeType
{
	HKH_Normal, 
	HKH_Motorized,  // keep the desired Vel
	HKH_Controlled  // acieve the desired angle (A or B depending on the hkUseDesiredAngleB flag
} hkHingeType;

var(HavokConstraint) enum EHavokHingeMotorType
{
	HKHM_SpringDamper,  // simple motor
	HKHM_Blending // implicit spring damper.
} hkHingeMotorType;

// Motorized hinge
var(HavokConstraint) bool hkMotorActive;
var(HavokConstraint) float hkDesiredAngVel; // 65535 = 1 full rotation per second
var(HavokConstraint) float hkMaxForce; // 0 == no max
var(HavokConstraint) float hkMotorDamping; // 0 == no max

// Controlled Motor to achieve a certain angle
// Uses hkDesiredAngVel and hkMaxTorque from above.
var(HavokConstraint) float hkDesiredAngleA; // 65535 = 360 degrees
var(HavokConstraint) float hkDesiredAngleB; // 65535 = 360 degrees
var(HavokConstraint) bool  hkUseDesiredAngleB;

// output - current angular position of joint // 65535 = 360 degrees
var const float hkCurrentAngle;

// In this state nothing will happen if this hinge is triggered or untriggered.
auto state Default
{
ignores Trigger, Untrigger;
}

// In this state, Trigger will cause the hinge type to change to HT_Motor.
// Another trigger will toggle it to HT_Controlled, and it will try and maintain its current angle.
state() ToggleMotor
{
ignores Untrigger;
	function Trigger( actor Other, pawn EventInstigator )
	{
		//Log("ToggleMotor - Trigger");
		if(hkHingeType == HKH_Motorized)
		{
			hkDesiredAngleA = hkCurrentAngle;
			hkUseDesiredAngleB = False;
			hkHingeType = HKH_Controlled;
		}
		else
			hkHingeType = HKH_Motorized;

		UpdateConstraintDetails(); // will wake actors
	}

Begin:
	hkHingeType = HKH_Controlled;
	hkUseDesiredAngleB = False;
	UpdateConstraintDetails();
}

// In this state, Trigger will turn motor on.
// Untrigger will turn toggle it to HKH_Controlled, and it will try and maintain its current angle.
state() ControlMotor
{
	function Trigger( actor Other, pawn EventInstigator )
	{
		//Log("ControlMotor - Trigger");
		if(hkHingeType != HKH_Motorized)
		{
			hkHingeType = HKH_Motorized;
			UpdateConstraintDetails();
		}
	}

	function Untrigger( actor Other, pawn EventInstigator )
	{
		//Log("ControlMotor - Untrigger");
		if(hkHingeType == HKH_Motorized)
		{
			hkDesiredAngleA = hkCurrentAngle;
			hkUseDesiredAngleB = False;
			hkHingeType = HKH_Controlled;
			UpdateConstraintDetails();
		}
	}

Begin:
	hkHingeType = HKH_Controlled;
	hkUseDesiredAngleB = False;
	UpdateConstraintDetails();
}

// In this state a trigger will toggle the hinge between using KDesiredAngle and KAltDesiredAngle.
// It will use whatever the current KHingeType is to achieve this, so this is only useful with HT_Controlled and HT_Springy.
state() ToggleDesired
{
ignores Untrigger;

	function Trigger( actor Other, pawn EventInstigator )
	{
		//Log("ToggleDesired - Trigger");
		if(hkUseDesiredAngleB)
			hkUseDesiredAngleB = False;
		else
			hkUseDesiredAngleB = True;
		//Log("UseAlt"$hkUseDesiredAngleB);
		UpdateConstraintDetails();
	}
}

// In this state, trigger will cause the hinge to use KAltDesiredAngle, untrigger will caus it to use KAltDesiredAngle
state() ControlDesired
{
	function Trigger( actor Other, pawn EventInstigator )
	{
		//Log("ControlDesired - Trigger");
		hkUseDesiredAngleB = True;
		//Log("UseAlt"$hkUseDesiredAngleB);
		UpdateConstraintDetails();
	}

	function Untrigger( actor Other, pawn EventInstigator )
	{
		//Log("ControlDesired - Untrigger");
		hkUseDesiredAngleB = False;
		//Log("UseAlt"$hkUseDesiredAngleB);
		UpdateConstraintDetails();
	}
}


defaultproperties
{
	Texture=Texture'Engine_res.Havok.S_HkHingeConstraint'
	bDirectional=True 
	hkUseDesiredAngleB=False
	hkHingeType=HKH_Normal 
	hkHingeMotorType=HKHM_SpringDamper
	hkMotorDamping=7500; 
	hkMaxForce=10000;// some large number normally.
	hkMotorActive=true;// when the hinge is motorized, you can toggle the motor (controlled or velocity) on or off with this
	AutoComputeLocals=HKC_AutoComputeBFromC; // base the B basis on the Constraint Actor rotation.
}