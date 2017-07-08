// ifdef WITH_LIPSinc

//=============================================================================
// Object to facilitate properties editing
//=============================================================================
//  LIPSinc Prefs editor object to expose/shuttle only selected editable 
//  parameters from TLIPSincPrefs objects back and forth in the editor.

class LIPSincPrefsProps extends Core.Object
	hidecategories(Object)
	native;	

cpptext
{
	void PostEditChange();
}

var const int WBrowserLIPSincPtr;

defaultproperties
{	
}

// endif