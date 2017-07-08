class GUIClassicCommandInterfaceContainer extends GUI.GUIScrollTextBox;

var(CCI) config string RedStyleName;
var(CCI) config string BlueStyleName;
var(CCI) config string ElementStyleName;

var(CCI) Editinline GUIStyles RedStyle;
var(CCI) Editinline GUIStyles BlueStyle;
var(CCI) Editinline GUIStyles ElementStyle;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    RedStyle = Controller.GetStyle(RedStyleName);
    BlueStyle = Controller.GetStyle(BlueStyleName);
    ElementStyle = Controller.GetStyle(ElementStyleName);

    assert(RedStyle != None);
    assert(BlueStyle != None);
    assert(ElementStyle != None);
}

simulated function SetCCIStyle(name NewStyle)
{
    switch (NewStyle)
    {
        case 'Red':
            Style = RedStyle;
            break;
        case 'Blue':
            Style = BlueStyle;
            break;
        case 'Element':
            Style = ElementStyle;
            break;
    }
    MyScrollText.Style = Style;
}

defaultproperties
{
    bPersistent=True
}