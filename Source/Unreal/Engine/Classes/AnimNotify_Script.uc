class AnimNotify_Script extends AnimNotify
	native;

var() name NotifyName;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( UMeshInstance *Instance, AActor *Owner );
}