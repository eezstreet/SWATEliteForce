///////////////////////////////////////////////////////////////////////////////

class ActionTrainerLookAtPlayer extends TrainerScriptActionBase;

///////////////////////////////////////////////////////////////////////////////

latent function Variable execute()
{
    local SwatTrainer swatTrainer;
    local Pawn playerPawn;
    swatTrainer = GetSwatTrainer();
    
    if( parentScript.Level.GetLocalPlayerController() != None )
        playerPawn  = parentScript.Level.GetLocalPlayerController().Pawn;

    if (swatTrainer != None && playerPawn != None)
    {
        swatTrainer.AnimSetFlag(kAF_Aim, true);
        swatTrainer.AimAtActor(playerPawn);
        swatTrainer.AnimSnapBaseToAim();
    }

    return None;
}

///////////////////////////////////////

function editorDisplayString(out string s)
{
    s = "Trainer AI - look at player";
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    returnType        = None
    actionDisplayName = "Trainer - Look At Player"
    actionHelp        = "Causes the Trainer AI to look at the player."
    category          = "AI"
}

///////////////////////////////////////////////////////////////////////////////
