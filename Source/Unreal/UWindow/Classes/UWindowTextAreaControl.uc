class UWindowTextAreaControl extends UWindowDialogControl;

var string TextArea[750];
var string Prompt;
var int Font;
var Font AbsoluteFont;
var int BufSize;
var int Head, Tail, Lines, VisibleRows;

var bool bCursor;
var bool bScrollable;
var bool bShowCaret;
var bool bScrollOnResize;

var UWindowVScrollBar VertSB;
var float LastDrawTime;

function Created()
{
	Super.Created();
	LastDrawTime = GetLevel().TimeSeconds;
}

function SetScrollable(bool newScrollable)
{
	bScrollable = newScrollable;
	if(newScrollable)
	{
		VertSB = UWindowVScrollbar(CreateWindow(class'UWindowVScrollbar', WinWidth-12, 0, 12, WinHeight));
		VertSB.bAlwaysOnTop = True;
	}
	else
	{
		if (VertSB != None)
		{
			VertSB.Close();
			VertSB = None;
		}
	}
}

function BeforePaint( Canvas C, float X, float Y )
{
	Super.BeforePaint(C, X, Y);

	if(VertSB != None)
	{
		VertSB.WinTop = 0;
		VertSB.WinHeight = WinHeight;
		VertSB.WinWidth = LookAndFeel.Size_ScrollbarWidth;
		VertSB.WinLeft = WinWidth - LookAndFeel.Size_ScrollbarWidth;
	}
}

function SetAbsoluteFont(Font F)
{
	AbsoluteFont = F;
}

function Paint( Canvas C, float X, float Y )
{
	local int i, Line;
	local int TempHead, TempTail;
	local float XL, YL;
	local float W, H;

	if(AbsoluteFont != None)
		C.Font = AbsoluteFont;
	else
		C.Font = Root.Fonts[Font];

	C.SetDrawColor(255,255,255);

	TextSize(C, "TEST", XL, YL);
	VisibleRows = WinHeight / YL;

	TempHead = Head;
	TempTail = Tail;
	Line = TempHead;
	TextArea[Line] = Prompt;

	if(Prompt == "")
	{
		Line--;
		if(Line < 0)
			Line += BufSize;
	}

	if(bScrollable)
	{
		if (VertSB.MaxPos - VertSB.Pos >= 0)
		{
			Line -= VertSB.MaxPos - VertSB.Pos;
			TempTail -= VertSB.MaxPos - VertSB.Pos;

			if(Line < 0)
				Line += BufSize;
			if(TempTail < 0)
				TempTail += BufSize;
		}
	}

	if(!bCursor)
	{
		bShowCaret = False;
	}
	else
	{
		if((GetLevel().TimeSeconds > LastDrawTime + 0.3) || (GetLevel().TimeSeconds < LastDrawTime))
		{
			LastDrawTime = GetLevel().TimeSeconds;
			bShowCaret = !bShowCaret;
		}
	}

	for(i=0; i<VisibleRows+1; i++)
	{
		ClipText(C, 2, WinHeight-YL*(i+1), TextArea[Line]);
		if(Line == Head && bShowCaret)
		{
			// Draw cursor..
			TextSize(C, TextArea[Line], W, H);
			ClipText(C, W, WinHeight-YL*(i+1), "|");
		}

		if(TempTail == Line)
			break;

		Line--;
		if(Line < 0)
			Line += BufSize;
	}
}

function AddText(string NewLine)
{
	TextArea[Head] = NewLine;
	Head = (Head + 1)%BufSize;

	if(Head == Tail)
		Tail = (Tail + 1)%BufSize;

	// Calculate lines for scrollbar.
	Lines = Head - Tail;
	if(Lines < 0)
		Lines += BufSize;

	if(bScrollable)
	{
		VertSB.SetRange(0, Lines, VisibleRows);
		VertSB.Pos = VertSB.MaxPos;
	}
}

function Resized()
{
	if(bScrollable)
	{
		VertSB.SetRange(0, Lines, VisibleRows);
		if(bScrollOnResize)
			VertSB.Pos = VertSB.MaxPos;
	}
}

function SetPrompt(string NewPrompt)
{
	Prompt = NewPrompt;
}

function Clear()
{
	TextArea[0] = "";
	Head = 0;
	Tail = 0;
}

defaultproperties
{
	BufSize=750
	bScrollOnResize=True
}