// ====================================================================
//  Class:  GUI.GUIVertScrollZone
//
//  The VertScrollZone is the background zone for a vertical scrollbar.
//  When the user clicks on the zone, it caculates it's percentage.
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================

class GUIVertScrollZone extends GUIComponent
	Native;

cpptext
{
		void Draw(UCanvas* Canvas);
}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

event Click()
{
	local float perc;

	Super.Click();

	if (!IsInBounds())
		return;

	perc = ( Controller.MouseY - ActualTop() ) / ActualHeight();
	OnScrollZoneClick(perc);
}


delegate OnScrollZoneClick(float Delta)		// Should be overridden
{
}

defaultproperties
{
	StyleName="STY_ScrollZone"
	bNeverFocus=true
	bAcceptsInput=true
	bCaptureMouse=true
	bRepeatClick=true
    RenderWeight=0.25
	bDrawStyle=true
}