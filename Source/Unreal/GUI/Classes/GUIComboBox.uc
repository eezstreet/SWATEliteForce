// ====================================================================
//	Class: GUI.GUIComboBox
//
//  A Combination of an EditBox, a Down Arrow Button and a ListBox
//
//  Written by Michel Comeau
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

class GUIComboBox extends GUIMultiComponent
        HideCategories(Menu,Object)
	Native;

cpptext
{
		void PreDraw(UCanvas* Canvas);
		void UpdateComponent(UCanvas* Canvas);
}

var   	GUIEditBox 		Edit;
var   	GUIComboButton 	MyShowListBtn;
var   	GUIListBox 		MyListBox;
var		GUIList			List;


var(GUIComboBox) config int		MaxVisibleItems "Maximum number of lines to display at once";
var(GUIComboBox) config bool		bShowListOnFocus "Show the attached list when this recieves focus";
var(GUIComboBox) config bool		bReadOnly "Is this ComboBox read only";

var		int		Index;
var		string	TextStr;

function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

    MyListBox=GUIListBox(AddComponent( "GUI.GUIListBox", self.Name$"_LBox" ));
    Edit=GUIEditBox(AddComponent( "GUI.GUIEditBox" , self.Name$"_EditBox"));
    MyShowListBtn=GUIComboButton(AddComponent( "GUI.GUIComboButton" ,self.Name$"_ComboB"));
}


function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	Edit.SetText("",true);

    MyShowListBtn.bRepeatClick=false;

	List 			  = MyListBox.List;
	List.bHotTrack	  = true;
	List.OnChange 	  = SubComponentChanged;
	List.OnLostFocus  = SubComponentFocusLost;

	Edit.OnChange 		= SubComponentChanged;
	Edit.OnClick     	= SubComponentClicked;
	Edit.OnLostFocus    = SubComponentFocusLost;
	Edit.bReadOnly  	= bReadOnly;
    if( bReadOnly )
    	Edit.SetFocusInstead(List);

	MyShowListBtn.OnClick = SubComponentClicked;
	MyShowListBtn.SetFocusInstead(List);
}

event Show()
{
	Super.Show();
	MyListBox.Hide();
    SetDirty();
}

event Activate()
{
	Super.Activate();
	MyListBox.DeActivate();
    SetDirty();
}

function SubComponentFocusLost(GUIComponent Sender)
{
log("[dkaplan} SubComponentFocusLost: Sender = " $ Sender $ ", bActive = " $ Sender.bActiveInput $ ", bVisible = " $ Sender.bVisible );
    switch (Sender)
    {
        case Edit:
        case List:
            MyListBox.Hide();
	        MyListBox.DeActivate();
            break;
    }
}


function SubComponentClicked(GUIComponent Sender)
{
    switch (Sender)
    {
        case Edit:
            if( !Edit.bReadOnly )
                break;
        case MyShowListBtn:
	        if (MyListBox.bVisible)
	        {
                InternalCloseList();
	        }
	        else
	        {
                InternalOpenList();
            }
            break;
            }
}

private function InternalOpenList()
{
	MyListBox.Show();
	MyListBox.Activate();
	MyListBox.Focus();
	
	if( GUIMultiComponent(MenuOwner) != None )
	    GUIMultiComponent(MenuOwner).BringToFront( Self );
}

private function InternalCloseList()
{
	MyListBox.Hide();
	MyListBox.DeActivate();
}

function SubComponentChanged(GUIComponent Sender)
{
    switch (Sender)
    {
        case List:
	        Edit.SetText(List.SelectedText(-1),true);
	        Index = List.GetIndex();
            OnListIndexChanged(Sender);
            break;
        case Edit:
	        TextStr = Edit.GetText();
	        OnChange(self);
	        MyListBox.Hide();
	        MyListBox.DeActivate();
            break;
    }
}

delegate OnListIndexChanged(GUIComponent Sender);

function SetText(string NewText)
{
	List.Find(NewText);
	Edit.SetText(NewText,true);
	SetDirty();
}

function string GetText() 
{
	return Edit.GetText();
}

function string Get()
{
	local string temp;

	temp = List.Get();

	if ( temp~=Edit.GetText() )
		return List.Get();
	else
		return "";
}

function object GetObject()
{
	local string temp;

	temp = List.Get();

	if ( temp~=Edit.GetText() )
		return List.GetObject();
	else
		return none;
}

function string GetExtra()
{
	local string temp;

	temp = List.Get();

	if ( temp~=Edit.GetText() )
		return List.GetExtra();
	else
		return "";
}

function int GetInt()
{
	return List.GetExtraIntData();
}

function bool GetBool()
{
	return List.GetExtraBoolData();
}

function SetIndex(int I)
{
	List.SetIndex(i);
	SetDirty();
}

function int GetIndex()
{
	return List.GetIndex();
}

function Clear()
{
    List.Clear();
}

function AddItem(string Item, Optional object Extra, Optional string Str, optional int theInt, optional bool theBool)
{
	List.Add(Item,Extra,Str,theInt,theBool);
}

function RemoveItem(int item, optional int Count)
{
	List.Remove(item, Count);
}

function string GetItem(int index)
{
	List.SetIndex(Index);
	return List.Get();
}

function object GetItemObject(int index)
{
	List.SetIndex(Index);
	return List.GetObject();
}

function string find(string Text, optional bool bExact, optional bool bDontSetIndex)
{
	return List.Find(Text,bExact, bDontSetIndex);
}

function int ItemCount()
{
	return List.ItemCount;
}

function ReadOnly(bool b)
{
	Edit.bReadOnly = b;
}

defaultproperties
{
    //dkaplan- high default render weight so lists aren't hidden
    RenderWeight=0.951
	MaxVisibleItems=8
	WinHeight=0.027344
    StyleName="STY_ComboListBox"
    bReadOnly=True
}