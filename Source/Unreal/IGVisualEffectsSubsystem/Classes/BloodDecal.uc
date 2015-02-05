class BloodDecal extends ProjectedDecal;

var() Range DrawScaleRange;

function PostBeginPlay()
{
    Super.PostBeginPlay();

    SetDrawScale(RandRange( DrawScaleRange.Min, DrawScaleRange.Max ));
}

defaultproperties
{
    ProjTexture=Texture'SwatFXTex.BloodSplat1'
    MaxTraceDistance=50
    DrawScale=0.3
    bClipBSP=true
    FOV=1
    DrawScaleRange=(Min=0.01,Max=0.19)
}