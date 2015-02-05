class LowReadyInterface extends PlayerFocusInterface
    Config(PlayerInterface_LowReady)
    native;

var config float LowReadyRefractoryPeriod;          //after coming up from low-ready to fire, how long before player can go low-ready again to avoid flagging an officer
var private float LastTimeLowReadyRefractoryBegan;

var bool ShouldLowReady;
var name LowReadyReason;

//
// Update Sequence - See documentation above PlayerFocusInterface::PreUpdate()
//

simulated protected function ResetFocusHook(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    ShouldLowReady = false;
    LowReadyReason = '';
}

simulated protected event PostContextMatched(PlayerInterfaceContext inContext, Actor Target)
{
    local LowReadyInterfaceContext Context;
    Context = LowReadyInterfaceContext(inContext);
    LowReadyReason = Context.Reason;
}

simulated protected event PostDoorRelatedContextMatched(PlayerInterfaceDoorRelatedContext inContext, Actor Target)
{
    local LowReadyInterfaceDoorRelatedContext Context;
    Context = LowReadyInterfaceDoorRelatedContext(inContext);
    LowReadyReason = Context.Reason;
}

simulated protected event PostFocusAdded(PlayerInterfaceContext inContext, Actor Target, ESkeletalRegion SkeletalRegionHit)
{
    local LowReadyInterfaceContext Context;
    local HandheldEquipment ActiveItem;

    Context = LowReadyInterfaceContext(inContext);

    //when flagging officers, we don't low ready if we're in a low-ready refractory period
    if  (
            Target.IsA('SwatOfficer')
        &&  InLowReadyRefractoryPeriod()
        )
        return;

    ActiveItem = SwatPlayer(Level.GetLocalPlayerController().Pawn).GetActiveItem();

    if (Context.ShouldLowReady)
        ShouldLowReady = true;
}

simulated protected event PostDoorRelatedFocusAdded(PlayerInterfaceDoorRelatedContext inContext, Actor Target, ESkeletalRegion SkeletalRegionHit)
{
    local LowReadyInterfaceDoorRelatedContext Context;

    Context = LowReadyInterfaceDoorRelatedContext(inContext);

    if (Context.ShouldLowReady)
        ShouldLowReady = true;
}

simulated function PostUpdate(SwatGamePlayerController Player)
{
    local SwatPlayer PlayerPawn;
    local HandheldEquipment ActiveItem;
    local HUDPageBase HUD;

    PlayerPawn = SwatPlayer(Player.Pawn);
    ActiveItem = PlayerPawn.GetActiveItem();
    HUD = Player.GetHUDPage();

    //always low-ready in certain conditions:
    if  (
            (
                Player.ActiveViewport != None           //controlling a viewport
            &&  Player.bControlViewport != 0            //its an external viewport (not including the Optiwand)
            )
        ||  (
                Level.NetMode != NM_Standalone
            &&  PlayerPawn.CanBeArrestedNow()           //can be arrested
            )
        ||  (                                           //you have a preview icon for an item other that the current ActiveItem
                HUD.Reticle.CenterPreviewImage != None
            &&  ActiveItem != None
            &&  Player.EquipmentSlotForQualify != ActiveItem.GetSlot()
            )
        )
        ShouldLowReady = true;

    // If we shouldn't low ready, make sure the reason name is NULL'd out
    if (!ShouldLowReady)
        LowReadyReason = '';

    PlayerPawn.SetLowReady(ShouldLowReady, LowReadyReason);
}

//
// (End of Update Sequence)
//

simulated function bool InLowReadyRefractoryPeriod()
{
    return
        (
            LastTimeLowReadyRefractoryBegan > 0
        &&  Level.TimeSeconds < LastTimeLowReadyRefractoryBegan + LowReadyRefractoryPeriod
        );
}

simulated function BeginLowReadyRefractoryPeriod()
{
    LastTimeLowReadyRefractoryBegan = Level.TimeSeconds;
}

cpptext
{
    virtual UBOOL DoorRelatedContextMatches(UPlayerInterfaceDoorRelatedContext* DoorRelatedContext, ASwatDoor* Door);
    virtual UBOOL ContextMatches(UPlayerInterfaceContext* inContext, AActor* Candidate);
}

defaultproperties
{
    DoorRelatedContextClass=class'SwatGame.LowReadyInterfaceDoorRelatedContext'
    ContextClass=class'SwatGame.LowReadyInterfaceContext'
}
