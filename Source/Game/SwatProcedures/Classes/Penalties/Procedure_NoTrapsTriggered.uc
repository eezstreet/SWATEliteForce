class Procedure_NoTrapsTriggered extends SwatGame.Procedure
    implements  IInterested_GameEvent_BoobyTrapTriggered;

var config int PenaltyPerTrap;

var int NumTrapsTriggered;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.BoobyTrapTriggered.Register(self);
}

function OnBoobyTrapTriggered(SwatGame.BoobyTrap Pawn, Actor Triggerer)
{
  NumTrapsTriggered++;
  ChatMessageEvent('PenaltyIssued');
  GetGame().CampaignStats_TrackPenaltyIssued();

  if (GetGame().DebugLeadership)
      log("[LEADERSHIP] "$class.name
          $" added "$Pawn.name
          $" to its list of TrapTriggered");
}

function string Status()
{
    return string(NumTrapsTriggered);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
  log("[LEADERSHIP] "$class.name
    $" is returning with NumTrapsTriggered = "$ string(NumTrapsTriggered));
    return PenaltyPerTrap * NumTrapsTriggered;
}

/*defaultproperties
{
  NumTrapsTriggered = 0
}*/
