class VisualEffectsSubsystem extends IGEffectsSystem.EffectsSubsystem
    native
    config(VisualEffects);

enum MatchResult
{
    MatchResult_None,           //no match & no default
    MatchResult_Matched,        //found a match with a non-default material
    MatchResult_UseDefault      //no explicit material matched, but use default
};

var private array<class<Actor> > MatchingEffectClasses;
var private array<class<Actor> > DefaultEffectClasses;
var private array<class<Actor> > SelectedEffectClasses;

var private int CurrentDecal;

//This TSet<> is used to keep track of effects that
//  have already been requested for precaching, so that we don't
//  request the same effect for precaching more than once.
var private native noexport const int PrecacheVisualEffects[5];        //Declared as a TSet<UClass*> in cpptext{}

//Overridden from EffectsSubsystem
native function PostLoaded();

// Either a source or an overrideWorldLocation must be specified to identify the location of the new effect
simulated event Actor PlayEffectSpecification(
    EffectSpecification EffectSpec,
    Actor Source,
    optional Actor Target,
    optional Material TargetMaterial,
    optional vector overrideWorldLocation,
    optional rotator overrideWorldRotation,
    optional IEffectObserver Observer)
{
    local VisualEffectSpecification visualEffectSpec;
    local Actor effect;
    local int i;
    local MatchResult result;
    local Vector AdditionalLocationOffset;
	local class<Actor> EffectSpecClass;
	
	if (EffectSpec == None)
		return None;

    visualEffectSpec = VisualEffectSpecification(EffectSpec);
    assert(visualEffectSpec != None);

    // Clear the effect classes arrays
    MatchingEffectClasses.Remove(0, MatchingEffectClasses.length);
    DefaultEffectClasses.Remove(0, DefaultEffectClasses.length);
    
    // Find the index of the specified material
    for (i=0; i<visualEffectSpec.materialType.length; i++)
    {
		EffectSpecClass = visualEffectSpec.EffectClass[i];
        if (TargetMaterial != None && visualEffectSpec.materialType[i] == TargetMaterial.MaterialVisualType)
        {
            // make sure that the effect class specified actually exists
            // (i.e., could be spawned).
            if (EffectSpecClass == None)
				assertWithDescription(false, "EffectsManager::PlayEffect(): Nonexistent EffectClass specified for effect named "$EffectSpec.name$" materialType "$TargetMaterial.MaterialVisualType);            

            MatchingEffectClasses[MatchingEffectClasses.length] = EffectSpecClass;
            result = MatchResult_Matched;
        }
        
        if (visualEffectSpec.MaterialType[i] == MVT_Default)
        {
            // Make sure that the default effect class specified actually exists
            // (i.e., could be spawned).
            if(EffectSpecClass == None)
				assertWithDescription(false, "EffectsManager::PlayEffect(): Nonexistent *default* EffectClass specified for effect named "$EffectSpec.name);            

            DefaultEffectClasses[DefaultEffectClasses.length] = EffectSpecClass;

            // If we haven't found any match, then use this default
            if (result == MatchResult_None)
                result = MatchResult_UseDefault;
        }
    }

    // Either the default effect was requested, or no effect class was defined
    // for the specified material type and we're falling back to the
    // default. 

    SelectedEffectClasses.Remove(0, SelectedEffectClasses.length);
    switch (result)
    {
        case MatchResult_None:
            // Return because there is no default class to spawn
            return None;
        
        case MatchResult_Matched:
            //copy the matching classes into the selected array (since we can't have reference to an array)
            for (i=0; i<MatchingEffectClasses.length; ++i)
                SelectedEffectClasses[SelectedEffectClasses.length] = MatchingEffectClasses[i];
            break;

        case MatchResult_UseDefault:
            //copy the default classes into the selected array (since we can't have reference to an array)
            for (i=0; i<DefaultEffectClasses.length; ++i)
                SelectedEffectClasses[SelectedEffectClasses.length] = DefaultEffectClasses[i];
            break;
    }

    // Spawn the selected effects.
    // 
    // Note that we'll spawn them at (0,0,0).  This indicates to Actor::PostBeginPlay()
    //  that the Actor's location has not been initialized, so the 'Spawned'
    //  effect event should not be triggered... we'll do that ourselves below.

    for (i=0; i<SelectedEffectClasses.length; ++i)
    {
		// Don't spawn FX if the level's detail level is lower than the detail level
		// required for the effect
		if((SelectedEffectClasses[i].Default.bHighDetail && Level.DetailMode == DM_Low) || 
			(SelectedEffectClasses[i].Default.bSuperHighDetail && Level.DetailMode != DM_SuperHigh))
		{
			if (EffectsSystem.LogEffectEvents)
			{
				log("**** "$Name$" NOT spawning "$SelectedEffectClasses[i]$" because Level is DetailMode="$GetEnum(EDetailMode, Level.DetailMode)$
					" and effect is (bHighDetail="$SelectedEffectClasses[i].Default.bHighDetail$
					", bSuperHighDetail="$SelectedEffectClasses[i].Default.bSuperHighDetail$")");
			}

			// don't spawn this effect because client's detail setting is too low
			continue;
		}
		else if (EffectsSystem.LogEffectEvents)
		{
			log("**** "$Name$" SPAWNING "$SelectedEffectClasses[i]$"; Level is DetailMode="$GetEnum(EDetailMode, Level.DetailMode)$
				" and effect is (bHighDetail="$SelectedEffectClasses[i].Default.bHighDetail$
			    ", bSuperHighDetail="$SelectedEffectClasses[i].Default.bSuperHighDetail$")");
		}
				
        if (Source != None)
        {
            // Spawn with owner being the Source Actor, and its tag is the name of the
            // EffectSpecification (to identify it later for stopping).
            effect = ProxySpawn(SelectedEffectClasses[i], Source, EffectSpec.name, vect(0,0,0));
        }
        else
        {
            // Since we have no source, check that we have an overrideWorldLocation... enforce the rule above.
			if (overrideWorldLocation == vect(0,0,0))
			{
				assertWithDescription(false, "EffectsManager::PlayEffect() was called with no Source and no overrideWorldLocation... I don't know where to put the effect!?");
			}
			
            // Spawn with the outer of this EffectsManager as the owner
            effect = ProxySpawn(SelectedEffectClasses[i], GameInfo(Outer), EffectSpec.name, vect(0,0,0));
        }
        
        if (effect == None)
        {
			assertWithDescription(false, "VisualEffectsSubsystem.PlayEffectSpecification(): couldn't spawn effect "$EffectSpec.name$" with Source "$Source$" (chose SelectedEffectClasses[i]="$SelectedEffectClasses[i]$")");
		}
		else if (EffectsSystem.LogEffectEvents)
		{
			log("**** "$Name$" ---> Spawn returned: "$effect);
		}

        // If a location is passed explicitly, then use that.
        //otherwise, if the effect should be attached, then attach it.
        //otherwise, if a source was passed, then locate the effect at the source.
        //(we already asserted that we have either a source or an overrideWorldLocation.)

		// rowan: runtime handle NULL effect
		if (effect != None)
		{
            if (effectSpec.AttachToSource)
            {
				if (Source == None)
					assertWithDescription(false, "EffectsManager: tried to attach effect "$EffectSpec.name$" to None Source");
    
                if (Source != None)
                {
                    if (effectSpec.AttachmentBone == '' || effectSpec.AttachmentBone == 'PIVOT')
                    {
                        // attach relative to the source's location (its pivot)
                        effect.SetBase(Source);
                    }
                    else if (effectSpec.AttachmentBone == 'CENTER')
                    {
                        effect.SetBase(Source);
                        // attach relative to the source's bounding sphere center
                        AdditionalLocationOffset = Source.GetRenderBoundingSphere() - Source.Location;
                    }
                    else
                    {
                        // attach to the specified bone
                        Source.AttachToBone(effect, effectSpec.AttachmentBone);
            	    }
                }
    
                effect.SetRelativeLocation(effectSpec.LocationOffset + AdditionalLocationOffset);
                effect.SetRelativeRotation(effectSpec.RotationOffset);
            }
			else if (overrideWorldLocation != vect(0,0,0))
            {
                //use passed location & rotation
                effect.SetLocation(overrideWorldLocation);
                effect.SetRotation(overrideWorldRotation);
            }
            else if (Source != None)
            {
                effect.SetLocation(Source.Location);
                effect.SetRotation(Source.Rotation);
            }
    
            if (effect.IsA('ProjectedDecal'))
            {
                // Invert rotation of the projector to face hit location
                ProjectedDecal(effect).Target = Target;
                ProjectedDecal(effect).SetRotation(rotator(vector(effect.Rotation) * vect(-1,-1,-1)));
                ProjectedDecal(effect).Init();
            }
            
            if (Observer != None)
                Observer.OnEffectStarted(effect);
        }
    }

    return effect;
}

// ckline NOTE: keeping this function around even though it's no longer needed now that we don't 
// use a projector pool. However, it's potentially a good place to hook in functionality needed
// to finish implementing LogState()
simulated function Actor ProxySpawn(class<actor> SpawnClass, actor SpawnOwner, name SpawnTag, vector SpawnLocation)
{
    local Actor Result;

    Result = SpawnOwner.Spawn(SpawnClass, SpawnOwner, SpawnTag, SpawnLocation);
    //Log("VisualFX: "$SpawnOwner$".Spawn("$SpawnClass$","$SpawnOwner$","$SpawnTag$","$SpawnLocation$") returned "$Result);

    return Result;
}

simulated event StopEffectSpecification(
    EffectSpecification EffectSpec,
    Actor Source)
{
    local Actor effect;

    //stop effects with tag=effectTag
    //if Source is specified, then only stop those whose owner is Source
    foreach DynamicActors(class'Actor', effect, EffectSpec.name)
        if (source == None || effect.Owner == source)
            StopEffect(effect, true);  //TMC TODO confirm assumption: visual effects explicitly stopped want to be stopped over time (respawnDeadParticles=false, but let existing particles live-out their lifetimes)
}

simulated function StopEffect(Actor it, bool stopOverTime)
{
    if (stopOverTime && it.IsA('Emitter'))
        Emitter(it).Kill();
    else
        it.Destroy();
}

// Print the current effects to the log
simulated function LogState()
{
//    local int i;
//    local String StateString;

    Log("----------------------------------------------------------------");
    Log("|              VISUAL EFFECTS SUBSYSTEM STATE                   |");
    Log("----------------------------------------------------------------");

Log("| WARNING: LogState() not yet implemented for visual effects subsystem");
// TODO: implement this function for visual effects with output similar to sound effects
//
//    Log("| Existing effects:");
//    for (i = 0; i < CurrentSounds.Length; ++i)
//    {
//        StateString = "None";
//        if (CurrentSounds[i] != None) { StateString = CurrentSounds[i].toString(); }
//        Log("|   #"$i$": "$StateString);
//    }
    Log("----------------------------------------------------------------");
}

simulated event OnEffectSpawned(Actor SpawnedEffect)
{
	if (SpawnedEffect != None && SpawnedEffect.bNeedLifetimeEffectEvents)
	{
		SpawnedEffect.TriggerEffectEvent('Spawned');
		SpawnedEffect.TriggerEffectEvent('Alive');
	}
}

cpptext
{
    //declaration of script-side
    //  var private native noexport const int PrecacheVisualEffects[5];
    TSet<UClass*> PrecacheVisualEffects;

    //overridden from EffectsSubsystem
    void PrecacheEffectSpecification(UEffectSpecification* Spec);

    //instruct the engine to precache all assets related to the specified Effect class.
    //Effect can theoretically be any class<Actor>, but is usually one of:
    //  Emitter, Projector, DynamicLight.
    void PrecacheVisualEffect(UClass* EffectClass);
}

defaultproperties
{
    IniFileName="VisualEffects.ini"
    ConfigPackageName="VisualEffectsConfig"
    ConfigPackageFullFileName="..\\system\\VisualEffectsConfig.u"
    EventResponseSubClass=class'EventResponse_VisualEffectsSubsystem'
    EffectSpecificationSubClass=class'VisualEffectSpecification'
}
