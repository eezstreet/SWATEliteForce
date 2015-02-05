class ActionOpenMenu extends Action;

var() string menu;
var() string param1;
var() string param2;
var() string param3;

// execute
latent function Variable execute()
{
	local PlayerController pc;

	Super.execute();

	pc = parentScript.Level.GetLocalPlayerController();

	if (pc != None)
	{
		pc.player.GUIController.OpenMenu(menu, param1, param2, param3);
	}
	else
	{
		SLog("Couldn't get the player controller");
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Open menu " $ propertyDisplayString('menu');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Open Menu"
	actionHelp			= "Opens a menu"
	category			= "Other"
}