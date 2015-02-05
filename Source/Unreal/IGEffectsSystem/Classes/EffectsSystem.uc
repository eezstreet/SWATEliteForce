class EffectsSystem extends Engine.IGEffectsSystemBase
    native
    config(EffectsSystem);

import enum EMaterialVisualType from Material;

var private config array< class<EffectsSubsystem> > EffectsSubsystem;       //named in the singular for clarity of configuration file
var private array<EffectsSubsystem> AllEffectsSubsystems;  // effects subsystems that were created in Init()

//This is a list of classes that need to be preloaded for effects purposes.
//Classes normally do not need to be preloaded.
//A class should be preloaded by the Effects System iff
//  1) effects may be played on instance(s) of the class, and
//  2) the class would otherwise not be loaded until PostBeginPlay(), ie. by a DynamicLoadObject().
//Note that if a class is dynamically loaded in PreBeginPlay(), then it does not need to be preloaded.
//Also, there is no harm in "Preloading" a class that would be loaded early enough anyway.
var private config array< String > PreloadActorClass;                 //named in the singular for clarity of configuration file

// switch on trigger logging in an .ini
var public config bool LogEffectEvents;

var private int CurrentSeed;                                    //seed used for determining the next event response

var array<name> TemporaryContexts;
var array<name> PersistentContexts;

//Queued Events
//  (FYI, We're using multiple arrays because
//  - dynamic arrays of structs don't work in UnrealScript, and
//  - using an array of objects would leak those objects since objects aren't garbage collected)
var private bool            QueueingEvents;                 //is the system currently queueing events
var private array<Actor>    QueuedSource;
var private array<name>     QueuedEffectEvent;
var private array<Actor>    QueuedTarget;
var private array<Material> QueuedTargetMaterial;
var private array<vector>   QueuedOverrideWorldLocation;
var private array<rotator>  QueuedOverrideWorldRotation;
var private array<byte>     QueuedUnTriggered;

// DebugEffectEvent support:
//   The EffectsSystem will log details of a TriggerEffectEvent() call if the name of the EffectEvent triggered is in this list.
//   To make this work, you will need to add an exec function like the following to somewhere appropriate:
//     function DebugEffectEvent(name EffectEvent)
//     {
//         EffectsSystem(Level.EffectsSystem).DebugEffectEvent[EffectsSystem(Level.EffectsSystem).DebugEffectEvent.length] = EffectEvent;
//     }
var config array<name> DebugEffectEvent;    

simulated native function Init(Actor Owner);

simulated function EffectsSubsystem GetSubsystem(name inSubsystem)
{
    local int i;

    //find subsystem
    for (i=0; i<AllEffectsSubsystems.length; ++i)
        if (AllEffectsSubsystems[i].tag == inSubsystem)
            return AllEffectsSubsystems[i];

    //not found
    return None;
}

//sets the seed value to be used by the next effect event 
simulated function SetSeedForNextEffectEvent( int newSeed )
{
    CurrentSeed = NewSeed;
}

simulated function AddContextForNextEffectEvent(name Context)
{
    TemporaryContexts[TemporaryContexts.length] = Context;
}

//it is not an error to add a persistent context that is already a persistent context
simulated function AddPersistentContext(name Context)
{
    local int i;

    //don't add duplicate contexts to persistent list
    for (i=0; i<PersistentContexts.length; ++i)
        if (PersistentContexts[i] == Context)
            return;     //already in that context

    PersistentContexts[PersistentContexts.length] = Context;
}

//it is not an error to remove a persistent context that is not a current persistent context
simulated function RemovePersistentContext(name Context)
{
    local int i;

    for (i=0; i<PersistentContexts.length; ++i)
    {
        if (PersistentContexts[i] == Context)
        {
            PersistentContexts.Remove(i, 1);

            //it is guaranteed to be unique by AddPersistentContext(), so we're done.
            return;
        }
    }
}

simulated function ClearPersistentContexts()
{
    PersistentContexts.Remove(0, PersistentContexts.length);
}

//starts queueing events.  Effect Events will be queued until
//  FlushQueuedEvents() is called.
//It is not an error to call QueueEvents() when already queueing.
simulated function QueueEvents()
{
    QueueingEvents = true;
}

simulated event FlushQueuedEvents()
{
    local int i;

    QueueingEvents = false;

    for (i=0; i<QueuedSource.length; ++i)
    {	
		// rowan: check for cleaned up actors (=none) in the queued source array
		if (QueuedSource[i] != None)
		{
			EffectEventTriggered(
				QueuedSource[i],
				QueuedEffectEvent[i],
				QueuedTarget[i],
				QueuedTargetMaterial[i],
				QueuedOverrideWorldLocation[i],
				QueuedOverrideWorldRotation[i],
				(QueuedUnTriggered[i]!=0));                //convert byte to bool
		}
    }
    //empty the queueing arrays... thanks to Ryan for the tip
    QueuedSource.Remove(0, QueuedSource.length);
    QueuedEffectEvent.Remove(0, QueuedEffectEvent.length);
    QueuedTarget.Remove(0, QueuedTarget.length);
    QueuedTargetMaterial.Remove(0, QueuedTargetMaterial.length);
    QueuedOverrideWorldLocation.Remove(0, QueuedOverrideWorldLocation.length);
    QueuedOverrideWorldRotation.Remove(0, QueuedOverrideWorldRotation.length);
    QueuedUnTriggered.Remove(0, QueuedUnTriggered.length);
}

// Most parameters are documentated in Actor.uc TriggerEffectEvent()
simulated function bool EffectEventTriggered(
    Actor Source,
    name EffectEvent,
    optional Actor Target,
    optional Material TargetMaterial,
    optional vector overrideWorldLocation, 
    optional rotator overrideWorldRotation,
    optional bool unTriggered,
    optional bool PlayOnTarget,
    optional bool QueryOnly,
    optional IEffectObserver Observer,
    optional name Tag,
    optional name SkipSubsystemWithThisName)
{
    local int i, j, k, m;
    local bool AnySubsystemFoundMatch;
	local String DebugString;
	local bool ThisSubsystemFoundMatch;

    if (QueueingEvents)
    {
        //array sizes should always be equal
        i = QueuedSource.length;
        assert( QueuedEffectEvent.length == i
            &&  QueuedTarget.length == i
            &&  QueuedTargetMaterial.length == i
            &&  QueuedOverrideWorldLocation.length == i
            &&  QueuedOverrideWorldRotation.length == i
            &&  QueuedUnTriggered.length == i);

        QueuedSource[i] = Source;
        QueuedEffectEvent[i] = EffectEvent;
        QueuedTarget[i] = Target;
        QueuedTargetMaterial[i] = targetMaterial;
        QueuedOverrideWorldLocation[i] = overrideWorldLocation;
        QueuedOverrideWorldRotation[i] = overrideWorldRotation;
        QueuedUnTriggered[i] = byte(unTriggered);   //convert bool to byte
    }
    else //dispatch to subsystems
    {
        if ( AllEffectsSubsystems.Length == 0 )
            return false;

        for (i=0; i<AllEffectsSubsystems.length; ++i)
		{
		    if( AllEffectsSubsystems[i] == None )
		        continue;
		        
            if (AnySubsystemFoundMatch && QueryOnly)
			{
                return AnySubsystemFoundMatch;
			}
            // else trigger the event unless this subsystem should be ignored
            else if (SkipSubsystemWithThisName != AllEffectsSubsystems[i].Class.Name) 
			{
				ThisSubsystemFoundMatch = 
				    AllEffectsSubsystems[i].EffectEventTriggered(
						    Source, EffectEvent, Target, TargetMaterial, overrideWorldLocation, 
                            overrideWorldRotation, unTriggered, PlayOnTarget, QueryOnly, Observer, Tag
                        );
				AnySubsystemFoundMatch = ThisSubsystemFoundMatch ||  AnySubsystemFoundMatch;
			}
		}
	}
	
	// DebugEffectEvent support
    for (i=0; i<DebugEffectEvent.length; ++i)
	{
        if (DebugEffectEvent[i] == EffectEvent)
		{
			DebugString = " EffectsSystem::EffectEventTriggered() ";

            DebugString = DebugString$" EffectEvent="$EffectEvent$": ";

            DebugString = DebugString$"AnythingMatched="$AnySubsystemFoundMatch;

			if (Source!=None)
				DebugString = DebugString$", Source.Class="$Source.Class.name;
			else
					DebugString = DebugString$", Source.Class=None";			


			if (Target!=None) 
				DebugString = DebugString$", Target="$Target.class.name;
			else
				DebugString = DebugString$", Target=None";

			if (TargetMaterial!=None) 
			{
				DebugString = DebugString
					$", TargetMaterial.MaterialSoundType="$TargetMaterial.MaterialSoundType
					$", TargetMaterial.MaterialVisualType="$GetEnum(EMaterialVisualType, TargetMaterial.MaterialVisualType)$" ("$TargetMaterial.MaterialVisualType$")";
			}
			else
			{
				DebugString = DebugString
					$", TargetMaterial.MaterialSoundType=Unknown, TargetMaterial.MaterialVisualType=Unknown";
			}

			DebugString = DebugString
				$", UnTriggered="$UnTriggered
				$", PlayOnTarget="$PlayOnTarget
				$", QueryOnly="$QueryOnly
				$", Observer="$Observer
                $", Tag="$Tag;
            
            DebugString = DebugString$" ZoneContexts=[";
            for (j = 0; j < Source.Region.Zone.EffectsContexts.Length; j++)
                DebugString = DebugString$" "$Source.Region.Zone.EffectsContexts[j];
            DebugString = DebugString$" ]";

            DebugString = DebugString$" PersistentContexts=[";
            for (k = 0; k < PersistentContexts.Length; k++)
                DebugString = DebugString$" "$PersistentContexts[k];
            DebugString = DebugString$" ]";

            //tcohen 6/22/2004 Note that the TemporaryContexts report will be wrong if anything
            //  matches for the 'Spawned' or 'Alive' events on an effect, because the
            //  TemporaryContexts list will have already been cleared by now.
            DebugString = DebugString$" TemporaryContexts=[";
            for (m = 0; m < TemporaryContexts.Length; m++)
                DebugString = DebugString$" "$TemporaryContexts[m];
            DebugString = DebugString$" ]";

			log (DebugString);
		}
	}

    //clear contexts after every EffectEventTriggered()
    TemporaryContexts.Remove(0, TemporaryContexts.length);

    return AnySubsystemFoundMatch;
}

// Dump the state of an EffectsSubsystem to the log
//
// SubsystemName should be one of "VISUAL" or "SOUND",
// since only IGSoundEffectsSubsystem and IGVisualEffectSubsytem 
// are currently supported
exec function DumpEffects(Name SubsystemName)
{
    local EffectsSubsystem SubSys;
    local Name ClassName;
        
    if (SubsystemName == 'SOUND')
    {
        ClassName = 'SoundEffectsSubsystem';
    }
    else if (SubsystemName == 'VISUAL')
    {
        ClassName = 'VisualEffectsSubsystem';
    }

    Subsys = GetSubsystem(ClassName);
    if (Subsys == None)
    {
        Warn("WARNING: Cannot dump effects; subsystem not found: "$ClassName);
        return;
    }
    Subsys.LogState();
}

cpptext
{
    virtual void Init(AActor* Owner);
}

defaultproperties
{
    //the system initially queues events, until it is initialized
    QueueingEvents=true
}
