class ActionIf extends Action
	native;

cpptext
{
	virtual void CleanupDestroyed();
}

var() deepcopy editinline Array<ActionBool> testsOr;
var() deepcopy editinline Array<Action> trueActions;
var() deepcopy editinline Array<Action> elseActions;

function setParentScript(Script s)
{
	local int i;

	super.setParentScript(s);

	for (i = 0; i < testsOr.Length; ++i)
			testsOr[i].setParentScript(s);
	
	for (i = 0; i < trueActions.Length; ++i)
			trueActions[i].setParentScript(s);

	for (i = 0; i < elseActions.Length; ++i)
			elseActions[i].setParentScript(s);
}

// execute
latent function Variable execute()
{
	local int i;
	local Variable temp;
	local VariableBool result;

	Super.execute();

	if (testsOr.Length == 0)
		return None;

	// If
	for (i = 0; i < testsOr.Length; i++)
	{
		temp = testsOr[i].execute();
		result = VariableBool(temp);
		if (result != None && result.value)
		{
			for (i = 0; (i < trueActions.Length) && parentScript.continueExecution(); i++)
			{
					trueActions[i].execute();
			}
			return None;
		}
	}

	// Else
	for (i = 0; (i < elseActions.Length) && parentScript.continueExecution(); i++)
	{
			elseActions[i].execute();
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	local int i;
	local string actionString;

	s = "If ";

	if (testsOr.Length == 0)
	{
		s = s $ "nothing";
	}
	else
	{
		for (i = 0; i < testsOr.Length; i++)
		{
			testsOr[i].editorDisplayString(actionString);
			
			s = s $ actionString;

			if (i < testsOr.Length - 1)
				s = s $ " OR ";
		}
	}

	s = s $ " Then ";
	if (trueActions.Length == 0)
	{
		s = s $ "do nothing";
	}
	else if (trueActions.Length > 2)
	{
		s = s $ "do " $ trueActions.Length $ " actions";
	}
	else
	{
		for (i = 0; i < trueActions.Length; i++)
		{
			trueActions[i].editorDisplayString(actionString);
			
			s = s $ actionString;

			if (i < trueActions.Length - 1)
				s = s $ ", ";
		}
	}

	if (elseActions.Length == 0)
	{
		return;
	}

	s = s $ ", Else ";
	if (elseActions.Length > 2)
	{
		s = s $ "do " $ elseActions.Length $ " actions";
	}
	else
	{
		for (i = 0; i < elseActions.Length; i++)
		{
			elseActions[i].editorDisplayString(actionString);
			
			s = s $ actionString;

			if (i < elseActions.Length - 1)
				s = s $ ", ";
		}
	}
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "If Statement"
	actionHelp			= "If one of the boolean statements in the 'testsOr' array is true, executes the Actions in 'trueActions', else executes the Actions in 'elseActions'."
	category			= "Script"
}