///////////////////////////////////////////////////////////////////////////////
// AttackEnemyGoal.uc - AttackEnemyGoal class
// The goal that causes the AI to attack a particular enemy with any weapon it 
// has

class AttackEnemyGoal extends SwatCharacterGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var(parameters) private Pawn Enemy;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct(AI_Resource r, Pawn inEnemy)
{
	super.construct(r, priority);

	assert(inEnemy != None);
	Enemy = inEnemy;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Priority   = 85
    GoalName   = "AttackEnemy"
    bPermanent = false
}

