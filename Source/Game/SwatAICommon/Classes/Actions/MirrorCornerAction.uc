///////////////////////////////////////////////////////////////////////////////
// MirrorCornerAction.uc - MirrorCornerAction class
// The Action that causes the Officers to mirror a corner

class MirrorCornerAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) Actor					TargetMirrorPoint;

// behaviors we use
var private MoveToLocationGoal			CurrentMoveToLocationGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var private UseOptiwandGoal				CurrentUseOptiwandGoal;

// direction we mirror in
var private Rotator						MirrorCornerRotation;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if (CurrentUseOptiwandGoal != None)
	{
		CurrentUseOptiwandGoal.Release();
		CurrentUseOptiwandGoal = None;
	}

	// unlock aim
	ISwatAI(m_Pawn).UnlockAim();

	// make sure we re-enable collision avoidance
	m_Pawn.EnableCollisionAvoidance();
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveToMirrorPoint()
{
	// move the officer to the location
	CurrentMoveToLocationGoal = new class'MoveToLocationGoal'(movementResource(), achievingGoal.priority, IMirrorPoint(TargetMirrorPoint).GetMirroringFromPoint());
	assert(CurrentMoveToLocationGoal != None);
	CurrentMoveToLocationGoal.AddRef();

	CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToLocationGoal.PostGoal(self);
	WaitForGoal(CurrentMoveToLocationGoal);
	CurrentMoveToLocationGoal.unPostGoal(self);

	CurrentMoveToLocationGoal.Release();
	CurrentMoveToLocationGoal = None;
}

latent function RotateToMirrorCorner()
{
	local vector MirrorToPoint;

	MirrorToPoint        = IMirrorPoint(TargetMirrorPoint).GetMirroringToPoint();
	MirrorCornerRotation = rotator(MirrorToPoint - m_Pawn.Location);

//	m_Pawn.Level.GetLocalPlayerController().myHUD.AddDebugLine(m_Pawn.Location, MirrorToPoint, class'Engine.Canvas'.Static.MakeColor(255,200,200));

	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, MirrorCornerRotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;

	ISwatAI(m_Pawn).AimToRotation(MirrorCornerRotation);
	ISwatAI(m_Pawn).LockAim();
	ISwatAI(m_Pawn).AnimSnapBaseToAim();
}

latent function MirrorAroundCorner()
{
	CurrentUseOptiwandGoal = new class'UseOptiwandGoal'(weaponResource(), vector(MirrorCornerRotation));
	assert(CurrentUseOptiwandGoal != None);
	CurrentUseOptiwandGoal.AddRef();

	CurrentUseOptiwandGoal.SetMirrorAroundCorner();

	CurrentUseOptiwandGoal.postGoal(self);
	WaitForGoal(CurrentUseOptiwandGoal);
	CurrentUseOptiwandGoal.unPostGoal(self);

	CurrentUseOptiwandGoal.Release();
	CurrentUseOptiwandGoal = None;
}

state Running
{
Begin:
	useResources(class'AI_Resource'.const.RU_ARMS);

	MoveToMirrorPoint();

	// disable collision avoidance while we're mirroring
	m_Pawn.DisableCollisionAvoidance();

	RotateToMirrorCorner();

	useResources(class'AI_Resource'.const.RU_LEGS);

	clearDummyWeaponGoal();
	MirrorAroundCorner();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'MirrorCornerGoal'
}
