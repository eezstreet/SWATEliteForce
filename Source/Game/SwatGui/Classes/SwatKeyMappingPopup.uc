// ====================================================================
//  Class:  SwatGui.SwatKeyMappingPopup
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatKeyMappingPopup extends SwatGuiPage
     ;

import enum EInputKey from Engine.Interactions;

var(SWATGui) private EditInline Config GUILabel    MyTitleLabel;
var(SWATGui) private EditInline Config GUIButton	MyCancelButton;
var String      Passback;       //passback string
var int         PassbackInt;
var GUIListElem theElem;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
    MyCancelButton.OnClick=InternalOnClick;
}

function InternalOnActivate()
{
//log("[dkaplan]: in internalOnActivate()");
    theElem = CreateElement("");
    Controller.OnNeedRawKeyPress=InternalOnRawKeyPress;
}

function InternalOnDeActivate()
{
//log("[dkaplan]: in internalOnDeActivate(), ParentPage = "$ParentPage);
    Controller.OnNeedRawKeyPress=None; //dkaplan: doesn't seem to unset the delegate, why?
    Controller.ParentPage().OnPopupReturned( theElem, Passback );
}

event HandleParameters(string Param1, string Param2, optional int param3)
{
    MyTitleLabel.SetCaption( Param1 );
    Passback = Param2;
    PassbackInt = param3;
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

function bool InternalOnRawKeyPress(byte NewKey)
{
    local string iKey;
    if( !bActiveInput )
        return false;
        
    if( NewKey == EInputKey.IK_LeftMouse && MyCancelButton.IsInBounds() )
    {
        Controller.CloseMenu();
        return true;
    }
    
    iKey = PlayerOwner().ConsoleCommand("KEYNAME"@NewKey);
//log( "[dkaplan] key pressed (and returned via InternalOnRawKeyPress): NewKey="$NewKey$", iKey="$iKey);
    theElem = CreateElement(Passback,,iKey,PassbackInt);

    Controller.CloseMenu();
	return true;
}

protected function bool HandleKeyEvent( out byte Key, out byte State, float delta )
{
    return false;
}


defaultproperties
{
    OnActivate=InternalOnActivate
    OnDeActivate=InternalOnDeActivate
}