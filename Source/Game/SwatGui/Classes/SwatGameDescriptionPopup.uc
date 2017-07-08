// ====================================================================
//  Class:  SwatGui.SwatGameDescriptionPopup
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatGameDescriptionPopup extends SwatGuiPage
     ;

var(SWATGui) private EditInline Config GUIButton	MyCancelButton;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyCancelButton.OnClick=InternalOnClick;
}

function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyCancelButton:
            Controller.CloseMenu();
            break;
	}
}

defaultproperties
{
}