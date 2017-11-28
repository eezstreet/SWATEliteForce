// ====================================================================
//  Class:  GUI.GUIEditBox
//
//	GUIEditBox - The basic text edit control.  I've merged Normal
//  edit, restricted edit, numeric edit and password edit in to 1 control.
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================
/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIEditBox extends GUIButton
        HideCategories(Menu,Object)
		Native;

cpptext
{
		void Draw(UCanvas* Canvas);
}

import enum EInputKey from Engine.Interactions;
import enum EInputAction from Engine.Interactions;

var(GUIEditBox) config	Color		CursorColor "Color to draw the cursor in (alpha disregarded)";
var(GUIEditBox) config Material 	CursorImage "The Material to Render for the cursor";
var(GUIEditBox) config	Color		HighlightColor "Color to draw the highlight in (alpha disregarded)";
var(GUIEditBox) config Material 	HighlightImage "The Material to Render for the highlight";
var(GUIEditBox) config	protected string		TextStr "Holds the current string";
var(GUIEditBox) config 	string		AllowedCharSet "Only Allow these characters";
var(GUIEditBox) config	bool		bMaskText "Displays the text as a string of masked chars";
var(GUIEditBox) config  string      MaskedChar "Char to display instead of the actual chars if bMaskText";
var(GUIEditBox) config	bool		bIntOnly "Only Allow Interger Numeric entry";
var(GUIEditBox) config 	bool		bFloatOnly "Only Allow Float Numeric entry";
var(GUIEditBox) config	bool		bIncludeSign "Do we need to allow a -/+ sign";
var(GUIEditBox) config	bool		bConvertSpaces "Do we want to convert Spaces to _";
var(GUIEditBox) config	int			MaxWidth "Holds the maximum width (in chars) of the string - 0 = No Max";
var(GUIEditBox) config	eTextCase	TextCase "Controls forcing case, etc";
var(GUIEditBox) editinline config	int			BorderOffsets[4] "How far in from the edit is the edit area";
var(GUIEditBox) config	bool		bReadOnly "Can't actually edit this box";

var(GUIEditBox) editconst string		VisibleText "Holds the current visible string";
var(GUIEditBox) editconst  int HighlightStart; //position in the string to begin highlight block
var(GUIEditBox) editconst  int HighlightEnd; //position in the string to end highlight block

var(GUIEditBox) editconst  int 	CaretPos;		// Where is the cursor within the string
var(GUIEditBox) editconst 	int		FirstVis;		// Position of the first visible character;
var(GUIEditBox) editconst  int		LastLength, LastCaret;	// Used to make things quick

var bool bMouseDownTrapped, bMouseUpTrapped;

var byte	LastKey;
var float	DelayTime;

Delegate    OnEntryCompleted(GUIComponent Sender);
Delegate    OnEntryCancelled(GUIComponent Sender);

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    AssertWithDescription( Len(MaskedChar)<=1, "A maximum of one character should be specified for MaskedChar for "$self);

    //all GUIEditBoxes should accept mouse input
    bCaptureMouse=True;

	OnKeyType = InternalOnKeyType;
	OnKeyEvent = InternalOnKeyEvent;

	if ( (bIntOnly) || (bFloatOnly) )
	{
		AllowedCharSet = "0123456789";
		if (bFloatOnly)
			AllowedCharSet=AllowedCharSet$".";

	}

    CaretPos=len(TextStr);
	Change();
    HighlightStart = 0;
}

event Show()
{
    SetVisibleText();

    Super.Show();
}

event DblClick()
{
    Super.DblClick();

    CaretPos=len(TextStr);

    HighlightStart = 0;
    HighlightEnd = CaretPos;
}

event MousePressed()
{
    bMouseDownTrapped = true;
    bMouseUpTrapped = true;
    Super.MousePressed();
}

event MouseReleased()
{
    Super.MouseReleased();
    bMouseUpTrapped = false;
}

event SetText(string NewText, optional bool bForceUpdate)
{
    if( NewText == TextStr && !bForceUpdate )
        return;

	TextStr = NewText;
	if( MaxWidth > 0 )
    	TextStr = Left( TextStr, MaxWidth );

	CaretPos=len(TextStr);

	Change();

    HighlightStart = 0;
}

//accessor for TextStr
function String GetText()
{
    return TextStr;
}

function Change()
{
    HighlightEnd = CaretPos;
    HighlightStart = CaretPos;

    SetVisibleText();

    SetDirty();

    OnChange(self);
}

private function SetVisibleText()
{
    local int i;

    if( bMaskText )
    {
        VisibleText = "";
        for( i = len(TextStr); i > 0; i-- )
        {
            VisibleText = VisibleText $ MaskedChar;
        }
    }
    else
    {
        VisibleText = TextStr;
    }

    SetDirty();
}

function DeleteChar()
{
    //is anything highlighted?
    if( HighlightEnd - HighlightStart > 0 )
    {
        CaretPos = HighlightStart;
        TextStr = left(TextStr,HighlightStart)$Mid(TextStr,HighlightEnd);
        HighlightEnd=CaretPos;
    }
	else if (CaretPos<len(TextStr))
    {
		TextStr = left(TextStr,CaretPos)$Mid(TextStr,CaretPos+1);
	}
}

function bool InternalOnKeyType(out byte Key, optional string Unicode)
{
	local string temp,st, PrevText;
//log("[dkaplan] "$self$"::InternalOnKeyType( Key == "$GetEnum(EInputKey,Key)$", Unicode == "$Unicode );

	if (bReadOnly)
		return false;

    PrevText = TextStr;

	if(Key < 32)
	{
		if( Controller.CtrlPressed &&
			(  key == 3      // ctrl-c, copy to console
			|| key == 24 ) ) // ctrl-x, clear and copy
		{
			PlayerOwner().CopyToClipboard(Mid(TextStr, HighlightStart, HighlightEnd - HighlightStart));
			if( key == 24 && HighlightEnd - HighlightStart > 0 )
			{
				DeleteChar();
				Change();
			}
			return true;
		}

		if( Controller.CtrlPressed &&
			key == 22 ) // ctrl-v, paste at position
		{
			//remove highlighted before typing/ new text
			if( HighlightEnd - HighlightStart > 0 )
				DeleteChar();

			temp = ConvertIllegal( PlayerOwner().PasteFromClipboard() );
			TextStr = left(TextStr,CaretPos) $ temp $ Mid(TextStr,CaretPos);
			if( MaxWidth > 0 )
			    TextStr = Left( TextStr, MaxWidth );
			CaretPos = CaretPos + Len(temp);
			Change();
			return true;
		}

		// anything less than 32 has no unicode representation, unless it is in the ExtendedUnicodeCharSet
		// so we should return now.
		if( InStr( Controller.ExtendedUnicodeCharSet, Unicode ) < 0 )
    		return false;
	}

	//remove highlighted before typing/ new text
	if( HighlightEnd - HighlightStart > 0 )
		DeleteChar();

	if (UniCode!="")
		st = Unicode;
	else
		st = chr(Key);

	if ( (AllowedCharSet=="") || ( (bIncludeSign) && ( (st=="-") || (st=="+") ) && (TextStr=="") ) || (InStr(AllowedCharSet,St)>=0) )
	{

		if ( (MaxWidth==0) || (Len(TextStr)<MaxWidth) )
		{
			if ( (bConvertSpaces) && ((st==" ") || (st=="?") || (st=="\\")) )
				st = "_";

			if ( (TextStr=="") || ( CaretPos==len(TextStr) ) )	// At the end of the string, just add
			{
				TextStr = TextStr$st;
				CaretPos=len(TextStr);
			}
			else
			{
				// We are somewhere inside the string, insert it.

				temp    = left(TextStr,CaretPos)$st$Mid(TextStr,CaretPos);
				TextStr = temp;
				CaretPos++;
			}
		}
	}

    if( PrevText != TextStr )
        Change();

	return true;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
//log("[dkaplan] "$self$"::InternalOnKeyEvent( Key == "$GetEnum(EInputKey,Key)$", State == "$GetEnum(EInputAction,State) );
	if (bReadOnly)
		return false;

	if( (key==EInputKey.IK_Enter) && (State==EInputAction.IST_Press) )	// ENTER Pressed
	{
	    //dont use this button if in edit mode
	    if( !Controller.bDesignMode )
		    OnEntryCompleted(self);
		return true;
	}

	if( (key==EInputKey.IK_Escape) && (State==EInputAction.IST_Press) )	// ESCAPE Pressed
	{
	    //dont use this button if in edit mode
	    if( !Controller.bDesignMode )
		    OnEntryCancelled(self);
		return true;
	}

	if( (Key==EInputKey.IK_Backspace) && (State==EInputAction.IST_Press) ) // Process Backspace
	{
		if (CaretPos>0)
		{
			CaretPos--;
			DeleteChar();
			Change();
		}
		return true;
	}

	if ( (Key==EInputKey.IK_Delete) && (State==EInputAction.IST_Press) ) // Delete key
	{
		DeleteChar();
		Change();
		return true;
	}

	if ( (Key==EInputKey.IK_Left) && (State==EInputAction.IST_Press) )	// Left Arrow
	{
	    if( Controller.CtrlPressed )
	        CaretPos = 0;
        else if ( CaretPos > 0 )
    		CaretPos--;
        else if( Controller.ShiftPressed )
            return true;

        if( Controller.ShiftPressed )
        {
            if( HighlightStart > CaretPos )
                HighlightStart = CaretPos;
            else
                HighlightEnd = CaretPos;
        }
        else
        {
            if( HighlightEnd - HighlightStart > 0 &&
                CaretPos > HighlightStart )
                CaretPos = HighlightStart;

            HighlightEnd = CaretPos;
            HighlightStart = CaretPos;
        }
		return true;
	}

	if ( (Key==EInputKey.IK_Right) && (State==EInputAction.IST_Press) ) // Right Arrow
	{
	    if( Controller.CtrlPressed )
	        CaretPos = Len(TextStr);
        else if ( CaretPos < Len(TextStr) )
    		CaretPos++;
        else if( Controller.ShiftPressed )
            return true;

        if( Controller.ShiftPressed )
        {
            if( HighlightEnd < CaretPos )
                HighlightEnd = CaretPos;
            else
                HighlightStart = CaretPos;
        }
        else
        {
            if( HighlightEnd - HighlightStart > 0 &&
                CaretPos < HighlightEnd )
                CaretPos = HighlightEnd;

            HighlightEnd = CaretPos;
            HighlightStart = CaretPos;
        }
		return true;
	}

	if ( (Key==EInputKey.IK_Home) && (State==EInputAction.IST_Press) ) // Home
	{
		CaretPos=0;
        HighlightStart = CaretPos;
        if( !Controller.ShiftPressed )
            HighlightEnd = CaretPos;
		return true;
	}

	if ( (Key==EInputKey.IK_End) && (State==EInputAction.IST_Press) ) // End
	{
		CaretPos=len(TextStr);
        HighlightEnd = CaretPos;
        if( !Controller.ShiftPressed )
            HighlightStart = CaretPos;
		return true;
	}

	return false;
}

// converts space-characters and chars not in the allowed char array
// ensure string stays within max bounds
function string ConvertIllegal(string inputstr)
{
	local int i, max;
	local string retval;
	local string c;

	i = 0;
	max = Len(inputstr);
	while ( i < max )
	{
		c = Mid(inputstr,i,1);
		if ( AllowedCharSet != "" && InStr(AllowedCharSet,c) < 0 )
		{
			c = "";
		}
		if ( bConvertSpaces &&
			((c == " ") || (c =="?") || (c=="\\") ))
		{
			c = "_";
		}
		retval = retval $ c;
		i++;
	}

	if (MaxWidth > 0)
		return Left(retval,MaxWidth);
	else
		return retval;
}

defaultproperties
{
	bNeverFocus=false
	StyleName="STY_SquareButton"
	MaxWidth=0
	TextCase=TXTC_None
	TextAlign=TXTA_Left
	LastCaret=-1
	LastLength=-1
	WinHeight=0.027344
	bCaptureMouse=True
	OnClickSound=CS_Edit
	MaskedChar="#"
	CursorColor=(R=0,G=0,B=0,A=255)
    CursorImage=Material'gui_tex.white'
	HighlightColor=(R=112,G=112,B=112,A=255)
    HighlightImage=Material'gui_tex.white'
    bFocusWhenReleaseHitTestFails=true
}
