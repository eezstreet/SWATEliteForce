// ====================================================================
//  Class:  GUI.GUIListBase
//
//  Abstract GUIList list box component.   
//
//  Written by Joe Wilcox
//  Made abstract by Jack Porter
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

class GUIListBase extends GUIComponent
        HideCategories(Menu,Object)
		Native
		Abstract;

cpptext
{
	virtual void DrawItem(UCanvas* Canvas, INT Item, FLOAT X, FLOAT Y, FLOAT W, FLOAT H) {}
}
		
var(GUIListBase) config color				SelectedBKColor "Color for a selection background";
var(GUIListBase) config Material			SelectedImage "Image to use when displaying";
var(GUIListBase) EditConst int 	    		Top,Index "Pointers in to the list";
var(GUIListBase) EditConst int				ItemsPerPage "# of items per Page.  Is set natively";
var(GUIListBase) EditConst int				ItemHeight "Size of each row.  Subclass should set in PreDraw.";
var(GUIListBase) EditConst int				ItemWidth "Width of each row.. Subclass should set in PreDraw.";
var(GUIListBase) EditConst int				ItemCount "# of items in this list";
var(GUIListBase) config bool				bHotTrack "Use the Mouse X/Y to always hightlight something";
var(GUIListBase) config bool				bVisibleWhenEmpty "List is still drawn when there are no items in it.";
var(GUIListBase) config bool				bReadOnly "If true, list is unselectable";
var(GUIListBase) config bool				bDeselectable "If true, list is not deselectable";


var		GUIScrollBarBase	MyScrollBar;


// Owner-draw.
delegate OnDrawItem(Canvas Canvas, int Item, float X, float Y, float W, float H, bool bSelected);
delegate OnAdjustTop(GUIComponent Sender);

function InitComponent(GUIComponent Owner)
{
    Super.InitComponent(Owner);
}

function Sort(); // should be implemented in subclass

function int SetIndex(int NewIndex, optional bool bDontPropChange, optional bool bDontReAlign )
{
	if (NewIndex < 0 || NewIndex >= ItemCount)
		Index = -1;
	else
		Index = NewIndex;
		
	if( !bDontReAlign && (index>=0) && (ItemsPerPage>0) )
	{
		if (Index<top)
			Top = Index;
			
		if (ItemsPerPage != 0 && Index>=Top+ItemsPerPage)
			Top = Index-ItemsPerPage+1;

	    if( ItemsPerPage >= ItemCount )
            Top = 0;
    }		
		
	if( MyScrollBar != None )
    	MyScrollBar.AlignThumb();

	if( !bDontPropChange )
    	OnChange(self);
    	
    SetDirty();
	return Index;
}

function int GetIndex()
{
    return Index;
}

function Clear()
{
	Top = 0;
	ItemCount=0;
	SetIndex(-1);
	if( MyScrollBar != None )
    	MyScrollBar.AlignThumb();
}

function MakeVisible(float Perc)
{
	SetTopItem(int((ItemCount-ItemsPerPage) * Perc));
}

function SetTopItem(int Item)
{
	Top = Item;
	if (Top+ItemsPerPage>=ItemCount)
		Top = ItemCount - ItemsPerPage; 	

	if ( Top<0 || ItemsPerPage>=ItemCount )
		Top=0;
		
	SetDirty();
	OnAdjustTop(Self);		
}

defaultproperties
{
	bAcceptsInput=true
	StyleName="STY_ListBox"
    SelectedBKColor=(B=255,G=255,R=255,A=255)
    SelectedImage=Texture'gui_tex.White'
	Top=0
	Index=0	
	ItemsPerPage=0
	bTabStop=true	
	bVisibleWhenEmpty=false
	bCaptureMouse=true	
}
