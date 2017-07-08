class ActionFailDoNotSpecialObjective extends Scripting.Action;

var() Name DoNotSpecialObjectiveName;

latent function Variable execute()
{
    local int i;
    local MissionObjectives Objectives;

	Super.execute();

    Objectives = SwatRepo(parentScript.Level.GetRepo()).MissionObjectives;
    assert(Objectives != None);

    for (i=0; i<Objectives.Objectives.length; ++i)
    {
        if (Objectives.Objectives[i].name == DoNotSpecialObjectiveName)
        {
            assertWithDescription(Objectives.Objectives[i].IsA('DoNot_Special'),
                "[tcohen] ActionFailDoNotSpecialObjective::Execute() The Objective named "$DoNotSpecialObjectiveName
                $" is not a DoNot_Special type of Objective.  This Action can only be used on Objectives of class DoNot_Special.");

            DoNot_Special(Objectives.Objectives[i]).OnSpecialGameEvent('');
            return None;
        }
    }

    assertWithDescription(false,
        "[tcohen] ActionFailDoNotSpecialObjective::Execute() The Objective named "$DoNotSpecialObjectiveName
        $" was not found to be a current Objective.");

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
    if (DoNotSpecialObjectiveName == '')
        s = "Fail a 'DoNot_Special' Mission Objective.";
    else
        s = "Fail the '"$DoNotSpecialObjectiveName$"' Mission Objective.";
}

defaultproperties
{
	actionDisplayName	= "Fail a 'DoNot_Special' Mission Objective."
	actionHelp			= "Fails a 'DoNot_Special' Mission Objective."
	returnType			= None
	category			= "Objectives"
}
