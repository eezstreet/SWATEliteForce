class Cuffs extends SwatGame.EquipmentUsedOnOther
    implements ITacticalAid;

var float LastInterruptTime;

simulated function bool CanUseOnOtherNow(Actor Other)
{
    local SwatPawn Pawn;

    Pawn = SwatPawn(Other);

    if (Pawn == None)
        return false;   //can't use cuffs on anything other than a SwatPawn

    if (Pawn.IsBeingArrestedNow())
        return false;   //currently being arrested (by someone else)

    return true;
}

simulated latent protected function OnUsingBegan()
{
    mplog( self$"---Cuffs::OnUsingBegan(). Other="$Other$", Owner="$Owner );

    Super.OnUsingBegan();

    //tcohen: there was a bug where if an arrest began and interrupted
    //  on the same frame, then the interrupt would happen before the begin
    //  (because PlayerController::PlayerTick() happens before
    //  ProcessState() on the Cuffs).
    //  So if we were interrupted on the same frame, then we'll ignore the
    //  begin.
    if (LastInterruptTime != Level.TimeSeconds)
        ICanBeArrested(Other).OnArrestBegan(Pawn(Owner));

    if (Pawn(Owner).GetHands() != None)
        Pawn(Owner).GetHands().SetNextIdleTweenTime(0.2);
}

simulated function UsedHook()
{
    local SwatGamePlayerController SGPC;

    mplog( self$"---Cuffs::UsedHook(). Other="$Other$", Owner="$Owner );

    Assert( Pawn(Other) != None );

    ICanBeArrested(Other).OnArrested(Pawn(Owner));

    //trigger PawnArrested here...
    if( Level.NetMode != NM_Client )
        SwatGameInfo(Level.Game).GameEvents.PawnArrested.Triggered( Pawn(Other), Pawn(Owner) );

    SGPC = SwatGamePlayerController(Pawn(Other).Controller);
    if( SGPC != None )
        SGPC.PostArrested();
}

//override from HandheldEquipment:
//Cuffs become unavailable even in Training
simulated function UpdateAvailability()
{
    if (UnavailableAfterUsed)
        SetAvailable(false);
}

// QualifiedUseEquipment overrides

simulated function OnInterrupted()
{
    mplog( self$"---Cuffs::OnInterrupted. Other="$Other$", Owner="$Owner );

    ICanBeArrested(Other).OnArrestInterrupted(Pawn(Owner));
    LastInterruptTime = Level.TimeSeconds;
}

simulated function bool ShouldUseAlternate()
{
    //use alternate animations in adversarial multiplayer
    return Level.NetMode != NM_Standalone && !Level.IsPlayingCOOP;
}

// IAmAQualifiedUseEquipment implementation

simulated function float GetQualifyDuration()
{
    return ICanBeArrested(Other).GetQualifyTimeForArrest(Pawn(Owner)); // Don't apply
}

// IAmUsedOnOther implementation

simulated protected function AssertOtherIsValid()
{
    assertWithDescription(Other.IsA('ICanBeArrested'),
        "[tcohen] Cuffs were called to AssertOtherIsValid(), but Other is a "$Other.class.name
        $", which is not an ICanBeArrested.");
}

//See HandheldEquipment::OnForgotten() for an explanation of the notion of "Forgotten".
//Cuffs become "magically" Available again after they have been Forgotten.
simulated function OnForgotten()
{
    SetAvailable(true);
}

defaultproperties
{
    Slot=SLOT_Cuffs
    UnavailableAfterUsed=true
	bAbleToMelee=true
}
