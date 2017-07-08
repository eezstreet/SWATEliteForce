class EffectsSubsystem extends Engine.Actor
    native
    abstract;

var EffectsSystem EffectsSystem;                                //note: assigned after Spawn() returns, so not available in *BeginPlay()

var private config array<Name> EventResponse;            		//named in the singular for clarity of configuration file

var class EffectSpecificationSubClass;

var private bool debugSlow;                                     //if true, does some error checking that takes extra time

var bool ShouldInitOnDedicatedServer;                           //if true, this effects subsystem should be inited on a dedicated server

#if IG_PACKAGE_EFFECTS_CONFIG
var bool IsPackagingEffectsConfig;
var string IniFileName;                                         //the file name of the .ini config file for this subsystem, including extension, but not inlcuding path, ie. "{*}Effects.ini"
var string ConfigPackageName;                                   //the file name of the package containing the configurable objects for this subsystem, not inlcuding path, extension, ie. "{*}EffectsConfig"
var string ConfigPackageFullFileName;                           //the file name of the package containing the configurable objects for this subsystem, not inlcuding path, extension, ie. "..\\..\\content\\system\\{*}EffectsConfig.u"
#endif

var class<EventResponse> EventResponseSubClass;                 //EventResponse subclass to instantiate for this EffectsSubsystem's EventResponses

//native noexport variables (must come last)

var private native noexport const int EventResponses[5];        //Declared as a TMultiMap<FName, UEventResponse*> in AEffectsSystem.h
var private native noexport const int EffectSpecifications[5];  //Declared as a TMap<FName, UEffectSpecification*> in AEffectsSystem.h
#if IG_PACKAGE_EFFECTS_CONFIG
var private transient native noexport const int ConfigPackageBeingBuilt;  //Declared as a UPackage* in AEffectsSystem.h
#endif

simulated function PreBeginPlay()
{
    local EventResponse newEventResponse;
    local int i, j;
    local String LevelContext;
    local bool FoundNonMatchingLevelContext;

#if IG_SWAT
    local bool UsingCustomScenario;

    UsingCustomScenario = Level.UsingCustomScenario();
#endif

    Super.PreBeginPlay();

#if IG_PACKAGE_EFFECTS_CONFIG
    BeginLoadingSubsystemConfig();
#endif

    for (i=0; i<EventResponse.length; ++i)
    {
#if IG_PACKAGE_EFFECTS_CONFIG
        if (IsPackagingEffectsConfig)
        //when packaging effects configuration data, instantiate all EventResponses as well
        //  as all of their EffectsSpecifications, and move all of these from the Transient
        //  package to the config package.
        {
            //instantiate the event response
            newEventResponse = new(self, string(EventResponse[i]), 0) EventResponseSubClass;

            //the hash key for EventResponses is ClassName+EventName, since these are the mandatory data members
            AddEventResponse(
                name(String(newEventResponse.SourceClassName)$String(newEventResponse.Event)), newEventResponse);

            newEventResponse.Init();
            PackageEventResponse(newEventResponse);
            
            InitializeResponseSpecifications(newEventResponse);
        }
        else    //!IsPackagingEffectsConfig
        {
            newEventResponse = 
                EventResponse(DynamicLoadObject(ConfigPackageName$"."$string(EventResponse[i]), EventResponseSubClass));
#else
            //instantiate event responses
            newEventResponse = new(self, string(EventResponse[i]), 0) EventResponseSubClass;
#endif

            //The special EventResponse SourceClassName 'Level' means that all
            //  specifications referenced by the Response should automatically
            //  be instantiated for the Level specified by Event.
            if (newEventResponse.SourceClassName == 'Level')
            {
                if (Level.Label == newEventResponse.Event)
                    InitializeResponseSpecifications(newEventResponse);
                
                //note that newEventResponse is not added to the EventResponses hash, since
                //  the EventResponse is not meant to ever match an EffectEvent.
            }
            else
            {
                //if the newEventResponse specifies a 'Level_' context for a different level,
                //  then it will never match, so skip it
                FoundNonMatchingLevelContext = false;
                for (j=0; j<newEventResponse.Context.length; ++j)
                {
                    LevelContext = String(newEventResponse.Context[j]);
                    if  (
                            Left(LevelContext, 6) ~= "Level_"
                        &&  !( Right(LevelContext, Len(LevelContext) - 6) ~= String(Level.Label) )
                        )
                    {
#if IG_SWAT
                        //Exception: in QuickMissions, we need to _keep some_ EventResponses that
                        //  are specific to a different level.
                        //AlwaysInQM is used on EventResponses for voices of special characters that
                        //  may be used outside of their "native habitat", ie. in a Quick Mission / Custom Scenario.
                        if (newEventResponse.AlwaysInQM  && UsingCustomScenario)
                            newEventResponse.Context.Remove(j, 1);      //remove the level-specific context for this EventResponse in this instance of the effects system
                        else
#endif
                            FoundNonMatchingLevelContext = true;

                        break;
                    }
                }

                if (FoundNonMatchingLevelContext)
                {
                    if (debugSlow) 
                    {
                        log("TMC "$class.name
                                $"::PreBeginPlay() skipping EventResponse named "$newEventResponse
                                $" because it specifies the Context "$LevelContext
                                $", but the current level is "$Level.Label
                                $". Left()="$Left(LevelContext, 6)
                                $", Right()="$Right(LevelContext, Len(LevelContext) - 6));
                    }
                    continue;
                }
                
                //hook-up source & target classes.
                //
                //they're specified by names in the config files so that they will not be loaded
                //  just because they're the subject of events.  Thus we do a DynamicFindObject()
                //  and hook-up the classes only if they're already loaded for another purpose.

                newEventResponse.SourceClass =
                    class<Actor>(
                            DynamicFindObject(
                                String(newEventResponse.SourceClassName),
                                class'Class'));

                //if the SourceClass is not in this map, then this event can never happen
                if (newEventResponse.SourceClass == None)
                    continue;

                //as far as we can tell, this EventResponse may match some EffectEvent during gameplay,
                //  so add it to the list of EventResponses.
                
                //the hash key for EventResponses is ClassName+EventName, since these are the mandatory data members
                AddEventResponse(
                    name(String(newEventResponse.SourceClassName)$String(newEventResponse.Event)), newEventResponse);

                InitializeResponseSpecifications(newEventResponse);
            }
        } //!IsPackagingEffectsConfig
#if IG_PACKAGE_EFFECTS_CONFIG
    } // end loop over EventResponses

	// Collect garbage to clean up refs to unneeded responses 
	// (i.e., the ones we didn't call AddEventResponse() on.
	//
	// Not sure if GCing after packaging will screw things up, so we only
	// GC after loading when not packaging. At any rate, after packaging 
	// we re-load from the package, so GC will eventually happen.
    if (!IsPackagingEffectsConfig) 
	{
		ConsoleCommand("OBJ GARBAGE");
	}

	

    EndLoadingSubsystemConfig();
#endif
    
    PostLoaded();

	if (debugSlow)
	{
		//this used to say, "Initialized."  To avoid confusion, this was changed to read "Loaded," since EffectsSubsystems are technically "initialized" when the game starts.
		log(name$" Loaded. ");
	}
}

native function AddEventResponse(name EventResponseName, EventResponse EventResponse);

#if IG_PACKAGE_EFFECTS_CONFIG
native function BeginLoadingSubsystemConfig();

//renames the supplied EventResponse from the Transient package to the EffectsConfig package
native function PackageEventResponse(EventResponse EventResponse);
//renames the supplied EffectSpecification from the Transient package to the EffectsConfig package
native function PackageEffectSpecification(EffectSpecification EffectSpecification);

native function EndLoadingSubsystemConfig();
#endif

//Called after all of the subsystem's responses and specifications are created and initialized.
//Note that the EffectsSystem itself is not technically initialized; that happens later, when the game starts.
function PostLoaded();

function InitializeResponseSpecifications(EventResponse EventResponse)
{
    local EffectSpecification newEffectSpecification;
    local int i;

    //instantiate the specifications referenced by this response,
    //  and add them to the collection of specifications.
    //(if the specification has already been instantiated, then just
    //  reference that instance.)
    for (i=0; i<EventResponse.Specification.length; ++i)
    {
        //a 'None' specification is valid, ie. there's a chance of doing nothing in response to the event
        if (EventResponse.Specification[i].SpecificationType != 'None')
        {
            //lookup to see if the specification has already been instantiated
            newEffectSpecification = FindEffectSpecification(EventResponse.Specification[i].SpecificationType);

            if (newEffectSpecification == None)     //not yet instantiated, so instantiate it
            {
#if IG_TRIBES3  //tcohen: Tribes prefers error messages in the log.
                // validate the class... warfare crashes out big time if its not valid
                if (class<EffectSpecification>(EventResponse.Specification[i].SpecificationClass) == None)
                {
                    Log("ERROR! EventResponse ["$EventResponse.Event$"] hooked up to invalid specification ["$EventResponse.Specification[i].SpecificationType$"]");
                    continue;
                }
#else     // TMC I prefer AssertWithDescription()s.
                AssertWithDescription(class<EffectSpecification>(EventResponse.Specification[i].SpecificationClass) != None,
                    "[tcohen] EffectsSubsystem::InitializeResponseSpecifications() The EventResponse "$EventResponse.name
                    $" lists specification #"$i
                    $" (base zero) as "$EventResponse.Specification[i].SpecificationType
                    $", but that's not a valid class of EffectSpecification.");
#endif

#if IG_PACKAGE_EFFECTS_CONFIG
                if (IsPackagingEffectsConfig)
                //when packaging effects configuration data, instantiate all EventResponses as well
                //  as all of their EffectsSpecifications, and move all of these from the Transient
                //  package to the "EffectsConfig" package.
                {
                    newEffectSpecification = EffectSpecification(
                            new(None, string(EventResponse.Specification[i].SpecificationType), 0) EventResponse.Specification[i].SpecificationClass); 

                    PackageEffectSpecification(newEffectSpecification);
                }
                else
                    newEffectSpecification = EffectSpecification(DynamicLoadObject(
                            ConfigPackageName$"."$string(EventResponse.Specification[i].SpecificationType), 
                            class'EffectSpecification'));
#else
                newEffectSpecification = EffectSpecification(
                        new(self, string(EventResponse.Specification[i].SpecificationType), 0) EventResponse.Specification[i].SpecificationClass); 
#endif
                assert(newEffectSpecification!=None);
                newEffectSpecification.Level = XLevel;
                newEffectSpecification.Init(self);

                //the hash key for EffectSpecifications is the EffectSpecification's name
                AddEffectSpecification(newEffectSpecification.name, newEffectSpecification);
            }

            EventResponse.SpecificationReference[i] = newEffectSpecification;
        }
    }
}

native function EffectSpecification FindEffectSpecification(name EffectSpecificationName);

native function AddEffectSpecification(name EffectSpecificationName, EffectSpecification EffectSpecification);

// See parameter documentation in Actor.uc TriggerEffectEvent()
native function bool EffectEventTriggered(
        Actor Source,
        name EffectEvent,
        optional Actor Target,
        optional Material TargetMaterial,
        optional vector overrideWorldLocation,
        optional rotator overrideWorldRotation,
        optional bool unTriggered, //only one EffectSpecification should be specified for EffectEvents that may be UnTriggered
        optional bool PlayOnTarget,
        optional bool QueryOnly,
        optional IEffectObserver Observer,
        optional name Tag);

simulated function EffectSpecification GetSpecificationByString(string Specification)
{
    return FindEffectSpecification(name(Specification));
}

// Should print the current state of the subsystem to the log (via Log()) in a
// human-readable form that is suitable for debugging.
simulated function LogState() 
{
    Log("LogState not implemented for subsystem: "$self);
}

simulated event Actor PlayEffectSpecification(
        EffectSpecification EffectSpec,
        Actor Source,
        optional Actor Target,
        optional Material TargetMaterial,
        optional vector overrideWorldLocation,
        optional rotator overrideWorldRotation,
        optional IEffectObserver Observer)
{ assert(false); return None; }  // must implement in subclass!!!

simulated event StopEffectSpecification(
        EffectSpecification EffectSpec,
        Actor Source);

simulated event OnEffectSpawned(Actor SpawnedEffect);

defaultproperties
{
    debugSlow=false
    bHidden=true
}
