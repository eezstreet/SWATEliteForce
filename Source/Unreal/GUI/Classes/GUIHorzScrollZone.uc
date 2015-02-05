// ====================================================================
//  Class:  GUI.GUIHorzScrollZone
//  Parent: GUI.GUIComponent
//
//  <Enter a description here>
// ====================================================================

class GUIHorzScrollZone extends GUIComponent
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

	perc = ( Controller.MouseX - ActualLeft() ) / ActualWidth();
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
	bDrawStyle=true
}