///////////////////////////////////////////////////////////////////////////////
// SquadSecureGoal.uc - SquadSecureGoal class
// this goal is used to organize the Officer's restrain and securing evidence

class SquadSecureGoal extends SquadCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var array<Actor> SecureTargets;

///////////////////////////////////////////////////////////////////////////////
//
// Behavior Copying

// copy the restrain targets from the template
function CopyAdditionalPropertiesFromTemplate(SquadCommandGoal Template)
{
	local int i;
	local SquadSecureGoal TemplateSquadSecureGoal;

	TemplateSquadSecureGoal = SquadSecureGoal(Template);
	assert(TemplateSquadSecureGoal != None);
	assert(SecureTargets.Length == 0);

	super.CopyAdditionalPropertiesFromTemplate(Template);

	if (TemplateSquadSecureGoal.achievingAction != None)
	{
		SquadSecureAction(TemplateSquadSecureGoal.achievingAction).CopyTargetsBeingSecuredToGoal();
	}

	log("TemplateSquadSecureGoal.SecureTargets.Length is: " $ TemplateSquadSecureGoal.SecureTargets.Length);

	for(i=0; i<TemplateSquadSecureGoal.SecureTargets.Length; ++i)
	{
		SecureTargets[i] = TemplateSquadSecureGoal.SecureTargets[i];
		log("SecureTargets["$i$"] is: " $ SecureTargets[i]);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Restrain Targets

private function AddTargetToList(Actor SecureTarget)
{
	SecureTargets[SecureTargets.Length] = SecureTarget;

	if(achievingAction != None)
	{
		SquadSecureAction(achievingAction).NotifyNewSecureTarget();
	}
}

function AddSecureTarget(Actor SecureTarget)
{
	if(SecureTarget == None)
	{
		return;
	}

	if (!IsASecureTarget(SecureTarget))	// Don't add this if it's already in the list
	{
		if(SecureTarget.IsA('IEvidence'))
		{
			if(IEvidence(SecureTarget).CanBeUsedNow())
			{	// Only add evidence items that can be used
				AddTargetToList(SecureTarget);
			}
		}
		else if(SecureTarget.IsA('IDisableableByAI'))
		{
			if(IDisableableByAI(SecureTarget).IsDisableableNow())
			{	// Only add disableable targets that aren't active
				AddTargetToList(SecureTarget);
			}
		}
		else if(SecureTarget.IsA('ISwatAI'))
		{
			if(class'Pawn'.static.checkConscious(Pawn(SecureTarget)) && !ISwatAI(SecureTarget).IsArrested())
			{ // Only allow alive, non-restrained targets to the list
				AddTargetToList(SecureTarget);
			}
		}
	}
}

function int GetNumSecureTargets()
{
	ValidateSecureTargets();

	return SecureTargets.Length;
}

function Actor GetSecureTarget(int SecureTargetIndex)
{
	assert(SecureTargetIndex < SecureTargets.Length);
	assert(SecureTargetIndex >= 0);

	return SecureTargets[SecureTargetIndex];
}

function RemoveSecureTarget(Actor SecureTarget)
{
	local int i;

	if(SecureTarget == None)
	{
		return;
	}

	for(i=0; i<SecureTargets.Length; ++i)
	{
		if (SecureTargets[i] == SecureTarget)
		{
			SecureTargets.Remove(i, 1);
			break;
		}
	}
}

function bool IsASecureTarget(Actor TestSecureTarget)
{
	local int i;

	if(TestSecureTarget == None)
	{
		return false;
	}

	for(i=0; i<SecureTargets.Length; ++i)
	{
		if (SecureTargets[i] == TestSecureTarget)
		{
			return true;
		}
	}

	return false;
}


private function ValidateSecureTargets()
{
	local int i;
	local Pawn RestrainTarget;
	local IDisableableByAI DisableTarget;

	for(i=0; i<SecureTargets.Length; ++i)
	{
		assert(SecureTargets[i] != None);

		if (SecureTargets[i].IsA('Pawn'))
		{
			RestrainTarget = Pawn(SecureTargets[i]);

			// if the target is dead or got restrained (by the player),
			// we remove them from the list
			if (! class'Pawn'.static.checkConscious(RestrainTarget) || ISwatAI(RestrainTarget).IsArrested())
			{
				SecureTargets.Remove(i, 1);
			}
		}
		else if(SecureTargets[i].IsA('IDisableableByAI'))
		{
			DisableTarget = IDisableableByAI(SecureTargets[i]);

			if(!DisableTarget.IsDisableableNow())
			{
				SecureTargets.Remove(i, 1);
			}
		}
		else
		{
			// sanity check
			assert(SecureTargets[i].IsA('IEvidence'));

			// evidence gets hidden when secured
			if (! IEvidence(SecureTargets[i]).CanBeUsedNow())
			{
				SecureTargets.Remove(i, 1);
			}
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function bool IsInteractingWith(Actor TestActor)
{
	if (TestActor.IsA('Pawn') || TestActor.IsA('IEvidence') || TestActor.IsA('IDisableableByAI'))
	{
		if (IsASecureTarget(TestActor))
			return true;

		if ((achievingAction != None) && SquadSecureAction(achievingAction).IsTargetBeingSecured(TestActor))
			return true;
	}

	return false;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadSecure"
	bRepostElementGoalOnSubElementSquad = true
}
