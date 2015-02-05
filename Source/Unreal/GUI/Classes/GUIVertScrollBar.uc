// ====================================================================
//  Class:  GUI.GUIVertScrollBar

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

class GUIVertScrollBar extends GUIScrollBarBase
		Native;

cpptext
{
		void PreDraw(UCanvas* Canvas);
		void UpdateComponent(UCanvas* Canvas);
}

var   GUIVertScrollZone MyScrollZone;
var   GUIVertScrollButton MyUpButton;
var   GUIVertScrollButton MyDownButton;
var   GUIVertGripButton MyGripButton;


var		float			GripTop;		// Where in the ScrollZone is the grip	- Set Natively
var		float			GripHeight;		// How big is the grip - Set Natively

var		float			GrabOffset; // distance from top of button that the user started their drag. Set natively.


function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

    MyScrollZone=GUIVertScrollZone(AddComponent( "GUI.GUIVertScrollZone" , self.Name$"_SZone"));
    MyUpButton=GUIVertScrollButton(AddComponent( "GUI.GUIVertScrollButton" , self.Name$"_Up"));
    MyDownButton=GUIVertScrollButton(AddComponent( "GUI.GUIVertScrollButton" , self.Name$"_Down"));
	MyGripButton=GUIVertGripButton(AddComponent( "GUI.GUIVertGripButton" , self.Name$"_Grip"));
}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	MyUpButton.UpButton=true;

	MyDownButton.UpButton=false;

	MyScrollZone.OnScrollZoneClick = ZoneClick;
	MyUpButton.OnClick = UpTickClick;
	MyDownButton.OnClick = DownTickClick;
	MyGripButton.OnCapturedMouseMove = GripMouseMove;
	MyGripButton.OnMousePressed = GripClick;

    ReFocus(MyList);

}

function UpdateGripPosition(float NewPos)
{
	MyList.MakeVisible(NewPos);
	GripTop = NewPos;
	SetDirty();
}

// Record location you grabbed the grip
function GripClick(GUIComponent Sender)
{
	GrabOffset = Controller.MouseY - MyGripButton.ActualTop();
}

function bool GripMouseMove(float deltaX, float deltaY)
{
	local float NewPerc,NewTop;

	// Calculate the new Grip Top using the mouse cursor location.
	NewPerc = (  Controller.MouseY - (GrabOffset + MyScrollZone.ActualTop()) )  /(MyScrollZone.ActualHeight()-GripHeight);
	NewTop = FClamp(NewPerc,0.0,1.0);

	UpdateGripPosition(Newtop);

	return true;
}

function ZoneClick(float Delta)
{
	if ( Controller.MouseY < MyGripButton.Bounds[1] )
		MoveGripBy(-MyList.ItemsPerPage);
	else if ( Controller.MouseY > MyGripButton.Bounds[3] )
		MoveGripBy(MyList.ItemsPerPage);

	return;
}

function MoveGripBy(int items)
{
	local int TopItem;

	TopItem = MyList.Top + items;
	if (MyList.ItemCount > 0)
	{
		MyList.SetTopItem(TopItem);
		AlignThumb();
	}
	SetDirty();
}

function UpTickClick(GUIComponent Sender)
{
	WheelUp();
}

function DownTickClick(GUIComponent Sender)
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
	local float NewTop;

	if (MyList.ItemCount==0)
		NewTop = 0;
	else
	{
		NewTop = Float(MyList.Top) / Float(MyList.ItemCount-MyList.ItemsPerPage);
		NewTop = FClamp(NewTop,0.0,1.0);
	}

	GripTop = NewTop;
	SetDirty();
}


// NOTE:  Add graphics for no-man's land about and below the scrollzone, and the Scroll nub.
defaultproperties
{
	bAcceptsInput=true;
	WinWidth=0.0375
}