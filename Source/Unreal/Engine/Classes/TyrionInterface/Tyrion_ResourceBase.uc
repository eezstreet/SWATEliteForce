//=====================================================================
// Tyrion_ResourceBase
// The Tyrion Resource class: Resources are the entities that can
// perform actions.
// This class should be embedded in every data structure that
// functions as a resource (such as Rook)
//=====================================================================

class Tyrion_ResourceBase extends Core.RefCount
	abstract
	threaded
	native;

//=====================================================================
// Constants

enum ResourceTypes
{
	RT_DEFAULT,
	RT_VEHICLE,
	RT_GUNNER,
	RT_DRIVER,
	RT_TURRET,
	RT_CHARACTER,
	RT_SQUAD,
	RT_ARMS,
	RT_LEGS,
	RT_HEAD
};

enum AI_LOD_Levels
{
	AILOD_NONE,		// AI doesn't know this rook exists; AI control must be activated in script
	AILOD_MINIMAL,	// AI does minimal processing on this rook to determine when it needs to activate full AI
	AILOD_IDLE,		// AI has rook perform idle animations, but no complex behavior; monitors whether to activate full AI
	AILOD_NORMAL,	// Normal AI control, can drop back to AILOD_Minimal
	AILOD_ALWAYS_ON	// Normal AI control, never changes LOD state
};

//=====================================================================
// Variables

var(AI) editinline DeepCopy array<Tyrion_GoalBase> goals;	// goals the resource is trying to achieve
var(AI)	editinline array<Tyrion_ActionBase> abilities;	// the actions this resource is capable of performing

var bool bMatchGoals;						// is action-to-goal matching necessary?
var bool bUnInitialized;					// resource still needs to be initialized?
var bool bGoalsReset;						// is goal list in its initial state?

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Called before the resource is first ticked

event init();

//---------------------------------------------------------------------
// Store a back pointer to the actor (pawn or squad) that this resource is attached to

function setResourceOwner( Actor p );

//---------------------------------------------------------------------
// Stores index of this resource in "positions" array
// (only used in vehicles)

function setIndex( int index );

//---------------------------------------------------------------------
// Clean up resource-related stuff when pawn dies

function cleanup();

//---------------------------------------------------------------------
// Delete all the sensors attached to this resource

function deleteSensors();

//---------------------------------------------------------------------
// Delete actions that have been removed from idle and running lists

event deleteRemovedActions();

//---------------------------------------------------------------------
// Mark all goals as achieved: this will reset the resource to have
// only permanent goals (used when a mount loses its driver)

event resetGoals();

//---------------------------------------------------------------------
// Should this resource be trying to satisfy goals?
// (A dead resource should not, for example)
// The default is true but individual resources can define their own logic

event bool isActive()
{
	return true;
}

//---------------------------------------------------------------------
// Does the resource have the sub-resources available to run an action?
// legspriority:  priority of the sub-goal that will be posted on the legs (0 if no goal)
// armsPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)
// headPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)

function bool requiredResourcesAvailable( int legsPriority, int armsPriority, optional int headPriority );

//---------------------------------------------------------------------
// Inform a resource that a particular pawn died

function pawnDied( Pawn pawn );

//---------------------------------------------------------------------
// Move designer-assigned goals to the resource

function assignGoal( class<Tyrion_GoalBase> goalClass )
{
	if ( goalClass != None )
	{
		if ( ClassIsChildOf( class, goalClass.static.getResourceClass() ) )
		{
			goals[goals.length] = new goalClass;	// goals.push( goalClass )
			goals[goals.length-1].addRef();			// corresponds to the one given by "addGoal()" for non-designer goals
			goals[goals.length-1].addRef();			// guarantees that designer-created goals never get deleted

			//log( name @ "added" @ goals[goals.length-1] @ "Outer:" @ goals[goals.length-1].Outer );
		}
	}
}

//---------------------------------------------------------------------
// Move designer-assigned abilities (actions) of type "resourceType" to the resource

function assignAbility( class<Tyrion_ActionBase> abilityClass )
{
	if ( abilityClass != None )
	{
		if ( ClassIsChildOf( class, abilityClass.static.getResourceClass() ) )
		{
			abilities[abilities.length] = new abilityClass;		// abilities.push( abilityClass )
			//log( name @ "added" @ abilities[abilities.length-1]);
		}
	}
}

//---------------------------------------------------------------------
// Called whenever time passes

native function Tick( float deltaTime );

//---------------------------------------------------------------------
// adds an ability to a resource

function addAbility(Tyrion_ActionBase newAbility)
{
    assert(NewAbility != None);
    abilities[abilities.Length] = newAbility;
}

//---------------------------------------------------------------------
// action/goal debug display function

function displayTyrionDebug();

//=====================================================================

defaultproperties
{
	bUnInitialized = true
	bGoalsReset = true
}

