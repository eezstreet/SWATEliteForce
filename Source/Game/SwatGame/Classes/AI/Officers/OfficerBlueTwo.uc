///////////////////////////////////////////////////////////////////////////////
//
// OfficerBlueTwo.uc - the OfficerBlueTwo class

class OfficerBlueTwo extends SwatOfficer;
///////////////////////////////////////////////////////////////////////////////

function PreBeginPlay()
{
    Super.PreBeginPlay();

    Label = 'OfficerBlueTwo';
}

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

protected function AddToSquads()
{
	local SwatAIRepository SwatAIRepo;
	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	SwatAIRepo.GetBlueSquad().addToSquad(self);
	SwatAIRepo.GetElementSquad().addToSquad(self);
}

protected function RemoveFromSquads()
{
	local SwatAIRepository SwatAIRepo;
	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	SwatAIRepo.GetBlueSquad().removeFromSquad(self);
	SwatAIRepo.GetElementSquad().removeFromSquad(self);

	SwatAIRepo.GetBlueSquad().memberDied(self);
	SwatAIRepo.GetElementSquad().memberDied(self);
}

///////////////////////////////////////

// Provides the effect event name to use when this ai is being reported to
// TOC. Overridden from SwatAI
simulated function name GetEffectEventForReportingToTOCWhenIncapacitated()  { return 'ReportedB2DownToTOC'; }


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	OfficerLoadOutType="OfficerBlueTwoLoadOut"
	OfficerFriendlyName="Officer Blue Two"
}
