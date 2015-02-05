// ====================================================================
//  Class:  GUI.GUIHorzScrollBar
//  Parent: GUI.GUIMultiComponent
//
//  <Enter a description here>
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

class GUIHorzScrollBar extends GUIScrollBarBase
		Native;

cpptext
{
		void PreDraw(UCanvas* Canvas);
	void UpdateComponent(UCanvas* Canvas);
}

var   GUIHorzScrollZone MyScrollZone;
var   GUIHorzScrollButton MyLeftButton;
var   GUIHorzScrollButton MyRightButton;
var   GUIHorzGripButton MyGripButton;

var		float			GripLeft;		// Where in the ScrollZone is the grip	- Set Natively
var		float			GripWidth;		// How big is the grip - Set Natively

function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

	MyScrollZone=GUIHorzScrollZone(AddComponent( "GUI.GUIHorzScrollZone" , self.Name$"_SZone"));
	MyLeftButton=GUIHorzScrollButton(AddComponent( "GUI.GUIHorzScrollButton" , self.Name$"_Left"));
	MyRightButton=GUIHorzScrollButton(AddComponent( "GUI.GUIHorzScrollButton" , self.Name$"_Right"));
	MyGripButton=GUIHorzGripButton(AddComponent( "GUI.GUIHorzGripButton" , self.Name$"_Grip"));
}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	MyLeftButton.LeftButton=true;

	MyRightButton.LeftButton=false;
 
	MyScrollZone.OnScrollZoneClick = ZoneClick;
	MyLeftButton.OnClick = LeftTickClick;
	MyRightButton.OnClick = RightTickClick;
	MyGripButton.OnCapturedMouseMove = GripMouseMove;

    Refocus(MyList);
}

function UpdateGripPosition(float NewPos)
{
	MyList.MakeVisible(NewPos);
	GripLeft = NewPos;
	SetDirty();
}

function bool GripMouseMove(float deltaX, float deltaY)
{
	local float NewPerc,NewLeft;

	if (deltaX==0)	// Don't care about horz movement
		return true;


	deltaX*=-1;

	// Calculate the new Grip Left using the mouse cursor location.

	NewPerc = abs(deltaX) / (MyScrollZone.ActualWidth()-GripWidth);

	if (deltaX<0)
		NewPerc*=-1;

	NewLeft = FClamp(GripLeft+NewPerc,0.0,1.0);

	UpdateGripPosition(NewLeft);

	return true;
}

function ZoneClick(float Delta)
{
	if ( Controller.MouseX < MyGripButton.Bounds[0] )
		MoveGripBy(-MyList.ItemsPerPage);
	else if ( Controller.MouseX > MyGripButton.Bounds[2] )
		MoveGripBy(MyList.ItemsPerPage);

	return;
}

function MoveGripBy(int items)
{
	local int LeftItem;

	LeftItem = MyList.Top + items;
	if (MyList.ItemCount > 0)
	{
		MyList.SetTopItem(LeftItem);
		AlignThumb();
	}
	SetDirty();
}

function LeftTickClick(GUIComponent Sender)
{
	WheelUp();
}

function RightTickClick(GUIComponent Sender)
{
	WheelDown();
}

function WheelUp()
{
	if (!Controller.CtrlPressed)
		MoveGripBy(-1);
	else
		MoveGripBy(-MyList.ItemsPerPage);
}

function WheelDown()
{
	if (!Controller.CtrlPressed)
		MoveGripBy(1);
	else
		MoveGripBy(MyList.ItemsPerPage);
}

function AlignThumb()
{
	local float NewLeft;

	if (MyList.ItemCount==0)
		NewLeft = 0;
	else
	{
		NewLeft = Float(MyList.Top) / Float(MyList.ItemCount-MyList.ItemsPerPage );
		NewLeft = FClamp(NewLeft,0.0,1.0);
	}

	GripLeft = NewLeft;
	SetDirty();
}


// NOTE:  Add graphics for no-man's land about and below the scrollzone, and the Scroll nub.

defaultproperties
{
	bAcceptsInput=true;
	WinWidth=0.0375
}