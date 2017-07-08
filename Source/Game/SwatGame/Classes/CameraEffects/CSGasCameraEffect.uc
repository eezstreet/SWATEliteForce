class CSGasCameraEffect extends PepperSprayCameraEffect
    config(SwatEquipment)
	native
	noexport;

// This effect is the same as PepperSprayCameraEffect but it uses
// different parameters, as set by DesignerCSGasParams.

defaultproperties
{
    ParamsClassName="SwatCameraEffects.DesignerCSGasParams"
}
