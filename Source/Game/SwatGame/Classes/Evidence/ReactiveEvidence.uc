// ReactiveEvidence falls down when spawned, and can be tossed around via flashbangs, etc
class ReactiveEvidence extends RWOSupport.ReactiveStaticMesh
    implements IEvidence, ICanBeSpawned, IUseArchetype
    abstract;

var protected InanimateSpawner SpawnedFrom;   //the Spawner that I was spawned from
var private Name SpawnedFromName;

var protected ArchetypeInstance ArchetypeInstance;

var private bool Secured;

var() config bool DropOnSpawn "Whether this piece of evidence falls upon spawning";

///////////////////////////////////////////////////////////////////////////////

replication
{
    reliable if ( Role == ROLE_Authority )
        SpawnedFromName;
}


///////////////////////////////////////////////////////////////////////////////

// Static Evidence does not get destroyed,
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
    if(DropOnSpawn)
    {
      SetRotation(Rot(0,0,0));
      SetPhysics(PHYS_Falling);
      bCollideWorld=true;
      SetCollision(true,true,true);
    }
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

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    ReactToTriggered( None );
}

defaultproperties
{
    bNoDelete=false
    RemoteRole=ROLE_DumbProxy
    bAlwaysRelevant=true
    DropOnSpawn=true
    CollisionRadius=20
  	CollisionHeight=5
    bStatic=false
}
