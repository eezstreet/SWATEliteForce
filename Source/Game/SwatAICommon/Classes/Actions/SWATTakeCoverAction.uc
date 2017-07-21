///////////////////////////////////////////////////////////////////////////////
//
// Tyrion goal for an AI taking cover. This action will cause the AI to
// attempt to take cover in the AI's current room only.
//

class SWATTakeCoverAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

var protected AICoverFinder AICoverFinder;

var protected bool m_tookCover;
var protected AICoverFinder.AICoverResult CoverResult;

var private	MoveToLocationGoal	CurrentMoveToLocationGoal;

///////////////////////////////////////////////////////////////////////////////

function initAction(AI_Resource r, AI_Goal goal)
{
    local ISwatAI swatAI;

    super.initAction(r, goal);

	// subclasses may set the AI Cover finder before initAction (in their selection heuristic function)
	if (AICoverFinder == None)
	{
		swatAI = ISwatAI(m_pawn);
		if (swatAI != None)
		{
			AICoverFinder = swatAI.GetCoverFinder();
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}

	ResetFullBodyAnimations();
}

///////////////////////////////////////////////////////////////////////////////
//
// Animation Swapping

function SwapInFullBodyTakeCoverAnimations()
{
	if (m_Pawn.IsA('SwatOfficer'))
	{
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_LowReady, kUBABCI_TakeCoverAndAttackAction);
	}
}

function ResetFullBodyAnimations()
{
	if (m_Pawn.IsA('SwatOfficer'))
	{
		ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_TakeCoverAndAttackAction);
	}
}

///////////////////////////////////////////////////////////////////////////////

protected latent function NotifyFoundCover()
{
	// base take cover just swaps in the full body cover animations
	SwapInFullBodyTakeCoverAnimations();
}

protected latent function MoveToTakeCover(vector Destination)
{
	assert(CurrentMoveToLocationGoal == None);

	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " MoveToTakeCover - Destination is: " $ Destination);

	CurrentMoveToLocationGoal = new class'MoveToLocationGoal'(AI_MovementResource(m_pawn.MovementAI), achievingGoal.priority, Destination);
    assert(CurrentMoveToLocationGoal != none);
	CurrentMoveToLocationGoal.AddRef();

	CurrentMoveToLocationGoal.SetWalkThreshold(0.0);
	CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToLocationGoal.SetAcceptNearbyPath(true);

	// we want to use cover while moving
	CurrentMoveToLocationGoal.SetUseCoveredPaths();

    CurrentMoveToLocationGoal.postGoal(self);
    WaitForGoal(CurrentMoveToLocationGoal);
    CurrentMoveToLocationGoal.unPostGoal(self);

	CurrentMoveToLocationGoal.Release();
	CurrentMoveToLocationGoal = None;
}

protected latent function TakeCover()
{
    m_tookCover = false;

	assert(m_Pawn != None);
	assert(SwatCharacterResource(m_Pawn.characterAI).CommonSensorAction != None);
	assert(SwatCharacterResource(m_Pawn.characterAI).CommonSensorAction.GetVisionSensor() != None);

    CoverResult = AICoverFinder.FindCover(SwatCharacterResource(m_Pawn.characterAI).CommonSensorAction.GetVisionSensor().Pawns,
        kAICLT_NearestSide);
    if (CoverResult.coverLocationInfo != kAICLI_NotInCover)
    {
		// notification
		NotifyFoundCover();

		if (m_Pawn.logAI)
	        log("Taking cover at: "$CoverResult.coverLocation);
		
		MoveToTakeCover(CoverResult.coverLocation);
        
		ResetFullBodyAnimations();

        // @TODO: Fix this. Crouching needs to be handled better at a higher level
        if (CoverResult.coverLocationInfo == kAICLI_InLowCover)
        {
            m_pawn.ShouldCrouch(true);
        }

		m_tookCover = true;
    }
}

///////////////////////////////////////

state Running
{
Begin:
    TakeCover();

    if (m_tookCover)
    {
        succeed();
    }
    else
    {
        fail(ACT_NO_COVER_FOUND);
    }
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    satisfiesGoal = class'SWATTakeCoverGoal'
}

///////////////////////////////////////////////////////////////////////////////
