class EffectSpecification extends Core.Object
    native
    abstract;

var config bool Precache;           //should the engine precache all assets associated with this EffectSpecification
var config bool AttachToSource;     //should effect attach to object on which it was played
var config name AttachmentBone;     //don't set (ie. leave None) to use owner as base
var config vector LocationOffset;   //default.  may be overridden by TriggerEffectEvent() parameters
var config rotator RotationOffset;  //default.  may be overridden by TriggerEffectEvent() parameters

var transient Level Level;          //the Level of the EffectsSystem that contains this specification (note that this is not a LevelInfo)

simulated function Init(EffectsSubsystem EffectsSubsystem);

