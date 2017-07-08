class ActionTrigger extends Scripting.Action;

var() editcombotype(enumScriptLabels) Name Target;

latent function Variable execute()
{
	local ReactiveWorldObject a;

	Super.execute();

	ForEach parentScript.actorLabel(class'ReactiveWorldObject', a, Target)
        a.BroadcastTrigger(None, None);

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Trigger a Reactive World Object";
}

defaultproperties
{
	actionDisplayName	= "Trigger a ReactiveWorldObject"
	actionHelp			= "Triggers a Reactive WorldObject"
	returnType			= None
	category			= "Script"
}
