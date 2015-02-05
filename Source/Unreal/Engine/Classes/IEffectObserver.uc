interface IEffectObserver
    native;

// =============================================================================
//  IEffectObserver
//  
//  IEffectObserver is an interface which receives callbacks from the EffectsSystem.
//  It gets notified whenever an effect starts or stops.  The implementor must handle
//  testing the effect type for what they care about, and managing what gets updated
//  and when.  Care should be taken to ensure that nothing happens to any reference
//  after it gets Stopped.  
//
// ==============================================================================

// Called whenever an effect is started.
function OnEffectStarted(Actor inStartedEffect);

// Called whenever an effect is stopped.
function OnEffectStopped(Actor inStoppedEffect, bool Completed);

// Called whenever an effect is created.
function OnEffectInitialized(Actor inInitializedEffect);