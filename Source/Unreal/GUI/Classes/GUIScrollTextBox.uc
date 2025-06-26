/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIScrollTextBox extends GUIListBoxBase
        HideCategories(Menu,Object)
	native;

cpptext
{
	void PreDraw(UCanvas* Canvas);
}

var(GUIScrollTextBox) Editinline Editconst   GUIScrollText MyScrollText;
var(GUIScrollTextBox) config  bool			bRepeat "Should the sequence be repeated ?";
var(GUIScrollTextBox) config  bool			bNoTeletype "Dont do the teletyping effect at all";
var(GUIScrollTextBox) config  bool			bStripColors "Strip out IRC-style colour characters (^C)";
var(GUIScrollTextBox) config  float			InitialDelay "Initial delay after new content was set";
var(GUIScrollTextBox) config  float			CharDelay "This is the delay between each char";
var(GUIScrollTextBox) config  float			EOLDelay "This is the delay to use when reaching end of line";
var(GUIScrollTextBox) config  float			RepeatDelay "This is used after all the text has been displayed and bRepeat is true";
var(GUIScrollTextBox) config  eTextAlign		TextAlign "How is text Aligned in the control";

function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

	MyScrollText=GUIScrollText(AddComponent( "GUI.GUIScrollText" , self.Name$"_ScrollText"));
}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    InitBaseList(MyScrollText);

   	MyScrollText.InitialDelay = InitialDelay;
	MyScrollText.CharDelay = CharDelay;
	MyScrollText.EOLDelay = EOLDelay;
	MyScrollText.RepeatDelay = RepeatDelay;
	MyScrollText.TextAlign = TextAlign;
	MyScrollText.bRepeat = bRepeat;
	MyScrollText.bNoTeletype = bNoTeletype;
	MyScrollText.OnADjustTop  = InternalOnAdjustTop;

}

function SetContent(string NewContent, optional string sep)
{
	MyScrollText.SetContent(NewContent, sep);
}

function Restart()
{
	MyScrollText.Restart();
}

function Stop()
{
	MyScrollText.Stop();
}

function InternalOnAdjustTop(GUIComponent Sender)
{
	MyScrollText.EndScrolling();

}

function AddText(string NewText)
{
	local string StrippedText;

	if(NewText == "")
		return;

	if(bStripColors)
		StrippedText = StripColors(NewText);
	else
		StrippedText = NewText;

	if(MyScrollText.NewText == "")
		MyScrollText.NewText = StrippedText;
	else
		MyScrollText.NewText = MyScrollText.NewText$MyScrollText.Separator$StrippedText;
}

defaultproperties
{
	TextAlign=TXTA_Left
	InitialDelay=0.0
	CharDelay=0.025
	EOLDelay=0.15
	RepeatDelay=3.0
	bNoTeletype=true
}
