class SkeletalRegionInformation extends Core.Object 
    config(SkeletalRegionInformation)
    PerObjectConfig;

var config Range    DamageModifier;
var config Range    AimErrorPenalty;
var config Range    LimpModifier;
var config float    MomentumToPenetrate;

defaultproperties
{
    DamageModifier=(Min=1.0,Max=1.0)
    AimErrorPenalty=(Min=1.0,Max=1.0)
    LimpModifier=(Min=1.0,Max=1.0)
    MomentumToPenetrate=100
}
