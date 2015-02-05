// ====================================================================
//  Class:  GUI.GUIPanel
//
//  The GUI panel is a visual control that holds components.  All
//  components who are children of the GUIPanel are bound to the panel
//  by default.
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

class GUIPanel extends GUIMultiComponent
        HideCategories(Menu,Object)
	Native;

defaultproperties
{
	bTabStop=False
	WinTop=0.2
	WinLeft=0.2
	WinWidth=0.6
	WinHeight=0.6
	//very high render weight b/c panels should be on top of all other normal components
	RenderWeight=0.95
    PropagateState=false
}