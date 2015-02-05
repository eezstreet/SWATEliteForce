class ActionStopEffect extends Action;

var() Name effectEvent;
var() editcombotype(enumScriptLabels) Name actorLabel;

// execute
latent function Variable execute()
{
	local Actor actor;

	Super.execute();

	ForEach parentScript.actorLabel(class'Actor', actor, actorLabel)
	{
		actor.UnTriggerEffectEvent(effectEvent);
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Stop effect " $ propertyDisplayString('effectEvent') $ " on " $ propertyDisplayString('actorLabel');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Stop Effect"
	actionHelp			= "Stops a playing effect"
	category			= "AudioVisual"
}