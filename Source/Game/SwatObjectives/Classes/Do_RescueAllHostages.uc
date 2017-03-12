class Do_RescueAllHostages extends SwatGame.Objective_Do
    implements IInterested_GameEvent_MissionStarted,
               IInterested_GameEvent_PawnDied,
               IInterested_GameEvent_PawnIncapacitated,
               IInterested_GameEvent_PawnArrested;

function Initialize()
{
    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.MissionStarted.Register(self);
    Game.GameEvents.PawnDied.Register(self);
    Game.GameEvents.PawnIncapacitated.Register(self);
    Game.GameEvents.PawnArrested.Register(self);
}

function UnRegisterGameEventsHook()
{
    Game.GameEvents.MissionStarted.UnRegister(self);
    Game.GameEvents.PawnDied.UnRegister(self);
    Game.GameEvents.PawnIncapacitated.UnRegister(self);
    Game.GameEvents.PawnArrested.UnRegister(self);
}

// IInterested_GameEvent_MissionStarted Implementation
function OnMissionStarted()
{
    // We should check for completion at mission start, in case there are no
    // enemies in the level.
    CheckComplete('MissionStarted');
}

//IInterested_GameEvent_PawnDied Implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    local SwatHostage Hostage;

    if (!Pawn.IsA('SwatHostage'))
        return;                             //we don't care

    Hostage = SwatHostage(Pawn);
    if(Hostage.IsDOA()) return; // It's a DOA, it doesn't count towards the objective

    if (Game.DebugObjectives)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" is setting its status to Failed because the Hostage named "$Pawn.name
            $" died.  (If a Hostage dies, then you can't Do_RescueAllHostages.)");

    SetStatus(ObjectiveStatus_Failed);
}

//IInterested_GameEvent_PawnIncapacitated Implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
	if (!Pawn.IsA('SwatHostage'))
        return;                             //we don't care

    if (SwatHostage(Pawn).WasHostageSpawnedIncapacitated())
        return;                             //they started out that way

    CheckComplete('PawnIncapacitated');
}

//IInterested_GameEvent_PawnArrested Implementation
function OnPawnArrested(Pawn Pawn, Pawn Arrester )
{
    if (!Pawn.IsA('SwatHostage'))
        return;                             //we don't care

    CheckComplete('PawnArrested');
}

private function CheckComplete(name DebugWhy)
{
	local Pawn PawnIter;
    local SwatHostage CurrentHostage;

    if (Game.DebugObjectives)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" was called to CheckComplete() because "$DebugWhy
            $"...");

	//if this is the last hostage, then the objective is complete
	for (PawnIter = Game.Level.pawnList; PawnIter != None; PawnIter = PawnIter.nextPawn)
	{
		CurrentHostage = SwatHostage(PawnIter);

		if ((CurrentHostage != None) && !CurrentHostage.IsArrested() && !CurrentHostage.IsIncapacitated())
        {
            if (Game.DebugObjectives && (CurrentHostage != None))
                log("[OBJECTIVES] ... It is not yet complete because "$CurrentHostage
                    $" is not rescued (not arrested and not incapacitated).");

            return;                         //we're not done yet
        }
	}

    if (Game.DebugObjectives)
        log("[OBJECTIVES] ... It is complete because all hostages are rescued (arrested or incapacitated).");

    SetStatus(ObjectiveStatus_Completed);
}
