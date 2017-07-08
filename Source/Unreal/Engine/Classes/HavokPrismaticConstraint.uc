// Havok Prismatic constraint. This constraint keeps the object
// on a given orientation and lateral movement (along primary axis)

class HavokPrismaticConstraint extends HavokConstraint
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
	Texture=Texture'Engine_res.Havok.S_HkPrismaticConstraint'
	bDirectional=true
}