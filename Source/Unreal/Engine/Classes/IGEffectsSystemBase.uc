class IGEffectsSystemBase extends Core.Object
    native
    config(EffectsSystem);

#if IG_CAPTIONS
var bool ShowCaptions;
#endif

function Init(Actor Owner);

simulated function SetSeedForNextEffectEvent( int newSeed );
simulated function AddPersistentContext(name Context);
simulated function RemovePersistentContext(name Context);

//see Actor::AddContextForNextEffectEvent for documentation
simulated function AddContextForNextEffectEvent(name Context);

//see Actor::TriggerEffectEvent for documentation
function bool EffectEventTriggered(
    Actor source,
    name effectEvent,
    optional Actor target,
    optional Material targetMaterial,
    optional vector overrideWorldLocation, 
    optional rotator overrideWorldRotation,
    optional bool unTriggered,
    optional bool PlayOnTarget,
    optional bool QueryOnly,
    optional IEffectObserver Observer,
    optional name Tag,
    optional name SkipSubsystemWithThisName);

static final function class<IGEffectsSystemBase> GetEffectsSystemClass()
{
    return class<IGEffectsSystemBase>(DynamicLoadObject("IGEffectsSystem.EffectsSystem", class'Class'));
}

cpptext
{
    virtual void Init(AActor* Owner);
}

