// ====================================================================
//  Class:  SwatGui.SwatSaveCustomPopup
//  Parent: SwatGUIPopup
//
//  Popup to grab server join password from connecting client.
// ====================================================================

class SwatSaveCustomPopup extends SwatGUIPopup
     ;

var(SWATGui) private EditInline Config GUIEditBox  MyEditBox;
var(SWATGui) private localized config string DefaultLoadoutName;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyEditBox.OnEntryCompleted = InternalOnConfirm;
    MyEditBox.OnChange = EntryOnChanged;
	MyEditBox.SetText(DefaultLoadoutName);
}

function EntryOnChanged( GUIComponent Sender )
{
    MyOKButton.SetEnabled( MyEditBox.GetText() != "" );
}

protected function InternalOnConfirm(GUIComponent Sender)
{
    if( MyEditBox.GetText() != "" )
        Super.InternalOnConfirm(Sender);
}

protected function Confirm()
{
	ReturnElem.item = MyEditBox.GetText();
}

defaultproperties
{
    Passback="SaveCustom"
	DefaultLoadoutName="My Loadout"
}