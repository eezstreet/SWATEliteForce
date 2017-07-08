///////////////////////////////////////////////////////////////////////////////

class ActionTrainerStopAnim extends TrainerScriptActionBase;

///////////////////////////////////////////////////////////////////////////////

latent function Variable execute()
{
    local SwatTrainer swatTrainer;
    swatTrainer = GetSwatTrainer();

    if (swatTrainer != None)
    {
        swatTrainer.AnimStopSpecial();
    }

    return None;
}

///////////////////////////////////////

function editorDisplayString(out string s)
{
    s = "Trainer AI - stop looping animation";
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    returnType        = None
    actionDisplayName = "Trainer - Stop Looping Animation"
    actionHelp        = "Stops a looping animation on the Trainer AI."
    category          = "AI"
}

///////////////////////////////////////////////////////////////////////////////
