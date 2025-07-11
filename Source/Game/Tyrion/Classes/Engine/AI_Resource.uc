//=====================================================================
// AI_Resource
// The Tyrion (Tribes 3 AI System) AI Control Mechanism
//=====================================================================

// A note on resource usage:
//
// Resources are hierarchical. Squads are made up of pawns which are made up of arms, legs,
// and a head. Arms, legs, and head resources are called "leaf resources". Leaf resources
// are the resources that actually do things in the world, characters and squads are just
// collections of these resources.
//
// Only actions running on leaf resources actually "use" the resources. Character and squad
// actions use resources only by virtue of the fact that they spawn child actions that run
// on the character's or squad's leaf resources. Consequently, it's easy for character and
// squad actions to share a resource. They can run in parallel and won't conflict unless two
// of them start a child action on the same leaf resource at the same time.
// 
// Every action has "resourceUsage" bits that indicate what resources it requires. Squad
// actions must have uniform usage of resources across their members (i.e. you can't have
// a single squad action that needs the arms of Pawn A and the legs of Pawn B).
//
// For an action to run on a resource, the resources it requires must be available. Resource
// checking occurs in two places: When an action is chosen for a pending goal (inside
// "processGoals()") and when a new goal is added to a resource (in "resourceCheck()").
// ProcessGoals() won't chose any action (including character and squad actions) unless
// the resources specified by that action are currently available. ResourceCheck() will
// interrupt an action running on a resources if this resource is a leaf resource and
// the new goal has a higher priority.

class AI_Resource extends Engine.Tyrion_ResourceBase
	native
	editinlinenew
	abstract;

import class Engine.Canvas;
import class Engine.HUD;

//=====================================================================
// Constants

// Optional resources 
const OPTIONAL_RESOURCE_PRIORITY = 20;	// maximum priority for an optional resource

// Resource usage bits - specify the leaf nodes of the resource hierarchy
// character parts
const RU_HEAD    = 1;
const RU_ARMS    = 2;
const RU_LEGS    = 4;


// vehicle parts
const RU_MOUNT		= 8;

// base installation parts
// ...

//=====================================================================
// Variables

var array<AI_RunnableAction> idleActions;
var array<AI_RunnableAction> runningActions;
var array<AI_RunnableAction> removedActions;	// actions waiting to be deleted
var AI_Action usedByAction;					// the action that is "using" this resource; only leaf resources (legs/arms/head etc) can be used
var array<AI_Sensor> sensors;				// the sensors available to this resource
var array<AI_SensorAction> sensorActions;	// the sensorActions running on this resource

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Called before the resource is first ticked
// (called explicitly by Actors that use AI_Resource's,
// since objects don't have their own postBeginPlay()'s)
// (called on first UAI_Resource.Tick)

event init()
{
	local int i;
	local AI_Goal goal;
	local array<AI_Goal> removeGoals;

	// designer-created goals have to be initialized...
	for ( i = 0; i < goals.length; i++ )
	{
		//log("@@@@@ goal " $ goals[i]);
		goal = AI_Goal(goals[i]);

		if ( goal.priorityFn() <= 0 )
			removeGoals[removeGoals.length] = goal;		// removeGoals.push(goal)
		else if ( goal.resource == None )	// goal not yet initialized 
			goal.init( self );
	}

	for ( i = 0; i < removeGoals.length; i++ )
	{
		if ( pawn().logTyrion )
			log( "Removing" @ removeGoals[i].name @ "from" @ pawn().name @ "(priority <= 0)" ); 
		removeGoal( removeGoals[i] );		// remove goals with 0 priority so they don't clog up resources
	}

	bUnInitialized = false;
}

//---------------------------------------------------------------------
// clean up resource-related stuff when pawn dies

function cleanup()
{
	local int i;
	local AI_Goal goal;
	local ActionBase action;

	//if ( pawn() != None )
	//	log( "Cleanup called on" @ name @ pawn().name );
	//else
	//	log( "Cleanup called on" @ name @ "(pawn unknown - ragdoll cleanup?)" );

	for ( i = 0; i < goals.length; i++ )
	{
		goal = AI_Goal(goals[i]);
		//log( "... considering" @ goal.name );

		// de-link goals from sensor's recipient lists (in lieu of removing them alltogether)
		if ( goal.activationSentinel != None && goal.activationSentinel.sensor != None )
		{
			goal.activationSentinel.deactivateSentinel( goal );
			goal.activationSentinel.sensor = None;
		}
		if ( goal.deactivationSentinel != None && goal.deactivationSentinel.sensor != None )
		{
			goal.deactivationSentinel.deactivateSentinel( goal );
			goal.deactivationSentinel.sensor = None;
		}
	}

	//log( " idleActions:" @ idleActions.length );
	while ( idleActions.length > 0 )
	{
		//log( "... considering idle" @ idleActions[0].name );
		action = idleActions[0];
		idleActions.remove(0, 1);			// remove element explicitly (so sensorActions get removed)
		action.instantFail( ACT_RESOURCE_INACTIVE );
	}

	//log( " runningActions:" @ runningActions.length );
	while ( runningActions.length > 0 )
	{
		//log( "... considering running" @ runningActions[0].name );
		action = runningActions[0];
		runningActions.remove(0, 1);		// remove element explicitly (so sensorActions get removed)
		action.instantFail( ACT_RESOURCE_INACTIVE );
	}

	for ( i = 0; i < sensors.length; i++ )
	{
		//log( "... considering sensor" @ sensors[i].name @ sensors[i].recipients.length );
		/*if ( sensors[i].recipients.length > 0 )
		{
			log( "    The following still have references to this sensor:" );
			for ( j = 0; j < sensors[i].recipients.length; j++ )
				log( "     " @ sensors[i].recipients[j].recipient.name );
		}*/
		sensors[i].cleanup();
	}

	// InstantFail doesn't remove sensor actions (even though they are in the "runningActions" list),
	// so remove them here explicitly
	//log( " sensorActions:" @ sensorActions.length );
	for ( i = 0; i < sensorActions.length; i++ )
	{
		//log( "... considering sensorAction" @ sensorActions[i].name );
		sensorActions[i].removeAction();
	}
	sensorActions.length = 0;

	// remove remaining goals
	while( goals.length > 0 )
	{
		//log( "... considering goal" @ goals[0].name ); 
		removeGoal( AI_Goal(goals[0]) );
	}

	//log( "Cleanup FINISHED on" @ name @ pawn().name );
}

//---------------------------------------------------------------------
// Delete all the sensors attached to this resource

function deleteSensors()
{
	local int i;

	for ( i = 0; i < sensors.length; i++ )
	{
		sensors[i].value.Delete();		// this would be in the sensor's destructor if we had one...
		sensors[i].Delete();
	}
	sensors.length = 0;
}

//---------------------------------------------------------------------
// Delete actions that have been removed from idle and running lists

native function deleteRemovedActions();

//---------------------------------------------------------------------
// increments refCount and returns object

function AI_Resource myAddRef()
{
	AddRef();
	return self;
}

function PushRunnableAction(AI_RunnableAction Pushed)
{
    assert(Pushed != None);
    runningActions[runningActions.Length] = Pushed;
}

//---------------------------------------------------------------------
// Inform a resource that a particular pawn died
// (Resources should not assume they will only get one of these messages per pawn death)

function pawnDied( Pawn pawn )
{
	local int i;
	local array<ActionBase> actions;

	// collect actions (don't want to be iterating over lists that might change length)
	for ( i = 0; i < runningActions.length; ++i )
		actions[actions.length] = runningActions[i];

	for ( i = 0; i < idleActions.length; ++i )
		actions[actions.length] = idleActions[i];

	// inform all actions
	for ( i = 0; i < actions.length; ++i )
	{
		if ( !actions[i].bDeleted )
			actions[i].pawnDied( pawn );
	}
}

//----------------------------------------------------------------------
// Chooses the best action from 'abilities' that satisfies 'goal'
// Returns a copy of this action (or None) with a reference count of 1
//
// Note: to save on action copying, for now goal constraints are not taken into account when
//       determining value of selectionHeuristic

native function AI_Action chooseAction( AI_Goal goal );

event AI_Action ShallowCopyAction(AI_Action otherAction)
{
	return AI_Action(class'Engine.Tyrion_Setup'.static.shallowCopy(otherAction));
}

//----------------------------------------------------------------------
// Makes sure a high priority goal isn't being prevented from running
// because its resource is being used by a lower priority one;
// if it is, interrupt the lower priority one
// 'bestAction': if known, the action you want running on this goal

event resourceCheck( AI_Goal goal, optional AI_Action bestAction )
{
	// Interrupt lower priority actions that are preventing this goal from being satisfied:
	// 1. find out what actions match this goal
	// 2. if the best one needs to use this resource but a lower priority action is claiming
	//    the resource, interrupt the lower priority action

	if ( usedByAction != None &&		// will only be non-None on leaf resources (there is no resource contention for non-leaf resources)
		 goal.bInactive == false &&		// inactive goals don't need to be considered
		 goal.priorityFn() > usedByAction.achievingGoal.priorityFn() &&	// new goal's priority is higher
		 !doesParentHaveResource( goal.parentAction ) )					// parent isn't already using the resource
	{
		// possible optimization: store bestAction for use by processGoals() - if processGoals() is called on this tick
		if ( bestAction == None )
			bestAction = chooseAction( goal );	// if a new bestAction is created here it will get deleted at the end of this function...
		else
			bestAction.AddRef();				// ...but if it was passed in it its reference counts will remain unchanged

		// the best action needs the resource (resource must be a leaf resource)
		// old: if ( (bestAction.resourceUsage & bestAction.default.resourceUsage) != 0 )
		if ( !multipleActionsCheck( bestAction ) )
		{
			//if ( pawn().logTyrion )
				log( "resourceCheck: Interrupting" @ usedByAction.name @
					"(pri" @ usedByAction.achievingGoal.priorityFn() $
					") to achieve" @ goal.name @ "(pri" @ goal.priorityFn() $ ")" );
			if ( usedByAction == goal.parentAction )
				log( "AI WARNING: Child action" @ bestAction.name @ "is interrupting its parent" @ goal.parentAction.name ); 

			// invoke parent's "resources stolen" callback
			if ( usedByAction.achievingGoal.parentAction != None )
				usedByAction.achievingGoal.parentAction.resourceStolenCB( usedByAction.achievingGoal, self );

			// free up resource
			if ( usedByAction != None )
				usedByAction.interruptAction();
		}

		if ( bestAction != None )
			bestAction.Release();
	}
}

//---------------------------------------------------------------------
// Adds a sensor action to a resource

function AI_SensorAction addSensorActionClass( class<AI_SensorAction> sensorActionClass )
{
	local AI_SensorAction sensorAction;

	assert(sensorActionClass != None);

#if ! IG_SWAT
	if ( !ClassIsChildOf( class, sensorActionClass.static.getResourceClass() ) )
	{
		log( "AI WARNING: addSensorActionClass:" @ class @ "is not a child of" @ sensorActionClass.static.getResourceClass() );
		assert( ClassIsChildOf( class, sensorActionClass.static.getResourceClass() ) );
	}
#endif

	//log( name @ "added sensor action class:" @ sensorActionClass );

	// allocate a new sensor action, but have it be idle

	sensorAction = (new sensorActionClass( self )).myAddRef();
	//log( "---" @ sensorAction @ "addreffed" );
	sensorAction.setupSensors( self );
	sensorAction.pauseAction();

	sensorActions[sensorActions.length] = sensorAction;

	return sensorAction;
}

//---------------------------------------------------------------------
// Can this resource run "action" if it's already being used?
// (default is "yes", but individual resources can define their own logic)
// Note: check will never be called for non-leaf resources, since they can
// always run multiple actions

event bool multipleActionsCheck( AI_Action action )
{
	return true;
}

//----------------------------------------------------------------------
// Is the parent of this action already using a leaf resource?

event bool doesParentHaveResource( AI_Action parentAction )
{
	return false;
}

//----------------------------------------------------------------------
// Return the corresponding action class for this type of resource

function class<AI_RunnableAction> getActionClass();

//----------------------------------------------------------------------
// Wrapper function for setActionParametersInternal

function bool setActionParameters( AI_Goal goal, AI_Action action )
{
	return setActionParametersInternal( goal, action );
}

//---------------------------------------------------------------------
// Accessor function
event function Pawn Pawn()
{
	return None;
}

//---------------------------------------------------------------------
// Given the name of a goal, retrieve the object (or None)

native function AI_Goal findGoalByName(string gName);

//----------------------------------------------------------------------
// Set parameters in 'action' to those specified by 'goal', if possible
//
// Notes on goal constraints:
// - goal constraints are parameters of the action that matches the goal
// - goal constraints steer the the action, giving the poster of the goal some control
//   on the execution of the action
// - when goal constraints are set, the action uses their values, instead of filling them in itself

private native function bool setActionParametersInternal( Object goal, Object action );

//----------------------------------------------------------------------
// Adds a goal to the AI_Resource
// low-level function - don't call this directly!
// 'parentAction' can be None for top-level goals
// Does an implicit "AddRef" on the goal that was added

function addGoal( AI_Action parent, AI_Goal goal )
{
	goal.AddRef();
    if ((pawn() != None) && pawn().logTyrion)
		log( self $ ": Adding goal" @ goal @ "(pri" @ goal.priority $ ")");

	goals[goals.length] = goal;	// goals.push(goal)
	goal.parentAction = parent;

	if ( parent != None )
	{
		// childGoals.Push( self )
		parent.childGoals[parent.childGoals.length] = goal;
	}

	if ( goal.bInactive == false )
		bMatchGoals = true;
}

//-----------------------------------------------------------------------
// Removes a goal from this AI_Resource
// low-level function - don't call this directly!
// clears achievingAction
// Does an implicit "Release" on the goal that was removed (which means goal may be invalid after this call!!)
// It's ok to call removeGoal on a goal that's already been removed.

function removeGoal( AI_Goal goal )
{
	local int i;

	if ( goal.parentAction != None )
	{
		for ( i = 0; i < goal.parentAction.childGoals.length; i++ )
			if ( goal.parentAction.childGoals[i] == goal )
			{
				//log( "-> removing" @ goal.name @ "from child list of" @ goal.parentAction.name );
				goal.parentAction.childGoals.remove( i, 1 );	// removes element - shifts the rest
				break;
			}
	}

	if ( goal.activationSentinel != None && goal.activationSentinel.sensor != None )
	{
		goal.activationSentinel.deactivateSentinel( goal );
		goal.activationSentinel.sensor = None;
	}
	if ( goal.deactivationSentinel != None && goal.deactivationSentinel.sensor != None )
	{
		goal.deactivationSentinel.deactivateSentinel( goal );
		goal.deactivationSentinel.sensor = None;
	}

	// Check to see if bMatchGoals needs to be set after a goal is removed.
	// If a goal is being achieved by an action that isn't using the resource,
	// then removing that goal doesn't free up any resources. Consequently,
	// no new goal matching has to be performed.
	// (Note: goal's achievingAction slot must still be valid)

	if ( usedByAction != None && goal.achievingAction == usedByAction )
		bMatchGoals = true;

	// A more general note:
	// There are four cases when you might have to perform action-to-goal matching:
	// 1. A goal was added (handled in addGoal)
	// 2. A goal was removed (handled in removeGoal)
	// 3. An action completed - because although the goals may not have changed,
	//    resources may have been freed up (handled in goalAchieved / goalFailed)
	//    When an action completes, all the sub-goals it posted have to be removed as well;
	//    this is why removeAction calls removeGoal recursively
	// 4. An action was interrupted - again, resources may have been freed up
	//    (handled in interruptAction which calls goalFailed)
	// The possibility still exists that bMatchGoals will be set to true unnecessarily,
	// but no cases were it should have been set and wasn't will occur.

	if ( goal.achievingAction != None )
	{
		//log( "-> removing" @ goal.achievingAction.name );
		goal.achievingAction.removeAction();	// clears achievingAction
	}

	for ( i = 0; i < goals.length; i++ )
		if ( goals[i] == goal )
		{
			goals.remove( i, 1 );				// removes element - shifts the rest
			goal.bDeleted = true;
			//log( "->" @ goal.name @ "in" @ pawn().name @ "RELEASED" );
			if (goal.Release() > 0)
				goal.NullReferences();
			break;
		}
}

//---------------------------------------------------------------------
// Mark all goals as achieved: this will reset the resource to have
// only permanent goals (used when a mount loses its driver)

event resetGoals()
{
	local int i, n;
	local AI_Goal goal;

	n = goals.length;
	for ( i = 0; i < n; ++i )
	{
		goal = AI_Goal(goals[i]);
		if ( goal.achievingAction != None )
		{
			//log( "-->" @ localRook().name @ "Calling succeed on" @ goal.name );
			goal.achievingAction.instantSucceed();

			// handle goals array length being modified
			if ( goals.length != n )
			{
				n = goals.length;
				--i;
			}
		}
	}

	bGoalsReset = true;
}

//---------------------------------------------------------------------
// action/goal debug display function

#if IG_TRIBES3			// Tribes version...
function displayTyrionDebug()
{
    local int i;
	local Pawn debugPawn;
	local AI_Goal goal;

	debugPawn = pawn();

	if ( class'Pawn'.static.checkAlive( debugPawn ) && goals.length > 0 )
	{
		debugPawn.AddDebugMessage(" ");
		debugPawn.AddDebugMessage( Name @ "Goals", class'Canvas'.static.MakeColor(255,255,255));

		for ( i = 0; i < goals.length; i++ )
		{
			goal = AI_Goal(goals[i]);
			if ( !goal.bInActive )
			{
				debugPawn.AddDebugMessage( "  " $ goal.goalDebuggingString() @ "(" $ goal.priorityFn() $ ")" );
				if ( goal.achievingAction != None )
					debugPawn.AddDebugMessage( "   " $ goal.achievingAction.actionDebuggingString(), class'Canvas'.static.MakeColor(200,200,200));
			}
		}
	}
}
#endif

#if IG_SWAT				// SWAT version...
function displayTyrionDebug()
{
    local int i;
	local Pawn debugPawn;

	debugPawn = pawn();
    debugPawn.AddDebugMessage(" ");

	if ( goals.length > 0 )
	{
		debugPawn.AddDebugMessage( Name $ " Goals", class'Canvas'.Static.MakeColor(255,255,255));
		for ( i = 0; i < goals.length; i++ )
			if ( !AI_Goal(goals[i]).bInActive )
				debugPawn.AddDebugMessage("  " $ goals[i].goalDebuggingString());
	}

	if ( runningActions.length > 0 )
	{
		debugPawn.AddDebugMessage("Running " $ Name $ " Actions", class'Canvas'.Static.MakeColor(255,255,255));
		for ( i = 0; i < runningActions.length; i++ )
			debugPawn.AddDebugMessage("  " $ runningActions[i].actionDebuggingString());
	}

	if ( idleActions.length > 0 )
	{
		debugPawn.AddDebugMessage("Idle " $ Name $ " Actions", class'Canvas'.Static.MakeColor(255,255,255));
		for ( i = 0; i < idleActions.length; i++ )
			debugPawn.AddDebugMessage("  " $ idleActions[i].actionDebuggingString());
	}
}
#endif

//=======================================================================

defaultproperties
{
	bMatchGoals = true
}