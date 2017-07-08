///////////////////////////////////////////////////////////////////////////////
// ElementSquadInfo.uc - the ElementSquadInfo class
// this is the leaf class for the entire Officer element

class ElementSquadInfo extends OfficerTeamInfo
	native;
///////////////////////////////////////////////////////////////////////////////

var private ElementSpeechManagerGoal	ElementSpeechManagerGoal;
var private ElementSpeechManagerAction	ElementSpeechManager;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

event PostBeginPlay()
{
	// have to call this before calling InitAbilities because the SquadAI 
	// is created in a parent class
	Super.PostBeginPlay();

	PostSpeechManagerGoal();
}

protected function InitAbilities()
{
	Super.InitAbilities();

	SquadAI.addAbility( new class'ElementSpeechManagerAction' );
}

private function PostSpeechManagerGoal()
{
	ElementSpeechManagerGoal = new class'ElementSpeechManagerGoal'(AI_Resource(SquadAI));
	assert(ElementSpeechManagerGoal != None);
	ElementSpeechManagerGoal.AddRef();

	ElementSpeechManagerGoal.postGoal(None);
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

event Destroyed()
{
	super.Destroyed();

	ElementSpeechManager = None;

	if (ElementSpeechManagerGoal != None)
	{
		ElementSpeechManagerGoal.Release();
		ElementSpeechManagerGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

private function ElementSpeechManagerAction GetElementSpeechManagerAction()
{
	assert(ElementSpeechManagerGoal != None);
	assert(ElementSpeechManagerGoal.achievingAction != None);
	assert(ElementSpeechManagerAction(ElementSpeechManagerGoal.achievingAction) != None);

	return ElementSpeechManagerAction(ElementSpeechManagerGoal.achievingAction);
}


///////////////////////////////////////////////////////////////////////////////
//
// Command Goals

// remove the command goal from ourselves, as well as the blue and red squads
protected function UnpostCommandGoals()
{
	local OfficerTeamInfo RedSquad, BlueSquad;

	// clear our own command goal out
	ClearCommandGoal();

	// clear out the red and blue squads
	RedSquad  = SwatAIRepo.GetRedSquad();
	BlueSquad = SwatAIRepo.GetBlueSquad();

	RedSquad.ClearCommandGoal();
	BlueSquad.ClearCommandGoal();
}

// removes any command goals from the element to pass to the other team
// TeamInfo should either be the Red or Blue Team
function RemoveCommandGoalsFor(OfficerTeamInfo TeamInfo)
{
	local SquadCommandGoal NewCommandGoal;
	local OfficerTeamInfo RedSquad, BlueSquad;
	assert(TeamInfo != None);
	assert(TeamInfo != self);

	// if the element a command goal and we should create the command goal on a sub-element (Red or Blue team)
	if (IsExecutingCommandGoal())
	{
		RedSquad  = SwatAIRepo.GetRedSquad();
		BlueSquad = SwatAIRepo.GetBlueSquad();

		if (CurrentSquadCommandGoal.ShouldRepostElementGoalOnSubElementSquad())
		{
			// if the team getting a new command is the red team
			if (TeamInfo == RedSquad)
			{
				// if the blue squad doesn't have a command goal, give them the one the element has
				if (! BlueSquad.IsExecutingCommandGoal() && BlueSquad.CanExecuteCommand())
				{
					NewCommandGoal = CreateCommandGoalFromTemplate(BlueSquad, CurrentSquadCommandGoal);
					assert(NewCommandGoal != None);

					BlueSquad.InternalPostCommandGoal(NewCommandGoal);
				}
			}
			else 
			{
				// sanity check
				assert(TeamInfo == BlueSquad);

				// if the red squad doesn't have a command goal, give them the one the element has
				if (! RedSquad.IsExecutingCommandGoal() && RedSquad.CanExecuteCommand())
				{
					NewCommandGoal = CreateCommandGoalFromTemplate(RedSquad, CurrentSquadCommandGoal);
					assert(NewCommandGoal != None);

					RedSquad.InternalPostCommandGoal(NewCommandGoal);
				}
			}

			// unPost the squad command goal after the templates are copied
			// so we don't null out any references
			CurrentSquadCommandGoal.unPostGoal(None);
		}
		else
		{
			// need to trigger some speech to let the player know we're not doing anything
			if ((TeamInfo == RedSquad) && ! BlueSquad.IsExecutingCommandGoal())
			{
				ColoredSquadInfo(BlueSquad).TriggerNeedOrdersSpeech();
			}
			else if ((TeamInfo == BlueSquad) && ! RedSquad.IsExecutingCommandGoal())
			{	
				ColoredSquadInfo(RedSquad).TriggerNeedOrdersSpeech();
			}
		}
	}

	// now clear out our command goal
	ClearCommandGoal();
}

// given a team and a command goal template, make a new goal based on the goal template for the team
private function SquadCommandGoal CreateCommandGoalFromTemplate(OfficerTeamInfo TeamInfo, SquadCommandGoal CommandGoalTemplate)
{
	local SquadCommandGoal NewCommandGoal;

	assert(CommandGoalTemplate != None);

	NewCommandGoal = new CommandGoalTemplate.Class(AI_Resource(TeamInfo.SquadAI));
	assert(NewCommandGoal != None);

	NewCommandGoal.copyParametersFrom(CommandGoalTemplate);

	// copy any additional variables from the existing template to the new command goal
	NewCommandGoal.CopyAdditionalPropertiesFromTemplate(CommandGoalTemplate);

	// let the goal know that it's a copy
	NewCommandGoal.SetHasBeenCopied();

	return NewCommandGoal;
}

///////////////////////////////////////////////////////////////////////////////
//
// Speech Triggers

private function bool CanSpeak()
{
	local int i;
	
	for (i=0; i<pawns.length; ++i)
	{
		// we can speak if we have any members in our squad are alive
		if (class'Pawn'.static.checkConscious(pawns[i]))
			return true;
	}
	
	return false;
}

function TriggerEnemyFleeingSpeech(Pawn Enemy)
{
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerEnemyFleeingSpeech(Enemy);
	}
}

function TriggerSuspectDownSpeech(Pawn Enemy)
{	
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerSuspectDownSpeech(Enemy);
	}
}

function TriggerHostageDownSpeech(Pawn Hostage)
{	
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerHostageDownSpeech(Hostage);
	}
}

function TriggerOfficerDownSpeech(Pawn Officer)
{
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerOfficerDownSpeech(Officer);
	}
}

function TriggerLeadDownSpeech(Pawn Lead)
{
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerLeadDownSpeech(Lead);
	}
}

function TriggerSuspectWontComplySpeech(Pawn Suspect)
{
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerSuspectWontComplySpeech(Suspect);
	}
}

function TriggerHostageWontComplySpeech(Pawn Hostage)
{
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerHostageWontComplySpeech(Hostage);
	}
}

function TriggerReactedFirstShotSpeech(Pawn OfficerShot)
{
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerReactedFirstShotSpeech(OfficerShot);
	}
}

function TriggerReactedSecondShotSpeech(Pawn OfficerShot)
{
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerReactedSecondShotSpeech(OfficerShot);
	}
}

function TriggerReactedThirdShotSpeech(Pawn OfficerShot)
{
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerReactedThirdShotSpeech(OfficerShot);
	}
}

function TriggerTargetCompliantSpeech(Pawn Target)
{
	if (CanSpeak())
	{
		GetElementSpeechManagerAction().TriggerTargetCompliantSpeech(Target);
	}
}

function TriggerTeamReportedSpeech(Pawn Officer)
{
	ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerElementReportedSpeech();
}