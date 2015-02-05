class VisualEffectSpecification extends IGEffectsSystem.EffectSpecification
    config(VisualEffects)
	PerObjectConfig
    native;

var config array<Material.EMaterialVisualType> MaterialType;
var config array< class<Actor> > EffectClass;

simulated function Init(EffectsSubsystem EffectsSubsystem)
{
    assert(EffectsSubsystem != None);

    // If no material type is specified, then 
    //  1) there may be only one specification, and
    //  2) that specification is automatically for the 'Default' material type

    if (MaterialType.length == 0)
    {
        assertWithDescription(EffectClass.length == 1,
            "The visual effect "$name
            $" has more than one EffectClass, but no MaterialTypes.  If an effect specifies more than one EffectClass, then it must have a MaterialType for *each* EffectClass");

        MaterialType[0] = MVT_Default; 
    }
    else
        assertWithDescription(EffectClass.length == MaterialType.length,
            "The visual effect "$name
            $" does not specify the same number of MaterialTypes and EffectClasses.  If an Effect specifies any MaterialType(s), then the number of MaterialTypes specified must equal the number of EffectClasses specified.");
}

