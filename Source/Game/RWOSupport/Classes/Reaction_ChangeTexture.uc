class Reaction_ChangeTexture extends Reaction;

var (Reaction) array<Material> Materials;
var (Reaction) int IndexToChange "Index of the material to change in the Material array of the owner's StaticMesh or Skeletal Mesh";
var (Reaction) bool BecomeBroken "If BecomeBroken is TRUE, then the 'Alive' EffectEvent will not be retriggered after the appearance change";
var int MaterialIndex;

protected simulated function Execute(Actor Owner, Actor Other)
{
    local ReactiveWorldObject Host;

    Host = ReactiveWorldObject(Owner);
    assert(Host != None);   //only a ReactiveWorldObject should host a Reaction
    
    if (BecomeBroken)
        Host.IsConseptuallyBroken = true;

    if (Materials.length > MaterialIndex)
    {
        //TMC TODO add & use CopyMaterialsToSkins()

        if (Host.bNeedLifetimeEffectEvents)
            Host.UntriggerEffectEvent('Alive');

        Host.TriggerEffectEvent('PreAppearanceChanged');
        Host.RemoveProjectors();
        Host.Skins[IndexToChange] = Materials[MaterialIndex];
        Host.TriggerEffectEvent('PostAppearanceChanged');

        if (Host.bNeedLifetimeEffectEvents)
            Host.TriggerEffectEvent('Alive');

        ++MaterialIndex;
    }
}

