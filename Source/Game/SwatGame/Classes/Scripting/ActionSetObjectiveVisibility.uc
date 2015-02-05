class ActionSetObjectiveVisibility extends Scripting.Action;

var() Name ObjectiveName;
var() bool Visible;

latent function Variable execute()
{
    SwatGameReplicationInfo(parentScript.Level.GetGameReplicationInfo()).SetObjectiveVisibility( ObjectiveName, Visible );

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
    local string ShowHide;

    if (Visible)
        ShowHide = "Show";
    else
        ShowHide = "Hide";

    if (ObjectiveName == '')
        s = ShowHide $ " some Objective";
    else
        s = ShowHide $ " the objective named "$ObjectiveName;
}

defaultproperties
{
	actionDisplayName	= "Show or Hide an Objective"
	actionHelp			= "Shows or Hides an Objective"
	returnType			= None
	category			= "Objectives"

    Visible             = true
}
