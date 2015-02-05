class ActionChangeLevel extends Action;

var() string	mapname;
var() bool		bShowLoadingMessage;
var() bool		persist;

// execute
latent function Variable execute()
{
	Super.execute();

	if( bShowLoadingMessage )
		parentScript.Level.ServerTravel(mapname, persist);
	else
		parentScript.Level.ServerTravel(mapname$"?quiet", persist);

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Change level to map " $ propertyDisplayString('mapname');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Change Level"
	actionHelp			= "Loads a new map"
	category			= "Level"
}