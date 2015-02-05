class UWindowComboRightButton extends UWindowButton;

function BeforePaint(Canvas C, float X, float Y)
{
	LookAndFeel.Combo_SetupRightButton(Self);
}

function LMouseDown(float X, float Y)
{
	local int i;

	Super.LMouseDown(X, Y);
	if(!bDisabled)
	{
		i = UWindowComboControl(OwnerWindow).GetSelectedIndex();
		i++;
		if(i >= UWindowComboControl(OwnerWindow).List.Items.Count())
			i = 0;
		UWindowComboControl(OwnerWindow).SetSelectedIndex(i);
	}
}

defaultproperties
{
	bNoKeyboard=True
}