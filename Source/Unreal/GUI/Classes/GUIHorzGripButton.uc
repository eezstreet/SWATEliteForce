// ====================================================================
//  Class:  GUI.GUIHorzGripButton
//  Parent: GUI.GUIGFXButton
//
//  <Enter a description here>
// ====================================================================

class GUIHorzGripButton extends GUIGFXButton
		Native;

var(GUIHorzGripButton) config  Material	GripButtonImage "Image to use for a grip button";

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	Graphic = GripButtonImage;
}


defaultproperties
{
	StyleName="STY_RoundButton"
	Position=ICP_Bound
	bNeverFocus=true
	bCaptureMouse=true	
	GripButtonImage=Material'gui_tex.white'
}
