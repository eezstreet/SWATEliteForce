// ====================================================================
//  Class:  GUI.GUIListBoxBase
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

class GUIListBoxBase extends GUIMultiComponent
		Native;
 
cpptext
{
	void PreDraw(UCanvas* Canvas);
	void Draw(UCanvas* Canvas);								// Handle drawing of the component natively
	void UpdateComponent(UCanvas* Canvas);
}

var(GUIListBoxBase) editinline editconst GUIVertScrollBar	MyScrollBar;
var(GUIListBoxBase) editinline editconst GUIListBase		MyActiveList;
var(GUIListBoxBase) config	bool	bVisibleWhenEmpty "List box is visible when empty.";
var(GUIListBoxBase) config	bool	bReadOnly "List box is Unselectable.";
var(GUIListBoxBase) config	bool	bPropagateStyle "If true, the style is propagated to the lists.";

function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

    MyScrollBar=GUIVertScrollBar(AddComponent( "GUI.GUIVertScrollBar" , self.Name$"_SBar"));
}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyScrollBar.WinLeft = -1.0;
    MyScrollBar.WinTop = -1.0;
    MyScrollBar.WinWidth = 0.0;
    MyScrollBar.WinHeight = 0.0;
	MyScrollBar.bVisible=false;
	MyScrollBar.bActiveInput=bActiveInput;
}

function InitBaseList(GUIListBase LocalList)
{
    if( bPropagateStyle )
    {
        LocalList.StyleName = StyleName;
        LocalList.Style = Style;
    }
    
	LocalList.bVisibleWhenEmpty = bVisibleWhenEmpty;
	LocalList.bAllowHTMLTextFormatting = bAllowHTMLTextFormatting;
	LocalList.MyScrollBar = MyScrollBar;
	
	LocalList.bReadOnly = bReadOnly;
	
	SetVisibility(bVisible);
	SetActive(bActiveInput);
	
	SetActiveList( LocalList );
}

function SetActiveList( GUIListBase LocalList )
{
	local int i;

    MyActiveList = LocalList;
	MyScrollBar.MyList = LocalList;

    for (i=0;i<MyScrollBar.Controls.Length;i++)
	{
	    if( MyScrollBar.Controls[i].FocusInstead != LocalList );
    		MyScrollBar.Controls[i].SetFocusInstead(LocalList);
    }
    
	if( MyScrollBar.FocusInstead != LocalList );
        MyScrollBar.SetFocusInstead(LocalList);
	
	SetDirty();
}

event Show()
{
    Super.Show();
    MyScrollBar.Hide();
}

function bool IsEmpty()
{
    return MyActiveList.ItemCount == 0;
}

function int Num()
{
    return MyActiveList.ItemCount;
}

function Clear()
{
    MyActiveList.Clear();
}

function int GetIndex()
{
    return MyActiveList.GetIndex();
}

function int SetIndex(int newIndex)
{
    return MyActiveList.SetIndex(newIndex);
}

defaultproperties
{
	StyleName="STY_ListBox"
	bVisibleWhenEmpty=True
	bDrawStyle=True
	bPropagateStyle=True
}