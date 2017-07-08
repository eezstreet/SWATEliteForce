class SwatPlayerStart extends SwatStartPointBase
    placeable
	native;

///////////////////////////////////////////////////////////////////////////////

cpptext
{
	virtual void CheckForErrors();
	void CheckNumberOfSwatPlayerStarts();
}

defaultproperties
{
	bSinglePlayerStart=true
}
