///////////////////////////////////////////////////////////////////////////////
// IncapacitatedAction.uc - IncapacitatedAction class
// The action that causes the AI to be incapacitated

class IncapacitatedAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum ESkeletalRegion from Engine.Actor;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) name			IncapaciatedIdleCategoryOverride;
var(parameters) bool			bIsInstantIncapacitation;

// config
var config float				MinTimeBeforeTriggeringIncapacitatedSpeech;
var config float				MaxTimeBeforeTriggeringIncapacitatedSpeech;

var config float				MinTimeBetweenTriggeringIncapacitatedSpeech;
var config float				MaxTimeBetweenTriggeringIncapacitatedSpeech;

var config float				DistanceToHearIncapacitatedSpeech;

///////////////////////////////////////////////////////////////////////////////
//
// Queries

function bool IsRagdollIncapacitation()
{
	return (IncapaciatedIdleCategoryOverride == '');
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// Ragdoll Incapacitation

function Convulse()
{
}

private function bool ShouldTriggerIncapacitatedSpeech()
{
	local Pawn Player;
	local Controller Iter;

	// if it's standalone, figure out if the player can hear us speeak
	// otherwise if it's a coop server, go through the players, and see if anyone can hear us
	assert(Level != None);
	if (Level.NetMode == NM_Standalone)
	{
		Player = Level.GetLocalPlayerController().Pawn;
	
        if( Player != None )
        {
		    if (m_Pawn.Controller.GetDistanceToSound(Player, m_Pawn.Location, Player.Location) <= DistanceToHearIncapacitatedSpeech)
			    return true;
        }
	}
	else
	{
		// go through the (alive) players on the server, and see who is close enough
		for (Iter = Level.ControllerList; Iter != None; Iter = Iter.NextController)
		{
			if (Iter.IsA('PlayerController'))
			{
				Player = Iter.Pawn;

                if( Player != None )
                {
				    if (m_Pawn.Controller.GetDistanceToSound(Player, m_Pawn.Location, Player.Location) <= DistanceToHearIncapacitatedSpeech)
					    return true;
                }
			}
		}
	}

	// didn't find anyone close enough
	return false;
}

state Running
{
 Begin:
	if (m_Pawn.logTyrion)
		log(m_Pawn.Name $ " started incapacitated behavior");

	useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);

	if (IsRagdollIncapacitation()) // pawn uses ragdoll physics in incapacitated state
	{
        m_Pawn.BecomeRagdoll();
        // Carlos: Incapacitated ragdoll's handle disabling independently of this action
		//sleep(ISwatAI(m_Pawn).GetRagdollSimulationTimeout());
		//ISwatAI(m_Pawn).DisableRagdoll();
	}
	else  // use an animation to represent the incapacitated state
	{
		m_Pawn.SetCollision(true, false, false);
		ISwatAI(m_Pawn).SetIdleCategory(IncapaciatedIdleCategoryOverride);
	}	

	// if we did an instant incapacitation, wait some amount of time before triggering our incapacitated speech
	if (bIsInstantIncapacitation)
	{
		sleep(RandRange(MinTimeBeforeTriggeringIncapacitatedSpeech, MaxTimeBeforeTriggeringIncapacitatedSpeech));
	}

 Loop:
	// trigger the incapacitated speech, if we should
	if (ShouldTriggerIncapacitatedSpeech())
	{
		ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerIncapacitatedSpeech();
	}

	// wait a random amount of time
	sleep(RandRange(MinTimeBetweenTriggeringIncapacitatedSpeech, MaxTimeBetweenTriggeringIncapacitatedSpeech));

	goto('Loop');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'IncapacitatedGoal'
}