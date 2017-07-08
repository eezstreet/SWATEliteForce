///////////////////////////////////////////////////////////////////////////////
// AimAtPointAction.uc - AimAtPointAction class
// The action that causes the weapon resource to aim at a particular point with
// the current weapon

class AimAtPointAction extends SwatWeaponAction
    dependson(ISwatAI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// copied to our action
var(parameters) vector	Point;

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);
    ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AimAtPointAction);
}

function cleanup()
{
	super.cleanup();
    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_AimAtPointAction);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function AimAtDesiredPoint()
{
    // if we can aim at the target
    while (ISwatAI(m_pawn).AnimCanAimAtDesiredPoint(Point))
    {
        LatentAimAtPoint(Point);

		yield();
    }
}

state Running
{
 Begin:
    AimAtDesiredPoint();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'AimAtPointGoal'
}