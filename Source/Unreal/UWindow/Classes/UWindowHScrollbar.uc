//=============================================================================
// UWindowHScrollBar - A horizontal scrollbar
//=============================================================================
class UWindowHScrollBar extends UWindowWindow;

var UWindowSBLeftButton		LeftButton;
var UWindowSBRightButton	RightButton;
var bool					bDisabled;
var float					MinPos;
var float					MaxPos;
var float					MaxVisible;
var float					Pos;				// offset to WinTop
var float					ThumbStart, ThumbWidth;
var float					NextClickTime;
var float					DragX;
var bool					bDragging;
var float					ScrollAmount;

function Show(float P)
{
	if(P < 0) return;
	if(P > MaxPos + MaxVisible) return;

	while(P < Pos) 
		if(!Scroll(-1))
			break;
	while(P - Pos > MaxVisible - 1)
		if(!Scroll(1))
			break;
}

function bool Scroll(float Delta) 
{
	local float OldPos;
	
	OldPos = Pos;
	Pos = Pos + Delta;
	CheckRange();
	return Pos == OldPos + Delta;
}

function SetRange(float NewMinPos, float NewMaxPos, float NewMaxVisible, optional float NewScrollAmount)
{
	if(NewScrollAmount == 0)
		NewScrollAmount = 1;

	ScrollAmount = NewScrollAmount;
	MinPos = NewMinPos;
	MaxPos = NewMaxPos - NewMaxVisible;
	MaxVisible = NewMaxVisible;

	CheckRange();
}

function CheckRange() 
{
	if(Pos < MinPos)
	{
		Pos = MinPos;
	}
	else
	{
		if(Pos > MaxPos) Pos = MaxPos;
	}

	bDisabled = (MaxPos <= MinPos);
	LeftButton.bDisabled = bDisabled;
	RightButton.bDisabled = bDisabled;

	if(bDisabled)
	{
		Pos = 0;
	}
	else
	{
		ThumbStart = ((Pos - MinPos) * (WinWidth - (2*LookAndFeel.Size_ScrollbarButtonHeight))) / (MaxPos + MaxVisible - MinPos);
		ThumbWidth = (MaxVisible * (WinWidth - (2*LookAndFeel.Size_ScrollbarButtonHeight))) / (MaxPos + MaxVisible - MinPos);

		if(ThumbWidth < LookAndFeel.Size_MinScrollbarHeight) 
			ThumbWidth = LookAndFeel.Size_MinScrollbarHeight;
		
		if(ThumbWidth + ThumbStart > WinWidth - 2*LookAndFeel.Size_ScrollbarButtonHeight)
		{
			ThumbStart = WinWidth - 2*LookAndFeel.Size_ScrollbarButtonHeight - ThumbWidth;
		}

		ThumbStart = ThumbStart + LookAndFeel.Size_ScrollbarButtonHeight;
	}
}

function Created() 
{
	Super.Created();
	LeftButton = UWindowSBLeftButton(CreateWindow(class'UWindowSBLeftButton', 0, 0, 10, 12));
	RightButton = UWindowSBRightButton(CreateWindow(class'UWindowSBRightButton', WinWidth-10, 0, 10, 12));
}


function BeforePaint(Canvas C, float X, float Y)
{
	LeftButton.WinTop = 0;
	LeftButton.WinLeft = 0;
	LeftButton.WinWidth = LookAndFeel.Size_ScrollbarButtonHeight;
	LeftButton.WinHeight = LookAndFeel.Size_ScrollbarWidth;

	RightButton.WinTop = 0;
	RightButton.WinLeft = WinWidth - LookAndFeel.Size_ScrollbarButtonHeight;
	RightButton.WinWidth = LookAndFeel.Size_ScrollbarButtonHeight;
	RightButton.WinHeight = LookAndFeel.Size_ScrollbarWidth;

	CheckRange();
}

function Paint(Canvas C, float X, float Y) 
{
	LookAndFeel.SB_HDraw(Self, C);
}

function LMouseDown(float X, float Y)
{
	Super.LMouseDown(X, Y);

	if(bDisabled) return;

	if(X < ThumbStart)
	{
		Scroll(-(MaxVisible-1));
		NextClickTime = GetLevel().TimeSeconds + 0.5;
		return;
	}
	if(X > ThumbStart + ThumbWidth)
	{
		Scroll(MaxVisible-1);
		NextClickTime = GetLevel().TimeSeconds + 0.5;
		return;
	}

	if((X >= ThumbStart) && (X <= ThumbStart + ThumbWidth))
	{
		DragX = X - ThumbStart;
		bDragging = True;
		Root.CaptureMouse();
		return;
	}
}


function Tick(float Delta) 
{
	local bool bLeft, bRight;
	local float X, Y;

	if(bDragging) return;

	bLeft = False;
	bRight = False;

	if(bMouseDown)
	{
		GetMouseXY(X, Y);
		bLeft = (X < ThumbStart);
		bRight = (X > ThumbStart + ThumbWidth);
	}
	
	if(bMouseDown && (NextClickTime > 0) && (NextClickTime < GetLevel().TimeSeconds)  && bLeft)
	{
		Scroll(-(MaxVisible-1));
		NextClickTime = GetLevel().TimeSeconds + 0.1;
	}

	if(bMouseDown && (NextClickTime > 0) && (NextClickTime < GetLevel().TimeSeconds)  && bRight)
	{
		Scroll(MaxVisible-1);
		NextClickTime = GetLevel().TimeSeconds + 0.1;
	}

	if(!bMouseDown || (!bLeft && !bRight))
	{
		NextClickTime = 0;
	}
}

function MouseMove(float X, float Y)
{
	if(bDragging && bMouseDown && !bDisabled)
	{
		while(X < (ThumbStart+DragX) && Pos > MinPos)
		{
			Scroll(-1);
		}

		while(X > (ThumbStart+DragX) && Pos < MaxPos)
		{
			Scroll(1);
		}	
	}
	else
		bDragging = False;
}
