///////////////////////////////////////////////////////////////////////////////
// ElementSpeechManagerAction.uc - ElementSpeechManagerAction class
// this action is the speech manager for the Officer Element

class ElementSpeechManagerAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Utility functions

function Pawn GetClosestOfficerToOfficer(Pawn Officer)
{
	local int i;
	local float IterDistance, ClosestDistance;
	local Pawn IterOfficer, ClosestOfficer;

	// if anyone can has a line of sight to the enemy, play the speech
	for(i=0; i<squad().pawns.length; ++i)
	{
		IterOfficer = squad().pawns[i];

		if (IterOfficer != Officer)
		{
			IterDistance = VSize(Officer.Location - IterOfficer.Location);

			if ((ClosestOfficer == None) || (IterDistance < ClosestDistance))
			{
				ClosestDistance = IterDistance;
				ClosestOfficer  = IterOfficer;
			}
		}
	}

	return ClosestOfficer;
}

///////////////////////////////////////////////////////////////////////////////
//
// Speech Requests

function TriggerEnemyFleeingSpeech(Pawn Enemy)
{
	local int i;
	local Pawn Officer;

	// if anyone can has a line of sight to the enemy, play the speech
	for(i=0; i<squad().pawns.length; ++i)
	{
		Officer = squad().pawns[i];

		if (Officer.LineOfSightTo(Enemy))
		{
			ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerSuspectFleeingSpeech(Enemy);
		}
	}
}

function TriggerSuspectDownSpeech(Pawn Enemy)
{	
	local Pawn ClosestOfficer;

	ClosestOfficer = GetClosestOfficerTo(Enemy, true);

	if (ClosestOfficer != None)
	{
		ISwatOfficer(ClosestOfficer).GetOfficerSpeechManagerAction().TriggerSuspectDownSpeech(Enemy);
	}
}

function TriggerHostageDownSpeech(Pawn Hostage)
{	
	local Pawn ClosestOfficer;

	ClosestOfficer = GetClosestOfficerTo(Hostage, true);

	if (ClosestOfficer != None)
	{
		ISwatOfficer(ClosestOfficer).GetOfficerSpeechManagerAction().TriggerHostageDownSpeech(Hostage);
	}
}

function TriggerOfficerDownSpeech(Pawn Officer)
{
	local Pawn ClosestOfficer;	

	ClosestOfficer = GetClosestOfficerTo(Officer, true);

	// they're all dead if this is the case
	if (ClosestOfficer != None)
	{
		ISwatOfficer(ClosestOfficer).GetOfficerSpeechManagerAction().TriggerOfficerDownSpeech();
	}
}

function TriggerLeadDownSpeech(Pawn Lead)
{
	local Pawn ClosestOfficer;	

	ClosestOfficer = GetClosestOfficerTo(Lead, true);

	// they're all dead if this is the case
	if (ClosestOfficer != None)
	{
		ISwatOfficer(ClosestOfficer).GetOfficerSpeechManagerAction().TriggerLeadDownSpeech();
	}
}

function TriggerSuspectWontComplySpeech(Pawn Suspect)
{
	local Pawn ClosestOfficer;	

	ClosestOfficer = GetClosestOfficerTo(Suspect, true);

	// they're all dead if this is the case
	if (ClosestOfficer != None)
	{
		ISwatOfficer(ClosestOfficer).GetOfficerSpeechManagerAction().TriggerSuspectWontComplySpeech(Suspect);
	}
}

function TriggerHostageWontComplySpeech(Pawn Hostage)
{
	local Pawn ClosestOfficer;	

	ClosestOfficer = GetClosestOfficerTo(Hostage, true);

	// they're all dead if this is the case
	if (ClosestOfficer != None)
	{
		ISwatOfficer(ClosestOfficer).GetOfficerSpeechManagerAction().TriggerHostageWontComplySpeech(Hostage);
	}
}

function TriggerReactedFirstShotSpeech(Pawn OfficerShot)
{
	local Pawn ClosestOfficer;

	ClosestOfficer = GetClosestOfficerToOfficer(OfficerShot);

	// they're all dead if this is the case
	if (ClosestOfficer != None)
	{
		ISwatOfficer(ClosestOfficer).GetOfficerSpeechManagerAction().TriggerReactedFirstShotSpeech();
	}
}

function TriggerReactedSecondShotSpeech(Pawn OfficerShot)
{
	local Pawn ClosestOfficer;

	ClosestOfficer = GetClosestOfficerToOfficer(OfficerShot);

	// they're all dead if this is the case
	if (ClosestOfficer != None)
	{
		ISwatOfficer(ClosestOfficer).GetOfficerSpeechManagerAction().TriggerReactedSecondShotSpeech();
	}
}

function TriggerReactedThirdShotSpeech(Pawn OfficerShot)
{
	local Pawn ClosestOfficer;

	ClosestOfficer = GetClosestOfficerToOfficer(OfficerShot);

	// they're all dead if this is the case
	if (ClosestOfficer != None)
	{
		ISwatOfficer(ClosestOfficer).GetOfficerSpeechManagerAction().TriggerReactedThirdShotSpeech();
	}
}

function TriggerTargetCompliantSpeech(Pawn Target)
{
	local Pawn OfficerIter;
	local int i;

	for(i=0; i<squad().pawns.length; ++i)
	{
		OfficerIter = squad().pawns[i];

		if (OfficerIter.LineOfSightTo(Target))
		{
			ISwatOfficer(OfficerIter).GetOfficerSpeechManagerAction().TriggerTargetCompliantSpeech(Target);
			break;
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'ElementSpeechManagerGoal'
}
