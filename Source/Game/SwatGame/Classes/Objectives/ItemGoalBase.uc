class ItemGoalBase extends Engine.Actor implements ICanBeSpawned, IUseArchetype
	placeable;

var Spawner Spawner;

// IUseArchetype implementation
function InitializeFromSpawner(Spawner inSpawner)
{
    Spawner = inSpawner;
	SetLocation(inSpawner.Location);
}

function Internal_InitializeFromArchetypeInstance(ArchetypeInstance Instance);  //TMC Implementers: FINAL, please
function InitializeFromArchetypeInstance();

//ICanBeSpawned implementation
function Spawner GetSpawner()
{
    return Spawner;
}

function Touch(Actor touchedActor)
{
	local NetPlayer np;

	if (touchedActor.IsA('NetPlayer'))
	{
		np = NetPlayer(touchedActor);

		if (np.IsAlive() && np.HasTheItem())
			GameModeSmashAndGrab(SwatGameInfo(Level.Game).GetGameMode()).ItemGoalAchieved(np);
	}
}

defaultproperties
{
	bCollideActors = true
	bBlockZeroExtentTraces = false
	bAlwaysRelevant = true
}