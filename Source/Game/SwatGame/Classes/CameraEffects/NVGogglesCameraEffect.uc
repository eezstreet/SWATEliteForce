class NVGogglesCameraEffect extends SwatCameraEffect
    config(SwatEquipment)
	native
	noexport;

var private const transient int 	RenderTargets[2];   //TMC Note: this must match the size in SwatCameraEffects.h
var protected SwatGamePlayerController PlayerController; // used to get some parameters for the effect

function Initialize(SwatGamePlayerController inPlayerController)
{
    PlayerController = inPlayerController;
}

defaultproperties
{
}
