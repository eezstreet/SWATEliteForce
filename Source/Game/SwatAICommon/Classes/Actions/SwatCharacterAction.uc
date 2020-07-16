///////////////////////////////////////////////////////////////////////////////
// SwatCharacterAction.uc - SwatCharacterAction class
// The base Action class for all Swat Tyrion Character Actions

class SwatCharacterAction extends Tyrion.AI_CharacterAction
	abstract
	config(AI)
    native;

///////////////////////////////////////////////////////////////////////////////

var protected Pawn      m_pawn;
var protected LevelInfo Level;

var config float		MinInitialDelayTime;
var config float		MaxInitialDelayTime;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
	m_Pawn = AI_CharacterResource(r).m_pawn;
    assert(m_Pawn != None);
    
    Level = m_Pawn.Level;

    super.initAction(r, goal);
}

function SetPawn(Pawn inPawn)
{
	assert(inPawn != None);
	m_Pawn = inPawn;
}

///////////////////////////////////////////////////////////////////////////////
//
// Senses

function DisableSenses(optional bool bPermanently)
{
	assert(m_Pawn != None);

	ISwatAI(m_Pawn).DisableVision(bPermanently);
	ISwatAI(m_Pawn).DisableHearing(bPermanently);
}

function EnableSenses()
{
	assert(m_Pawn != None);

	ISwatAI(m_Pawn).EnableVision();
	ISwatAI(m_Pawn).EnableHearing();
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

protected latent function SleepInitialDelayTime(bool bClaimChildResources)
{
	local float DelayTime;

	DelayTime = RandRange(MinInitialDelayTime, MaxInitialDelayTime);
	
	if (m_Pawn.logTyrion)
		log(Name $ " DelayTime is: " $ DelayTime);

	if (DelayTime > 0.0)
	{
		if (bClaimChildResources)
			useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);

		sleep(DelayTime);

		if (bClaimChildResources)
		{
			clearDummyGoals();
		}
	}
}

// wait for zulu command to be issued
latent function WaitForZulu()
{
	local SwatAIRepository SwatAIRepo;
	local OfficerTeamInfo team;

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);

	if ( SwatAIRepo.GetRedSquad().IsOfficerOnTeam(m_Pawn) )
		team = SwatAIRepo.GetRedSquad();
	else
		team = SwatAIRepo.GetBlueSquad();

	if (m_Pawn.logTyrion && (team.IsHoldingCommandGoal() || SwatAIRepo.GetElementSquad().IsHoldingCommandGoal()))
		log(Name @ "WAITING for Zulu");

	while (team.IsHoldingCommandGoal() || SwatAIRepo.GetElementSquad().IsHoldingCommandGoal())
	{
		yield();
	}
}

// returns true if the character is falling in
function bool IsFallingIn()
{
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);

	if(SwatAIRepo.GetElementSquad().IsExecutingCommandGoal())
	{
		return SwatAIRepo.GetElementSquad().IsFallingIn();
	}
	else if(SwatAIRepo.GetRedSquad().IsOfficerOnTeam(m_Pawn))
	{
		return SwatAIRepo.GetRedSquad().IsFallingIn();
	}
	else
	{
		return SwatAIRepo.GetBlueSquad().IsFallingIn();
	}
}

// returns true if the character is moving to a destination
function bool IsMovingTo()
{
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);

	if(SwatAIRepo.GetElementSquad().IsExecutingCommandGoal())
	{
		return SwatAIRepo.GetElementSquad().IsMovingTo();
	}
	else if(SwatAIRepo.GetRedSquad().IsOfficerOnTeam(m_Pawn))
	{
		return SwatAIRepo.GetRedSquad().IsMovingTo();
	}
	else
	{
		return SwatAIRepo.GetBlueSquad().IsMovingTo();
	}
}