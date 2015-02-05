class Combiner extends Material
	editinlinenew
	native;

enum EColorOperation
{
	CO_Use_Color_From_Material1,
	CO_Use_Color_From_Material2,
	CO_Multiply,
	CO_Add,
	CO_Subtract,
	CO_AlphaBlend_With_Mask,
	CO_Add_With_Mask_Modulation,
	CO_Use_Color_From_Mask,
};

enum EAlphaOperation
{
	AO_Use_Mask,
	AO_Multiply,
	AO_Add,
	AO_Use_Alpha_From_Material1,
	AO_Use_Alpha_From_Material2,
};


var() EColorOperation CombineOperation;
var() EAlphaOperation AlphaOperation;
var() editinlineuse Material Material1;
var() editinlineuse Material Material2;
var() editinlineuse Material Mask;
var() bool InvertMask;
var() bool Modulate2X;
var() bool Modulate4X;

defaultproperties
{
	AlphaOperation=AO_Use_Mask;

//#if IG_RENDERER	// rowan: set Materialtype for quick casts
	MaterialType = MT_Combiner
//#endif
}
