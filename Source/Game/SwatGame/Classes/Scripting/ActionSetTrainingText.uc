class ActionSetTrainingText extends Scripting.Action;

var() Name TrainingText;

latent function Variable execute()
{
    SwatRepo(parentScript.Level.GetRepo()).GetTrainingTextManager().SetTrainingText(TrainingText);

    return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
    if (TrainingText == '')
        s = "Clear the training text control.";
    else
        s = "Display the "$TrainingText$" training text.";
}

defaultproperties
{
	actionDisplayName	= "Set the contents of the training text control"
	actionHelp			= "Sets the contents of the training text control"
	returnType			= None
	category			= "Script"
}
