// ifdef WITH_LIPSinc

//=============================================================================
// Object to facilitate properties editing
//=============================================================================
//  LIPSinc Anim editor object to expose/shuttle only selected editable 
//  parameters from TLIPSincAnimation objects back and forth in the editor.

class LIPSincAnimProps extends Core.Object
	hidecategories(Object)
	native;	

cpptext
{
	void PostEditChange();
}

var const int WBrowserLIPSincPtr;

var(Sound) sound	Sound;

var(Properties) bool    bInterruptible;
var(Properties) float   BlendInTime;
var(Properties) float   BlendOutTime;

defaultproperties
{
	bInterruptible = true;	
	BlendInTime    = 160.0;
	BlendOutTime   = 220.0;
}

// endif