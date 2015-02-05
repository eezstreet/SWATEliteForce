// The Havok Rigid body class.

class HavokRigidBody extends HavokObject
	editinlinenew
	native;

cpptext
{
#	ifdef UNREAL_HAVOK
		void PostEditChange();
#	endif
}

var const transient int hkEntityPtr; //the hkEntity pointer for hkRigidbody
var const transient int hkUprightConstraintPtr; //the hkConstraint pointer for the force upright constraint

// bHighDetailOnly: is this object reserved for high detail situations only?
var()	bool    bHighDetailOnly "If true, the object will have physics disabled if the level's physics setting is less than PDL_High, or if running on a dedicated server.";

// bClientOnly: is this an effect? only on the client side, not server.
var()   bool    bClientOnly     "If true, the object's physics will be disabled when running on a server (i.e., it will only be physical on clients)";

// hkMass: 0 == fixed body, overrides the keyframed flag. >0 == dynamic or keyframed motion.
var()   float   hkMass          "The mass of the object.\r\n\r\nWARNING: If mass is set to 0 then the object will be fixed in place, and the hkKeyframed setting will be ignored!"; 

// hkStabilizedInertia: false by default, but you can use this special Inertia computation mode for more unstable configurations like long thin objects
var()   bool    hkStabilizedInertia "Set this flag to help stabilize the physics of unstable configurations, such as long thin objects. For normal configurations is should be left at the default value of false."; 

// hkFriction: [0,1] How sticky something is.
var()   float   hkFriction      "Controls how sticky the object is. Minimum value is 0 and maximum is 1"; 

// hkRestitution: [0,1] How bouncy something is.
var()   float   hkRestitution   "Controls how bouncy the object is. Minimum value is 0 and maximum is 1"; 

// hkLinearDamping: >=0 damping on the linear velocity. Usually very small (0 by default)
var()   float   hkLinearDamping "Controls how much damping is applied to linear velocity. Values are usually very small, and 0 means 'no damping'"; 

// hkAngularDamping: >=0 damping on the angular velocity. Usually very small (0.05 by default)
var()   float   hkAngularDamping "Controls how much damping is applied to angular velocity. Values are usually very small, and 0 means 'no damping'"; 

// hkActive: is the body to start moving?
var()   bool	hkActive        "If true, the object will be 'physical' as soon as the level starts (e.g., it will fall to the ground, etc). If false, it will be inactive until it is activated (i.e., it will float in space something collides with it, etc.)";

// hkKeyframed: transform taken from Unreal when Actor moves? Use this mode for Movers etc.
var()   bool	hkKeyframed     "Only set this to true for objects that should block other physics objects but whose movement is controlled by Unreal instead of physical forces. For example, this should be true for Movers.\r\n\r\nWARNING: this flag is ignored if hkMass is 0!"; 

// hkLinearVel: in Unreal units
var()   vector  hkLinearVel     "The initial linear velocity of the object.\r\n\r\nWARNING: this value must be in Unreal units, not meters/second (1 meter = 50 Unreal distance units).";

// hkAngularVel: in Unreal units
var()   vector  hkAngularVel    "The initial angular velocity of the object.\r\n\r\nWARNING: this value must be in Unreal units, not radians/second (1 radian = 10430.2192 Unreal angular units)."; 


/// The Advanced Group Filter
///
/// The behaves like the normal group filter but allows the user to selectively turn off pairs
/// of collidables. This is particularly useful when you have a constrained system and want to 
/// disable collision between connected objects.
/// This filter takes two additional parameter when setting up the filter info.
/// A subpart ID : indicates a unique ID for this object in the system
/// An ignore subpartID : indicates which subpart collision should be ignored for.
///
/// The extra parameters are only used for collidables that belong to the same system group.
/// If you want to use them you must ensure all collidables have the same system group number.
///
/// Here is an example of how you might set the subpart and ignore ID's for a ragdoll
///
///	Part			Subpart ID	Ignore ID
/// --------------------------------------
/// Torso				1			0
/// Pelvis				2			1
/// Head				5			1
/// Upper Left  Arm		4			1
/// Upper Right Arm		3			1
/// Lower Left  Arm		7			4
/// Lower Right Arm		6			3
/// Upper Left  Leg		8			2
/// Upper Right Leg		9			2
/// Lower Left  Leg		10			8
/// Lower Right Leg		11			9
///
///
/// Predefined Layers in Havok:
//	  LAYER_NONE = 0, no filtering , collides with everything
///   LAYER_STATIC = 1, (default for landscape), does not collide with its own group or static
///   LAYER_DYNAMIC = 2, (default for free moving rigid bodies), 
///	  LAYER_KEYFRAME = 5, (default for keyframed (Movers etc) and the Player Pawn), does not collide with its own group or static
///	  LAYER_FAST_DEBRIS = 7, nothing in it by default, does not collide with its own group.
/// 
/// See LevelInfo.HavokSetCollisionLayerEnabled(int layerA, int layerB, bool enabled, bool updateWorldInfo)
/// for runtime enable / disable of groups.

const HavokCollisionLayer_All=0;
const HavokCollisionLayer_Static=1;
const HavokCollisionLayer_Dynamic=2;
const HavokCollisionLayer_Keyframed=5;
const HavokCollisionLayer_Debris=7;

// ckline note: don't expose these to editor, because they aren't generally supported yet in our integration (see havok ticket 619-117889)
// 32 layers (see the 5 defaults above, but you can use whatever)
var   int		hkCollisionLayer    "The collision layer in which this object resides. Supported values are:\r\n\r\n0 = no filtering, collides with everything\r\n\r\n1 = does not collide with its own group or static (default for static objects and landscape)\r\n\r\n2 = collides with everything (default for free moving rigid bodies)\r\n\r\n5 = does not collide with its own group or static objects (default for keyframed (Movers etc) and the Player Pawn),\r\n\r\n7 = does not collide with its own group (nothing in it by default, intended for fast debris)."; 

// 0..32768 system groups.
var   int		hkCollisionSystemGroup; 

// 0..64 subpart ids
var   int		hkCollisionSubpartID; 

// 0..64 subpart ids
var   int		hkCollisionSubpartIgnoreID; 

// If Keyframed or Mass 0 (fixed) then this following orientation constraint will be ignored.
// If this is not 'Free' then the code will create a constraint very similar to the Havok6DOFConstraint
var()	enum EOrientationConstraint
{
	HKOC_Free, // Just let the rigid body do what it wants
	HKOC_ConstrainX, // Angular Constraint on the world X and what that maps to when the body is created
	HKOC_ConstrainY, // Angular Constraint on the world Y and what that maps to when the body is created
	HKOC_ConstrainZ, // Angular Constraint on the world Z and what that maps to when the body is created
	HKOC_ConstrainXYZ, // Constraint all 3 Angular DOFs (Degrees of Freedom)
} hkForceUpright "Controls which, if any, of the object's rotational axes are constrained while moving.\r\n\r\nWARNING: this parameter is ignored hkKeyframed is true or hkMass is 0."; 

// 'stay upright' strength
var()   float   hkForceUprightStrength "Governs how quickly an object bounces back when tilted away from its upright axis. Higher values mean that the object recovers more quickly. Values can range from 0 to 1";  

// 'stay upright' damping
var()   float   hkForceUprightDamping "Governs how quickly the oscillation along the vertical axis settles down. Low values create springy behavior, while high values will reduce any oscillations very quickly with the size of the oscillations getting much smaller each time. Values can range from 0 to 1";  

defaultproperties
{
	bHighDetailOnly=false
	bClientOnly=false
    hkMass=1
    hkStabilizedInertia=false
    hkFriction=0.8
    hkRestitution=0.3
    hkLinearDamping=0
	hkAngularDamping=0.05
    hkActive=true
	hkKeyframed=false
	hkForceUpright=HKOC_Free
	hkForceUprightStrength = 0.3
	hkForceUprightDamping = 0.9
}