class EquipmentUsedOnOther extends QualifiedUseEquipment
    implements IAmUsedOnOther
    dependsOn(SwatGamePlayerController)
    abstract;

import enum EFocusInterface from SwatGamePlayerController;

var Actor Other;         //what this EquipmentUseOnOther is being UsedOn()

//called by the PlayerController when the player instigates Use of this HandheldEquipment
simulated function OnPlayerUse()
{
    local Actor DefaultFireFocusActor;
    local SwatGamePlayerController LPC;

    LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

    if( LPC != None )
        DefaultFireFocusActor = LPC.GetFocusInterface(Focus_Fire).GetDefaultFocusActor();

    if (DefaultFireFocusActor == None)  return; //TMC TODO feedback for nothing to use?

    // We have to store this in the controller, so when it goes to state
    // QualifyingForUse, it will have the target.
    LPC.OtherForQualifyingUse = DefaultFireFocusActor;

    // In a standalone game we immediately begin qualifying. In a network
    // game, we have to ask the server for permission before we begin
    // qualifying. When the server replies and permits us to begin,
    // the NetPlayer will call NetBeginQualifying below.
    if ( Level.NetMode == NM_Standalone )
    {
        if (!CanUseOnOtherNow(DefaultFireFocusActor))
            return;

        BeginQualifying( DefaultFireFocusActor );
    }
    else
    {
        SwatPlayer(Owner).ServerRequestQualify( DefaultFireFocusActor );
    }
}
simulated function bool CanUseOnOtherNow(Actor Other) { return true; }

simulated function BeginQualifying( Actor DefaultFireFocusActor )
{
    local SwatGamePlayerController ControllerOfOwner;

    mplog( self$"---EquipmentUsedOnOther::BeginQualifying()." );

    // Hey! If we are in a standalone game, we do the gotostate here. If we
    // are in a network game, we only do the gotostate on the server (and it's
    // replicated to the client), and we do it from ServerRequestQualify
    // instead of here.

    if ( Level.NetMode == NM_Standalone )
    {
        // We don't want the LPC. We want the Owner's Controller.
        ControllerOfOwner = SwatGamePlayerController( Pawn(Owner).Controller );
        if ( ControllerOfOwner != None )
        {
            ControllerOfOwner.GotoState('QualifyingForUse');
        }
    }

    UseOn(DefaultFireFocusActor);
}


// IAmUsedOnOther implementation

simulated function UseOn(Actor inOther)                 //FINAL, please
{
    Other = inOther;

    AssertOtherIsValid();

    Use();
}

simulated latent function LatentUseOn(Actor inOther)    //FINAL, please
{
    Other = inOther;

    AssertOtherIsValid();

    LatentUse();
}

simulated function Actor GetOther()
{
	return Other;
}

simulated protected function AssertOtherIsValid() { assert(false); } //subclasses must implement
