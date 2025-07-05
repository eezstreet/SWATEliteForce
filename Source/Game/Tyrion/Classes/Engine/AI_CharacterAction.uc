//=====================================================================
// AI_CharacterAction
// Actions that involve "character" resources (rooks, vehicles)
//=====================================================================

class AI_CharacterAction extends AI_Action
	abstract
    native;

//=====================================================================
// Variables

var Pawn pawn;
var AI_MovementResource movementResourceStorage;
var AI_WeaponResource weaponResourceStorage;

var AI_Goal DummyMovementGoal;
var AI_Goal DummyWeaponGoal;

//=====================================================================
// Functions

function cleanup()
{
	super.cleanup();

	if (DummyMovementGoal != None)
	{
		DummyMovementGoal.Release();
		DummyMovementGoal = None;
	}

	if (DummyWeaponGoal != None)
	{
		DummyWeaponGoal.Release();
		DummyWeaponGoal = None;
	}
}

function clearDummyMovementGoal()
{
	if (DummyMovementGoal != None)
	{
		DummyMovementGoal.unPostGoal(self);
		DummyMovementGoal.Release();
		DummyMovementGoal = None;
	}
}

function clearDummyWeaponGoal()
{
	if (DummyWeaponGoal != None)
	{
		DummyWeaponGoal.unPostGoal(self);
		DummyWeaponGoal.Release();
		DummyWeaponGoal = None;
	}
}

function clearDummyGoals()
{
	clearDummyMovementGoal();
	clearDummyWeaponGoal();
}

//=====================================================================
// Action Idioms

//---------------------------------------------------------------------
// Marks the specified resources as being "in use" by this action
// If any of the specified resources are stolen by another action, the action that called this
// function will terminate with a ACT_REQUIRED_RESOURCE_STOLEN message
// resourceBits: Using RU_x constants, specified which leaf resources a dummy action should be created for

latent function useResources( int resourceBits, optional int dummyGoalPriority )
{
	local int priority;
	local ACT_ErrorCodes errorCode;
	local AI_Goal movementGoal;
	local AI_Goal weaponGoal;

	if (dummyGoalPriority != 0)
	{
		priority = dummyGoalPriority;
	}
	else
	{
		priority = achievingGoal.priorityFn();
	}

//	log(Name $ " useResources - (resourceBits & resourceUsage & class'AI_Resource'.const.RU_ARMS ) " $ (resourceBits & resourceUsage & class'AI_Resource'.const.RU_ARMS ));

	if ( (resourceBits & resourceUsage & class'AI_Resource'.const.RU_ARMS ) != 0 )
	{
		weaponGoal =   (new class'AI_DummyWeaponGoal'( weaponResource(), priority )).postGoal( self ).myAddRef();
		weaponGoal.bTerminateIfStolen = true;
		//if ( pawn.logTyrion )
			log( "useResources:" @ weaponGoal.name @ "posted for" @ name );

		DummyWeaponGoal = weaponGoal;
		DummyWeaponGoal.addRef();
	}

//	log(Name $ " useResources - (resourceBits & resourceUsage & class'AI_Resource'.const.RU_LEGS ) " $ (resourceBits & resourceUsage & class'AI_Resource'.const.RU_LEGS ));

	if ( (resourceBits & resourceUsage & class'AI_Resource'.const.RU_LEGS ) != 0 )
	{
		movementGoal = (new class'AI_DummyMovementGoal'( movementResource(), priority )).postGoal( self ).myAddRef();
		movementGoal.bTerminateIfStolen = true;
		//if ( pawn.logTyrion )
			log( "useResources:" @ movementGoal.name @ "posted for" @ name );

		DummyMovementGoal = movementGoal;
		DummyMovementGoal.addRef();
	}

	if ( weaponGoal != None )
		waitForAllGoalsConsidered( weaponGoal, movementGoal );
	else
		waitForAllGoalsConsidered( movementGoal );

	if ( ( weaponGoal != None && !weaponGoal.beingAchieved() ) || ( movementGoal != None && !movementGoal.beingAchieved() ) )
	{
		//if ( pawn.logTyrion )
			log( "useResources:" @ name @ "failing because resources unavailable" );

		errorCode = ACT_INSUFFICIENT_RESOURCES_AVAILABLE;
	}

	if ( weaponGoal != None )
		weaponGoal.Release();

	if ( movementGoal != None )
		movementGoal.Release();

	if ( errorCode != ACT_SUCCESS )
		Fail( errorCode );
}

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Initialize a new action 
// 'goal' is the AI_Goal the action is achieving
// 'r' is the resource the action is running on
// Typically called by the resource - sets achievingAction

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction( r, goal );

	pawn = AI_CharacterResource(r).m_pawn;
	movementResourceStorage = AI_MovementResource(pawn.movementAI);
	weaponResourceStorage = AI_WeaponResource(pawn.weaponAI);
}

//---------------------------------------------------------------------
// Accessor function for resources

function AI_CharacterResource characterResource()
{
	return AI_CharacterResource(resource);
}

function AI_MovementResource movementResource()
{
	return movementResourceStorage;
}

function AI_WeaponResource weaponResource()
{
	return weaponResourceStorage;
}

//---------------------------------------------------------------------
// Return the resource class for this action

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_CharacterResource';
}

//---------------------------------------------------------------------
// Depending on the type of action, find the resource the action should
// be attached to

static function Tyrion_ResourceBase findResource( Pawn p )
{
	return p.characterAI;
}

//=======================================================================

function classConstruct()
{
	// character actions use all of a character's sub-resources by default
	resourceUsage = class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS | class'AI_Resource'.const.RU_HEAD;
}

defaultproperties
{
	//resourceUsage = 7 // should be RU_HEAD | RU_ARMS | RU_LEGS - can't access or use or's here;
}
