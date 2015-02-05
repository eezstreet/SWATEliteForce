// ====================================================================
//  Class:  GUI.GUIRadioButton
// ====================================================================

class GUIRadioButton extends GUICheckBoxButton
	Native;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    RadioGroup = self;
}

event Click()
{
    Super(GUIComponent).Click();
    SelectRadioButton();
}

function SetRadioGroup( GUIRadioButton group )
{
    SetChecked( self == group );
}

function SelectRadioButton()
{
    if( GUIMultiComponent(MenuOwner) != None )
        GUIMultiComponent(MenuOwner).SetRadioGroup( self );
}

defaultproperties
{
	Graphic=Texture'gui_tex.radio_om'
}