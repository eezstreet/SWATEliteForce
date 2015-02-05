class SwatNewFeaturesMenu extends SwatGUIPage;

var(SWATGui) private EditInline Config GUIButton		MyMainMenuButton;
var(SWATGui) private EditInline Config GUIButton		MyQuitButton;
var(SWATGui) private EditInline Config GUIScrollTextBox	MyNewFeaturesText;

var private SwatNewFeatures NewFeaturesText;

function InitComponent(GUIComponent MyOwner)
{
	local int i;
	local String TextString;

	Super.InitComponent(MyOwner);

	NewFeaturesText = new() class'SwatNewFeatures';

	assert(NewFeaturesText != None);
	assert(NewFeaturesText.NewFeaturesLines.Length != 0);

	for (i = 0; i < NewFeaturesText.NewFeaturesLines.Length; ++i)
	{
		TextString = TextString $ NewFeaturesText.NewFeaturesLines[i] $ "|";
	}

	assert(TextString != "");

	MyNewFeaturesText.SetContent(TextString);
}

function InternalOnShow()
{
	MyMainMenuButton.OnClick=InternalOnClick;
	MyQuitButton.OnClick=InternalOnClick;
}

function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
	    case MyQuitButton:
            Quit(); 
            break;
		case MyMainMenuButton:
            DisplayMainMenu();
            break;
	}
}

defaultproperties
{
	OnShow=InternalOnShow
	StyleName="STY_NewFeaturesMenu"
}