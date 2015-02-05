// ====================================================================
//  Class:  GUI.GUIImage
//
//	GUILabel - A text label that get's displayed.  By default, it
//  uses the default font, however you can override it if you wish.
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

class GUILabel extends GUITextComponent
        HideCategories(Menu,Object)
        Native;

defaultproperties
{
	StyleName="STY_DefaultTextStyle"
    bAcceptsInput=false
}