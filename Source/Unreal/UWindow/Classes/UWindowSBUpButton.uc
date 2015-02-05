//=============================================================================
// UWindowSBUpButton - Scrollbar up button
//=============================================================================
class UWindowSBUpButton extends UWindowButton;

var float NextClickTime;

function Created()
{
	bNoKeyboard = True;
	Super.Created();
}

function BeforePaint(Canvas C, float X, float Y)
{
	LookAndFeel.SB_SetupUpButton(Self);
}

function LMouseDown(float X, float Y)
{
	Super.LMouseDown(X, Y);
	if(bDisabled)
		return;
	UWindowVScrollBar(ParentWindow).Scroll(-UWindowVScrollBar(ParentWindow).ScrollAmount);
	NextClickTime = GetLevel().TimeSeconds + 0.5;
}

function Tick(float Delta)
{
	if(bMouseDown && (NextClickTime > 0) && (NextClickTime < GetLevel().TimeSeconds))
	{
		UWindowVScrollBar(ParentWindow).Scroll(-UWindowVScrollBar(ParentWindow).ScrollAmount);
		NextClickTime = GetLevel().TimeSeconds + 0.1;
	}

	if(!bMouseDown)
	{
		NextClickTime = 0;
	}
}

