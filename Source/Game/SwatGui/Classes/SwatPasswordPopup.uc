// ====================================================================
//  Class:  SwatGui.SwatPasswordPopup
//  Parent: SwatGUIPopup
//
//  Popup to grab server join password from connecting client.
// ====================================================================

class SwatPasswordPopup extends SwatGUIPopup
     ;

var(SWATGui) private EditInline Config GUIEditBox  MyPWEditBox;
var(SWATGui) private EditInline Config GUILabel  MyCaption;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyPWEditBox.OnEntryCompleted = InternalOnConfirm;
}

event HandleParameters(string Param1, string Param2, optional int param3)
{
    MyCaption.SetCaption( Param1 );
    ReturnElem.ExtraStrData = Param2;

    MyPWEditBox.SetText("");
}

protected function Confirm()
{
    ReturnElem.item = MyPWEditBox.GetText();
}

defaultproperties
{
    Passback="Password"
}