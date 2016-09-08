///////////////////////////////////////////////////////////////////////////////
//
// OfficerRedOne.uc - the OfficerRedOne class

class OfficerRedOne extends SwatOfficer;

var private IAmReportableCharacter CurrentReportableCharacter;
///////////////////////////////////////////////////////////////////////////////

function PreBeginPlay()
{
    Super.PreBeginPlay();

    Label = 'OfficerRedOne';
}

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

protected function AddToSquads()
{
	local SwatAIRepository SwatAIRepo;
	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	SwatAIRepo.GetRedSquad().addToSquad(self);
	SwatAIRepo.GetElementSquad().addToSquad(self);
}

protected function RemoveFromSquads()
{
	local SwatAIRepository SwatAIRepo;
	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	SwatAIRepo.GetRedSquad().removeFromSquad(self);
	SwatAIRepo.GetElementSquad().removeFromSquad(self);

	SwatAIRepo.GetRedSquad().memberDied(self);
	SwatAIRepo.GetElementSquad().memberDied(self);
}

///////////////////////////////////////

// Provides the effect event name to use when this ai is being reported to
// TOC. Overridden from SwatAI
simulated function name GetEffectEventForReportingToTOCWhenIncapacitated()  { return 'ReportedR1DownToTOC'; }

//////////////////////////////////////

function ReportToTOC(name EffectEventName, name ReplyEventName, Actor other, SwatGamePlayerController controller)
{
  log("ReportToTOC("$EffectEventName$", "$ReplyEventName$", "$other$", "$controller$")");
  TriggerEffectEvent( EffectEventName, other, , , , , , IEffectObserver(controller), 'OfficerRedOne' );
}

function IAmReportableCharacter GetCurrentReportableCharacter()
{
  return CurrentReportableCharacter;
}

function SetCurrentReportableCharacter(IAmReportableCharacter InChar)
{
  CurrentReportableCharacter = InChar;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	OfficerLoadOutType="OfficerRedOneLoadOut"
	OfficerFriendlyName="Officer Red One"
}
