///////////////////////////////////////////////////////////////////////////////

class SquadDeployGrenadeLauncherGoal extends SquadCommandGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var(parameters) Actor TargetActor;		// takes precedence unless None
var(parameters) vector TargetLocation;

///////////////////////////////////////////////////////////////////////////////
//
// Constructors

// Use this constructor
overloaded function construct( AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin, Actor inTargetActor, vector inTargetLocation )
{
	super.construct(r, inCommandGiver, inCommandOrigin);

	TargetActor = inTargetActor;
	TargetLocation = inTargetLocation;
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function bool IsInteractingWith(Actor TestActor)
{
	return (TargetActor != None && TargetActor == TestActor);
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	goalName = "SquadDeployGrenadeLauncher"
    bIsCharacterInteractionCommandGoal=true
}