// ====================================================================
//  Class:  GUI.GUICircularList
//  Parent: GUI.GUIListBase
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

class GUICircularList extends GUIListBase
        HideCategories(Menu,Object)
	Native;

cpptext
{
	void Draw(UCanvas* Canva);	
}
		
var(GUICircularList) config bool		bCenterInBounds "Center the list in the bounding box";
var(GUICircularList) config bool		bFillBounds "If true, the list will take up the whole bounding box";
var(GUICircularList) config bool		bIgnoreBackClick "If true, will ignore any click on back region";
var(GUICircularList) config bool		bAllowSelectEmpty "If true, allows selection of empty slots";
var(GUICircularList) config int		FixedItemsPerPage "There are a fixed number of items in the list";

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	// Sanity
	
	if (bFillBounds)
		bCenterInBounds=false;

	if (!bAllowSelectEmpty && ItemCount == 0)
		Index = -1;

	OnKeyEvent=InternalOnKeyEvent;
	OnXControllerEvent=InternalOnXControllerEvent;
}	

function float CalculateOffset(float MouseX)
{
	local float x,x1,x2,Width,xMod;
	local int i;

	x1 = ClientBounds[0];
	x2 = ClientBounds[2];

	if ( (MouseX<x1) || (MouseX>x2) )
		return -1.0;
	
	width = x2-x1;
		 
	if ( (bCenterInBounds) && (ItemsPerPage*ItemWidth<Width) )
	{
	
		xMod = (Width - (ItemsPerPage*ItemWidth)) / 2;
		x1+=xMod;
		x2-=xMod;
	
		if ( (MouseX>=x1) && (MouseX<=x2) )
			return (MouseX-x1) / ItemWidth;
		else
			return -1;
	}
	
	if ( (bFillBounds) && (ItemsPerPage*ItemWidth<Width) )
	{
		xMod = (Width - (ItemsPerPage*ItemWidth)) / ItemsPerPage;
		
		i = 0;
		x = x1;
		while (x<=x2)
		{
			if ((MouseX>=x) && (MouseX<=x+ItemWidth) )
				return i;
			
			i++;
			x+= ItemWidth+xmod;
		} 
		
		return -1;
	}
	
	return (MouseX-x1)/ItemWidth;
						
}
		
event Click()
{
	local int NewIndex, Col;

	Super.Click();

	if ( ( !IsInClientBounds() ) || (ItemsPerPage==0) )
		return;
		
	// Get the Col

	Col = CalculateOffset(Controller.MouseX);

	NewIndex = (Top + Col) % ItemCount;
	
	// Keep selected index in range
	if (NewIndex == -1 && bIgnoreBackClick)
		return;
		
	// check if allowed to go out of range
	if ( (!bAllowSelectEmpty)&& ( (NewIndex >= 0) && (NewIndex > ItemCount - 1))) 
		return;

	SetIndex(NewIndex);
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
    	PgDown();
        return true;
    }

    else if (iCode==XC_Y)
    {
    	PgUp();
        return true;
    }

	else if (iCode==XC_Start)
    {
    	OnClick(self);
        return true;
    }
    return false;
}



function WheelUp()
{
	ScrollLeft();
}

function WheelDown()
{
	ScrollRight();
}
	
function ScrollLeft()
{
	local int last;

	if (ItemCount<2)  return;

	Last = Index;
	
	if (Index==0)
		Index=ItemCount-1;
	else
		Index--;
		
	if (Last==Top)
		Top=Index;

	OnChange(self);

}

function ScrollRight()
{
	local int last;
	
	if (ItemCount<2)  return;

	Last = Index;
	
	Index++;
	if (Index==ItemCOunt)
		Index = 0;
		
	if (Last==(Top+ItemsPerPage-1)%ItemCount)
	{
		Top++;
		if (Top==ItemCount)
		  Top=0;
	}
	
	OnChange(self);
}
	
function Home()
{
	if (ItemCount<2)	return;	

	SetIndex(0);
	Top = 0;

	OnChange(self);
	
}

function End()
{
	if (ItemCount<2)	return;	

	Top = ItemCount - ItemsPerPage;
	if (Top<0)
		Top = 0;
		
	SetIndex(ItemCount-1);
}	

function PgUp()
{
	local int moveCount, Last;

	if (ItemCount<2)  return;

	for(moveCount=0; moveCount<ItemsPerPage-1; moveCount++)
	{
		Last = Index;

		if (Index==0)
			Index=ItemCount-1;
		else
			Index--;

		if (Last==Top)
			Top=Index;
	}

	OnChange(self);
}

function PgDown()
{
	local int moveCount, Last;

	if (ItemCount<2)  return;

	for(moveCount=0; moveCount<ItemsPerPage-1; moveCount++)
	{
		Last = Index;

		Index++;
		if (Index==ItemCOunt)
			Index = 0;

		if (Last==(Top+ItemsPerPage-1)%ItemCount)
		{
			Top++;
			if (Top==ItemCount)
				Top=0;
		}
	}

	OnChange(self);
}
		

defaultproperties
{
	bCenterInBounds=true
	bIgnoreBackClick=true
	FixedItemsPerPage=0;
	bAllowSelectEmpty=true
}
