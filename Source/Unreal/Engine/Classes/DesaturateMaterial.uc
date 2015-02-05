// rowan: NOTE: This class has been added purely to work around a bug where C++ classes derived from native script classes do not inherit
// the scripted classes default properties. The work around is to add a placeholder noexprt native script class for the C++ class.
// class created by henry
class DesaturateMaterial extends Material
    native
    noexport
    dependsOn(FinalBlend);

import enum EFrameBufferBlending from FinalBlend;

var BitmapMaterial       SourceBitmap;
var Vector               GreyColorChooser;
var Vector               GreyWeight;
var EFrameBufferBlending Blending;
var bool				 NVGogglesDesaturate;

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	GreyColorChooser=(X=0.3,Y=0.6,Z=0.1)
	GreyWeight=(X=0.7,Y=0.7,Z=0.7)
	Blending=FB_Overwrite
}
