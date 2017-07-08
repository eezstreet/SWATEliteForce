class ActionHUDSetFireModeVisibility extends Scripting.Action;

var() bool Visible;

latent function Variable execute()
{
    if( parentScript.Level.GetLocalPlayerController() != None )
        SwatGamePlayerController(parentScript.Level.GetLocalPlayerController()).GetHUDPage().FireMode.SetVisibility(Visible);

    return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
    if (Visible)
        s = "Show the FireMode HUD component";
    else
        s = "Hide the FireMode HUD component";
}

defaultproperties
{
	actionDisplayName	= "Set the visibility of the FireMode HUD component"
	actionHelp			= "Sets the visibility of the FireMode indicator"
	returnType			= None
	category			= "Script"
}
