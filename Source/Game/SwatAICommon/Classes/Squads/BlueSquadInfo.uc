///////////////////////////////////////////////////////////////////////////////
// BlueSquadInfo.uc - the BlueSquadInfo class
// this is the leaf class for the Officer Blue team

class BlueSquadInfo extends ColoredSquadInfo
	native;
///////////////////////////////////////////////////////////////////////////////

// overridden from ColoredSquadInfo
protected function TriggerSquadSpecificNeedOrdersSpeech(Pawn OfficerSpeaker)
{
	assert(class'Pawn'.static.checkConscious(OfficerSpeaker));

	ISwatOfficer(OfficerSpeaker).GetOfficerSpeechManagerAction().TriggerBlueTeamNeedsOrdersSpeech();
}

function TriggerTeamReportedSpeech(Pawn Officer)
{
	ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerBlueTeamReportedSpeech();
}