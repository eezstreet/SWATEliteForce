class ActionKill extends Action;

var() editcombotype(enumScriptLabels) Name target;

// execute
latent function Variable execute()
{
	local Pawn p;

	Super.execute();

	ForEach parentScript.actorLabel(class'Pawn', p, target)
	{
		p.Died(None, class'GenericDamageType', Vect(0,0,0)
#if IG_SWAT
             ,vect(0,0,0)
#endif
            );
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Kill Pawn " $ propertyDisplayString('target');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Kill Pawn"
	actionHelp			= "Kills the target Pawn"
	category			= "Actor"
}
