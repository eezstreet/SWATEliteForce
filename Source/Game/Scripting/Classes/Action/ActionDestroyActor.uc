class ActionDestroyActor extends Action;

var() editcombotype(enumScriptLabels) Name target;

// execute
latent function Variable execute()
{
	local Actor a;
	local Pawn pawn;

	Super.execute();

	ForEach parentScript.actorLabel(class'Actor', a, target)
	{
		// remove from seen lists
		pawn = Pawn(a);
		if ( pawn != None )
			a.Level.Game.NotifyKilled( pawn.Controller, pawn.Controller, pawn );

		a.Destroy();
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Destroy Actor " $ propertyDisplayString('target');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Destroy Actor"
	actionHelp			= "Removes the target Actor from the game"
	category			= "Actor"
}