///////////////////////////////////////////////////////////////////////////////

class ActionTrainerLookAtActor extends TrainerScriptActionBase;

///////////////////////////////////////////////////////////////////////////////

var() editcombotype(enumActors) Name targetActorLabel;

///////////////////////////////////////////////////////////////////////////////

latent function Variable execute()
{
    local SwatTrainer swatTrainer;
	local Actor targetActor;
    swatTrainer = GetSwatTrainer();
    targetActor = FindTargetActor();

    if (swatTrainer != None && targetActor != None)
    {
        swatTrainer.AnimSetFlag(kAF_Aim, true);
        swatTrainer.AimAtActor(targetActor);
        swatTrainer.AnimSnapBaseToAim();
    }

    return None;
}

///////////////////////////////////////

function Actor FindTargetActor()
{
	local Actor actor;
    foreach parentScript.Level.AllActors(class'Actor', actor)
    {
        if (actor.label == targetActorLabel)
        {
            return actor;
        }
    }

    return None;
}

///////////////////////////////////////

function enumActors(LevelInfo l, out Array<Name> s)
{
	local Actor actor;
    foreach l.AllActors(class'Actor', actor)
    {
        if (actor.label != '')
        {
            s[s.length] = actor.label;
        }
    }
}

///////////////////////////////////////

function editorDisplayString(out string s)
{
    s = "Trainer AI - look at actor labeled "$targetActorLabel;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    returnType        = None
    actionDisplayName = "Trainer - Look At Actor"
    actionHelp        = "Causes the Trainer AI to look at a specific actor."
    category          = "AI"
}

///////////////////////////////////////////////////////////////////////////////
