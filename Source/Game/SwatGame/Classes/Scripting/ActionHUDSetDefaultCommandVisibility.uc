class ActionHUDSetDefaultCommandVisibility extends Scripting.Action;

var() bool Visible;

latent function Variable execute()
{
    if( parentScript.Level.GetLocalPlayerController() != None )
        SwatGamePlayerController(parentScript.Level.GetLocalPlayerController()).GetHUDPage().DefaultCommand.SetVisibility(Visible);

    return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
    if (Visible)
        s = "Show the DefaultCommand HUD component";
    else
        s = "Hide the DefaultCommand HUD component";
}

defaultproperties
{
	actionDisplayName	= "Set the visibility of the DefaultCommand HUD component"
	actionHelp			= "Sets the visibility of the DefaultCommand indicator"
	returnType			= None
	category			= "Script"
}
