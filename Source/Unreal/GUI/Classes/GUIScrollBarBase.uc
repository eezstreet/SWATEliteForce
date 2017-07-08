// ====================================================================
//  Class:  GUI.GUIScrollBarBase
//  Parent: GUI.GUIMultiComponent
//
//  <Enter a description here>
// ====================================================================

class GUIScrollBarBase extends GUIMultiComponent
		Native;

var		GUIListBase		MyList;			// The list this Scrollbar is attached to

function UpdateGripPosition(float NewPos);
function MoveGripBy(int items);
event AlignThumb();

function Refocus(GUIComponent Who)
{
	local int i;
	
	if (Who != None && Controls.Length > 0)
		for (i=0;i<Controls.Length;i++)
	    {
	    	Controls[i].SetFocusInstead(Who);
	        Controls[i].bNeverFocus=true;
	    }
}

defaultproperties
{
	bTabStop=false
	PropagateVisibility=true

}