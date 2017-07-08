class ActionKillAll extends Action;

// execute
latent function Variable execute()
{
	local Pawn p;

	Super.execute();

	ForEach parentScript.DynamicActors(class'Pawn', p)
	{
		p.Died(None, class'GenericDamageType', Vect(0,0,0), Vect(0,0,0));
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Kill all Pawns";
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Kill all Pawns"
	actionHelp			= "Kills all Pawns"
	category			= "Actor"
}
