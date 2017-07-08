// ====================================================================
//  Class:  GUI.moNumericEdit
//  Parent: GUI.GUIMenuOption
//
//  <Enter a description here>
// ====================================================================

class moNumericEdit extends GUIMenuOption;

var		GUINumericEdit	MyNumericEdit;
var		int				MinValue, MaxValue;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	MyNumericEdit = GUINumericEdit(MyComponent);
	MyNumericEdit.MinValue = MinValue;
	MyNumericEdit.MaxValue = MaxValue;
	MyNumericEdit.CalcMaxLen();
	MyNumericEdit.OnChange = InternalOnChange;
}

function SetValue(int V)
{
	MyNumericEdit.SetValue(v);
}

function int GetValue()
{
	return MyNumericEdit.Value;
}

function InternalOnChange(GUIComponent Sender)
{
	OnChange(self);
}


defaultproperties
{
	ComponentClassName="GUI.GUINumericEdit"
	OnClickSound=CS_Click
}