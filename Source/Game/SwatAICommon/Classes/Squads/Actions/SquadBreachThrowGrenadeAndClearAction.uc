///////////////////////////////////////////////////////////////////////////////
// SquadBreachThrowGrenadeAndClearAction.uc - SquadBreachThrowGrenadeAndClearAction class
// this action is the base class for squad breach and throw grenades (bang, sting, or cs) command
// it is not actually an ability, simply a base class

class SquadBreachThrowGrenadeAndClearAction extends SquadBreachAndClearAction
	implements IInterestedInDetonatorEquipping;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// State code

// place and use the breaching charge, then throw the grenade
latent function PrepareToMoveSquad(optional bool bNoZuluCheck)
{
	MoveUpThrower();

	// the SquadBreachAndClearAction takes care of getting the door open
	super.PrepareToMoveSquad(bNoZuluCheck);		// <-- "WaitForZulu" happens here
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}