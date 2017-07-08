// ====================================================================
//  Class:  GUI.GUIMoComboBox
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================

class moComboBox extends GUIMenuOption;

var		GUIComboBox MyComboBox;
var		bool		bReadOnly;		// This Combobox is read only

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	MyComboBox = GUIComboBox(MyComponent);

	ReadOnly(bReadOnly);

}


function int ItemCount()
{
	return MyComboBox.ItemCount();
}

function SetIndex(int I)
{
	MyComboBox.SetIndex(i);
}

function int GetIndex()
{
	return MyComboBox.GetIndex();
}


function string Find(string Test, bool bExact)
{
	return MyComboBox.Find(Test,bExact);
}

function AddItem(string Item, optional object Extra, optional string Str)
{
	MyComboBox.AddItem(Item,Extra,str);
}

function RemoveItem(int item, optional int Count)
{
	MyComboBox.RemoveItem(item, Count);
}

function string GetItem(int index)
{
	return MyComboBox.GetItem(index);
}

function object GetItemObject(int index)
{
	return MyComboBox.GetItemObject(index);
}

function string GetText()
{
	local string aaa;
	aaa = MyComboBox.Get();
	return aaa;
}

function object GetObject()
{
	return MyComboBox.GetObject();
}

function string GetExtra()
{
	return MyComboBox.GetExtra();
}


function SetText(string NewText)
{
	MyComboBox.SetText(NewText);
}

function ReadOnly(bool b)
{
	MyComboBox.ReadOnly(b);
}

defaultproperties
{
	ComponentClassName="GUI.GUIComboBox"
}