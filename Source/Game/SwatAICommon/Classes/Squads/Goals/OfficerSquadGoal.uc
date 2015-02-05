///////////////////////////////////////////////////////////////////////////////
// OfficerSquadGoal.uc - OfficerSquadGoal class
// this goal is the base class for all Swat Officer Squad goals

class OfficerSquadGoal extends Tyrion.AI_SquadGoal;
///////////////////////////////////////////////////////////////////////////////

var bool bIsCharacterInteractionCommandGoal;
var bool bHoldCommand;					// hold command until zulu order received

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	bTryOnlyOnce=false
    bIsCharacterInteractionCommandGoal=false
}
