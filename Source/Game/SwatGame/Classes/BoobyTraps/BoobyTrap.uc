class BoobyTrap extends RWOSupport.ReactiveStaticMesh
      implements IUseArchetype, ICanBeDisabled, ICanBeSpawned, IDisableableByAI;

var() SwatDoor                    BoobyTrapDoor;
var config float                QualifyTime;
var() bool                        bActive;
var() name                        AttachSocket;

var protected BoobyTrapSpawner SpawnedFrom;   //the Spawner that I was spawned from
var private Name SpawnedFromName;

replication
{
    reliable if ( Role == ROLE_Authority )
        bActive, SpawnedFromName;
}

function PostBeginPlay()
{
    Super.PostBeginPlay();

    //tcohen 5/19/2004 to fix 3484: Booby traps cannot be used directly - they are only used with a toolkit
    UsableNow = false;
}

function OnBoobyTrapInitialize();

// IAmUsedByToolkit implementation

simulated function bool CanBeUsedByToolkitNow()
{
    return bActive;
}

// Called when qualifying begins.
function OnUsingByToolkitBegan( Pawn User );

// Called when qualifying completes successfully.
function OnUsedByToolkit(Pawn User)
{
    ReactToUsed(User.GetActiveItem());
}

// Called when qualifying is interrupted.
function OnUsingByToolkitInterrupted( Pawn User );


//return the time to qualify to use this with a Toolkit
simulated function float GetQualifyTimeForToolkit()
{
    return QualifyTime;
}

//ICanBeDisabled implementation
simulated function bool IsActive()
{
    return bActive;
}

// IDisableableByAI interface
simulated function bool IsDisableableNow()
{
  return IsActive();
}

// end of Interface implementation


function Deactivate()
{
    bActive = false;
    BoobyTrapDoor.SetBoobyTrap(None);
}

function ReactToUsed(Actor Other)
{
    if ( bActive && (Other.IsA('Toolkit') || Other.IsA('SwatDoor')) )
    {
        Super.ReactToUsed(Other);
        Deactivate();
    }
}

function ReactToDamaged(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    if ( bActive )
    {
        Super.ReactToDamaged(Damage, EventInstigator, HitLocation, Momentum, DamageType);
        Deactivate();
    }
}

function ReactToTriggered(Actor Other)
{
    if ( bActive )
    {
        Super.ReactToTriggered(BoobyTrapDoor);
        BoobyTrapDoor.BoobyTrapTriggered();
        SwatGameInfo(Level.Game).GameEvents.BoobyTrapTriggered.Triggered(self, Other);
        dispatchMessage(new class'MessageBoobyTrapTriggered');
        Deactivate();
    }
}

function OnTriggeredByDoor(Actor Opener)
{
    ReactToTriggered(Opener);
}

// Make these final, as we want to control flow directly from here
final function InitializeFromSpawner(Spawner Spawner)
{
    local BoobyTrapSpawner BoobySpawner;
    local SwatDoor Door;

    BoobySpawner = BoobyTrapSpawner(Spawner);
    assert(BoobySpawner != None);

    SpawnedFrom = BoobySpawner;
    SpawnedFromName = BoobySpawner.Name;

    foreach DynamicActors(class'SwatDoor', Door, BoobySpawner.DoorTag)
    {
        BoobyTrapDoor = Door;
    }

    BoobyTrapDoor.SetBoobyTrap(Self);
    bActive = true;
    AttachSocket = BoobySpawner.DoorAttachmentBone;

    OnBoobyTrapInitialize();
}

function Spawner GetSpawner()
{
    return SpawnedFrom;
}

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    ReactToTriggered( None );
}

final function Internal_InitializeFromArchetypeInstance(ArchetypeInstance Instance);
final function InitializeFromArchetypeInstance();

defaultproperties
{
  bAlwaysRelevant=true
  RemoteRole=ROLE_DumbProxy
  bUseCollisionBoneBoundingBox=true
}
