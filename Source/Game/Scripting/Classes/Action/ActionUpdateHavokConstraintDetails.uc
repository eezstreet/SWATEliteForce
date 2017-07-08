class ActionUpdateHavokConstraintDetails extends Action;

var() editcombotype(enumScriptLabels) Name target;

// execute
latent function Variable execute()
{
	local HavokConstraint a;

	Super.execute();

	ForEach parentScript.actorLabel(class'HavokConstraint', a, target)
	{
		a.UpdateConstraintDetails();
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Update Havok constraint details for HavocConstraints Labeled " $ propertyDisplayString('target');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Update Havok Constraint Details"
	actionHelp			= "Updates Havok Constraint Details"
	category			= "Havok"
}
