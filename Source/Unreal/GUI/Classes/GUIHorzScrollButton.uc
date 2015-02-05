// ====================================================================
//  Class:  GUI.GUIHorzScrollButton
//  Parent: GUI.GUIGFXButton
//
//  <Enter a description here>
// ====================================================================
/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIHorzScrollButton extends GUIGFXButton
        HideCategories(Menu,Object)
		Native;

var(GUIHorzScrollButton) config  bool	LeftButton "If true, this button will use a left arrow material for its graphic, else a right arrow";
var(GUIHorzScrollButton) config  Material	LeftImage "Image to use for a left arrow";
var(GUIHorzScrollButton) config  Material	RightImage "Image to use for a right arrow";

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	
	if (LeftButton)
		Graphic = LeftImage;
	else
		Graphic = RightImage;
}


defaultproperties
{
	StyleName="STY_RoundScaledButton"
	//StyleName="STY_NoBackground"
	LeftButton=false
	Position=ICP_Scaled
	bNeverFocus=true
	bCaptureMouse=true	
	LeftImage=Material'gui_tex.menu_scroll_left'
	RightImage=Material'gui_tex.menu_scroll_right'
}
