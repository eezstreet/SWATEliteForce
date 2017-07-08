// ====================================================================
//  Class:  GUI.GUIVertScrollButton
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

class GUIVertScrollButton extends GUIGFXButton
        HideCategories(Menu,Object)
		Native;

var(GUIVertScrollButton) config	bool	UpButton "If true, the graphic used is an up arrow (else a down arrow)";
var(GUIVertScrollButton) config  Material	UpImage "Image to use for a up arrow";
var(GUIVertScrollButton) config  Material	DownImage "Image to use for a down arrow";

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	if (UpButton)
		Graphic = UpImage;
	else
		Graphic = DownImage;
}


defaultproperties
{
	StyleName="STY_RoundScaledButton"
	UpButton=false
	Position=ICP_Scaled
	bNeverFocus=true
    bCaptureMouse=True
	UpImage=Material'gui_tex.menu_scroll_up'
	DownImage=Material'gui_tex.menu_scroll_down'
}