// Havok Ball and Socket constraint (Point to Point) constraint.
// Constrains the given local pivot points of the two Actors together.

class HavokBSConstraint extends HavokConstraint
	native
	placeable;

cpptext
{
#ifdef UNREAL_HAVOK
	virtual bool HavokInitActor();
	virtual void UpdateConstraintDetails();
#endif
}

defaultproperties
{
	Texture=Texture'Engine_res.Havok.S_HkBSConstraint'
}