// ====================================================================
//  Class:  SwatGui.SwatGUIPopup
//  Parent: GUI.GUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatGUIPopup extends GUI.GUIPage
     abstract
	 native;

var(DynamicConfig) EditInline EditConst protected   SwatGUIConfig   GC "Config class for the GUI";

var(SWATGui) protected EditInline Config GUIButton	MyOKButton;
var(SWATGui) protected EditInline Config GUIButton	MyCancelButton;

var(SWATGui) protected editconst String      Passback;       //passback string
var(SWATGui) protected editconst GUIListElem ReturnElem;     //passback element

function InitComponent(GUIComponent MyOwner)
{
	GC = SwatGUIController(Controller).GuiConfig;

	Super.InitComponent(MyOwner);

    if( MyCancelButton != None )
        MyCancelButton.OnClick = InternalOnCancel;
    if( MyOKButton != None )
        MyOKButton.OnClick = InternalOnConfirm;

    OnKeyEvent=InternalOnKeyEvent;
}

protected function InternalOnCancel(GUIComponent Sender)
{
    Cancel();
    Controller.CloseMenu();
}

protected function InternalOnConfirm(GUIComponent Sender)
{
    Confirm();
    Controller.CloseMenu();
    Controller.TopPage().OnPopupReturned( ReturnElem, Passback );
}

protected function Cancel() {}

protected function Confirm() {}

function bool InternalOnKeyEvent( out byte Key, out byte State, float delta )
{
    if( State == EInputAction.IST_Press && KeyMatchesBinding( Key, "GUICloseMenu" ) )
    {
        InternalOnCancel( None );
        return true;
    }
    
    return false;
}

defaultproperties
{
	WinTop=0.3
	WinLeft=0.2
	WinWidth=0.6
	WinHeight=0.4
	bAcceptsInput=true
    StyleName="STY_DialogPanel"
    bDrawStyle=True
    bIsOverlay=True;
}