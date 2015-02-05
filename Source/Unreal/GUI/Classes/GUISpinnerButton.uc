// ====================================================================
//  Class:  GUI.UT2SpinnerButton
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
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

class GUISpinnerButton extends GUIGFXButton
        HideCategories(Menu,Object)
	Native;

var(GUISpinnerButton) config  bool	PlusButton "If true this uses a plus graphic, else it uses minus graphic";
var(GUISpinnerButton) config  Material	PlusImage "Image to use for a plus";
var(GUISpinnerButton) config  Material	MinusImage "Image to use for a minus";

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	
	if (PlusButton)
		Graphic = PlusImage;
	else
		Graphic = MinusImage;
}


defaultproperties
{
	StyleName="STY_RoundScaledButton"
	PlusButton=false
	Position=ICP_Scaled
	bNeverFocus=true
	bRepeatClick=true
	bCaptureMouse=true
	PlusImage=Material'gui_tex.menu_plus'
	MinusImage=Material'gui_tex.menu_minus'
}
