// ====================================================================
//  Class:  GUI.GUIHorzList
//  Parent: GUI.GUIListBase
//
//  <Enter a description here>
// ====================================================================

class GUIHorzList extends GUIListBase
		Native;

cpptext
{
	void Draw(UCanvas* Canvas);	
}
		
function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	OnKeyType=InternalOnKeyType;
	OnKeyEvent=InternalOnKeyEvent;
	OnXControllerEvent=InternalOnXControllerEvent;
}	
		
event Click()
{
	local int NewIndex, Col;

	Super.Click();

	if ( bReadOnly || ( !IsInClientBounds() ) || (ItemsPerPage==0) )
		return;
		
	// Get the Col
	
	Col = Controller.MouseX - ClientBounds[0];
	NewIndex = Top + (Col / ItemWidth);
	
	if (NewIndex >= ItemCount)
		return;
		
	SetIndex(NewIndex);
}

function bool InternalOnKeyType(out byte Key, optional string Unicode)
{
	// Add code to jump to next line with Char	
		
	return true;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{

	if (ItemsPerPage==0) return false;

	
	if ( (Key==0x25 || Key==0x64) && (State==1) )	// Left Arrow
	{
		ScrollLeft();
		return true;
	}
	
	if ( (Key==0x27 || Key==0x66) && (State==1) ) // Left Arrow
	{
		ScrollRight();
		return true;
	}
	
	if ( (Key==0x24 || Key==0x67) && (State==1) ) // Home
	{
		Home();
		return true;
	}
	
	if ( (Key==0x23 || Key==0x61) && (State==1) ) // End
	{
		End();
		return true;
	}
	
	if ( (Key==0x21 || Key==0x69) && (State==1) ) // PgUp
	{
		PgUp();
		return true;
	}
	
	if ( (Key==0x22 || Key==0x63) && (State==1) ) // PgDn
	{
		PgDn();
		return true;
	}
	
	if ( (key==0xEC) && (State==3) )
	{
	
		WheelUp();
		return true;
	}
	
	if ( (key==0xED) && (State==3) )
	{
	
		WheelDown();
		return true;
	}
	
	
	return false;
}


function WheelUp()
{
	if (MyScrollBar!=None)
		GUIHorzScrollBar(MyScrollBar).WheelUp();
	else
	{
		if (!Controller.CtrlPressed)
			ScrollLeft();
		else
			PgUp();
	}
}

function bool InternalOnXControllerEvent(byte Id, eXControllerCodes iCode)
{

	if (ItemsPerPage==0) return false;

	if (iCode==XC_Left || iCode==XC_PadLeft)
    {
    	ScrollLeft();
        return true;
    }
    else if (iCode==XC_Right || iCode==XC_PadRight)
    {
    	ScrollRight();
        return true;
    }

    else if (iCode==XC_Black)
    {
    	Home();
        return true;
    }

    else if (iCode==XC_White)
    {
    	End();
        return true;
    }

    else if (iCode==XC_X)
    {
    	PgDn();
        return true;
    }

    else if (iCode==XC_Y)
    {
    	PgUp();
        return true;
    }

	else if (iCode==XC_Start)
    {
    	Click();
        return true;
    }
    return false;
}


function WheelDown()
{
	if (MyScrollBar!=None)
		GUIHorzScrollBar(MyScrollBar).WheelDown();
	else
	{
		if (!Controller.CtrlPressed)
			ScrollRight();
		else
			PgDn();
	}
}
	
function ScrollLeft()
{
	if ( (ItemCount<2) || (Index==0) ) return;

	Index = max(0,Index-1);

	if ( (Index<Top) || (Index>Top+ItemsPerPage) )
	{
		Top = Index;
		MyScrollBar.AlignThumb();
	}
}

function ScrollRight()
{
	if ( (ItemCount<2) || (Index==ItemCount-1) )	return;
	
	Index = min(Index+1,ItemCount-1);
	if (Index<Top)
	{
		Top = Index;
		MyScrollBar.AlignThumb();
	}
	else if (Index>=Top+ItemsPerPage)
	{
		Top = Index-ItemsPerPage+1;
		MyScrollBar.AlignThumb();
	}
	
}
	
function Home()
{
	if (ItemCount<2)	return;	

	SetIndex(0);
	Top = 0;
	MyScrollBar.AlignThumb();
	
}

function End()
{
	if (ItemCount<2)	return;	

	Top = ItemCount - ItemsPerPage;
	if (Top<0)
		Top = 0;
		
	SetIndex(ItemCount-1);
	MyScrollBar.AlignThumb();
}	

function PgUp()
{

	if (ItemCount<2)	return;

	Index -= ItemsPerPage;

	// Adjust to bounds
	if (Index < 0)
		Index = 0;

	// If new index 
	if (Top + ItemsPerPage <= Index)		// If index is forward but not visible, jump to it
		Top = Index;
	else if (Index + ItemsPerPage < Top)	// Item is way too far
		Top = Index;
	else if (Index < Top)	// Item is 1 page or less away
		SetTopItem(Top - ItemsPerPage);

	SetIndex(Index);
	MyScrollBar.AlignThumb();
}

function PgDn()
{

	if (ItemCount<2)	return;

	// Select item 1 page away from current selection
	Index += ItemsPerPage;

	// Adjust to bounds
	if (Index >= ItemCount)
		Index = ItemCount-1;

	
	if (Index < Top)  // If item is still before Top Item, go to it
		Top = Index;
	else if (Index - Top - ItemsPerPage >= ItemsPerPage)	// Too far away
		SetTopItem(Index);
	else if (Index - Top >= ItemsPerPage) // Just 1 page away
		SetTopItem(Top + ItemsPerPage);

	SetIndex(Index);
	MyScrollBar.AlignThumb();
}	

		

defaultproperties
{
}
