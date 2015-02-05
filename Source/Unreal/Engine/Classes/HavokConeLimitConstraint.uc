//=============================================================================
// The Havok Cone Limit class
// By using a seperate constraint on top a normal instead of a single constraint
// that has a limit in it (eg LimitedHingeConstraint) you are wasting CPU cycles!
//=============================================================================

class HavokConeLimitConstraint extends HavokConstraint
    native
    placeable;

cpptext
{
#ifdef UNREAL_HAVOK
	virtual bool HavokInitActor();
	virtual void UpdateConstraintDetails();
#endif
} 

var(HavokConstraint) float hkHalfAngle; // ( 65535 = 360 deg )

// Internal index references. Do not alter.
 var const transient int basisAIndex;
 var const transient int basisBIndex;
 var const transient int coneIndex;
//

defaultproperties
{
    hkHalfAngle=8200 // about 45 deg
   
	Texture=Texture'Engine_res.Havok.S_HkConeLimitConstraint'
    bDirectional=True
    AutoComputeLocals=HKC_AutoComputeBFromC; // base the B basis on the Constraint Actor rotation.
}