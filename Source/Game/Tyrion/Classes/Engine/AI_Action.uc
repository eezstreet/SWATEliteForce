//=====================================================================
// AI_Action
// The Tyrion Action class: *How* an AI does something
//
// Extends AI_RunnableAction with the ability to post and manage goals
//=====================================================================

class AI_Action extends AI_RunnableAction implements ISensorNotification
	abstract
    native;

//=====================================================================
// Constants

//=====================================================================
// Variables

var() const editconst class<AI_Goal> satisfiesGoal;	// class that this action satisfies
var AI_Goal achievingGoal;							// goal being achieved by this action
var array<AI_Goal> childGoals;						// child actions that are running
var float heuristicValue;							// storage for selectionHeuristic()
var int resourceUsage;								// bits indicate what leaf resources this action requires
var int waitingForGoalsN;							// number of goal completions this action is waiting for

//=====================================================================
// Action Idioms

//---------------------------------------------------------------------
// Called by an action when it has successfully accomplished its goal
// (No state code following this function is executed)

latent function succeed()
{
	achievingGoal.markGoalAsAchieved();		// may release the goal

	if (achievingGoal.parentAction != None )
		achievingGoal.parentAction.goalAchievedCB( achievingGoal, self );

	achievingGoal.handleGoalSuccess();

	if ( achievingGoal.achievingAction != None )	// optimization: check if markGoalAsAchieved already called removeAction...
		removeAction();

	achievingGoal.Release();				// balances AddRef done in initAction
	achievingGoal = None;

	yield();
}

event instantSucceed()
{
	achievingGoal.markGoalAsAchieved();

	if (achievingGoal.parentAction != None )
		achievingGoal.parentAction.goalAchievedCB( achievingGoal, self );

	achievingGoal.handleGoalSuccess();

	if ( achievingGoal.achievingAction != None )	// optimization: check if markGoalAsAchieved already called removeAction...
		removeAction();

	achievingGoal.Release();				// balances AddRef done in initAction
	achievingGoal = None;
}

//---------------------------------------------------------------------
// Called by an action when it has failed at accomplishing its goal
// bRemoveGoal: when true, goal is definitely removed (even if normally wouldn't be)
// (called from callbacks)

event instantFail( ACT_ErrorCodes errorCode, optional bool bRemoveGoal )
{
	if ( achievingGoal == None )
		return;						// goal had instantFail called on it already

	if ( bRemoveGoal )
		achievingGoal.bTryOnlyOnce = true;

	//log( "1." @ name @ "instantFail called with code" @ errorcode );

	achievingGoal.markGoalAsFailed();

	if (achievingGoal.parentAction != None )
		achievingGoal.parentAction.goalNotAchievedCB( achievingGoal, self, errorCode );

	achievingGoal.handleGoalFailure();

	//log( "2." @ name @ "being removed by instantFail" );
	removeAction();		// references achievingGoal

	achievingGoal.Release();				// balances AddRef done in initAction
	achievingGoal = None;
}

//---------------------------------------------------------------------
// Called by an action when it has failed at accomplishing its goal
// bRemoveGoal: when true, goal is definitely removed (even if normally wouldn't be)
// (called from state code; no state code following this function is executed)

latent function fail( ACT_ErrorCodes errorCode, optional bool bRemoveGoal )
{
	instantFail( errorCode, bRemoveGoal );
	yield();
}

//---------------------------------------------------------------------
// Action idiom: waitForGoal
// Pauses goal poster until sub-goal 'goal' matches some action and
// this matching action completes (fails or succeeds).
// If "bTryOnlyOnce" is set, only tries to achieve the goal once

latent function waitForGoal( AI_Goal goal, optional bool bTryOnlyOnce )
{
	waitingForGoalsN = 1;
	goal.bWakeUpPoster = true;
	goal.bTryOnlyOnce = bTryOnlyOnce;
	pause();
}

//---------------------------------------------------------------------
// Action idiom: interruptGoalIf
// Keeps goal poster running in parallel, and should the function
// 'goalTest' in the class 'condition' ever evaluate to true,
// unposts 'goal'

latent function interruptGoalIf( AI_Goal goal, class<IBooleanGoalCondition> condition )
{
	while ( !goal.hasCompleted() )
		if ( condition.static.goalTest( goal ))
		{
			goal.unPostGoal( self );
			break;
		}
		else
		{
			yield();
		}
}

//---------------------------------------------------------------------
// Action idiom: waitForAllGoals
// continues execution when all goals have matched and succeeded or when
// any goal has matched and failed

latent function waitForAllGoals( optional AI_Goal goal1,
					 optional AI_Goal goal2, optional AI_Goal goal3, optional AI_Goal goal4,
					 optional AI_Goal goal5, optional AI_Goal goal6, optional AI_Goal goal7,
					 optional AI_Goal goal8, optional AI_Goal goal9)
{
	waitingForGoalsN = 0;
	if ( goal1 != None )
	{
		waitingForGoalsN++;
		goal1.bWakeUpPoster = true;
	}
	if ( goal2 != None )
	{
		waitingForGoalsN++;
		goal2.bWakeUpPoster = true;
	}
	if ( goal3 != None )
	{
		waitingForGoalsN++;
		goal3.bWakeUpPoster = true;
	}
	if ( goal4 != None )
	{
		waitingForGoalsN++;
		goal4.bWakeUpPoster = true;
	}
	if ( goal5 != None )
	{
		waitingForGoalsN++;
		goal5.bWakeUpPoster = true;
	}
	if ( goal6 != None )
	{
		waitingForGoalsN++;
		goal6.bWakeUpPoster = true;
	}
	if ( goal7 != None )
	{
		waitingForGoalsN++;
		goal7.bWakeUpPoster = true;
	}
	if ( goal8 != None )
	{
		waitingForGoalsN++;
		goal8.bWakeUpPoster = true;
	}
	if ( goal9 != None )
	{
		waitingForGoalsN++;
		goal9.bWakeUpPoster = true;
	}

	pause();
}

latent function waitForAllGoalsInList(array<AI_Goal> goals)
{
	local int i;

	waitingForGoalsN = 0;

	for( i = 0; i < goals.Length; ++i )
	{
		if (goals[i] != None)
		{
			waitingForGoalsN++;
			goals[i].bWakeUpPoster = true;
		}
	}

	pause();
}

//---------------------------------------------------------------------
// Action idiom: waitForAnyGoals
// continues execution when any one of the specified goals has matched and completed

latent function waitForAnyGoal(AI_Goal goal1,
					 optional AI_Goal goal2, optional AI_Goal goal3, optional AI_Goal goal4,
					 optional AI_Goal goal5, optional AI_Goal goal6, optional AI_Goal goal7 )
{
	waitingForGoalsN = 1;
	goal1.bWakeUpPoster = true;

	if ( goal2 != None )
		goal2.bWakeUpPoster = true;

	if ( goal3 != None )
		goal3.bWakeUpPoster = true;

	if ( goal4 != None )
		goal4.bWakeUpPoster = true;

	if ( goal5 != None )
		goal5.bWakeUpPoster = true;

	if ( goal6 != None )
		goal6.bWakeUpPoster = true;

	if ( goal7 != None )
		goal7.bWakeUpPoster = true;

	pause();
}

//---------------------------------------------------------------------
// Action idiom: waitForAllGoalsConsidered
// continues execution when all one of the specified goals have been considered
// by the goal matching process (whether an actionw as actually started to
// achieve them or not)

latent function waitForAllGoalsConsidered(AI_Goal goal1,
					 optional AI_Goal goal2, optional AI_Goal goal3, optional AI_Goal goal4,
					 optional AI_Goal goal5, optional AI_Goal goal6, optional AI_Goal goal7 )
{
	while ( !(( goal1 == None || goal1.wasConsidered() ) &&
			  ( goal2 == None || goal2.wasConsidered() ) && 
			  ( goal3 == None || goal3.wasConsidered() ) && 
			  ( goal4 == None || goal4.wasConsidered() ) && 
			  ( goal5 == None || goal5.wasConsidered() ) && 
			  ( goal6 == None || goal6.wasConsidered() ) && 
			  ( goal7 == None || goal7.wasConsidered() )) )
		yield();
}

//---------------------------------------------------------------------
// Action idiom: waitForResourcesAvailable
// legspriority:  priority of the sub-goal that will be posted on the legs (0 if no goal)
// armsPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)
// headPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)
//
// todo: make event-based

latent function waitForResourcesAvailable( int legsPriority, int armsPriority, optional int headPriority )
{
	while ( !resource.requiredResourcesAvailable( legsPriority, armsPriority, headPriority ) )
		yield();
}

//=====================================================================
// Functions

//---------------------------------------------------------------------
// ISensorNotification implementation

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData );

function AI_Resource getResource()
{
	return resource;
}

//---------------------------------------------------------------------
// Initialize a new action 
// 'goal' is the AI_Goal the action is achieving
// 'r' is the resource the action is running on
// Typically called by the resource - sets achievingAction

event initAction(AI_Resource r, AI_Goal goal)
{
	resource = r;
	achievingGoal = goal;
	goal.achievingAction = self;

	achievingGoal.AddRef();				// Released when action succeeds or fails

	GotoState( 'Running' );
}

//---------------------------------------------------------------------
// increments refCount and returns object

function AI_Action myAddRef()
{
	AddRef();
	return self;
}

//---------------------------------------------------------------------
// Interrupt an action
// Stop a running (or idle) action; reclaim its resources
// Typically called by the resource - clears achievingAction

function interruptAction()
{
	// Remove this if "interruption callback" never gets used 
	if (achievingGoal.parentAction != None )
		achievingGoal.parentAction.goalNotAchievedCB( achievingGoal, self, ACT_ErrorCodes.ACT_INTERRUPTED );

	achievingGoal.markGoalAsFailed();

	super.interruptAction();
}

//---------------------------------------------------------------------
// Terminate an action
// Typically called by the resource - clears achievingAction and usedByAction

function removeAction()
{
	//@@@ log( "## Removing" @ name @ resource.pawn().name );

	// make sure we're out of the running state
	gotostate('');

	// Recursively remove all the child goals (and their actions)
	while ( childGoals.length > 0 )
	{
		//log( name $ ". RemoveAction:" @ childGoals[0].name @ "removed from" @ childGoals[0].resource.name );
		childGoals[0].resource.removeGoal( childGoals[0] );	// changes childGoals.length...
	}

	// fiddle with goals
	achievingGoal.achievingAction = None;
	
	if ( self == resource.usedByAction )
		resource.usedByAction = None;

	Super.removeAction();
}

//---------------------------------------------------------------------
// Run an action
// Typically called by the resource

function runAction()
{
	if ( !resource.isActive() )
	{
		if ( (resource.pawn() != None) && resource.pawn().logTyrion )
			log( name @ "stopped. Resource is dead" );

		instantFail( ACT_RESOURCE_INACTIVE );
		return;
	}

	Super.runAction();
}

//---------------------------------------------------------------------
// Selection Heuristic
// Returns a value in the range [0, 1], indicating how suitable this action is for achieving this goal

#if IG_TRIBES3
static
#endif
event float selectionHeuristic( AI_Goal goal )
{
	return 1.0;
}

#if IG_TRIBES3
//---------------------------------------------------------------------
// Add action to childAction list

function setChildReference( NS_Action child )
{
	nsChild = child;
}

//---------------------------------------------------------------------
// Remove action from childAction list

function removeChildReference( NS_Action child )
{
	if ( nsChild == child )
		nsChild = None;
}

//---------------------------------------------------------------------
// Return the Cersei child?

function NS_Action getChildReference()
{
	return nsChild;
}
#endif

//---------------------------------------------------------------------
// Child Goal Test
// Returns true if the goal given is a child goal, returns false otherwise

function bool isChildGoal ( AI_Goal goal )
{
	local int i;

    for(i=0; i<childGoals.Length; ++i)
    {
        if (childGoals[i] == goal)
            return true;
    }

    return false;
}

//---------------------------------------------------------------------
// Callback: action 'child' achieved 'goal'
// Note: When writing action-specific callbacks, call super.<callback> first

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	if ( goal.bWakeUpPoster && ( --waitingForGoalsN == 0 ) && bIdle )
	{
		runAction();
	}
}

//---------------------------------------------------------------------
// Callback: action 'child' did not succeed in achieving 'goal'
// ('errorCode' gives the reason)
// Note: When writing action-specific callbacks, call super.<callback> first

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	//log( name $ ".goalNotAchievedCB called with" @ goal.name );

	if ( goal.bWakeUpPoster && bIdle )
	{
		runAction();
	}
}

//---------------------------------------------------------------------
// Callback: resource 'stolenResource' stolen from 'goal'
// Note: When writing action-specific callbacks, call super.<callback> first

function resourceStolenCB( AI_goal goal, AI_Resource stolenResource )
{
	if ( resource.pawn().logTyrion )
		log( "---> resource" @ stolenResource.name @ "stolen from" @ goal.name );

	if ( goal.bTerminateIfStolen )
	{
		if ( resource.pawn().logTyrion )
			log( "--->" @ name @ "terminating" );
		instantFail( ACT_REQUIRED_RESOURCE_STOLEN );
	}
}
//=====================================================================

defaultproperties
{
}
