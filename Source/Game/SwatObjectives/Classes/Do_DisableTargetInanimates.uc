class Do_DisableTargetInanimates extends SwatGame.Objective_Do
    implements IInterested_GameEvent_GameStarted, IInterested_GameEvent_InanimateDisabled;

var config array<name> SpawnerGroup;

var array<ICanBeDisabled> Targets;

function Initialize()
{
	local int i;

    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.GameStarted.Register(self);
    Game.GameEvents.InanimateDisabled.Register(self);

    //add our SpawnerGroup to the Game's list of MissionObjectiveSpawnerGroups.
	for (i = 0; i < SpawnerGroup.Length; ++i)
		SwatRepo(Game.Level.GetRepo()).MissionObjectives.AddMissionObjectiveSpawnerGroup(self, SpawnerGroup[i]);
}

function UnRegisterGameEventsHook()
{
    Game.GameEvents.GameStarted.UnRegister(self);
    Game.GameEvents.InanimateDisabled.UnRegister(self);
}

function OnGameStarted()
{
    local ICanBeDisabled Current;

    foreach Game.DynamicActors(class'ICanBeDisabled', Current)
    {
        if  (
                Current.IsA('ICanBeSpawned')
            &&  IsSpawnedFromSpawnerGroups(ICanBeSpawned(Current).GetSpawner().SpawnedFromGroup()) )
        {
            if (Game.DebugObjectives)
                log("[OBJECTIVES] The "$class.name$" Objective named "$name
                    $" is adding "$Current.name
                    $" to its list of Targets.");
                
            Targets[Targets.length] = Current;
        }
    }

     assertWithDescription(Targets.length > 0,
        "[tcohen] The "$class.name
        $" named "$name
        $" can't be completed because it doesn't have any Targets.  Check that the SpawnerGroup specified in the Objective"
        $" matches a SpawnerGroup specified in the SpawningManager's Roster.");
}

function bool IsSpawnedFromSpawnerGroups(name SpawnedFromGroup)
{
	local int i;

	for (i = 0; i < SpawnerGroup.Length; ++i)
		if (SpawnerGroup[i] == SpawnedFromGroup)
			return true;

	return false;
}

function OnInanimateDisabled(ICanBeDisabled Disabled, Pawn Disabler)
{
    RemoveTarget(Disabled, 'InanimateDisabled');

    Game.dispatchMessage(new class'MessageTargetInanimateDisabled'(name, Disabler.Label, Targets.length));
}

private function RemoveTarget(ICanBeDisabled Disabled, name DebugWhy)
{
    local int i;
    local bool Found;

    for (i=0; i<Targets.length; ++i)
    {
        if (Targets[i] == Disabled)
        {
            //that's our guy... remove him from our list of active targets
            Found = true;
            if (Game.DebugObjectives)
                log("[OBJECTIVES] The "$class.name
                    $" Objective named "$name
                    $" is removing "$Targets[i].name
                    $" from its list of Targets because "$DebugWhy
                    $".  Number of remaining Targets: "$Targets.length-1);
            Targets.Remove(i, 1);

            break;
        }
    }
            
    if (Targets.length == 0)
        SetStatus(ObjectiveStatus_Completed);

    if (Game.DebugObjectives && !Found)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" was called to RemoveTarget("$Disabled.name
            $") from its list of Targets because "$DebugWhy
            $", but that wasn't found in its list of Targets.");
}
