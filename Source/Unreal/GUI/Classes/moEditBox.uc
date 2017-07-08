// ====================================================================
//  Class:  GUI.moEditBox
//  Parent: GUI.GUIMenuOption
//
//  <Enter a description here>
// ====================================================================

class moEditBox extends GUIMenuOption;

var		GUIEditBox MyEditBox;
var		bool	   bReadOnly;		// This Combobox is read only

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	MyEditBox = GUIEditBox(MyComponent);
	MyEditBox.bReadOnly = bReadOnly;
}

function string GetText()
{
	return MyEditBox.GetText();
}

function SetText(string NewText)
{
	MyEditBox.SetText(NewText);
}

function ReadOnly(bool b)
{
	MyEditBox.bReadOnly = b;
}

function IntOnly(bool b)
{
	MyEditBox.bIntOnly=b;
}

function FloatOnly(bool b)
{
	MyEditBox.bFloatOnly = b;
}

function MaskText(bool b)
{
	MyEditBox.bMaskText = b;
}

defaultproperties
{
	ComponentClassName="GUI.GUIEditBox"
}
