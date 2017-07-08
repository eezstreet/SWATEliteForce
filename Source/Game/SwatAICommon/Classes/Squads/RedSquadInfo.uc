///////////////////////////////////////////////////////////////////////////////
// RedSquadInfo.uc - the RedSquadInfo class
// this is the leaf class for the Officer Red team

class RedSquadInfo extends ColoredSquadInfo
	native;
///////////////////////////////////////////////////////////////////////////////

// overridden from ColoredSquadInfo
protected function TriggerSquadSpecificNeedOrdersSpeech(Pawn OfficerSpeaker)
{
	assert(class'Pawn'.static.checkConscious(OfficerSpeaker));

	ISwatOfficer(OfficerSpeaker).GetOfficerSpeechManagerAction().TriggerRedTeamNeedsOrdersSpeech();
}

function TriggerTeamReportedSpeech(Pawn Officer)
{
	ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerRedTeamReportedSpeech();
}