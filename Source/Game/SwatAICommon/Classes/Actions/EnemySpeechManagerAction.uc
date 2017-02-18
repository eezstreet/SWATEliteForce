///////////////////////////////////////////////////////////////////////////////
// EnemySpeechManagerAction.uc - the EnemySpeechManagerAction class
// this action is used by Enemies to organize their speech

class EnemySpeechManagerAction extends CharacterSpeechManagerAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Speech Requests

function TriggerOfficerEncounteredSpeech()
{
	if (ISwatEnemy(m_Pawn).GetEnemyCommanderAction().WasSurprised())
	{
		TriggerSpeech('AnnouncedSpottedOfficerSurprised');
	}
	else if (! ISwatAI(m_Pawn).IsAggressive() && (ISwatEnemy(m_Pawn).GetEnemySkill() < EnemySkill_High))
	{
		TriggerSpeech('AnnouncedSpottedOfficerScared');
	}
	else
	{
		TriggerSpeech('AnnouncedSpottedOfficer');
	}
}

function TriggerDoorBlockedSpeech()
{
	TriggerSpeech('DoorBlocked', true);
}

function TriggerDoorOpeningSpeech()
{
	TriggerSpeech('ShotAtBreachedDoor', true);
}

function TriggerFleeSpeech()
{
	TriggerSpeech('AnnouncedFlee');
}

function TriggerCallForHelpSpeech()
{
	TriggerSpeech('CalledForHelp');
}

function TriggerInvestigateSpeech()
{
	TriggerSpeech('AnnouncedInvestigate', true);
}

function TriggerBarricadeSpeech()
{
	TriggerSpeech('AnnouncedBarricade', true);
}

function TriggerUncompliantSpeech()
{
	TriggerSpeech('AnnouncedNonCompliant', true);
}

function TriggerDownedOfficerSpeech()
{
	TriggerSpeech('ReactedDownOfficer');
}

function TriggerDownedSuspectSpeech()
{
	TriggerSpeech('ReactedDownSuspect');
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}