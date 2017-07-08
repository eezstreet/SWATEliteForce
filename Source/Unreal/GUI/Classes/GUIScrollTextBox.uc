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

function bool IsNumber(string Num)
{
	if( Num == Chr(48) ) return true; // character '0' etc..
	if( Num == Chr(49) ) return true;
	if( Num == Chr(50) ) return true;
	if( Num == Chr(51) ) return true;
	if( Num == Chr(52) ) return true;
	if( Num == Chr(53) ) return true;
	if( Num == Chr(54) ) return true;
	if( Num == Chr(55) ) return true;
	if( Num == Chr(56) ) return true;
	if( Num == Chr(57) ) return true;

	return false;
}

function string StripColors(string MyString)
{
	local int EscapePos, RemCount, LenFromEscape;

	EscapePos = InStr(MyString, Chr(3)); // Chr(3) == ^C
	while(EscapePos != -1)
	{
		LenFromEscape = Len(MyString) - (EscapePos + 1); // how far after the escape character the string goes on for

		// Now we have to work out how many characters follow the ^C and should be removed. This is rather unpleasant..!

		RemCount = 1; // strip the ctrl-C regardless
		if( LenFromEscape >= 1 && IsNumber(Mid(MyString, EscapePos+1, 1)) ) // If a digit follows the ctrl-C, strip that
		{
			RemCount = 2; // #
			if( LenFromEscape >= 3 && Mid(MyString, EscapePos+2, 1) == Chr(44) && IsNumber(Mid(MyString, EscapePos+3, 1)) ) // If we have a comma and another digit, strip those
			{
				RemCount = 4; // #,#
				if( LenFromEscape >= 4 && IsNumber(Mid(MyString, EscapePos+4, 1)) ) // if there is another digit after that, strip it
					RemCount = 5; // #,##
			}
			else if( LenFromEscape >= 2 && IsNumber(Mid(MyString, EscapePos+2, 1)) )// if there is a second digit, strip that
			{
				RemCount = 3; // ##
				if( LenFromEscape >= 4 && Mid(MyString, EscapePos+3, 1) == Chr(44) && IsNumber(Mid(MyString, EscapePos+4, 1)) ) // If we have a comma and another digit, strip those
				{
					RemCount = 5; // ##,#
					if( LenFromEscape >= 5 && IsNumber(Mid(MyString, EscapePos+5, 1)) ) // if there is another digit after that, strip it
						RemCount = 6; // ##,##
				}
			}
		}

		MyString = Left(MyString, EscapePos)$Mid(MyString, EscapePos+RemCount);

		EscapePos = InStr(MyString, Chr(3));
	}

	return MyString;
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