class ActionSetMaterialSwitchIndex extends Action;

var() actionnoresolve MaterialSwitch material;
var() float index;

// execute
latent function Variable execute()
{
	Super.execute();

	if (!material.Set(int(index)))
		logError("Index " $ int(index) $ " out-of-bounds (0," $ material.Materials.length $ ")");

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	local string materialName;

	if (material != None)
		materialName = string(material.name);
	else
		materialName = "None";

	s = "Set the current index of " $ materialName $ " to " $ propertyDisplayString('index');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Set MaterialSwitch Index"
	actionHelp			= "Sets the given MaterialSwitch's index to the given index. Fails if the index is out of bounds"
	category			= "AudioVisual"
}