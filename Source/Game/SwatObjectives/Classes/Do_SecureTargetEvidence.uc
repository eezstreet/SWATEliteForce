class Do_SecureTargetEvidence extends SwatGame.Objective_Do
    implements IInterested_GameEvent_GameStarted, IInterested_GameEvent_EvidenceSecured;

var config name SpawnerGroup;

var array<IEvidence> Targets;

function Initialize()
{
    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.GameStarted.Register(self);
    Game.GameEvents.EvidenceSecured.Register(self);

    //add our SpawnerGroup to the Game's list of MissionObjectiveSpawnerGroups.
    SwatRepo(Game.Level.GetRepo()).MissionObjectives.AddMissionObjectiveSpawnerGroup(self, SpawnerGroup);
}

function UnRegisterGameEventsHook()
{
    Game.GameEvents.GameStarted.UnRegister(self);
    Game.GameEvents.EvidenceSecured.UnRegister(self);
}

function OnGameStarted()
{
    local IEvidence Current;

    foreach Game.DynamicActors(class'IEvidence', Current)
    {
        if  (
                Current.IsA('ICanBeSpawned')
            &&  ICanBeSpawned(Current).GetSpawner().SpawnedFromGroup() == SpawnerGroup
            )
        {
            if (Game.DebugObjectives)
                log("[OBJECTIVES] The "$class.name$" Objective named "$name
                    $" is adding "$Current.name
                    $" from SpawnerGroup "$SpawnerGroup
                    $" to its list of Targets.");
                
            Targets[Targets.length] = Current;
        }
		else if (Current.IsA('WieldableEvidenceEquipment'))
		{
			// consider dynamically spawned evidence such as WieldableEvidenceEquipment
            Targets[Targets.length] = Current;
		}
    }

    assertWithDescription(Targets.length > 0,
            "[tcohen] The "$class.name
            $" named "$name
            $" can't be completed because it doesn't have any Targets.  Check that the SpawnerGroup specified in the Objective ("$SpawnerGroup
            $") matches a SpawnerGroup specified in the SpawningManager's Roster.");
}

function OnEvidenceSecured(IEvidence Secured)
{
    RemoveTarget(Secured, 'EvidenceSecured');
}

private function RemoveTarget(IEvidence Secured, name DebugWhy)
{
    local int i;
    local bool Found;

    for (i=0; i<Targets.length; ++i)
    {
        if (Targets[i] == Secured)
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
            
    if (Found && Targets.length == 0)
        SetStatus(ObjectiveStatus_Completed);

    if (Game.DebugObjectives && !Found)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" was called to RemoveTarget("$Secured.name
            $") from its list of Targets because "$DebugWhy
            $", but that wasn't found in its list of Targets.");
}

