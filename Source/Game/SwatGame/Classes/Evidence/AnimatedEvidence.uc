class AnimatedEvidence extends RWOSupport.ReactiveAnimatedMesh
    implements IEvidence, ICanBeSpawned, IUseArchetype
    config(SwatGame)
    abstract;

var private bool Secured;

var protected InanimateSpawner SpawnedFrom;   //the Spawner that I was spawned from
var private Name SpawnedFromName;

var protected ArchetypeInstance ArchetypeInstance;

///////////////////////////////////////////////////////////////////////////////

replication
{
    reliable if ( Role == ROLE_Authority )
        SpawnedFromName;
}


///////////////////////////////////////////////////////////////////////////////

// Animated Evidence does not get destroyed, 
// it only gets hidden
simulated function DestroyRWO()
{
	Hide();
}

// IEvidence extends ICanBeUsed implementation

simulated function bool CanBeUsedNow()
{
    return !Secured && !bHidden;
}

simulated function OnUsed(Pawn SecurerPawn)
{
    ReactToUsed(SecurerPawn);

    SwatGameInfo(Level.Game).GameEvents.EvidenceSecured.Triggered(self);
}

simulated function PostUsed()
{
    Secured = true;
}

simulated function String UniqueID()
{
    return String(SpawnedFromName);
}

// IUseArchetype implementation

function InitializeFromSpawner(Spawner Spawner)
{
    SpawnedFrom = InanimateSpawner(Spawner);
    SpawnedFromName = Spawner.Name;
}

function Internal_InitializeFromArchetypeInstance(ArchetypeInstance inInstance)  //FINAL!
{
    ArchetypeInstance = inInstance;

    InitializeFromArchetypeInstance();
}
function InitializeFromArchetypeInstance();

// ICanBeSpawned implementation

function Spawner GetSpawner()
{
    return SpawnedFrom;
}

defaultproperties
{
    bNoDelete=false
    RemoteRole=ROLE_DumbProxy
}
