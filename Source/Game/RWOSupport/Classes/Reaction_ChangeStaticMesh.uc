class Reaction_ChangeStaticMesh extends Reaction;

var (Reaction) array<StaticMesh> StaticMeshes "Each time this reaction is triggered, the actor will change to the next static mesh in this array (until it has reached the final mesh).";
var (Reaction) bool BecomeBroken "If BecomeBroken is TRUE, then the 'Alive' EffectEvent will not be retriggered after the appearance change";

//TMC note to self: in the prototype, we had here a PreChangeEvent, PostChangeEventDelay, and PostChangeEvent.  This was to handle the emergency lights breaking flicker.  I'm leaving it out of here, because there's a better way to do that:  the base Reaction has an Event (which it triggers when the Reaction is Execute()d), and an UnTriggerDelay.

var private int StaticMeshIndex; // index of static mesh we should swap to next time this reaction triggers

protected simulated function Execute(Actor Owner, Actor Other)
{
    local ReactiveWorldObject Host;

    //Log("** Executing "$self$" On "$Owner);

    Host = ReactiveWorldObject(Owner);
    assert(Host != None);   //only a ReactiveWorldObject should host a Reaction
    
    if (BecomeBroken)
        Host.IsConseptuallyBroken = true;

    if (StaticMeshes.length > StaticMeshIndex)
    {
		//Log("  Doing it!");

        Host.TriggerEffectEvent('PreAppearanceChanged');
        // !! Note: we don't call RemoveProjectors here; instead we do it
        // in the native implementation of SetStaticMesh so that it also
        // happens when the RWO comes back into network relevancy
        Host.SetStaticMesh(StaticMeshes[StaticMeshIndex]);
        Host.TriggerEffectEvent('PostAppearanceChanged');

        // Sometimes during a chain-reaction of damage & changing static meshes
        // (such as in an explosion), the multiple SetStaticMesh calls can
        // leave havok in an inactive state. Here we guarantee that havok is
        // activated if it is PHYS_Havok.
        if (Host.Physics == PHYS_Havok)
        {
            Host.HavokActivate(true);
        }

        ++StaticMeshIndex;
    }
}
