class ActionPlayEffect extends Action;

var() Name effectEvent;
var() editcombotype(enumScriptLabels) Name actorLabel;

// execute
latent function Variable execute()
{
	local Actor actor;

	Super.execute();

	ForEach parentScript.actorLabel(class'Actor', actor, actorLabel)
	{
		actor.TriggerEffectEvent(effectEvent);
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Play effect " $ propertyDisplayString('effectEvent') $ " on " $ propertyDisplayString('actorLabel');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Play Effect"
	actionHelp			= "Plays an effect"
	category			= "AudioVisual"
}
