///////////////////////////////////////////////////////////////////////////////
// ConverseWithHostagesAction.uc - ConverseWithHostagesAction class
// Action class that causes Enemies to converse with Hostages

class ConverseWithHostagesAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum EnemyState from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// config
var config float						ConverseChance;
var config float						SubsequentEnemyResponseChance;

var config float						MinPlayerDistanceForConversation;

var config name							EnemyTalkToHostageTriggerEffectEvent;
var config name							HostageReplyToEnemyTriggerEffectEvent;
var config name							EnemyReplyToHostageTriggerEffectEvent;

var config float						MinSleepTimeBetweenSpeech;
var config float						MaxSleepTimeBetweenSpeech;

var config float						MinTimeBetweenConversing;
var config float						MaxTimeBetweenConversing;

// hostage
var private Pawn						TargetHostage;

// behaviors we use
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	// in case we don't get to unset it ourselves
	SwatAIRepository(Level.AIRepo).DeactivateEnemyHostageConversation(m_Pawn);
}

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

// returns true if we found a target hostage
private function bool FindTargetHostage()
{
	local Pawn Iter, ClosestTarget;
	local float IterDistance, ClosestDistance;

	for(Iter = Level.pawnList; Iter != None; Iter = Iter.nextPawn)
	{
		if (class'Pawn'.static.checkConscious(Iter) && Iter.IsA('SwatHostage') && Iter.IsInRoom(m_Pawn.GetRoomName()))
		{
			if ((ClosestTarget == None) || (IterDistance < ClosestDistance))
			{
				ClosestTarget   = Iter;
				ClosestDistance = IterDistance;
			}
		}
	}

	TargetHostage = ClosestTarget;
	return (TargetHostage != None);
}

private function bool CanPlayerHearConversation(bool bUsePropogationDistance)
{
	local Pawn Player;
	local Controller Iter;

	if (Level.NetMode == NM_Standalone)
	{
		Player = Level.GetLocalPlayerController().Pawn;

		if (class'Pawn'.static.checkConscious(Player))
		{
			if ((!bUsePropogationDistance && VSize(m_Pawn.Location - Player.Location) < MinPlayerDistanceForConversation) ||
				(bUsePropogationDistance && m_Pawn.Controller.GetDistanceToSound(Player, m_Pawn.Location, Player.Location) < MinPlayerDistanceForConversation))
			{
				return true;
			}
		}
	}
	else
	{
		// we should be a coop game
		assert(Level.IsCOOPServer);

		for(Iter = Level.ControllerList; Iter != None; Iter=Iter.NextController)
		{
			if (Iter.IsA('PlayerController'))
			{
				Player = Iter.Pawn;
				
				if (class'Pawn'.static.checkConscious(Player))
				{
					if ((!bUsePropogationDistance && VSize(m_Pawn.Location - Player.Location) < MinPlayerDistanceForConversation) ||
						(bUsePropogationDistance && m_Pawn.Controller.GetDistanceToSound(Player, m_Pawn.Location, Player.Location) < MinPlayerDistanceForConversation))
					{
						return true;
					}
				}
			}
		}
	}

	// player isn't within the necessary distance
	return false;
}

// returns true if the enemy is in the correct state for talking with hostages, if the level doesn't say there shouldn't be conversations
// otherwise returns false
private function bool CanEnemiesConverseWithHostages()
{
	local EnemyState CurrentEnemyState;

	// if the level says no enemy / hostage conversations, don't do any
	if (Level.NoEnemyHostageConversations)
		return false;
	
	// if the intro sequence hasn't completed, don't do a conversation
	if (! Level.Game.bPostGameStarted)
		return false;

    CurrentEnemyState = ISwatEnemy(m_Pawn).GetCurrentState();

	if (Level.EnemiesAlwaysTalkToHostages)
	{
		return (CurrentEnemyState <= EnemyState_Suspicious);
	}
	else
	{
		return (CurrentEnemyState == EnemyState_Unaware);
	}
}

function float selectionHeuristic( AI_Goal goal )
{	
	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	} 
	assert(m_Pawn.IsA('SwatEnemy'));

	// if we don't have a pointer to the level yet, set it
	if (Level == None)
	{
		Level = m_Pawn.Level;
		assert(Level != None);
	}

	// if the random die roll passes, the enemies are allowed to converse with hostages, 
	// the player can hear the conversation, and there is an hostage that the enemy can converse with
	if ((FRand() <= ConverseChance) && CanEnemiesConverseWithHostages() && CanPlayerHearConversation(false) && FindTargetHostage())
	{
		return 1.0;
	}
	else
	{
		return 0.0;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

private latent function RotateToFaceTarget()
{
	assert(TargetHostage != None);

	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, rotator(TargetHostage.Location - m_Pawn.Location));
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

private latent function ConverseWithTarget()
{
	// randomly choose to have the hostage or enemy talk firsts, if the hostage talks first then don't play the enemy response
	if (FRand() < 0.5)
	{
		ISwatAI(TargetHostage).LatentAITriggerEffectEvent(HostageReplyToEnemyTriggerEffectEvent,,,,,,true);

		sleep(RandRange(MinSleepTimeBetweenSpeech, MaxSleepTimeBetweenSpeech));

		ISwatAI(m_Pawn).LatentAITriggerEffectEvent(EnemyTalkToHostageTriggerEffectEvent,,,,,,true);
	}
	else
	{
		ISwatAI(m_Pawn).LatentAITriggerEffectEvent(EnemyTalkToHostageTriggerEffectEvent,,,,,,true);

		sleep(RandRange(MinSleepTimeBetweenSpeech, MaxSleepTimeBetweenSpeech));

		ISwatAI(TargetHostage).LatentAITriggerEffectEvent(HostageReplyToEnemyTriggerEffectEvent,,,,,,true);

		if (FRand() <= SubsequentEnemyResponseChance)
		{
			sleep(RandRange(MinSleepTimeBetweenSpeech, MaxSleepTimeBetweenSpeech));

			ISwatAI(m_Pawn).LatentAITriggerEffectEvent(EnemyReplyToHostageTriggerEffectEvent,,,,,,true);

			if (m_Pawn.logAI)
				log(m_Pawn.Name $ " replied to hostage " $ TargetHostage.Name);
		}
	}
}

state Running
{
 Begin:
	useResources(class'AI_Resource'.const.RU_ARMS);

	RotateToFaceTarget();

	useResources(class'AI_Resource'.const.RU_LEGS);

	// if the player can really hear the conversation, and there's not already one going on, play the conversation
	// otherwise sleep a bit and try again later
	if (CanPlayerHearConversation(true) && !SwatAIRepository(Level.AIRepo).IsEnemyHostageConversationActive())
	{
		SwatAIRepository(Level.AIRepo).ActivateEnemyHostageConversation(m_Pawn);
		ConverseWithTarget();
		SwatAIRepository(Level.AIRepo).DeactivateEnemyHostageConversation(m_Pawn);
		instantSucceed();
	}
	else
	{
		sleep(RandRange(MinTimeBetweenConversing, MaxTimeBetweenConversing));

		// fail so we can happen again
		instantFail(ACT_GENERAL_FAILURE);
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'ConverseWithHostagesGoal'
}
