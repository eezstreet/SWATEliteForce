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

function AddSecureTarget(Actor SecureTarget)
{
	assert(SecureTarget != None);

	// if the target is not already on our list, and it's either not a piece of evidence, or it's a piece of evidence that can be used
	if (! IsASecureTarget(SecureTarget) && (!SecureTarget.IsA('IEvidence') || IEvidence(SecureTarget).CanBeUsedNow()))
	{
		SecureTargets[SecureTargets.Length] = SecureTarget;

		if (achievingAction != None)
		{
			SquadSecureAction(achievingAction).NotifyNewSecureTarget();
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
	assert(SecureTarget != None);

	for(i=0; i<SecureTargets.Length; ++i)
	{
		if (SecureTargets[i] == SecureTarget)
		{
			SecureTargets.Remove(i, 1);
			break;
		}
	}
}

private function bool IsASecureTarget(Actor TestSecureTarget)
{
	local int i;

	assert(TestSecureTarget != None);

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
	if (TestActor.IsA('Pawn') || TestActor.IsA('IEvidence'))
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