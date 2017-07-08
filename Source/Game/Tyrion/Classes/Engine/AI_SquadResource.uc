//=====================================================================
// AI_SquadResource
// Specialized AI_Resource for groups of characters
//=====================================================================

class AI_SquadResource extends AI_Resource
    native;

//=====================================================================
// Variables

var SquadInfo squad;	// contains list of pawns

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Store a back pointer to the actor (pawn or squad) that this resource is attached to

function setResourceOwner( Engine.Actor aSquad )
{
	squad = SquadInfo(aSquad);
}

//---------------------------------------------------------------------
// Called explicitly at start of gameplay

event init()
{
	// sensors are created here....

	super.init();
}

//---------------------------------------------------------------------
// perform resource-specific cleanup before resource is deleted

function cleanup()
{
	// Set sensorActions to None
	// ...

	super.cleanup();

	// don't delete squad object - squad sticks around even if all members are dead
}

//---------------------------------------------------------------------
// Does the resource have the sub-resources available to run an action?
// legspriority:  priority of the sub-goal that will be posted on the legs (0 if no goal)
// armsPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)
// headPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)

function bool requiredResourcesAvailable( int legsPriority, int armsPriority, optional int headPriority )
{
	local int i;

	// loop over all pawns p in the squad, return true if all of them have the resources available
	for ( i = 0; i < squad.pawns.length; i++ )
		if ( class'Pawn'.static.checkAlive( squad.pawns[i] ) )
			if ( !AI_CharacterResource(squad.pawns[i].characterAI).requiredResourcesAvailable( legsPriority, armsPriority, headPriority ) )
				return false;

	return true;
}

//---------------------------------------------------------------------
// Should this resource be trying to satisfy goals?
// todo: (optimization) store number of livingPawns with the squad

event bool hasActiveMembers()
{
	local int i;

	// loop over all pawns p in the squad
	for ( i = 0; i < squad.pawns.length; i++ )
		if ( class'Pawn'.static.checkAlive( squad.pawns[i] ) )
			return true;

	return false;
}

event bool isActive()
{
	return squad.AI_LOD_Level >= AILOD_NORMAL && hasActiveMembers();
}

//---------------------------------------------------------------------
// Accessor function

function Pawn pawn()
{
	local int i;

	if ( squad.pawns.length == 0 )
	{
		log( "AI WARNING:" @ name @ "contains no pawns." );
		return None;
	}
	else
	{
		for (i=0; i<squad.pawns.length; ++i)
		{
			if ( class'Pawn'.static.checkAlive( squad.pawns[i] ) )
			{
				return squad.pawns[i];
			}
		}

		log( "AI WARNING:" @ name @ "contains no ACTIVE pawns." );
		return None;
	}
}

//----------------------------------------------------------------------
// Return the corresponding action class for this type of resource

function class<AI_RunnableAction> getActionClass()
{
	return class'AI_SquadAction';
}

//=====================================================================

defaultproperties
{
}
