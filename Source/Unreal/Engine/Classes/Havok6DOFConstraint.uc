
// Havok 6 Degree of Freedom constraint, so that leaves no degrees of freedom!
// Used as a replacement for the likes of Karma RPRO constraints
// It is very strong by default, so use the specific damping etc in HkConstraint
// to lessen if desired. Using keyframed objects with MoveActor is prefered to this
// constraint as the keyframed object is both cheaper and more tolerant (velocity based)
// Alternatively, use the HavokOrientationAction which is much cheaper, but weaker (which may be desired)

class Havok6DOFConstraint extends HavokConstraint
	native
	placeable;

cpptext
{
#ifdef UNREAL_HAVOK
	virtual bool HavokInitActor();
	virtual void UpdateConstraintDetails();
#endif
}

// If you change the following two bools, call RecreateConstraint not UpdateConstraint.
var(HavokConstraint) bool bConstrainAngular; //orientation
var(HavokConstraint) bool bConstrainLinear;  //pos

// Internal index references. Do not alter.
 var const transient int pivotAIndex;
 var const transient int pivotBIndex;
 var const transient int basisAIndex;
 var const transient int basisBIndex;
//

defaultproperties
{
	Texture=Texture'Engine_res.Havok.S_Hk6DOFConstraint'
	bDirectional=True
	bConstrainLinear=True
	bConstrainAngular=True
}