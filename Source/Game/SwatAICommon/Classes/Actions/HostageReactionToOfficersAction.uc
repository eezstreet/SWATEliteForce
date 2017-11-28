///////////////////////////////////////////////////////////////////////////////
// HostageReactionToOfficersAction.uc - HostageReactionToOfficersAction class
// The Action that causes the Hostage AI to run up to an officer and play an animation

class HostageReactionToOfficersAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Pawn					Officer;
var(parameters) bool					bWasInDanger;

// behaviors we use
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var private InitialReactionGoal			CurrentInitialReactionGoal;

// config
var config float						DesiredDistanceToOfficer;

var config name							PointToLeftAnimation;
var config name							PointToRightAnimation;
var config name							PointBehindAnimation;

// private
var private name						PointToThreatAnimation;

// constants
const kMinimumThreatToPoint = 0.1;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	// stop animating on the special channel
	m_Pawn.AnimStopSpecial();

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if (CurrentInitialReactionGoal != None)
	{
		CurrentInitialReactionGoal.Release();
		CurrentInitialReactionGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function RotateToOfficer()
{
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, rotator(Officer.Location - m_Pawn.Location));
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

latent function PlayReactionAnimation(name AnimationName)
{
	local int SpecialChannel;

	// Play the animation and wait for it to finish
    SpecialChannel = m_Pawn.AnimPlaySpecial(AnimationName, 0.2);    

	m_Pawn.FinishAnim(SpecialChannel);
}

// TODO: move somewhere more central?
function Actor GetHighestThreat(float MinimumValue)
{
	local int i;
	local Actor HighestThreatActor;
	local float HighestThreatValue;
	local array<AwarenessProxy.AwarenessKnowledge> PotentiallyVisibleSet;

	PotentiallyVisibleSet = ISwatAI(m_Pawn).GetAwareness().GetPotentiallyVisibleKnowledge();

//	log("PotentiallyVisibleSet.Length is: " $ PotentiallyVisibleSet.Length);

	for(i=0; i<PotentiallyVisibleSet.Length; ++i)
	{
//		log("PotentiallyVisibleSet[i].threat: " $ PotentiallyVisibleSet[i].threat $ " PotentiallyVisibleSet[i].aboutAwarenessPoint: " $ PotentiallyVisibleSet[i].aboutAwarenessPoint);

		if ((PotentiallyVisibleSet[i].threat >= MinimumValue) && (PotentiallyVisibleSet[i].threat > HighestThreatValue))
		{
			HighestThreatValue = PotentiallyVisibleSet[i].threat;
			HighestThreatActor = PotentiallyVisibleSet[i].aboutAwarenessPoint;
		}
	}

	return HighestThreatActor;
}

function name GetThreatAnimation()
{
	local Actor HighestThreat;
	local vector XAxis, YAxis, ZAxis;

	HighestThreat = GetHighestThreat(kMinimumThreatToPoint);
	GetAxes(m_Pawn.Rotation, XAxis, YAxis, ZAxis);

	if (HighestThreat != None)
	{
//		log("HighestThreat.Location Dot XAxis: " $ (Normal(HighestThreat.Location - m_Pawn.Location) Dot XAxis < -0.5) $ " HighestThreat.Location Dot YAxis: " $ (Normal(HighestThreat.Location - m_Pawn.Location) Dot YAxis >= 0.0));
		if (Normal(HighestThreat.Location - m_Pawn.Location) Dot XAxis < -0.5) // 120 degrees behind us
		{
			return PointBehindAnimation;
		}
		else
		{
			if (Normal(HighestThreat.Location - m_Pawn.Location) Dot YAxis >= 0.0)	// to the right
			{
				return PointToRightAnimation;
			}
			else // must be to the left
			{
				return PointToLeftAnimation;
			}
		}
	}

	// it's ok to return nothing
	return '';
}

latent function PlayInitialReaction()
{
	CurrentInitialReactionGoal = new class'InitialReactionGoal'(characterResource(), Officer);
	assert(CurrentInitialReactionGoal != None);
	CurrentInitialReactionGoal.AddRef();

	CurrentInitialReactionGoal.postGoal(self);
	WaitForGoal(CurrentInitialReactionGoal);
	CurrentInitialReactionGoal.unPostGoal(self);

	CurrentInitialReactionGoal.Release();
	CurrentInitialReactionGoal = None;
}

private function TriggerReactionSpeech()
{
    if (bWasInDanger)
    {
        ISwatHostage(m_Pawn).GetHostageSpeechManagerAction().TriggerSpottedOfficerScaredSpeech();
    }
    else
    {
        if (FRand() < 0.5)
        {
            ISwatHostage(m_Pawn).GetHostageSpeechManagerAction().TriggerSpottedOfficerNormalSpeech();
        }
        else
        {
            ISwatHostage(m_Pawn).GetHostageSpeechManagerAction().TriggerSpottedOfficerSurprisedSpeech();
        }
    }
}

state Running
{
Begin:
	useResources(class'AI_Resource'.const.RU_ARMS);

	PointToThreatAnimation = GetThreatAnimation();

	if ((PointToThreatAnimation != '') &&  ! ISwatHostage(m_Pawn).GetHostageCommanderAction().IsInDanger())
	{
		RotateToOfficer();

		useResources(class'AI_Resource'.const.RU_LEGS);

		PlayReactionAnimation(PointToThreatAnimation);
	}
	else
	{
		clearDummyWeaponGoal();

		TriggerReactionSpeech();

		// create an initial reaction behavior
		PlayInitialReaction();
	}

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'HostageReactionToOfficersGoal'
}
