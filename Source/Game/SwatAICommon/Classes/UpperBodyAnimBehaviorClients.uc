///////////////////////////////////////////////////////////////////////////////
//
// This file provides a centralized place to manage clients of the upper
// body animation behavior functions in ISwatAI. These clients are typically
// Tyrion actions, though this is not a strict convention. Having these
// clients ids in one class should alleviate a lot of hunting through files
// when trying to rebalance the priorities.
//
// The order of these client ids also dictate priority. The higher the client
// id, the higher the priority.
//
// Please refer to the comments above the SetUpperBodyAnimBehavior function
// in ISwatAI.uc

class UpperBodyAnimBehaviorClients extends Core.Object
    abstract;

///////////////////////////////////////////////////////////////////////////////

enum EUpperBodyAnimBehaviorClientId
{
    // Lowest priority

    // The default is the fallback behavior, when no other clients have set
    // a desired upper body anim behavior. It also supports clientId being
    // an optional parameter into SetUpperBodyAnimBehavior
    kUBABCI_Default,

	kUBABCI_SwatMovementAction,
    kUBABCI_BaseIdleAction,
    kUBABCI_IdleAimAround,
	kUBABCI_StackedUp,
    kUBABCI_MoveToActionBase,
    kUBABCI_NonIdleAimAround,
	kUBABCI_FallIn,
    kUBABCI_AvoidCollisions,
	kUBABCI_UsingToolkit,
    kUBABCI_OrderComplianceAction,
    kUBABCI_StunnedAction,
    kUBABCI_UseBreachingShotgunAction,
    kUBABCI_RestrainedAction,
    kUBABCI_AimAtPointAction,
    kUBABCI_AimAtTargetAction,
	kUBABCI_FleeAction,
	kUBABCI_RegroupAction,
	kUBABCI_TakeCoverAndAttackAction,
    kUBABCI_AttackTargetAction,
    kUBABCI_ComplianceAction,
    kUBABCI_MovingWhileCompliant,

    // Highest priority
};

///////////////////////////////////////////////////////////////////////////////
