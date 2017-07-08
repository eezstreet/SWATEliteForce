//=============================================================================
// UWindowCheckbox - a checkbox
//=============================================================================
class UWindowCheckbox extends UWindowButton;

var bool		bChecked;

function BeforePaint(Canvas C, float X, float Y)
{
	LookAndFeel.Checkbox_SetupSizes(Self, C);
	Super.BeforePaint(C, X, Y);
}

function Paint(Canvas C, float X, float Y)
{
	LookAndFeel.Checkbox_Draw(Self, C);
	Super.Paint(C, X, Y);
}


function LMouseUp(float X, float Y)
{
	if(!bDisabled)
	{	
		bChecked = !bChecked;
		Notify(DE_Change);
	}
	
	Super.LMouseUp(X, Y);
}
