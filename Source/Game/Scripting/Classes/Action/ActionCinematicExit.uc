class ActionCinematicExit extends Action
	native;

// execute
latent function Variable execute()
{
	Super.execute();
	cinematicExit();
	
    if( parentScript.Level.GetLocalPlayerController() != None )
    	PlayerController(parentScript.Level.GetLocalPlayerController().Pawn.Controller).myHud.bHideHud = false;

	return None;
}

native static function cinematicExit();

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Exit cinematic mode";
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Cinematic Mode: Exit"
	actionHelp			= "Exit cinematic mode"
	category			= "Cinematic"
}