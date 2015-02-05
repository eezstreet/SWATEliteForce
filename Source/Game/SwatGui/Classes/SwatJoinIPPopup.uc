// ====================================================================
//  Class:  SwatGui.SwatJoinIPPopup
//  Parent: SwatGUIPage
//
//  Menu to connect to a specific server at the given IP address.
// ====================================================================

class SwatJoinIPPopup extends SwatGUIPopup
     ;

var(SWATGui) private EditInline Config GUIEditBox  MyPWEditBox;
var(SWATGui) private EditInline Config GUIEditBox  MyEditBox;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyEditBox.OnEntryCompleted = InternalOnConfirm;
    MyPWEditBox.OnEntryCompleted = InternalOnConfirm;
}

protected function Confirm()
{
    local string password;
    
	ReturnElem.item=MyEditBox.GetText();
	password = MyPWEditBox.GetText();
    if( password != "" )
        ReturnElem.item = ReturnElem.item $ "?Password=" $ password;
}

defaultproperties
{
    Passback="JoinIP"
}