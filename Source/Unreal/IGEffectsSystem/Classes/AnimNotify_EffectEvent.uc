class AnimNotify_EffectEvent extends Engine.AnimNotify_Scripted
	native;

var() name EffectEvent  "This is the name of the EffectEvent to be triggered.";
var() name Bone         "If the animation is playing on a Pawn and this Bone is set to the name of a Bone or Socket on the skeleton, then the effect event will be passed the material on the first surface found below this pawn (by tracing downwards in the -Z direction)";
var() float MaxDistanceBelowBoneToCheckForMaterial "The maximum distance below the specified Bone to check for an underlying surface material. Ignored if the Bone parameters is not set, or if the animation is not played on a Pawn.";
var() bool UnTrigger    "Set to true if you want to UnTrigger the effect event instead of Triggering it (ie. stop the effect).";
var() bool PlayerOnly	"Set to true if you only want this notify to run on the player character";
var() bool bTraceOnlyStaticGeometry "If true and Bone is set, then only static geometry will be considered when determining which material is under the specified Bone. Set to true for speed, or to False if you need materials for when walking on dynamic geometry/actors.";
var() float MaxDistance "If this value is greater than zero and the distance between the animating mesh and the listener (the local player's viewtarget) is greater than this value, then the effect will not be triggered. If the value is 0 or less, the event will be trigged as it normally is";
enum EPassAsTag
{
    PassAsTag_Tag,
    PassAsTag_StaticMesh,
    PassAsTag_Mesh
};
var() EPassAsTag PassAsTag	"What piece of information about the animating Actor should be passed to the Effects System in the Tag field.";
var() bool OnlyOnThirdPersonPawns "If true, then the Effect Event will only be triggered on Pawns being viewed from a 3rd-person perspective.  (Has no effect for non-Pawns)";

simulated native event Notify( Actor Owner );

defaultproperties
{
	PlayerOnly = false
    bTraceOnlyStaticGeometry=true
    MaxDistanceBelowBoneToCheckForMaterial=15
}