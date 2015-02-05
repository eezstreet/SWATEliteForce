///////////////////////////////////////////////////////////////////////////////
// SwatMovementAction.uc - SwatMovementAction class
// The base Action class for all Swat Tyrion Movement Actions

class SwatMovementAction extends Tyrion.AI_MovementAction
    native;
///////////////////////////////////////////////////////////////////////////////

var protected Pawn m_pawn;
var protected LevelInfo Level;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
	m_Pawn = AI_MovementResource(r).m_pawn;
    assert(m_Pawn != None);

    Level = m_Pawn.Level;
	assert(Level != None);

	ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_FullBody, kUBABCI_SwatMovementAction);

    super.initAction(r, goal);
}


///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	ISwatAI(m_Pawn).AimToRotation(m_Pawn.Rotation);
	ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_SwatMovementAction);

    // stop moving
    m_pawn.Acceleration = vect(0.0, 0.0, 0.0);
}

///////////////////////////////////////////////////////////////////////////////
//
// Rotating Towards Something

latent function RotateTowardActor(Actor Target)
{
    ISwatAI(m_Pawn).AimAtActor(Target);
	FinishRotation();
}

latent function RotateTowardPoint(vector Point)
{
	ISwatAI(m_Pawn).AimAtPoint(Point);
	FinishRotation();
}

latent function RotateTowardRotation(rotator DesiredRotation)
{
	ISwatAI(m_Pawn).AimToRotation(DesiredRotation);
	FinishRotation();
}

latent function FinishRotation()
{
	// wait until we are aiming at what we desire AND the base of the body (basically everything below the waste)
	// matches up with that position as well
	do 
	{
//		log(m_Pawn.Name $ " Rotation.Yaw: " $ m_Pawn.Rotation.Yaw $ "  ISwatAI(m_Pawn).GetAimOrientation().Yaw: " $ ISwatAI(m_Pawn).GetAimOrientation().Yaw $ " WrapAngle0To2Pi(m_Pawn.Rotation.Yaw): " $ WrapAngle0To2Pi(m_Pawn.Rotation.Yaw) $ " WrapAngle0To2Pi(ISwatAI(m_Pawn).GetAimOrientation().Yaw) " $ WrapAngle0To2Pi(ISwatAI(m_Pawn).GetAimOrientation().Yaw));

		ISwatAI(m_Pawn).AnimSnapBaseToAim();

		yield();
	} until (WrapAngle0To2Pi(ISwatAI(m_Pawn).GetAimOrientation().Yaw) == WrapAngle0To2Pi(int(ISwatAI(m_Pawn).GetAnimBaseYaw())));
}

///////////////////////////////////////////////////////////////////////////////
//
// Drop to the Ground

latent function DropToGround()
{
    while (m_Pawn.Physics != PHYS_Walking)
    {
        yield();
    }
}