class AnimNotify_Sound extends AnimNotify
	native;

var() sound Sound;
var() float Volume;
var() int Radius;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( UMeshInstance *Instance, AActor *Owner );
}

defaultproperties
{
	Radius=0
	Volume=1.0
}