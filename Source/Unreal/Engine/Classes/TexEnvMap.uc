class TexEnvMap extends TexModifier
	editinlinenew
	native;

cpptext
{
	// UTexModifier interface
	virtual FMatrix* GetMatrix(FLOAT TimeSeconds);
}

var() enum ETexEnvMapType
{
	EM_WorldSpace,
	EM_CameraSpace,
} EnvMapType;

defaultproperties
{
	EnvMapType=EM_CameraSpace
	TexCoordCount=TCN_3DCoords

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_TexEnvMap
//#endif
}
