//=====================================================================
// AI_RunnableAction
// An action that can run or be idle, and can create children
// Superclass to AI_Actions and AI_SensorActions
//
// Notes on Usage:
// - every subclassed action should have a 'Running' state in which
//   the state code resides
//=====================================================================

class AI_RunnableAction extends ActionBase
	abstract
    native
	threaded;

//=====================================================================
// Variables

var AI_Resource resource;			// the resource this action is running on

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Interrupt an action
// Stop a running (or idle) action; reclaim its resources
// Typically called by the resource

function interruptAction()
{
	removeAction();
}

//---------------------------------------------------------------------
// Terminate an action
// Typically called by the resource

function removeAction()
{
	local int i;

	// Remove action from idle list (if it's in there)
	for ( i = 0; i < resource.idleActions.length; i++ )
		if ( resource.idleActions[i] == self )
		{
			resource.idleActions.remove(i, 1);		// removes element - shifts the rest
			break;
		}

	// Remove action from running list (if it's in there)
	for ( i = 0; i < resource.runningActions.length; i++ )
		if ( resource.runningActions[i] == self )
		{
			resource.runningActions.remove(i, 1);	// removes element - shifts the rest
			break;
		}

	if ( bCompleted == false )
	{
		resource.removedActions[resource.removedActions.length] = self;	// removedActions.Push(self)
		bCompleted = true;
	}

#if IG_SWAT	// only cleanup if we haven't already been deleted
	if (! bDeleted)
#endif
		cleanup();

	bDeleted = true;
}

//---------------------------------------------------------------------
// Run an action
// Typically called by the resource

function runAction()
{
	local int i;

	// Remove action from idle list (if it's in there)
	for ( i = 0; i < resource.idleActions.length; i++ )
		if ( resource.idleActions[i] == self )
		{
			resource.idleActions.remove(i, 1);		// removes element - shifts the rest
			break;
		}

	if ( isIdle() )
	{
		resource.PushRunnableAction(self);

		bIdle = false;
		//GotoState( 'Running' );
	}
}

//---------------------------------------------------------------------
// Pause an action (put it onto idle list)
// Note that an action can still be achieving a goal when it's idle.
// Typically called by the resource

function pauseAction()
{
	// Remove action from running list (if it's in there)
	local int i;
	for ( i = 0; i < resource.runningActions.length; i++ )
		if ( resource.runningActions[i] == self )
		{
			resource.runningActions.remove(i, 1);	// removes element - shifts the rest

			// idleActions.Push(self); (don't add if it wasn't in running list - it can screw up action deletion!)
			resource.idleActions[resource.idleActions.length] = self;
			break;
		}

	bIdle = true;
	//GotoState( 'Idle' );
}

//=====================================================================
// States

state Running
{
Begin:
}
