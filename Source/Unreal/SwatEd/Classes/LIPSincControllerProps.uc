// ifdef WITH_LIPSinc

//=============================================================================
// Object to facilitate properties editing
//=============================================================================
//  LIPSinc Controller editor object to expose/shuttle only selected editable 
//  parameters from TLIPSincController objects back and forth in the editor.

class LIPSincControllerProps extends Core.Object
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