class TexCoordSource extends TexModifier
	native
	editinlinenew
	collapsecategories;

var() int	SourceChannel;

cpptext
{
	void PostEditChange();
}

defaultproperties
{
	SourceChannel=0
	TexCoordSource=TCS_Stream0

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_TexCoordSource
//#endif
}