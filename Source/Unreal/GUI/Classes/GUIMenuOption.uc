// ====================================================================
//  Class:  GUI.GUIMultiComponent
//
//	MenuOptions combine a label and any other component in to 1 single
//  control.  The Label is left justified, the control is right.
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

class GUIMenuOption extends GUIMultiComponent
        HideCategories(Menu,Object)
		Native;

cpptext
{
		void PreDraw(UCanvas* Canvas);
	void UpdateComponent(UCanvas* Canvas);
}

var(GUIMenuOption) config string			ComponentClassName "Name of the component to spawn";
var(GUIMenuOption) config localized string	Caption "Caption for the label";
//var(GUIMenuOption) config string			LabelFont "Name of the Font for the label";
//var(GUIMenuOption) config Color			LabelColor "Color for the label";
var(GUIMenuOption) config string			LabelStyle "Name of the GUIStyle for the label";
var(GUIMenuOption) config bool			bHeightFromComponent "Get the Height of this component from the Component";
var(GUIMenuOption) config float			CaptionWidth "How big should the Caption be";
var(GUIMenuOption) config float			ComponentWidth "How big should the Component be (-1 = 1-CaptionWidth)";
var(GUIMenuOption) config bool			bFlipped "Draw the Component to the left of the caption";
var(GUIMenuOption) config eTextAlign		LabelJustification "How do we justify the label";
var(GUIMenuOption) config eTextAlign		ComponentJustification "How do we justify the label";
var(GUIMenuOption) config bool			bSquare "Use the Height for the Width";
var(GUIMenuOption) config bool			bVerticalLayout "Layout controls vertically";

var			GUILabel		MyLabel;				// Holds the label
var			GUIComponent	MyComponent;			// Holds the component


function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

    MyLabel = GUILabel(AddComponent("GUI.GUILabel", self.Name$"_Label"));
    MyComponent = AddComponent(ComponentClassName, self.Name$"_"$ComponentClassName);
}

function InitComponent(GUIComponent MyOwner)
{
	MyLabel.StyleName 	= LabelStyle;

	Super.InitComponent(MyOwner);

	// Create the two components

	if (MyLabel==None)
	{
		log("Failed to create "@self@" due to problems creating GUILabel");
		return;
	}

	if (bFlipped)
	{
		if (LabelJustification==TXTA_Left)
			LabelJustification=TXTA_Right;

		else if (LabelJustification==TXTA_Right)
			LabelJustification=TXTA_Left;

		if (ComponentJustification==TXTA_Left)
			ComponentJustification=TXTA_Right;

		else if (ComponentJustification==TXTA_Right)
   			ComponentJustification=TXTA_Left;
	}

	MyLabel.SetCaption( Caption );
//	MyLabel.TextFont 	= LabelFont;
//	MyLabel.TextColor	= LabelColor;
	MyLabel.TextAlign   = LabelJustification;

	// Check for errors
	if (MyComponent == None)
	{
		log("Could not create requested menu component"@ComponentClassName);
		return;
	}

	if (bHeightFromComponent && !bVerticalLayout)
		WinHeight = MyComponent.WinHeight;

	MyComponent.OnChange = InternalOnChange;
	
    MyComponent.bTabStop = true;
    MyComponent.TabOrder = 1;
}

function InternalOnChange(GUIComponent Sender)
{
	OnChange(self);
}

defaultproperties
{
	bHeightFromComponent=true
	CaptionWidth=0.5
	ComponentWidth=-1
	WinWidth=0.500000
	WinHeight=0.060000
	WinLeft=0.496094
	WinTop=0.347656
//	LabelFont="MenuFont"
//	LabelColor=(R=255,G=255,B=255,A=255)
	bFlipped=false
	LabelJustification=TXTA_Left
	ComponentJustification=TXTA_Right
	bSquare=false
    bTabStop=true
	PropagateVisibility=true

}