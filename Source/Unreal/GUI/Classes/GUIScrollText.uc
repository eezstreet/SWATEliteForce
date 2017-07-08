/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIScrollText extends GUIList
        HideCategories(Menu,Object)
	native;

cpptext
{
	void PreDraw(UCanvas *Canvas);
	void UpdateComponent(UCanvas* Canvas);
	void Draw(UCanvas* Canvas);	
	void DrawItem(UCanvas* Canvas, INT Item, FLOAT X, FLOAT Y, FLOAT W, FLOAT H);
}

enum eScrollState
{
	STS_None,
	STS_Initial,
	STS_Char,
	STS_EOL,
	STS_Repeat,
};

// Private set of vars
var(GUIScrollText) EditConst protected string	Content;		// This is the content to display in 1 single string
var(GUIScrollText) EditConst string				Separator;		// Separator to use
var(GUIScrollText) EditConst protected int		VisibleLines;	// This is the number of visible lines
var(GUIScrollText) EditConst protected int		VisibleChars;	// How Many chars in the last displayed line are visible
var(GUIScrollText) EditConst protected int		oldWidth;		// Last width of the diplay area
var(GUIScrollText) EditConst protected eScrollState ScrollState;	// What was the last action we did
var(GUIScrollText) EditConst protected bool		bNewContent;	// This is set when new text content has been set for the control
var(GUIScrollText) EditConst protected bool		bStopped;		// Tells when the sequence has stopped animating (can be rushed by clicking ?)
//var protected bool		bForceHideSB;	// Force Hide the scrollbar

var string	NewText;		// New text to add the end of 
var string	ClickedString;	// Filled in (if bSelectText is true) when user clicks on a word

// Public set of vars
var(GUIScrollText) config  int		MaxHistory "Maximum number of rows. Only used in conjunction with NewText. 0 indicates no limit.";
var(GUIScrollText) EditConst bool	bRepeat "Should the sequence be repeated ?";
var(GUIScrollText) EditConst  bool    bNoTeletype "Dont do the teletyping effect at all";
var(GUIScrollText) config  bool	bClickText "Upon clicking on this text box, fill in ClickedString field";
var(GUIScrollText) EditConst   float	InitialDelay "Initial delay after new content was set";
var(GUIScrollText) EditConst   float	CharDelay "This is the delay between each char";
var(GUIScrollText) EditConst   float	EOLDelay "This is the delay to use when reaching end of line";
var(GUIScrollText) EditConst   float	RepeatDelay "This is used after all the text has been displayed and bRepeat is true";

native final function string GetWordUnderCursor();

delegate OnEndOfLine();

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	OnKeyType=InternalOnKeyType;
	OnKeyEvent=InternalOnKeyEvent;

	if(bNoTeletype)
		EndScrolling();
}	
		
function SetContent(string NewContent, optional string sep)
{
    Clear();
    
	if (sep == "")
		Separator = default.Separator;
	else
		Separator = sep;

	Content = NewContent;
//log("[dkaplan] NewContent set: "$NewContent);
	bNewContent = true;

	if(bNoTeletype)
		EndScrolling();
	else
		Restart();
		
	SetDirty();
}

function Stop()
{
	bStopped = true;
	ScrollState = STS_None;
	TimerInterval = 0;
	SetDirty();
}

function Restart()
{
	VisibleLines = 0;
	VisibleChars = 0;
	if (InitialDelay <= 0.0)
	{
		ScrollState = STS_None;
		SetTimer(0.001, true);
	}
	else
	{
		ScrollState = STS_Initial;
		SetTimer(InitialDelay, true);
	}
	bStopped = false;
}

function bool SkipChar()
{
	if (ItemCount > 0 && !bStopped && VisibleLines >= 0 && VisibleLines < ItemCount)
	{
		if (VisibleChars == Len(Elements[VisibleLines].Item))
		{
			if (VisibleLines+1 < ItemCount)
			{
				VisibleLines++;
				VisibleChars = 0;
				TimerInterval = EOLDelay;
				ScrollState = STS_EOL;
				OnEndOfLine();
				return true;
			}
		}
		else
		{
			VisibleChars++;
			TimerInterval = CharDelay;
			ScrollState = STS_Char;
			return true;
		}
	}
	return false;
}

event Timer()
{
    SetDirty();
	if (ItemCount == 0)
	{
		if (!bNewContent)
			TimerInterval=0;
		return;
	}

	if (ScrollState == STS_Repeat)
	{
		Restart();
	}
	else if (ScrollState == STS_EOL)
	{
		if (!SkipChar())
		{
			if (bRepeat)
			{
				if (RepeatDelay > 0)
				{
					TimerInterval = RepeatDelay;
					ScrollState = STS_Repeat;
				}
				else
					Restart();
			}
			else
			{
				bStopped = true;
				ScrollState = STS_None;
				TimerInterval = 0;
			}
		}
	}
	else if (ScrollState == STS_None)
	{
		ScrollState = STS_Initial;
		SetTimer(CharDelay, true);
	}
	else
	{
		if (!SkipChar())
		{
			ScrollState=STS_EOL;
			TimerInterval=EOLDelay;
			OnEndOfLine();
		}
	}
}

event Click()
{
	if(bClickText)
	{
		ClickedString = GetWordUnderCursor();
		return;
	}

	Super.Click();

	EndScrolling();
}

function bool InternalOnKeyType(out byte Key, optional string Unicode)
{
    local bool retval;

	retval = Super.InternalOnKeyType(Key, Unicode);
	if (retval)
		EndScrolling();

	return retval;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    local bool retval;

	retval = Super.InternalOnKeyEvent(Key, State, delta);
	if (retval)
		EndScrolling();

	return retval;
}

function EndScrolling()
{
	bStopped = true;
	if(MyScrollBar != None)
		MyScrollBar.AlignThumb();
	KillTimer();
	SetDirty();
}

defaultproperties
{
	ScrollState=STS_None
	Separator="|"
	TextAlign=TXTA_Left
	InitialDelay=0.0
	CharDelay=0.025
	EOLDelay=0.15
	RepeatDelay=3.0
	VisibleLines=-1
	bNeverSort=true
	MaxHistory=0
}
