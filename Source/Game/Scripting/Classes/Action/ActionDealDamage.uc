class ActionDealDamage extends Action;

var() editcombotype(enumScriptLabels) Name target;
var() float damageAmount;

// execute
latent function Variable execute()
{
	local Actor a;

	Super.execute();

	ForEach parentScript.actorLabel(class'Actor', a, target)
	{
		a.TakeDamage(damageAmount, None, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), class'GenericDamageType');
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Deal " $ propertyDisplayString('damageAmount') $ " points of damage to " $ propertyDisplayString('target');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Deal Damage"
	actionHelp			= "Deals damage to target actors"
	category			= "Actor"
}
