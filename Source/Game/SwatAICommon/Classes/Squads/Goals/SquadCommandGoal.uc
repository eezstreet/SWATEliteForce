///////////////////////////////////////////////////////////////////////////////
// SquadCommandGoal.uc - SquadCommandGoal class
// this goal is the base class for all Swat Officer Squad Command goals

class SquadCommandGoal extends OfficerSquadGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) Pawn	CommandGiver;	// who gave us this goal
var(parameters) vector	CommandOrigin;	// where the command giver was when the goal was created
var(parameters) bool	bHasBeenCopied;	// whether we're a copy of another goal

var protected bool		bRepostElementGoalOnSubElementSquad;

///////////////////////////////////////////////////////////////////////////////
//
// Constructors

// Use this constructor
overloaded function construct( AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin )
{
	super.construct(r);

	assert(inCommandGiver != None);
	CommandGiver  = inCommandGiver;
	CommandOrigin = inCommandOrigin;
}

///////////////////////////////////////////////////////////////////////////////
//
// Behavior Copying

// subclasses should override and call down the chain
function CopyAdditionalPropertiesFromTemplate(SquadCommandGoal Template)
{
	Template.CommandGiver  = CommandGiver;
	Template.CommandOrigin = CommandOrigin;
}

function SetHasBeenCopied()
{
	bHasBeenCopied = true;
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function bool ShouldRepostElementGoalOnSubElementSquad()
{
	return bRepostElementGoalOnSubElementSquad;
}

function Door GetDoorBeingUsed()
{
	return None;
}

function bool IsInteractingWith(Actor TestActor)
{
	return false;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	bRepostElementGoalOnSubElementSquad = false
}