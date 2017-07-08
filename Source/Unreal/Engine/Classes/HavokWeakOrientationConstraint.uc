// Havok orientation constraint. Actually is a orientation Action that will try to match
// the two local basis. As the Action only deals with single bodies (it is a UnaryAction)
// BodyB should always be None in this constraint. It is also not breakable.

class HavokWeakOrientationConstraint extends HavokConstraint
	native
	placeable;

cpptext
{
#ifdef UNREAL_HAVOK
	virtual bool HavokInitActor();
	virtual void HavokQuitActor(); // removes the Action, not constraint
	virtual void UpdateConstraintDetails();
	virtual void* GetBaseConstraint(); // returns the Action, not constraint
#endif
}

defaultproperties
{
	Texture=Texture'Engine_res.Havok.S_HkWeakOConstraint'
	fSpecificStrength = 0.1;
	fSpecificDamping = 0.01;
	AutoComputeLocals=HKC_AutoComputeBFromC; // base the B basis on the Constraint Actor rotation.
	bDirectional=True
}