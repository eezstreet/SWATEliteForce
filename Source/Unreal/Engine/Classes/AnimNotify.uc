class AnimNotify extends Core.Object
	native
	abstract
	editinlinenew
	hidecategories(Object)
	collapsecategories;

var transient int Revision;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( UMeshInstance *Instance, AActor *Owner ) {};
	// UObject interface.
	virtual void PostEditChange();
}