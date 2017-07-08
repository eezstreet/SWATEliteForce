class ActionCompleteDoSpecialObjective extends Scripting.Action;

var() Name DoSpecialObjectiveName;

latent function Variable execute()
{
    local int i;
    local MissionObjectives Objectives;

	Super.execute();

    Objectives = SwatRepo(parentScript.Level.GetRepo()).MissionObjectives;
    assert(Objectives != None);

    for (i=0; i<Objectives.Objectives.length; ++i)
    {
        if (Objectives.Objectives[i].name == DoSpecialObjectiveName)
        {
            assertWithDescription(Objectives.Objectives[i].IsA('Do_Special'),
                "[tcohen] ActionCompleteDoSpecialObjective::Execute() The Objective named "$DoSpecialObjectiveName
                $" is not a Do_Special type of Objective.  This Action can only be used on Objectives of class Do_Special.");

            Do_Special(Objectives.Objectives[i]).OnSpecialGameEvent('');
            return None;
        }
    }

    assertWithDescription(false,
        "[tcohen] ActionCompleteDoSpecialObjective::Execute() The Objective named "$DoSpecialObjectiveName
        $" was not found to be a current Objective.");

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
    if (DoSpecialObjectiveName == '')
        s = "Complete a 'Do_Special' Mission Objective.";
    else
        s = "Complete the '"$DoSpecialObjectiveName$"' Mission Objective.";
}

defaultproperties
{
	actionDisplayName	= "Complete a 'Do_Special' Mission Objective."
	actionHelp			= "Completes a 'Do_Special' Mission Objective."
	returnType			= None
	category			= "Objectives"
}
