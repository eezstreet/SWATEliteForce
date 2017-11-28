///////////////////////////////////////////////////////////////////////////////
// HostageSpeechManagerAction.uc - the HostageSpeechManagerAction class
// this action is used by Enemies to organize their speech

class HostageSpeechManagerAction extends CharacterSpeechManagerAction
	config(AI);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var config array<name>	InDangerSpeechEffectEvents;

///////////////////////////////////////////////////////////////////////////////
//
// Speech Requests

function TriggerUncompliantSpeech()
{
	TriggerSpeech('AnnouncedNonCompliant', true);
}

function TriggerDownedHostageSpeech()
{
	TriggerSpeech('ReactedHostageDown');
}

function TriggerDownedOfficerSpeech()
{
	TriggerSpeech('ReactedOfficerDown');
}

function TriggerFleeSpeech()
{
	TriggerSpeech('AnnouncedFlee');
}

function TriggerDoorBlockedSpeech()
{
	TriggerSpeech('DoorBlocked', true);
}

function TriggerInDangerSpeech()
{
	TriggerSpeech(InDangerSpeechEffectEvents[Rand(InDangerSpeechEffectEvents.Length)], true);
}

function TriggerSpottedOfficerNormalSpeech()
{
	TriggerSpeech('AnnouncedSpottedOfficer');
}

function TriggerSpottedOfficerScaredSpeech()
{
	TriggerSpeech('AnnouncedSpottedOfficerScared');
}

function TriggerSpottedOfficerSurprisedSpeech()
{
	TriggerSpeech('AnnouncedSpottedOfficerSurprised');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
