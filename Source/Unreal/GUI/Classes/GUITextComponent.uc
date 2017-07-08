// ====================================================================
//  Class:  GUI.GUITextComponent
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

class GUITextComponent extends GUIComponent
    HideCategories(Menu,Object)
    Abstract
	Native;

cpptext
{
		void Draw(UCanvas* Canvas);
}

//this should be protected, but there is a bug in the compiler where subclasses can't access protected vars of the superclass
var(GUITextComponent) config localized string	Caption "The text to display";
var(GUITextComponent) config           eTextAlign		TextAlign "How is the text aligned in it's bounding box";
//this should be protected, but there is a bug in the compiler where subclasses can't access protected vars of the superclass

var(GUITextComponent) config		bool				bMultiLine "Will cut content to display on multiple lines when too long";
var(GUITextComponent) config		bool				bDontCenterVertically "If true, the text will be flushed to the top; when false, it will be centered vertically in the label";

function InitComponent(GUIComponent Owner)
{
    Super.InitComponent(Owner);
}

event SetCaption( string newCaption )
{
    Caption = newCaption;
	SetDirty();
}

function string GetCaption()
{
    return Caption;
}

defaultproperties
{
	TextAlign=TXTA_Left
    RenderWeight=0.8
}
