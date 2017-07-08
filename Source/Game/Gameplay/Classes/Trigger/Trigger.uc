class Trigger extends Engine.Actor
	hidecategories(Events)
	hidecategories(Force)
	hidecategories(Karma)
	hidecategories(Lighting)
	hidecategories(LightColor)
	hidecategories(Movement)
	hidecategories(Sound)
	abstract;

var() string debugLogString;

var() array<name> triggeredByFilter;

function bool canTrigger(Actor testActor)
{
	local int index;

	// if no actor is specified then all actors can trigger
	if (triggeredByFilter.length == 0)
		return true;

	for (index = 0; index < triggeredByFilter.length; ++index)
	{
		if (triggeredByFilter[index] == testActor.label)
			return true;
	}
	return false;
}

// dispatchMessage
function dispatchMessage(Message msg)
{
	log(self$".dispatchMessage: Use the 'dispatchTrigger' function to send messages from trigger classes.");
}

// dispatchTrigger
function bool dispatchTrigger(Actor instigator, MessageTrigger msg)
{
	local Pawn P;
	local PlayerController C;

	// debug log
	if (debugLogString != "")
	{
		P = Pawn(instigator);
		if (P != None)
		{
			C = PlayerController(P.Controller);
			if (C != None)
				C.ClientMessage("TRIGGER "$label$": "$debugLogString);
		}
	}

	super.dispatchMessage(msg);

	return true;
}

defaultproperties
{
    bHidden=True
    bCollideActors=True
	Texture=Texture'Engine_res.S_Trigger'
	bProjTarget = false
}
