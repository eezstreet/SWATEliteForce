class ActionTriggerMaterials extends Action;

var() actionnoresolve array<Material> materials;

// execute
latent function Variable execute()
{
	local int i;

	Super.execute();

	for (i = 0; i < materials.length; ++i)
		materials[i].Trigger(None, None);

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	local int i;

	s = "Trigger material";

	if (materials.length < 1)
	{
		s = s $ " None";
		return;
	}
	
	if (materials.length > 1)
		s = s $ "s";

	for (i = 0; i < materials.length - 1; ++i)
		s = s @ materials[i] $ ",";

	s = s @ materials[materials.length - 1];
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Trigger Materials"
	actionHelp			= "Triggers a set of materials."
	category			= "AudioVisual"
}