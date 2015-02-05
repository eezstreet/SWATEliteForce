// ====================================================================
//  Class:  GUI.GUISplitter
//
//	GUISplitters allow the user to size two other controls (usually Panels)
//
//  Written by Jack Porter
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

class GUISplitter extends GUIPanel
        HideCategories(Menu,Object)
	native;

cpptext
{
//	void UpdateComponent(UCanvas* Canvas);
		void PreDraw(UCanvas* Canvas);
		void Draw(UCanvas* Canvas);
#if IG_SHARED
		UBOOL MouseMove(FLOAT XDelta, FLOAT YDelta);
#else
		UBOOL MouseMove(INT XDelta, INT YDelta);
#endif
		UBOOL MousePressed(UBOOL IsRepeat);
        UBOOL MouseReleased();
		UBOOL MouseHover();
		void SplitterUpdatePositions();
}

enum EGUISplitterType
{
	SPLIT_Vertical,
	SPLIT_Horizontal,
};

var(GUISplitter) config		EGUISplitterType	SplitOrientation "Orientation for the splitter";
var(GUISplitter) config		float				SplitPosition "0.0 - 1.0";
var(GUISplitter) config		bool				bFixedSplitter "Can splitter be moved?";
var(GUISplitter) config		bool				bDrawSplitter "Draw the actual splitter bar";
var(GUISplitter) config		float				SplitAreaSize "size of splitter thing";
var(GUISplitter) editinline config		string				DefaultPanels[2] "Names of the default panels";
var(GUISplitter) config		float				MaxPercentage "How big can any 1 panel get";
var					GUIComponent		Panels[2];				// Quick Reference

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    if (DefaultPanels[0]!="")
	{
		Panels[0] = AddComponent(DefaultPanels[0]);
		if (DefaultPanels[1]!="")
		    Panels[1] = Addcomponent(DefaultPanels[1]);
    }

	SplitterUpdatePositions();
}

native function SplitterUpdatePositions();

defaultproperties
{
	StyleName="STY_SquareButton"
	SplitOrientation=SPLIT_Vertical
	bCaptureTabs=False
	bNeverFocus=True
	bTabStop=False
	bAcceptsInput=True
	SplitPosition=0.5
	SplitAreaSize=8
	bDrawSplitter=True
	bBoundToParent=True
    bScaleToParent=True
    MaxPercentage=0.0
}