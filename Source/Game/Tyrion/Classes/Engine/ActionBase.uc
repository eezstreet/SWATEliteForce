//=====================================================================
// ActionBase
//
// Base class for Tyrion (AI) and Cersei (Navigation System) actions
//=====================================================================

class ActionBase extends Engine.Tyrion_ActionBase
	native
	abstract
	native
	threaded;

//=====================================================================
// Constants

// errorCodes; everything > 0 is a failure
enum ACT_ErrorCodes
{
   ACT_SUCCESS,
   ACT_GENERAL_FAILURE,
   ACT_RESOURCE_INACTIVE,		// resource became inactive (due to death, LODding, etc.)
   ACT_INTERRUPTED,				// the action was interrupted by a call to "InterruptAction"
   ACT_CANT_FIND_PATH,
   ACT_IRREVERSIBLY_OFF_COURSE,
   ACT_TIME_LIMIT_EXCEEDED,
   ACT_INVALID_PARAMETERS,		// parameters provided to the action don't make sense
   ACT_CANT_REACH_DESTINATION,
   ACT_ALL_RESOURCES_DIED,		// all the resources the action was running on died
   ACT_REQUIRED_RESOURCE_STOLEN,
   ACT_INSUFFICIENT_RESOURCES_AVAILABLE,
   ACT_NO_COVER_FOUND,
   ACT_NO_LONGER_THREATENED,
   ACT_WILL_NOT_COMPLY,
   ACT_NO_WEAPONS_AVAILABLE,
   ACT_NOBODY_HAS_EQUIPMENT,
   ACT_TOO_CLOSE_TO_OFFICERS,
   ACT_DOOR_BLOCKED
};

//=====================================================================
// Variables

var bool bIdle;					// is this action idle?
var bool bCompleted;			// has this action completed?
var bool bWasTicked;			// true if action was ticked at least once
var bool bDeleted;				// set when this action has been deleted
var bool bSensorAction;			// is this action a sensorAction?

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Called when an action finished or is interrupted

function cleanup();

//---------------------------------------------------------------------
// Removes action from all the data structures it is in; terminates it

function removeAction();

//---------------------------------------------------------------------
// Removes the goal associated with the action (if any)

function removeGoal();

//---------------------------------------------------------------------
// action state query functions

// Note: idle state is undefined if action has completed
function bool isIdle()
{
	return bIdle;
}

function bool isRunning()
{
	return !bIdle;
}

function bool hasCompleted()
{
	return bCompleted;
}

// true if action was ticked at least once
function bool wasTicked()
{
	return bWasTicked;
}

//---------------------------------------------------------------------
// Pause an action (put it onto idle list)
// Typically called by the resource

function pauseAction();

//---------------------------------------------------------------------
// Run an action
// Typically called by the resource

event runAction();

//---------------------------------------------------------------------
// Inform an action that a particular pawn died
// (Actions should not assume they will only get one of these messages per pawn death)

function pawnDied( Pawn pawn );

//---------------------------------------------------------------------
// Called by an action when it has failed at accomplishing its goal

event instantFail( ACT_ErrorCodes errorCode, optional bool bRemoveGoal )
{
	removeAction();
}

#if IG_TRIBES3
//---------------------------------------------------------------------
// Add action to childAction list

function setChildReference( NS_Action child );

//---------------------------------------------------------------------
// Remove action from childAction list

function removeChildReference( NS_Action child );

//---------------------------------------------------------------------
// Return the Cersei child?

function NS_Action getChildReference();

//---------------------------------------------------------------------
// Callbacks from Navigation System actions
// (used when a Tyrion action wants to call a Cersei action)

function actionSucceededCB( NS_Action child )
{
	// If the child finishes and the parent was idle, start the parent up again
	if ( bIdle && child.bWakeUpParent )
	{
		runAction();
		//log( "-->" @ name @ "now knows that" @ child.name @ "succeeded!" );
	}
}

function actionFailedCB( NS_Action child, ACT_ErrorCodes errorCode )
{
	// If the child finishes and the parent was idle, start the parent up again
	if ( bIdle && child.bWakeUpParent )
	{
		runAction();
		//log( "-->" @ name @ "now knows that" @ child.name @ "failed!" );
	}
}
#endif

//=====================================================================
// Action Idioms

//---------------------------------------------------------------------
// Action idiom: yield
// Continue execution on next tick at the position following 'yield()'

latent function yield()
{
	Sleep(0.0);
}

//---------------------------------------------------------------------
// Action idiom: pause
// Pause an action by taken it off the 'runningActions' list;
// When action is switched back to 'Running' it
// continues execution at the position following 'pause()'

latent function pause()
{
	pauseAction();
	yield();
}

//---------------------------------------------------------------------
// Action idiom: sleepForever

latent function sleepForever()
{
	while( true )
		pause();
}

#if IG_TRIBES3
//---------------------------------------------------------------------
// Action idiom: waitForAction
// Pauses parent until 'child' completes (fails or succeeds)
// (Note: only makes sense for NS_Action children)

latent function waitForAction( NS_Action child )
{
	child.bWakeUpParent = true;
	pause();
}

//---------------------------------------------------------------------
// Action idiom: interruptActionIf
// Parent runs in parallel with child, and interrupts 'child' if 'condition' is true
// If child releases while this function is running, "getChildReference" will return None

latent function interruptActionIf( NS_Action child, class<IBooleanActionCondition> condition )
{
	while ( getChildReference() != None && !child.hasCompleted() )	// child is still running
		if ( condition.static.actionTest( self, child ))			// interrupt child when condition is true
		{
			child.interruptAction();
			break;
		}
		else
		{
			yield();
		}
}
#endif

//=====================================================================

defaultproperties
{
	bIdle			= true
	bCompleted		= false
	bSensorAction	= false
}

