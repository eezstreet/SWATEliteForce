///////////////////////////////////////////////////////////////////////////////
// SquadShareEquipmentAction.uc - SquadShareEquipmentAction class
// this action is used to organize the Officer's Share Equipment behavior

class SquadShareEquipmentAction extends OfficerSquadAction;
import enum EquipmentSlot from Engine.HandheldEquipment;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) EquipmentSlot Slot;

// determined during state code
var private ISwatOfficer GivingOfficer;
var private Pawn GivingPawn;

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	// if any of our goals fail, we succeed so we don't get reposted!
	if (goal.IsA('ShareEquipmentGoal'))
	{
		instantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

// Find which officer is the closest to the player
function DetermineGivingOfficer()
{
	GivingPawn = GetClosestOfficerWithEquipmentTo(Slot, CommandOrigin);
	GivingOfficer = ISwatOfficer(GivingPawn);
}

// Tell the officer to give equipment to the player
latent function ShareEquipment()
{
	local ShareEquipmentGoal CurrentGoal;

	CurrentGoal = new class'ShareEquipmentGoal'(AI_Resource(GivingPawn.characterAI), CommandGiver, Slot);
	CurrentGoal.AddRef();
	CurrentGoal.PostGoal(self);
	WaitForGoal(CurrentGoal);
	CurrentGoal.Release();
}

// Tell the officer to say "Roger" etc
function TriggerSpeech()
{
	GivingOfficer.GetOfficerSpeechManagerAction().TriggerGenericOrderReplySpeech();
}

state Running
{
Begin:
	DetermineGivingOfficer();
	TriggerSpeech();
	WaitForZulu();
	ShareEquipment();
	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadShareEquipmentGoal'
}
