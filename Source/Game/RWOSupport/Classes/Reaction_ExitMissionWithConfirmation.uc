class Reaction_ExitMissionWithConfirmation extends Reaction;

protected simulated function Execute(Actor Owner, Actor Other)
{
    if( Owner.Level.NetMode == NM_Standalone && Owner.Level.GetLocalPlayerController() != None )
        Owner.Level.GetLocalPlayerController().OnMissionExitDoorUsed();
}
