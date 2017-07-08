class UWindowWrappedTextArea extends UWindowTextAreaControl;

function Paint( Canvas C, float X, float Y )
{
	local int i, Line;
	local int TempHead, TempTail;
	local float XL, YL;

	C.Font = Root.Fonts[Font];
	C.SetDrawColor(255,255,255);

	TextSize(C, "TEST", XL, YL);
	VisibleRows = WinHeight / YL;

	if (bScrollable)
	{
		VertSB.SetRange(0, Lines, VisibleRows);
	}

	TempHead = Head;
	TempTail = Tail;
	Line = TempHead;
	TextArea[Line] = Prompt;
	if (bScrollable)
	{
		if (VertSB.MaxPos - VertSB.Pos > 0)
		{
			Line -= VertSB.MaxPos - VertSB.Pos;
			TempTail -= VertSB.MaxPos - VertSB.Pos;
		}
	}
	for (i=0; i<VisibleRows; i++)
	{
		WrapClipText(C, 2, YL*(VisibleRows-i-1), TextArea[Line-1]);
		Line--;
		if (TempTail == Line)
			break;
		if (Line < 0)
			Line = BufSize-1;
	}
}

