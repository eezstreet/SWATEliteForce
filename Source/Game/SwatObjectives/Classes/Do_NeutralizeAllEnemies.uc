class Do_NeutralizeAllEnemies extends SwatGame.Objective_Do
    implements IInterested_GameEvent_MissionStarted,
               IInterested_GameEvent_PawnDied,
               IInterested_GameEvent_PawnIncapacitated,
               IInterested_GameEvent_PawnArrested,
               IInterested_GameEvent_SuspectEscaped;

function Initialize()
{
    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.MissionStarted.Register(self);
    Game.GameEvents.PawnDied.Register(self);
    Game.GameEvents.PawnIncapacitated.Register(self);
    Game.GameEvents.PawnArrested.Register(self);
	Game.GameEvents.SuspectEscaped.Register(self);
}

function UnRegisterGameEventsHook()
{
    Game.GameEvents.MissionStarted.UnRegister(self);
    Game.GameEvents.PawnDied.UnRegister(self);
    Game.GameEvents.PawnIncapacitated.UnRegister(self);
    Game.GameEvents.PawnArrested.UnRegister(self);
	Game.GameEvents.SuspectEscaped.UnRegister(self);
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

    if (!Pawn.IsA('SwatEnemy'))
        return; //we don't care

    CheckComplete('PawnDied');
}

//IInterested_GameEvent_PawnIncapacitated Implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{

    if (!Pawn.IsA('SwatEnemy'))
        return; //we don't care

    CheckComplete('PawnIncapacitated');
}

//IInterested_GameEvent_PawnArrested Implementation
function OnPawnArrested( Pawn Pawn, Pawn Arrester )
{

    if (!Pawn.IsA('SwatEnemy'))
        return; //we don't care

    CheckComplete('PawnArrested');
}

//IInterested_GameEvent_SuspectEscaped Implementation
function OnSuspectEscaped( SwatPawn Pawn )
{
    if (!Pawn.IsA('SwatEnemy'))
        return; //we don't care

	CheckComplete('PawnEscaped');
}

private function CheckComplete(name DebugWhy)
{
	local Pawn PawnIter;
    local SwatEnemy CurrentEnemy;

    if (Game.DebugObjectives)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" was called to CheckComplete() because "$DebugWhy
            $"...");

	//if this is the last enemy, then the objective is complete
	for(PawnIter = Game.Level.pawnList; PawnIter != None; PawnIter = PawnIter.nextPawn)
	{
		CurrentEnemy = SwatEnemy(PawnIter);

		if ((CurrentEnemy != None) && !CurrentEnemy.IsNeutralized() && !CurrentEnemy.bHidden) // bHidden means escaped
        {
            if (Game.DebugObjectives && CurrentEnemy != None)
                log("[OBJECTIVES] ... It is not yet complete because "$CurrentEnemy
                    $" is not neutralized.");
        
            return; //we're not done yet
        }
	}
            
    if (Game.DebugObjectives)
        log("[OBJECTIVES] ... It is complete because all enemies are neutralized.");

    SetStatus(ObjectiveStatus_Completed);
}
