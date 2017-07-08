// ====================================================================
//  Class:  GUI.GUIListBox
//
//  The GUIListBoxBase is a wrapper for a GUIList and it's ScrollBar
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

class GUIListBox extends GUIListBoxBase
	native;

var	  GUIList List;	// For Quick Access;

function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

	List=GUIList(AddComponent( "GUI.GUIList" , self.Name$"_List"));
}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    InitBaseList(List);
	List.OnClick=InternalOnClick;
	List.OnClickSound=CS_Click;
	List.OnChange=InternalOnChange;
}

function InternalOnClick(GUIComponent Sender)
{
	Click();
}

function InternalOnChange(GUIComponent Sender)
{
    SetDirty();
	OnChange(Self);
}

function int ItemCount()
{
	return List.ItemCount;
}

defaultproperties
{
}