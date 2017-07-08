class FluidSurfaceParamaters extends Core.Object
	native
	editinlinenew
	hidecategories(Object);

var (WaveControl) plane	WaveHeights;
var (WaveControl) plane	WaveSpeeds;
var (WaveControl) plane	WaveOffsets;
var (WaveControl) plane	WaveXSizes;
var (WaveControl) plane	WaveYSizes;

defaultproperties
{
	WaveHeights	=(x=23,y=20,z=32,w=14)
	WaveSpeeds	=(x=0.2,y=-0.3,z=0.1,w=-0.1)
	WaveOffsets	=(x=0.7,y=-0.3,z=0.2,w=0)
	WaveXSizes	=(x=500,y=180,z=-310,w=100)
	WaveYSizes	=(x=-100,y=140,z=200,w=-500)
}
