
class SwatAIController extends Tyrion.AI_Controller
    dependsOn(SwatAI)
	native;

///////////////////////////////////////////////////////////////////////////////
//
// Low-Level Hearing Implementation

event OnHearSound(Actor SoundMaker, vector SoundOrigin, Name SoundCategory)
{
	// temporary (probably want to catch this case earlier)
	if (SwatAI(pawn).hearing != None)
		SwatAI(pawn).hearing.OnHearSound(SoundMaker, SoundOrigin, SoundCategory);
}

///////////////////////////////////////////////////////////////////////////////

function TryGiveItemToPlayer(Pawn Player, HandheldEquipment EquipmentPiece)
{
	local HandheldEquipment ActiveItem;
	local float AddedWeight;
	local float AddedBulk;
	local SwatGamePlayerController PC;
	local SwatPawn Other;

	ActiveItem = EquipmentPiece;

	if(!ActiveItem.AllowedToPassItem())
	{
		log("Tried to give "$ActiveItem$" to "$Player$" but failed because NotAllowedToPassItem");
		return;
	}

	if(!class'Pawn'.static.checkConscious(Player))
	{
		return;
	}

	PC = SwatGamePlayerController(Player.Controller);
	Other = SwatPawn(Player);

	AddedWeight = EquipmentPiece.GetWeight();
	AddedBulk = EquipmentPiece.GetBulk();
	if(AddedWeight + Other.GetTotalWeight() > Other.GetMaximumWeight())
	{
		// this item adds too much weight, tell the client but still block the trace
		PC.ClientMessage("", 'CantReceiveTooMuchWeight');
		return;
	}
	else if(AddedBulk + Other.GetTotalBulk() > Other.GetMaximumBulk())
	{
		// this item adds too much bulk, tell the client but still block the trace
		PC.ClientMessage("", 'CantReceiveTooMuchBulk');
		return;
	}

	// Spawn in the actual equipment and give it to the other player
	Other.GivenEquipmentFromPawn(class<HandheldEquipment>(ActiveItem.static.GetGivenClass()));

	ActiveItem.DecrementAvailableCount();

	// Tell the client we received some new equipment
	PC.ClientMessage(ActiveItem.GetGivenEquipmentName()$"\t1\t"$SwatPawn(Pawn).GetHumanReadableName(), 'GaveYouEquipment');
	PC.ClientSentOrReceivedEquipment();
}

//=============================================================================

defaultProperties
{
}
