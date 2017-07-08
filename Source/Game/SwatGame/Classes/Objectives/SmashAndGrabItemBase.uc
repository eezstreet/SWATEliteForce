class SmashAndGrabItemBase extends Engine.Actor implements ICanBeSpawned, IUseArchetype
	placeable;

var() config StaticMesh HeldMesh;

var Vector StartLocation;
var Rotator StartRotation;

var StaticMesh DroppedMesh;
var config name AttachPoint;
var NetPlayer Holder;

var Spawner Spawner;

// IUseArchetype implementation
function InitializeFromSpawner(Spawner inSpawner)
{
    Spawner = inSpawner;
	StartLocation = Location;
	StartRotation = Rotation;
}

function Internal_InitializeFromArchetypeInstance(ArchetypeInstance Instance);  //TMC Implementers: FINAL, please
function InitializeFromArchetypeInstance();

//ICanBeSpawned implementation
function Spawner GetSpawner()
{
    return Spawner;
}

function PreBeginPlay()
{
	SetCollision(true, false, false);
	DroppedMesh = StaticMesh;
}

function PostBeginPlay()
{
	SetTimer(10.0, true);
}

function Timer()
{
	if (Holder == None)
		BroadcastEffectEvent('ItemBeacon');
	else
		BroadcastUnTriggerEffectEvent('ItemBeacon');
}

function Reset()
{
	Dropped(StartLocation);
	SetRotation(StartRotation);
}

function Touch(Actor touchedActor)
{
	local NetPlayer np;
    local SwatGamePlayerController PlayerController;

	if (touchedActor.IsA('NetPlayer'))
	{
		np = NetPlayer(touchedActor);

		if (np == None || !np.IsAlive() || np.IsArrested() || np.HasTheItem())
			return;

		PlayerController = SwatGamePlayerController(np.Controller);

		// Only suspects can pick this up
		if (PlayerController != None && PlayerController.SwatRepoPlayerItem.TeamID == 1 ) // Suspects == 1
		{
			GameModeSmashAndGrab(SwatGameInfo(Level.Game).GetGameMode()).ItemPickup(np);
			np.SetHasTheItem();
			SetCollision(false, false, false);
			np.AttachToBone(self, AttachPoint);
			Holder = np;

			SetStaticMesh(HeldMesh);
			SetOwner(Holder);

			Timer();
		}
	}
}

function Landed(Vector HitNormal)
{
	SetPhysics(PHYS_None);
}

function Dropped(Vector dropLocation)
{
	if (Holder != None)
	{
		Holder.UnSetHasTheItem();
		Holder.DetachFromBone(self);
	}
	SetLocation(dropLocation);
	SetRotation(default.Rotation);
	Holder = None;
	SetCollision(true, false, false);
	SetStaticMesh(DroppedMesh);
	SetOwner(None);
	DropLocation = Location;
	SetPhysics(PHYS_Falling);
	Timer();
}

defaultproperties
{
	bNetNotify=true
	bCollideActors=true
	bCollideWorld=true
	bBlockZeroExtentTraces=false
	bAlwaysRelevant=true
	bHardAttach=true
	bNoRepMesh=false
	RemoteRole=ROLE_SimulatedProxy
	bOwnerNoSee = true
	bUpdateSimulatedPosition = true

	AttachPoint="GripBack"
}