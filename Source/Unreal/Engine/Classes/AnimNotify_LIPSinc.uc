
// ifdef WITH_LIPSinc

class AnimNotify_LIPSinc extends AnimNotify
	native;

var() name  LIPSincAnimName;
var() float Volume;
var() int   Radius;
var() float Pitch;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( UMeshInstance *Instance, AActor *Owner );
}

defaultproperties
{
	Radius=80
	Volume=1.0
	Pitch=1.0
}

// endif