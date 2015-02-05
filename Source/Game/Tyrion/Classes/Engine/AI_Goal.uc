//=====================================================================
// AI_Goal
// The Tyrion Goal class: *What* an AI wants to do
//
// To create and post a new goal:
// 1. call newgoal = new class'goal-you-want-to-create'( resource, priority, constraint1, constraint2, ...)
// 2. call newgoal.postGoal( parentAction )
//
//=====================================================================

class AI_Goal extends Engine.Tyrion_GoalBase implements ISensorNotification
	native
	abstract
	dependsOn(AI_Resource);

//=====================================================================
// Variables

var() bool bRemoveGoalOfSameType "remove an existing goal of the same type before adding this one";
var() bool bTryOnlyOnce "when true, don't try to achieve goal more than once (i.e. remove if it fails)";
var() int Priority "in the range [0, 100]; higher number means higher priority";
var() String goalName "reference to this goal for script actions";

var AI_SensorWithBounds activationSentinel;		// when triggered, switches goal to 'active'
var AI_SensorWithBounds deactivationSentinel;	// when triggered, switches goal to 'inactive'
var AI_Action achievingAction;			// the action achieving this goal
var AI_Action parentAction;				// the action that posted this goal
var bool bInactive;						// active / inactive (requires sensors for activation)
var bool bPermanent;					// achievable / permanent (goal remains after being achieved)
var bool bDeleted;						// set when this goal has been removed from "goals" list
var bool bGoalConsidered;				// was this goal considered by the matching process?
var bool bWakeUpPoster;					// when true, goal poster gets moved to 'Running' state upon goal's removal
var bool bTerminateIfStolen;			// when true, terminate goal poster if goal's resource gets stolen
var bool bGoalFailed;					// did the last action that ran on this goal fail to achieve it?
var bool bGoalAchieved;					// did the last action that ran on this goal achieve it?
var int ignoreCounter;					// ignore this goal for the specified number of ticks
var int matchedN;						// the number of times an action was matched to this goal

var AI_Resource resource;				// the resource this goal is attached to

//=====================================================================
// Functions

//---------------------------------------------------------------------
// ISensorNotification implementation

// Message notification function (callback) for activating/deactivating goals
function onSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	if ( userData == None )
	{
		deactivate();
	}
	else
	{
		activate();
	}
}

function AI_Resource getResource()
{
	return resource;
}

//---------------------------------------------------------------------
// Constructors

#if IG_SWAT
overloaded function construct()
{
    // not allowed, do not use this constructor!
    assert(false);
}
#endif

overloaded function construct( AI_Resource r )
{
	// log( "GOAL CONSTRUCTOR called on" @ name @ "(in" @ r.pawn().name $ ")" );
	init( r );
}

//---------------------------------------------------------------------
// Called explicitly at start of gameplay
// (equivalent to postBeginPlay for objects, used to initialize designer-placed goals)
// (called from goal constructor or in AI_Resource.init())

function init( AI_Resource r )
{
	if ( r == None )
		log( "AI WARNING:" @ name @ "(in" @ r.pawn().name $ ") given 'None' resource!" );
	if ( r != None && resource == r )
		log( "AI WARNING:" @ name @ "(in" @ r.pawn().name $ ") already initialized!" );

	resource = r;

	if ( activationSentinel == None )
		activationSentinel = new(r) class'AI_SensorWithBounds';
	if ( deactivationSentinel == None )
		deactivationSentinel = new(r) class'AI_SensorWithBounds';
}

//---------------------------------------------------------------------
// increments refCount and returns object

function AI_Goal myAddRef()
{
	AddRef();
	return self;
}

//----------------------------------------------------------------------
// returns the priority of this goal

event int priorityFn()
{
	return priority;
}

//----------------------------------------------------------------------
// Adds a goal to the AI_Resource
// Typically called by actions
// 'parent' can be None for top-level goals

function AI_Goal postGoal( AI_Action parent )
{
	local int i;

	if ( bRemoveGoalOfSameType )
	{
		for ( i = 0; i < resource.goals.length; ++i )
		{
			if ( resource.goals[i].class.name == class.name )
			{
				if ( resource.pawn().logTyrion )
					log( resource.pawn().name $ ": bRemoveGoalOfSameType = true; Replacing" @ resource.goals[i].name @ "with" @ name );

				AI_Goal(resource.goals[i]).unPostGoal( parentAction );
				break;
			}
		}
	}

	resource.addGoal( parent, self );
	//resource.resourceCheck( self );
	return self;
}

//----------------------------------------------------------------------
// Unpost a goal
// Typically called by actions
// You can only remove goals you yourself posted to your children
// 'parent' can be None for top-level goals
// It's ok to call unpostGoal on a goal that's already been unposted

function unPostGoal( AI_Action parent )
{
	if ( parent == parentAction )
	{
		// if action was waiting for this goal, start it running again
		if (bWakeUpPoster && parent != None && (--parent.waitingForGoalsN == 0) && parent.bIdle)
		{
			parent.runAction();
		}

		// remove the goal
		resource.removeGoal( self );
	}
	else
		log( "AI WARNING: invalid unPostGoal call." @ parent.name @ "does not own" @ name );
}

#if IG_SWAT
//----------------------------------------------------------------------
// Copies parameters and internal parameters from one goal to this goal

native function bool copyParametersFrom(AI_Goal otherGoal);
#endif

//---------------------------------------------------------------------
// Change the priority of a goal

function changePriority( int newPriority )
{
	if ( resource.pawn().logTyrion )
		log( name @ "priority changed from" @ priority @ "to" @ newPriority );

	priority = newPriority;
	if ( newpriority <= 0 )
		unPostGoal( parentAction );
	resource.bMatchGoals = true;	// re-evaluate goals
}

//---------------------------------------------------------------------
// Returns true if the goal has matched an action and that action has
// completed (failed or succeeded)
// Note: If by the time this function is called, a second action is
//       matched, the function still returns true

function bool hasCompleted()
{
	return ( bGoalFailed || bGoalAchieved );
}

//---------------------------------------------------------------------
// Returns true if the goal has matched an action and that action has
// achieved this goal

function bool wasAchieved()
{
	return ( bGoalAchieved );
}

//---------------------------------------------------------------------
// Returns true if the goal has matched an action and that action has
// *not* achieved this goal

function bool wasNotAchieved()
{
	return ( bGoalFailed );
}

//---------------------------------------------------------------------
// Returns true if the goal was considered by the goal-to-action matching
// process (even if no action was created for this goal)

function bool wasConsidered()
{
	return ( bGoalConsidered );
}

//---------------------------------------------------------------------
// Returns true if the goal is currently being achieved by an action

function bool beingAchieved()
{
	return ( achievingAction != None );
}

//---------------------------------------------------------------------
// Given the name of a goal, retrieve the object (or None)

#if IG_TRIBES3
static function AI_Goal findGoalByName( Actor a, String gName )
{
	local Character c;
	local SquadInfo si;
	local Turret turret;
	local Vehicle vehicle;

	c = Character(a);
	si = SquadInfo(a);
	turret = Turret(a);
	vehicle = Vehicle(a);

	if ( c != None )
		return findGoalInCharacterByName( c, gName );
	else if ( si != None )
		return findGoalInSquadByName( si, gName );
	else if ( vehicle != None )
		return findGoalInVehicleByName( vehicle, gName );
	else if (turret != None )
		return findGoalinTurretByName( turret, gName );
	else
		return None;
}
#endif

//---------------------------------------------------------------------
// Given the name of a goal in a Character, retrieve the object (or None)

#if IG_TRIBES3
static function AI_Goal findGoalInCharacterByName( Character c, String gName )
{
	local AI_Goal goal;

	goal = AI_Resource(c.characterAI).findGoalByName( gName );

	if ( goal == None )
		goal = AI_Resource(c.movementAI).findGoalByName( gName );
	if ( goal == None )
		goal = AI_Resource(c.weaponAI).findGoalByName( gName );
	if ( goal == None )
		goal = AI_Resource(c.headAI).findGoalByName( gName );

	return goal;
}
#endif

//---------------------------------------------------------------------
// Given the name of a goal in a SquadInfo, retrieve the object (or None)

#if IG_TRIBES3
static function AI_Goal findGoalInSquadByName( SquadInfo si, String gName )
{
	return AI_Resource(si.squadAI).findGoalByName( gName );
}
#endif

//---------------------------------------------------------------------
// Given the name of a goal in a Vehicle, retrieve the object (or None)

#if IG_TRIBES3
static function AI_Goal findGoalInVehicleByName( Vehicle vehicle, String gName )
{
	local int i;
	local AI_Goal goal;

	for ( i = 0; i < vehicle.positions.length; ++i )
	{
		goal = AI_Resource(vehicle.positions[i].toBePossessed.mountAI).findGoalByName( gName );
		if ( goal != None )
			return goal;
	}
	return None;
}
#endif

//---------------------------------------------------------------------
// Given the name of a goal in a Turret, retrieve the object (or None)

#if IG_TRIBES3
static function AI_Goal findGoalInTurretByName( Turret turret, String gName )
{
	return None;	// todo: implement
}
#endif

//---------------------------------------------------------------------
// Sets flags when a goal is achieved
// Low-level function - do not call directly

function markGoalAsAchieved()
{
	bGoalAchieved = true;
	bGoalFailed = false;
}

//---------------------------------------------------------------------
// remove goal etc.
// Low-level function - do not call directly

function handleGoalSuccess()
{
	//if ( resource == None )
	//	log( "AI Error: resource undefined in goalAchieved" );

	// activated goals are deactivated upon success
	if ( activationSentinel.sensor != None && !bInactive )
	{
		if ( resource.pawn().logTyrion )
			log( name @ "was just deactivated because the action achieving it succeeded!" );
		if ( deactivationSentinel.sensor != None )
		{
			deactivationSentinel.deactivateSentinel( self );	// if a permanent goal is achieved
			deactivationSentinel.sensor = None;
		}

		bInactive = true;
	}

	if ( bPermanent )
	{
		// Actions running on permanent goals call "succeed()" when they complete
		resource.bMatchGoals = true;	// goal is still around, so give a different action a chance
	}
	else
	{
		resource.removeGoal( self );	// deactivates sentinels
	}
}

//---------------------------------------------------------------------
// Sets flags when a goal is achieved
// Low-level function - do not call directly

function markGoalAsFailed()
{
	bGoalAchieved = false;
	bGoalFailed = true;
}

//---------------------------------------------------------------------
// remove goal etc.
// Low-level function - do not call directly

function handleGoalFailure()
{
	if ( bTryOnlyOnce )
	{
		// activated goals are not removed, but simply deactivated
		if ( activationSentinel.sensor != None && !bInactive )
		{
			if ( resource.pawn().logTyrion )
				log( name @ "was just deactivated because the action achieving it failed and goal was 'bTryOnce'!" );
			if ( deactivationSentinel.sensor != None )
			{
				deactivationSentinel.deactivateSentinel( self );	// if a permanent goal is achieved
				deactivationSentinel.sensor = None;
			}

			bInactive = true;
		}
		else
		{
			assert( !bPermanent );			// if it's a permanent goal you shouldn't be trying to remove it!
			if ( resource.pawn().logTyrion )
				log( name @ "(" @ resource.pawn().name @ ") bTryOnce = true: Removing" @ name );
			resource.removeGoal( self );	// deactivates sentinels
		}
	}
	else
	{
		resource.bMatchGoals = true;		// goal is still around, so give a different action a chance
		// think about putting in check to prevent the same action from repeatedly matching and failing?

		ignoreCounter = 1;
	}
}

//---------------------------------------------------------------------
// Deactivate a goal (switch from active to inactive, i.e. dormant)

function deactivate()
{
	if ( bInactive == false )
	{
		if ( resource.pawn().logTyrion )
			log( name @ "was just deactivated by its deactivationSentinel!" );
		bInactive = true;
		if ( achievingAction != None )
			achievingAction.interruptAction();
		if ( bPermanent )
		{
			if ( deactivationSentinel.sensor != None )
			{
				deactivationSentinel.deactivateSentinel( self );
				deactivationSentinel.sensor = None;
			}
		}
		else
			resource.removeGoal( self );	// deactivates sentinels
	}
}

//---------------------------------------------------------------------
// Activate a goal (switch from inactive to active)

function activate()
{
	if ( bInactive == true )
	{
		if ( resource.pawn().logTyrion )
			log( name @ "was just activated!" );
		bInactive = false;
		resource.bMatchGoals = true;	// optimization: may not have to be set to true all cases...
		//resource.resourceCheck( self );

		if ( deactivationSentinel.sensor != None )
		{
			log( "AI WARNING:" @ self @ "attempted to reset non-None deactivation sentinel");
			deactivationSentinel.deactivateSentinel( self );
			deactivationSentinel.sensor = None;
		}
		setupDeactivationSentinel();
	}
}

//---------------------------------------------------------------------
// Setup deactivation sentinel

function setUpDeactivationSentinel();

//---------------------------------------------------------------------
// Determining Default Priority

static function int GetDefaultPriority()
{
	return Default.priority;
}

//=====================================================================

defaultproperties
{
	priority = 50
	goalName = "<unnamed goal>"
	bWakeUpPoster = false
	bRemoveGoalOfSameType = false
	bTryOnlyOnce = false
}