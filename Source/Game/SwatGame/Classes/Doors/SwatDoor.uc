class SwatDoor extends Engine.Door
	implements SwatAICommon.ISwatDoor,
        IAmUsedByToolkit,
        IAmUsedByWedge,
        IAmUsedByC2Charge,
        IHaveSkeletalRegions
    native
    abstract
	config(SwatGame);

import enum AIDoorUsageSide from SwatAICommon.ISwatAI;
import enum AIDoorCloseSide from SwatAICommon.ISwatAI;

var() bool bIsMissionExit "If true, when the player tries to open this door during a single-player mission he will be given the option to end the mission";
var() private bool bIsLocked;
var() private bool bCanBeLocked;
var private bool bWasInitiallyLocked;
var private bool bWasInitiallyOpen;
var bool bIsBroken; //PRIVATE PLEASE! TMC I made this public so that it can be accessed by gameplay scripts.  ONLY SWATDOOR SHOULD CHANGE THIS.
var() bool bIsAntiPortal "If true, this door will become an antiportal when closed";
var() Vector AntiPortalScaleFactor "Determines the scale of the door's antiportal relative to the door model's collision geometry. Don't change unless you know what you are doing!";
var private AntiPortalActor DoorAntiPortal; // antiportal actor for this door; may be none if the level was not built or bIsAntiPortal=false!
var() bool bIsPushable "If true, this AIs will treat this door like it doesn't have a doorknob.";
var() bool bPlayerCanUse "If false, then a Player is unable to interact with the door.";

var private bool        bIsBoobyTrapped;
var private bool				bBoobyTrapTripped;
var private BoobyTrap   BoobyTrap;

struct native DoorAttachmentSpec
{
    var() StaticMesh StaticMesh;
    var() name AttachSocket;
    var() vector AttachLocationOffset;
    var() Rotator AttachRotationOffset;
};

var() array<DoorAttachmentSpec> Attachments;

var() StaticMesh BrokenStaticMesh "This is the StaticMesh that will be used when the Door is broken";


var() private DoorPosition InitialPosition "The DoorPosition that the Door should start in";
var private DoorPosition CurrentPosition;

//in seconds, the time required to qualify to pick a door (lock) with a Toolkit
var config float QualifyTimeForToolkit;
//in seconds, the time required to qualify to wedge a door
var config float QualifyTimeForWedge;
//in seconds, the time required to qualify to place a C2Charge on a door
var config float QualifyTimeForC2Charge;

// The doorway is an invisible copy of the DoorModel's static mesh, and it does
// not move. It is used to define the region of space that is occupied by the
// DoorModel when the door is closed.
var DoorWay DoorWay;

var private nocopy array<LeftStackupPoint> LeftStackupPoints;
var private nocopy array<RightStackupPoint> RightStackupPoints;

var private nocopy array<LeftClearPoint> LeftClearPoints;
var private nocopy array<RightClearPoint> RightClearPoints;

var private nocopy array<StackupPoint> AlternateLeftStackupPoints;
var private nocopy array<StackupPoint> AlternateRightStackupPoints;

var() edfindable nocopy AlternateStackupPoint LeftAlternatePlacedStackupPoints[4];
var() edfindable nocopy AlternateStackupPoint RightAlternatePlacedStackupPoints[4];

var() float	LeftAdditionalGrenadeThrowDistance;
var() float	RightAdditionalGrenadeThrowDistance;

var string LeftRoomName "Name of the room to the right of this door (if looking from the hinge side of the door to the opposite side)";
var string RightRoomName "Name of the room to the left of this door (if looking from the hinge side of the door to the opposite side)";

var name LeftInternalRoomName;
var name RightInternalRoomName;

var private Pawn LastInteractor;
var private	Pawn PendingInteractor;

var() edfindable PlacedThrowPoint	LeftPlacedThrowPoint;
var() edfindable PlacedThrowPoint	RightPlacedThrowPoint;

// exposure to artists
var private config name				LeftSideBackOpenPointBoneName;
var private config name				LeftSideFrontOpenPointBoneName;
var private config name				LeftSideCenterOpenPointBoneName;

var private config name				RightSideBackOpenPointBoneName;
var private config name				RightSideFrontOpenPointBoneName;
var private config name				RightSideCenterOpenPointBoneName;

var private config name				OpenLeftAwayClosePointBoneName;
var private config name				OpenLeftTowardsClosePointBoneName;

var private config name				OpenRightAwayClosePointBoneName;
var private config name				OpenRightTowardsClosePointBoneName;

var private config name				RightSideKnobBreachPointBoneName;
var private config name				RightSideHingeBreachPointBoneName;

var private config name				LeftSideKnobBreachPointBoneName;
var private config name				LeftSideHingeBreachPointBoneName;

var private bool					bLeftSideBackOpenPointUsable;
var private bool					bLeftSideFrontOpenPointUsable;
var private bool					bLeftSideCenterOpenPointUsable;

var private bool					bRightSideBackOpenPointUsable;
var private bool					bRightSideFrontOpenPointUsable;
var private bool					bRightSideCenterOpenPointUsable;

var private bool					bRightSideKnobBreachPointUsable;
var private bool					bRightSideHingeBreachPointUsable;

var private bool					bLeftSideKnobBreachPointUsable;
var private bool					bLeftSideHingeBreachPointUsable;

var private vector					LeftSideBackOpenPoint;
var private vector					LeftSideFrontOpenPoint;
var private vector					LeftSideCenterOpenPoint;

var private vector					RightSideBackOpenPoint;
var private vector					RightSideFrontOpenPoint;
var private vector					RightSideCenterOpenPoint;

var private vector					RightSideKnobBreachPoint;
var private vector					RightSideHingeBreachPoint;

var private vector					LeftSideKnobBreachPoint;
var private vector					LeftSideHingeBreachPoint;

var private vector					OpenLeftAwayClosePoint;
var private vector					OpenLeftTowardsClosePoint;

var private vector					OpenRightAwayClosePoint;
var private vector					OpenRightTowardsClosePoint;

var private config name				LeftSideBackKnobOpenAnimation;
var private config name				LeftSideFrontKnobOpenAnimation;
var private config name				LeftSideCenterKnobOpenAnimation;

var private config name				LeftSideBackPushOpenAnimation;
var private config name				LeftSideFrontPushOpenAnimation;
var private config name				LeftSideCenterPushOpenAnimation;

var private config name				RightSideBackKnobOpenAnimation;
var private config name				RightSideFrontKnobOpenAnimation;
var private config name				RightSideCenterKnobOpenAnimation;

var private config name				RightSideBackPushOpenAnimation;
var private config name				RightSideFrontPushOpenAnimation;
var private config name				RightSideCenterPushOpenAnimation;

var private config name				LeftSideBackKnobTryAnimation;
var private config name				LeftSideFrontKnobTryAnimation;
var private config name				LeftSideCenterKnobTryAnimation;

var private config name				LeftSideBackPushTryAnimation;
var private config name				LeftSideFrontPushTryAnimation;
var private config name				LeftSideCenterPushTryAnimation;

var private config name				RightSideBackKnobTryAnimation;
var private config name				RightSideFrontKnobTryAnimation;
var private config name				RightSideCenterKnobTryAnimation;

var private config name				RightSideBackPushTryAnimation;
var private config name				RightSideFrontPushTryAnimation;
var private config name				RightSideCenterPushTryAnimation;

var private config name				LeftSideCenterFranticKnobOpenAnimation;
var private config name				RightSideCenterFranticKnobOpenAnimation;

var private config name				LeftSideCenterFranticPushOpenAnimation;
var private config name				RightSideCenterFranticPushOpenAnimation;

var private config name				OLBackTowardsKnobCloseAnimation;
var private config name				OLBackTowardsPushCloseAnimation;
var private config name				OLFrontTowardsKnobCloseAnimation;
var private config name				OLFrontTowardsPushCloseAnimation;
var private config name				OLFrontAwayKnobCloseAnimation;
var private config name				OLFrontAwayPushCloseAnimation;
var private config name				ORBackTowardsKnobCloseAnimation;
var private config name				ORBackTowardsPushCloseAnimation;
var private config name				ORFrontTowardsKnobCloseAnimation;
var private config name				ORFrontTowardsPushCloseAnimation;
var private config name				ORFrontAwayKnobCloseAnimation;
var private config name				ORFrontAwayPushCloseAnimation;

var private config float			MoveAndClearPauseThreshold;

// Keeps players in mp games from getting too close to a closed door.
var DoorBufferVolume                DoorBufferVolume;
var StaticMesh                      DoorBufferVolumeCollisionMesh;

var string DeployedWedgeClassName;
var class<Actor> DeployedWedgeClass;

var string DeployedC2ChargeClassName;
var class<Actor> DeployedC2ChargeClass;

var private DeployedWedgeBase    DeployedWedge;
var private DeployedC2ChargeBase DeployedC2ChargeLeft;
var private DeployedC2ChargeBase DeployedC2ChargeRight;

enum ECommandDirection
{
	CD_BothSides, // commands can be given from both sides of the door
	CD_LeftSide,  // commands can only be given from the left side of the door
	CD_RightSide, // commands can only be given from the right side of the door
    CD_NeitherSide // commands cannot be given on this door.
};

var() ECommandDirection AcceptsCommandsFrom "Only applies in single-player.  Designates the side from which squad commands can be given on this door. The side is determined by drawing an imaginary line from the door hinge to the doorknob; if the player is standing to the right of this line, then he/she is on the right side of the door. Doors which can be commanded from NeitherSide are only used for non-coop multiplayer maps.";

enum EExternalSide
{
	ES_NeitherSide, // Both sides of the door are "inside" the level
	ES_LeftSide,    // The left side of the door faces the "outside" of the level
	ES_RightSide    // The right side of the door faces the "outside" of the level
};

var() EExternalSide ExternalFacingSide "Designates which side of the door is facing the \"outside\". Hence if the door is ES_LeftSide and you are on the left side of the door, then \"Breach and Clear\" becomes \"Breach and Make Entry\" because you are going from the outside to the inside of the level.";

// Used internally to detect changes in AcceptsCommandsFrom and warn designers of
// potentially dangerous operations. Should not be accessed from script or used
// during gameplay.
var private const transient ECommandDirection PreviousAcceptsCommandsFrom;

var private array<IInterestedInDoorOpening>	InterestedInDoorOpeningRegistrants;

// An array of pawns currently blocking the door from opening.
// This shouldn't be used unless PositionIsBlocked was called immediately beforehand
var private array<Pawn> BlockingPawns;

// For this array, 1 means the door is known to be locked and 0 means that we
// know that the door is unlocked or we don't have any knowledge of it.
// The array is indexed by the Team number.
var private int LockedKnowledge[3];

// This enum provides the reason for a Moved() call and needs to be set along with PendingPosition
// before calling Moved()
enum EMoveReason
{
    MR_Interacted,
    MR_Breached,
    MR_Blasted
};
var private EMoveReason ReasonForMove;

// MCJ: When we do an instant move, the animation plays for one tick. We need
// to update the attachment locations after the animation finishes, so we have
// to do it in the subsequent ticks. We set this to a value and call
// UpdateAttachmentLocations() as long as it is nonzero (and decrement it each
// tick).
var private int RemainingUpdateAttachmentLocationsCounter;


///////////////////////////

replication
{
    reliable if (Role == Role_Authority)
        bIsLocked, bIsBroken, ReasonForMove, LockedKnowledge,
        DeployedWedge, DeployedC2ChargeLeft, DeployedC2ChargeRight;
}
///////////////////////////

//Returns the side on which the Door is currently angled,
//  or DoorPosition_Closed if the Door is closed (no direction)
simulated function DoorPosition GetPosition() { return CurrentPosition; }

simulated function bool IsChargePlacedOnLeft()    { return DeployedC2ChargeLeft.IsDeployed(); }
simulated function bool IsChargePlacedOnRight()   { return DeployedC2ChargeRight.IsDeployed(); }
simulated function bool WasDoorInitiallyLocked() { return bWasInitiallyLocked; }
simulated function bool WasDoorInitiallyOpen() { return bWasInitiallyOpen; }

simulated function PreBeginPlay()
{
    local int i;
    local DoorAttachment Attachment;

    Super.PreBeginPlay();

    assertWithDescription(Mesh != None,
        "[tcohen] The class "$class.name$" has no Mesh set.  Terry should fix this.");

    SetDrawType(DT_Mesh);

    //create attachments
    for (i=0; i<Attachments.length; ++i)
    {
        Attachment = Spawn(class'DoorAttachment', self);
        assert(Attachment != None);
        Attachment.SetStaticMesh(Attachments[i].StaticMesh);
        AttachToBone(Attachment, Attachments[i].AttachSocket);
        Attachment.SetRelativeLocation(Attachments[i].AttachLocationOffset);
        Attachment.SetRelativeRotation(Attachments[i].AttachRotationOffset);
    }

    //subclasses will initialize the door in PostBeginPlay()

    assertWithDescription(!IsLocked() || InitialPosition == DoorPosition_Closed,
        "[tcohen] The SwatDoor named "$name$" is set to start Locked but not Closed.");

    CurrentPosition = DoorPosition_Closed;    // set the door position to closed in case it was left open when a designer was viewing paths to the left or the right
    SetPositionForMove( GetInitialPosition(), MR_Interacted );
    Moved(true); //instantly to initial position

	// assert that a locked door can be locked,
	// and unlock the door if bCanBeLocked is false and the door is locked
	assertWithDescription((! bIsLocked || bCanBeLocked), Name $ " is locked, but bCanBeLocked is false!  This is bad, set either bIsLocked to false or bCanBeLocked to true in UnrealEd!  (In the meantime this door will be set to be unlocked.)");
	if (bIsLocked && !bCanBeLocked)
		bIsLocked = false;

	// save off whether we were initially locked
	bWasInitiallyLocked = bIsLocked;

	// save off whether we were initially open
	bWasInitiallyOpen   = IsOpen();

    if (DoorBufferVolume != None)
    {
        if (!IsOpen())
        {
            DoorBufferVolume.EnableRepulsion();
        }
        else
        {
            DoorBufferVolume.DisableRepulsion();
        }
    }

    //load the DeployedWedgeClass and DeployedC2ChargeClass because they are
    // created by designers
    DeployedWedgeClass    = class<Actor>(DynamicLoadObject(DeployedWedgeClassName,class'Class'));
    DeployedC2ChargeClass = class<Actor>(DynamicLoadObject(DeployedC2ChargeClassName,class'Class'));

    // Spawn the deployed wedge and c2 objects for this door
    SpawnDeployedWedge();
    SpawnDeployedC2ChargeLeft();
    SpawnDeployedC2ChargeRight();

    //SwatDoors should, by default, be bCollideActors.  Some AI pathing code changed the collision of doors, so I'm setting it here.
    SetCollision(true);

    //We've had problems with Doors' collision size which was being changed during level processing... so I'm resetting it to default at runtime:
    SetCollisionSize(default.CollisionRadius, default.CollisionHeight);

    // Init locked knowledge. Initially neither team knows whether a door is locked.
    LockedKnowledge[ 0 ] = 0;
    LockedKnowledge[ 1 ] = 0;
    LockedKnowledge[ 2 ] = 0;
}

simulated function PostBeginPlay()
{
    local vector DoorWayDrawScale3D;

	Super.PostBeginPlay();

	// doorway - spawn at center location
    DoorWay = Spawn(class'DoorWay', self);
    assert(DoorWay != None);
    DoorWay.SetStaticMesh(StaticMesh);

    DoorWay.SetDrawScale(DrawScale);

    DoorWayDrawScale3D=DrawScale3D;
    DoorWayDrawScale3D.Y *= 1.1;
    DoorWay.SetDrawScale3D(DoorWayDrawScale3D);
}

simulated function PostNetBeginPlay()
{
	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatDoor::PostNetBeginPlay()." );

    Super.PostNetBeginPlay();

//     mplog( "...CurrentPosition="$CurrentPosition );
//     mplog( "...PendingPosition="$PendingPosition );
//     mplog( "...DesiredPosition="$DesiredPosition );

//     if ( DesiredPosition != CurrentPosition )
//     {
//         PendingPosition = DesiredPosition;
//         Moved( true );
//     }
}


function Tick( float dTime )
{
    super.Tick( dTime );

    if ( RemainingUpdateAttachmentLocationsCounter > 0 )
    {
        RemainingUpdateAttachmentLocationsCounter--;

        if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
        {
			if (Level.GetEngine().EnableDevTools)
				mplog( "on server, updating attachment locations for door." );

            UpdateAttachmentLocations();
        }
    }
}


simulated function DoorPosition GetInitialPosition()
{
    return InitialPosition;
}

simulated function bool IsBoobyTrapped()
{
    return bIsBoobyTrapped;
}

simulated function bool TrapIsDisabledByC2()
{
	local BoobyTrap_Door Trap;

	if(!IsBoobyTrapped()) {
		return false;
	}

	Trap = BoobyTrap_Door(BoobyTrap);
	assert(Trap != None);

	return Trap.C2DisablesThis;
}

simulated function DisableBoobyTrap()
{
	if(!IsBoobyTrapped()) {
		return;
	}

	BoobyTrap.ReactToUsed(self);
	bIsBoobyTrapped = false;
}

simulated function SetBoobyTrap(BoobyTrap Trap)
{
    BoobyTrap = Trap;

		bBoobyTrapTripped = False;

    if ( Trap != None )
        bIsBoobyTrapped = True;
    else
        bIsBoobyTrapped = False;
}

simulated function BoobyTrapTriggered()
{
	if (BoobyTrap != None)
		bBoobyTrapTripped = True;
}

simulated function bool IsBoobyTrapTriggered()
{
	return bBoobyTrapTripped;
}


//
// Registering for Door Opening
//

private function bool IsInterestedInDoorOpeningRegistrant(IInterestedInDoorOpening Registrant)
{
	local int i;

	for(i=0; i<InterestedInDoorOpeningRegistrants.Length; ++i)
	{
		if (InterestedInDoorOpeningRegistrants[i] == Registrant)
			return true;
	}

	// didn't find it
	return false;
}

function RegisterInterestedInDoorOpening(IInterestedInDoorOpening Registrant)
{
	if(!IsInterestedInDoorOpeningRegistrant(Registrant))
		InterestedInDoorOpeningRegistrants[InterestedInDoorOpeningRegistrants.Length] = Registrant;
}

function UnRegisterInterestedInDoorOpening(IInterestedInDoorOpening Registrant)
{
	local int i;

	for(i=0; i<InterestedInDoorOpeningRegistrants.Length; ++i)
	{
		if (InterestedInDoorOpeningRegistrants[i] == Registrant)
		{
			InterestedInDoorOpeningRegistrants.Remove(i, 1);
			break;
		}
	}
}

private function NotifyRegistrantsDoorOpening()
{
	local int i;

	for(i=0; i<InterestedInDoorOpeningRegistrants.Length; ++i)
	{
		InterestedInDoorOpeningRegistrants[i].NotifyDoorOpening(self);
	}
}

//
// Interacting with a Door (ie. attempting to Open or Close it)
//

simulated function bool CanInteract()
{
    return /*!IsBroken() &&*/ !IsWedged();
}

//pass Force=true to interact even with a locked door
simulated function Interact(Pawn Other, optional bool Force)
{
    local SwatPawn PlayerPawn;
    local NetPlayer NetPlayerPawn;
    local SwatGamePlayerController PC;

    Assert( Level.NetMode != NM_Client );

    assertWithDescription(CanInteract(),
        "[tcohen] SwatDoor::Interact() "$Other
        $" tried to interact with "$name
        $", but CanInteract() is false.  IsBroken()="$IsBroken()
        $", IsWedged()="$IsWedged());

    dispatchMessage(new class'MessageUsed'(Other.label, self.label));

    //if missionexit door handle mission exiting
    if( bIsMissionExit && Level.NetMode == NM_Standalone )
    {
        PC = SwatGamePlayerController(Level.GetLocalPlayerController());
        if( PC != None )
            PC.OnMissionExitDoorUsed();
        return;
    }

	// save off the last person who interacted with this door
	LastInteractor = Other;

//	log(Name $ " Debug Interaction - IsClosed(): " $ IsClosed() $ " bIsLocked: " $ bIsLocked $ " Force: " $ Force);

	// if bForce is true, we are forcing a locked door to open
	// only block locked doors if they are closed (let them become closed again -- and stay locked)
    if (IsClosed() && bIsLocked && !Force)
    {
        BroadcastEffectEvent('LockedDoorTried');

        if( Level.GetLocalPlayerController() != None )
            PlayerPawn = SwatPawn(Level.GetLocalPlayerController().Pawn);

        if ( PlayerPawn != None && Other == PlayerPawn)
        {
            PlayerPawn.SetDoorLockedBelief(self, true);
        }
        if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
        {
            NetPlayerPawn = NetPlayer( Other );
            LockedKnowledge[ NetPlayerPawn.GetTeamNumber() ] = 1;

			if (Level.GetEngine().EnableDevTools)
				mplog("Saving locked door knowledge for pawn: "$NetPlayerPawn$", team number: "$NetPlayerPawn.GetTeamNumber());
        }
    }
    else
    {
		// if the door is locked but we're forcing it open, make it unlocked
		if (Force && bIsLocked && IsClosed())
		{
			bIsLocked = false;
		}

        switch (CurrentPosition)
        {
        case DoorPosition_Closed:

            if (ActorIsToMyLeft(Other))
                SetPositionForMove( DoorPosition_OpenRight, MR_Interacted );
            else
                SetPositionForMove( DoorPosition_OpenLeft, MR_Interacted );
            break;

        case DoorPosition_OpenLeft:
        case DoorPosition_OpenRight:

            SetPositionForMove( DoorPosition_Closed, MR_Interacted );
            break;

        default:
            assert(false);  //unexpected DoorPosition
        }

        Moved();
    }
}

simulated function OnWedged()
{
    TriggerEffectEvent('Wedged');
}

//called by DeployedWedgeBase::OnUsedByToolkit(), and the Wedge will hide itself (and also will be ! IsDeployed())
simulated function OnUnwedged()
{
    TriggerEffectEvent('UnWedged');
}


// It is not an error to call this function multiple times on the same
// door. If a door is bIsUnlocked
simulated function OnUnlocked()
{
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;
    local NetPlayer CurrentNetPlayer;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatDoor::OnUnlocked()." );

    // OnUnlocked() may be called multiple times on the same door due to
    // network issues. We use the bIsLocked variable as a guard so that we
    // only do stuff the first time OnUnlocked() is called.
    if ( !bIsLocked )
        return;

	bIsLocked = false;

    TriggerEffectEvent('Unlocked');

	// update officer door knowledge in standalone
	UpdateOfficerDoorKnowledge();

    if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
    {
        LockedKnowledge[0] = 0;
        LockedKnowledge[1] = 0;
        LockedKnowledge[2] = 2;

        // Notify all clients that the door is unlocked.
        theLocalPlayerController = Level.GetLocalPlayerController();
        for ( i = Level.ControllerList; i != None; i = i.NextController )
        {
            current = SwatGamePlayerController( i );
            if ( current != None )
            {
                CurrentNetPlayer = NetPlayer(current.SwatPlayer);
                if ( current != theLocalPlayerController )
                {
					if (Level.GetEngine().EnableDevTools)
						mplog( "...on server: calling OnDoorUnlocked() on "$CurrentNetPlayer );

                    CurrentNetPlayer.OnDoorUnlocked( self );
                }
            }
        }
    }
}

// FIXME: there might be more that's required to get this to work correctly..?
simulated function OnDoorLockedByOperator() {
	if(bIsLocked) {
		// See above note about bIsLocked
		return;
	}

	bIsLocked = true;
	TriggerEffectEvent('Unlocked');

	UpdateOfficerDoorKnowledge(true);

	LockedKnowledge[0] = 1;
	LockedKnowledge[1] = 1;
	LockedKnowledge[2] = 1;
}

simulated function bool KnowsDoorIsLocked( int TeamNumber )
{
    assert( Level.NetMode != NM_Standalone );
    assert( TeamNumber < 3 ); // dbeswick: used to be 2, now there are potentially 3 teams in coop
    return LockedKnowledge[TeamNumber] == 1;
}

//
// Antiportal handling
//

private simulated function bool IsAntiPortalOn()
{
	// if this door doesn't act as an antiportal, the antiportal is never on
	if (!bIsAntiPortal || bIsBroken)
		return false;

	if (DoorAntiPortal == None)
	{
		// bad internal state... maybe map wasn't rebuilt before running?
		if (Level.GetEngine().EnableDevTools)
			Log("InIsAntiPortalOn(): Door '"$self$"' is bIsAntiPortal=true but has no DoorAntiPortal associated with it! Did you make sure to rebuild the map before running? If so, contact a programmer.");

		return false;
	}

	// Antiportal is on if its drawtype is DT_AntiPortal (off when it is DT_None)
	return (DoorAntiPortal.DrawType == DT_AntiPortal);
}

private simulated function ReactivateNearbyRagdolls()
{
    local SwatRagdollPawn SwatRagdollPawn;
    foreach VisibleCollidingActors(class'SwatRagdollPawn', SwatRagdollPawn, CollisionRadius, Location)
    {
        // If this pawn is unconscious, and his physics is not havok
        if (!SwatRagdollPawn.IsConscious() && SwatRagdollPawn.Physics != PHYS_HavokSkeletal)
        {
            SwatRagdollPawn.BecomeRagdoll();
            SwatRagdollPawn.SetTimer(SwatRagdollPawn.GetRagdollSimulationTimeout(), false);
        }
    }
}

// Turn the antiportal actor associated with this door on/off
private simulated function SetAntiPortalAndMPBlockingVolume(bool Enabled)
{
	// Ignore if this door does not act as an antiportal
	if (bIsAntiPortal && DoorAntiPortal != None)
    {
	    if (Enabled && !bIsBroken)
	    {
		    //Log("Changing AntiPortalActor.DrawType for Door '"$self$"' from "$GetEnum(EDrawType, DoorAntiPortal.DrawType)$" to DT_AntiPortal");
		    DoorAntiPortal.SetDrawType(DT_AntiPortal);
	    }
	    else
	    {
		    //log("Changing AntiPortalActor.DrawType for Door '"$self$"' from "$GetEnum(EDrawType, DoorAntiPortal.DrawType)$" to DT_None");
		    DoorAntiPortal.SetDrawType(DT_None);
	    }

	    //assertWithDescription(!bIsAntiPortal || Enabled == IsAntiPortalOn(), "[ckline] After SetAntiPortalAndMPBlockingVolume("$Enabled$") on Door '"$self$"', IsAntiPortalOn() == "$(!Enabled)$" -- this is not right.");
		//mezzo: We dont need this assertion really anymore
    }

    if (DoorBufferVolume != None)
    {
        if (Enabled)
        {
            DoorBufferVolume.EnableRepulsion();
        }
        else
        {
            DoorBufferVolume.DisableRepulsion();
        }
    }
}

simulated function SetPositionForMove( DoorPosition inPositionForMove, EMoveReason inReasonForMove, optional bool bDontUpdateDesired )
{
    //log( self$"---SwatDoor::SetPositionForMove(). PositionForMove="$inPositionForMove$", reason="$inReasonForMove );
    PendingPosition =   inPositionForMove;
    ReasonForMove   =   inReasonForMove;
}

//
// Door Actions: Moved, Blasted, Breached
//

//will do nothing if door is already in PendingPosition
simulated function Moved(optional bool Instantly, optional bool Force)
{
	if (Level.GetEngine().EnableDevTools)
		log("TMC T"$Level.TimeSeconds$" SwatDoor::Moved() Instantly="$Instantly$", CurrentPosition="$GetEnum(DoorPosition, CurrentPosition)$", PendingPosition="$GetEnum(DoorPosition, PendingPosition));

    if (CurrentPosition == PendingPosition && !Force) return; //already there

    if (Instantly)
    {
        if ( Level.NetMode != NM_Client )
            DesiredPosition = PendingPosition;
        switch (PendingPosition)
        {
            case DoorPosition_Closed:
                PlayAnim('AtClosed');
                break;

            case DoorPosition_OpenLeft:
                PlayAnim('AtOpenLeft');
                break;

            case DoorPosition_OpenRight:
                PlayAnim('AtOpenRight');
                break;

            default:
                assert(false);  //unexpected DoorPosition value
        }

        CurrentPosition = PendingPosition;

        InitializeRemainingUpdateAttachmentLocationsCounter();

        // MCJ: I'm not sure the following code ever worked correctly. The
        // same functionality is now provided by the function call above.

        // If we move the door instantly, we will need to update the
        // attachment locations if we are not currently rendering the
        // door. Currently, this is not needed because we call Moved(true)
        // only in PreBeginPlay(), but I'm putting it in because it would be
        // necessary if we ever call Moved(true) at any other time.
        //UpdateAttachmentLocations();

        // Set antiportal state manually here (non-Instantly moves handle the
        // antiportal in BeginState of state Moving).
        //Log( self$" in SwatDoor::Moved(). PendingPosition = "$GetEnum(DoorPosition,PendingPosition)$" CurrentPosition = "$GetEnum(DoorPosition,CurrentPosition));
		if (CurrentPosition == DoorPosition_Closed)
		{
			SetAntiPortalAndMPBlockingVolume(true); // on
		}
		else
		{
			SetAntiPortalAndMPBlockingVolume(false); // off
		}
    }
    else    //!Instantly
    {
        // Carlos: Closing is handled the same regardless of MoveReason
        if (PendingPosition == DoorPosition_Closed && !Force)
        {
            if (PositionIsBlocked(CurrentPosition))
            {
				NotifyAIsBlockingDoorClose();
                NotifyClientsOfDoorBlocked( false );
                GotoState('ClosingBlocked');
            }
            else
            {
                if ( Level.NetMode != NM_Client )
                    DesiredPosition = PendingPosition;
                GotoState('Closing');
            }
        }
        else
        {
            switch(ReasonForMove)
            {
                case MR_Interacted:
                    // Door is opening normally so we need to test if it can be blocked or not...
                    if ( PositionIsBlocked(PendingPosition) )
                    {
                        NotifyAIsBlockingDoorOpen();
                        NotifyClientsOfDoorBlocked( true );
                        GotoState('OpeningBlocked');
                    }
                    else
                    {
                        if ( Level.NetMode != NM_Client )
                            DesiredPosition = PendingPosition;
                        GotoState('Opening');
                    }
                    break;

                case MR_Breached:
                    if ( Level.NetMode != NM_Client )
                        DesiredPosition = PendingPosition;
                    GotoState('BeingBreached');
                    break;

                case MR_Blasted:
                    if ( Level.NetMode != NM_Client )
                        DesiredPosition = PendingPosition;
                    GotoState('BeingBlasted');
                    break;
            }
        }
    }
}

private function NotifyAIsBlockingDoorClose()
{
	local int i;
	local SwatAI IterAI;

	for(i=0; i<BlockingPawns.Length; ++i)
	{
		IterAI = SwatAI(BlockingPawns[i]);

		// checkConscious does check if IterAI == None if the cast failed
		if ((IterAI != GetPendingInteractor()) && class'Pawn'.static.checkConscious(IterAI))
		{
			IterAI.NotifyBlockingDoorClose(self);
		}
	}
}

private function NotifyAIsBlockingDoorOpen()
{
	local int i;
	local SwatAI IterAI;

	for(i=0; i<BlockingPawns.Length; ++i)
	{
		IterAI = SwatAI(BlockingPawns[i]);

		// checkConscious does check if IterAI == None if the cast failed
		if ((IterAI != GetPendingInteractor()) && class'Pawn'.static.checkConscious(IterAI))
		{
			IterAI.NotifyBlockingDoorOpen(self);
		}
	}
}

// this is to notify other multiplayer clients that a door is blocked
function NotifyClientsOfDoorBlocked( bool OpeningBlocked )
{
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;

    if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
    {

		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---SwatDoor::NotifyClientsOfDoorBlocked(). OpeningBlocked="$OpeningBlocked );

        theLocalPlayerController = Level.GetLocalPlayerController();
        for ( i = Level.ControllerList; i != None; i = i.NextController )
        {
            current = SwatGamePlayerController( i );
            if ( current != None )
            {
                if (current != theLocalPlayerController)
                {
					if (Level.GetEngine().EnableDevTools)
						mplog( "...on server: calling ClientPlayDoorIsBlocked() on "$current$", SwatDoor="$self );

                    current.ClientPlayDoorBlocked( self, OpeningBlocked, PendingPosition );
                }
            }
        }
    }
}


// Note: In multiplayer function Blasted only happens on the server
function Blasted(Pawn Instigator)
{
    SetPositionForMove( CurrentPosition, MR_Blasted );	//We want the lock to be obliterated, but we dont want the door to swing open
    Moved(false, true); //not instantly, but force
	OnUnlocked();
}

// Note: In multiplayer function Blasted only happens on the server
function Breached(DeployedC2ChargeBase Charge)
{
    if ( IsClosed() || IsClosing() )
    {
        if (ActorIsToMyLeft(Charge))
            SetPositionForMove( DoorPosition_OpenRight, MR_Breached );
        else
            SetPositionForMove( DoorPosition_OpenLeft, MR_Breached );

        Moved(false, true); //not instantly, but force
    }
    else
    {
        PlayBreachedEffects();
        Broken();
    }
	OnUnlocked();
}

//
// Utility functions for Door actions
//

native function bool PointIsToMyLeft(vector Point);

// Returns true if the point is on the same side of the door as the side
// that the door is open to. If the door is closed, always returns false;
//
// If TreatOpeningDoorsAsClosed=false (the default), then a door that is opening
// but not yet fully open will be treated as if it is already fully open; if
// TreatOpeningDoorsAsClosed=true, then a door that is opening
// but not yet fully open will be treated as if it is closed.
function bool PointIsOnSideThatDoorIsOpenTo(vector Point, optional bool TreatOpeningDoorsAsClosed)
{
    if (IsClosed())
        return false;

    if ( PointIsToMyLeft(Point) )
        return IsOpenLeft() || (!TreatOpeningDoorsAsClosed && IsOpeningLeft());
    else
        return IsOpenRight() || (!TreatOpeningDoorsAsClosed && IsOpeningRight());
}

//returns true if Other is to the left of this Door (when facing in the direction the Door is facing)
simulated function bool ActorIsToMyLeft(Actor Other)
{
	return PointIsToMyLeft(Other.Location);
}

simulated event bool LocalPlayerIsToMyLeft()
{
    return ActorIsToMyLeft(Level.GetLocalPlayerController().Pawn);
}

simulated event bool PointIsOnExternalSide(vector Point)
{
	if ( ExternalFacingSide == ES_NeitherSide)
	{
		return false;
	}
	else if (ExternalFacingSide == ES_LeftSide)
	{
		return PointIsToMyLeft(Point);
	}
	else // ES_RightSide
	{
		return (!PointIsToMyLeft(Point));
	}
}

//returns true if there is a Pawn blocking the path of the door to or from TestPosition
simulated function bool PositionIsBlocked(DoorPosition TestPosition)  //TMC TODO test this function
{
    local Pawn Candidate;
    local vector PivotLocation;
    local DoorPosition TestSide;        //which side of the door do we need to test

    // Clients should never care whether the door is blocked or not. If the
    // door is blocked, the server will tell them to play the blocked
    // animation, but if the server says to Move(), we should just do it
    // regardless of whether pawns on the client seem to be blocking.
    if ( Level.NetMode == NM_Client )
        return false;

    if  (
            TestPosition == DoorPosition_OpenRight
        ||  CurrentPosition == DoorPosition_OpenRight
        )
        TestSide = DoorPosition_OpenRight;
    else
        TestSide = DoorPosition_OpenLeft;

    PivotLocation = GetPivotLocation();

	// clear out the blocking pawns array
	BlockingPawns.Remove(0, BlockingPawns.Length);

    //TMC I'm guessing that the sum of the Door's width and a potential blocker's radius will not exceed 200 units
    foreach RadiusActors(class'Pawn', Candidate, 200, PivotLocation)
	{
		// only concious AIs can block doors
        if (class'Pawn'.static.checkConscious(Candidate) &&
			LocationIsInSweep(PivotLocation, Candidate.Location, Candidate.CollisionRadius, TestSide))
		{
            BlockingPawns[BlockingPawns.Length] = Candidate;
		}
	}

    return (BlockingPawns.Length > 0);   //nobody is blocking
}

simulated function vector GetPivotLocation()
{
    return Location - Normal(vector(Rotation)) * CollisionRadius / 2.0;
}

simulated function bool LocationIsInSweep(vector DoorPivot, vector TestLocation, float TestLocationCollisionRadius, DoorPosition Side)
{
    local bool LocationIsToMyLeft;
    local Rotator OffsetRotation;       //a rotation offset 45degrees towards the Side
    local vector ConeOrigin, ConeDirection, ConeTarget;

    //the candidate is not in the way if it is on another level
    if ((TestLocation.Z - DoorPivot.Z) > CollisionHeight)
        return false;

    //the candidate is not in the way if it is too far away
    if (VSize(TestLocation - DoorPivot) > CollisionRadius + TestLocationCollisionRadius)
        return false;   //this candidate is a safe distance away

    //okay, so candidate is too close... but is it in the way?

    //the candidate is not in the way if if it is not on the test side
    LocationIsToMyLeft = PointIsToMyLeft(TestLocation);
    if  (
            LocationIsToMyLeft && Side == DoorPosition_OpenRight
        ||  !LocationIsToMyLeft && Side == DoorPosition_OpenLeft
        )
        return false;   //the candidate is on the other side we're testing

    //okay, so candidate is too close and its on the side we're testing... but is it within the Door's sweep?

    // The candidate is not in the way if it is outside of the sweep of the door
    //
    // We pick the rotation that represents the door half-closed (at 45
    // degree angle), and then we test to see if the TestLocation is
    // within 90 degrees (45 degrees in either direction) with a call to
    // PointWithinInfiniteCone(). If it's within 45 in either direction when
    // the door is half-closed, then it's within the sweep.

    if (Side == DoorPosition_OpenLeft)
        OffsetRotation = Rotation - rot(0, 8192, 0);
    else
        OffsetRotation = Rotation + rot(0, 8192, 0);

    // Treat cone and test location as if both are at the same height
    // (i.e. test in the XY-plane)
    ConeDirection = Vector(OffsetRotation);
    ConeDirection.Z = 0;

    ConeOrigin = DoorPivot;
    ConeOrigin.Z = 0;

    ConeTarget = TestLocation;
    ConeTarget.Z = 0;

    if (!PointWithinInfiniteCone( ConeOrigin, ConeDirection, ConeTarget, PI/2.f))
       return false;

    return true;    //candidate is blocking
}

simulated function UpdateOfficerDoorKnowledge(optional bool locking)
{
	local SwatAIRepository AIRepo;
    local SwatPawn PlayerPawn;

	// this is only necessary for standalone games
	if (Level.NetMode == NM_Standalone)
	{
		PlayerPawn = SwatPawn(Level.GetLocalPlayerController().Pawn);

		// update our knowledge (and any AI knowledge, if any AIs exist)
		// NOTE: this is different from before where the AI behavior would
		// update the door knowledge (wanted one codepath)
		AIRepo = SwatAIRepository(Level.AIRepo);

		if (AIRepo != None)
			AIRepo.UpdateDoorKnowledgeForOfficers(self);
		else                //no AIRepository... tell myself
			PlayerPawn.SetDoorLockedBelief(self, locking);
	}
}

simulated event bool PawnBelievesDoorLocked(SwatPawn Pawn)
{
    local PawnDoorKnowledge Info;
    local NetPlayer         NetPawn;

    Info = Pawn.GetDoorKnowledge(self);
    assert(Info != None);   //shouldn't try to get door knowledge on a SwatPawn with no door knowledge

    if ( Level.NetMode != NM_Standalone )
    {
        NetPawn = NetPlayer(Pawn);
        return KnowsDoorIsLocked(NetPawn.GetTeamNumber());
    } else
        return Info.DoesBelieveDoorLocked();
}

simulated function bool BelievesDoorLocked(Pawn p) {
	local SwatPawn SwatPawn_;

	SwatPawn_ = SwatPawn(p);
	return PawnBelievesDoorLocked(SwatPawn_);
}

simulated function Broken()
{
    if (!IsBroken())
    {
        bIsBroken = true;

        //remove any wedge
        if (IsWedged())
            DeployedWedge.OnRemoved();

		// update officer door knowledge in standalone
		UpdateOfficerDoorKnowledge();

        LockedKnowledge[0] = 0;
        LockedKnowledge[1] = 0;
        LockedKnowledge[2] = 0;

		// allow subclasses to extend functionality
        PostBroken();
    }
}
simulated function PostBroken();

//
// States for door behavior
//
// The state hierarchy is:
//
//  Moving
//      Opening
//      Closing
//      Blocked
//          OpeningBlocked
//          ClosingBlocked
//  BeingBlasted
//  BeingBreached
//

// Base State

simulated state Moving
{
    //Doors cannot (currently) interact while moving
    simulated function bool CanInteract() { return false; }

    simulated function Interact(Pawn Other, optional bool Force)
    {
        assertWithDescription(false,
            "[tcohen] "$name$" was called to Interact() but it is busy Moving.");
    }

    simulated function MoveToPosition(DoorPosition newPosition, optional bool Instantly)
    {
        assertWithDescription(false,
            "[tcohen] "$name$" was called to MoveToPosition() but it is already Moving.");
    }

    simulated function StartMoving()
    {
        assert(false);  //substates should override
    }

    simulated function bool MoveSucceeds()
    {
        return true;
    }

    simulated function OnMoveEnded()
    {
    }

    function Tick( float dTime )
    {
        super.Tick( dTime );

        UpdateAttachmentLocations();
    }

Begin:

    // If door is trying to open, turn off the antiportal
	if (PendingPosition != DoorPosition_Closed)
	{
		//Log( self$" in state Moving (1) of SwatDoor. PendingPosition = "$GetEnum(DoorPosition,PendingPosition)$" CurrentPosition = "$GetEnum(DoorPosition,CurrentPosition));
		SetAntiPortalAndMPBlockingVolume(false); // off
	}

    ReactivateNearbyRagdolls();
    StartMoving();

    FinishAnim();

    if (MoveSucceeds())
    {
        CurrentPosition = PendingPosition;
    }

	// If door is closed, make sure the antiportal is on
	//Log( self$" in state Moving (2) of SwatDoor. PendingPosition = "$GetEnum(DoorPosition,PendingPosition)$" CurrentPosition = "$GetEnum(DoorPosition,CurrentPosition));
	if (CurrentPosition == DoorPosition_Closed)
	{
		SetAntiPortalAndMPBlockingVolume(true); // on
	}

    OnMoveEnded();

    GotoState('');
}

//State Hierarchy: Moving -> Opening
simulated state Opening extends Moving
{
    simulated function StartMoving()
    {
		NotifyRegistrantsDoorOpening();

        if ( IsBoobyTrapped() && !GetLastInteractor().IsA('SwatEnemy') )
        {
            assert(BoobyTrap != None);
            BoobyTrap.OnTriggeredByDoor();
        }

        if (PendingPosition == DoorPosition_OpenLeft)
            PlayAnim('OpenLeft');
        else
            PlayAnim('OpenRight');
    }

	// WARNING: can't do per-state override of native functions, so this
	// is handled manually in ASwatDoor::IsOpening()
	//
	//	simulated function bool IsOpening() { return true; }

    simulated function OnMoveEnded()
    {
    }
}

//State Hierarchy: Moving -> Closing
simulated state Closing extends Moving
{
	// WARNING: can't do per-state override of native functions, so this
	// is handled manually in ASwatDoor::IsClosing()
	//
	//	simulated function bool IsClosing() { return true; }

    simulated function StartMoving()
    {
        if (CurrentPosition == DoorPosition_OpenLeft)
            PlayAnim('CloseFromLeft');
        else
            PlayAnim('CloseFromRight');
    }
}

//this happens when an attempt is made to Move a door that is blocked
//State Hierarchy: Moving -> Blocked
simulated state Blocked extends Moving
{
    simulated function bool MoveSucceeds()
    {
        return false;   //move fails if door is blocked
    }
}

//State Hierarchy: Moving -> Blocked -> OpeningBlocked
simulated state OpeningBlocked extends Blocked
{
    simulated function StartMoving()
    {
        if (PendingPosition == DoorPosition_OpenLeft)
            PlayAnim('CloseBlockedLeft');
        else
            PlayAnim('CloseBlockedRight');
    }
}

//State Hierarchy: Moving -> Blocked -> ClosingBlocked
simulated state ClosingBlocked extends Blocked
{
    simulated function StartMoving()
    {
        if (CurrentPosition == DoorPosition_OpenLeft)
            PlayAnim('OpenBlockedLeft');
        else
            PlayAnim('OpenBlockedRight');
    }
}

//State Hierarchy: Moving -> BeingBlasted
simulated state BeingBlasted extends Moving
{
    simulated function BeginState()
    {
        if (!IsBroken())
        {
            PlayBlastedEffects();
//            TriggerEffectEvent('Blasted');
            Broken();
        }
    }

    simulated function StartMoving()
    {
		NotifyRegistrantsDoorOpening();

        /*if (PendingPosition == DoorPosition_OpenLeft)
            PlayAnim('BlastedLeft');
        else
            PlayAnim('BlastedRight');*/

		if ( IsBoobyTrapped() )
		{
			assert(BoobyTrap != None);
			BoobyTrap.OnTriggeredByDoor();
		}
    }

    simulated function PlayBlastedEffects();    //implemented in subclasses
}

//State Hierarchy: Moving -> BeingBreached
simulated state BeingBreached extends Moving
{
    simulated function BeginState()
    {
        if (!IsBroken())
        {
            PlayBreachedEffects();
//            TriggerEffectEvent('Breached');
            Broken();
        }
    }

    simulated function StartMoving()
    {
				if(IsBoobyTrapped() && TrapIsDisabledByC2()) {
					DisableBoobyTrap();
				}

				NotifyRegistrantsDoorOpening();

        if (PendingPosition == DoorPosition_OpenLeft)
            PlayAnim('BreachedLeft');
        else
            PlayAnim('BreachedRight');

		if ( IsBoobyTrapped() && !GetLastInteractor().IsA('SwatEnemy') )
		{
			assert(BoobyTrap != None);
		    BoobyTrap.OnTriggeredByDoor();
		}
    }
}
simulated function PlayBreachedEffects();    //implemented in subclasses

simulated function PlayDoorBreached( DeployedC2ChargeBase TheCharge )
{
		if(IsBoobyTrapped() && TrapIsDisabledByC2()) {
			DisableBoobyTrap();
		}

    Assert( Level.NetMode == NM_Client );
    TheCharge.OnDetonated();
}


///////////////////////////////////////////////////////////////////////////////
//
// AI support

private function bool IsDoorOpenTowardsRequesterLocation(vector RequesterLocation)
{
	local bool bStackUpOnLeft, bDoorOpenLeft;

	if (!IsEmptyDoorWay() && IsOpen())
	{
		bStackUpOnLeft = PointIsToMyLeft(RequesterLocation);
		bDoorOpenLeft  = IsOpenLeft();

		// if the door is open on the same side as where we're stacking up
		if (bStackUpOnLeft == bDoorOpenLeft)
		{
			return true;
		}
	}

	return false;
}

//Returns an array of four StackupPoints, the ones that started
//  on the same side of the Door as Requester.
//  (They may have been moved, so they may not still be on the
//  same side.)
simulated function array<StackupPoint> GetStackupPoints(vector RequesterLocation)
{
    if (PointIsToMyLeft(RequesterLocation))
	{
		if (IsDoorOpenTowardsRequesterLocation(RequesterLocation))
		{
			return AlternateLeftStackupPoints;
		}
		else
		{
	        return LeftStackupPoints;
		}
	}
    else
	{
		if (IsDoorOpenTowardsRequesterLocation(RequesterLocation))
		{
			return AlternateRightStackupPoints;
		}
		else
		{
	        return RightStackupPoints;
		}
	}
}

//Returns an array of four ClearPoints that are on the other side
// of the door from the requester
simulated function array<ClearPoint> GetClearPoints(vector RequesterLocation)
{
    if (PointIsToMyLeft(RequesterLocation))
        return RightClearPoints;
    else
        return LeftClearPoints;
}

// Doors get added to two lists
simulated function AddSelfToRoomList()
{
	if ((LeftInternalRoomName == '') && (LeftRoomName != ""))
	{
		LeftInternalRoomName = name(LeftRoomName);
	}

	if ((RightInternalRoomName == '') && (RightRoomName != ""))
	{
		RightInternalRoomName = name(RightRoomName);
	}

	if (LeftInternalRoomName != '')
    {
        Level.AIRepo.AddNavigationPointToRoomList(self, LeftInternalRoomName);
    }

	if (RightInternalRoomName != '')
	{
		Level.AIRepo.AddNavigationPointToRoomList(self, RightInternalRoomName);
	}
}

simulated native function name GetLeftRoomName();
simulated native function name GetRightRoomName();

simulated function array<Actor> GetDoorModels()
{
	local array<Actor> Empty;
	return Empty;
}

private simulated function bool IsLeftSideFrontOpenPointUsable()
{
	return bLeftSideFrontOpenPointUsable && (!IsOpen() || ! IsOpenLeft());
}

private simulated function bool IsRightSideFrontOpenPointUsable()
{
	return bRightSideFrontOpenPointUsable && (!IsOpen() || IsOpenLeft());
}

private simulated function bool AreSideOpenPointsUsableFromSide(bool bOnLeftSideOfDoor)
{
	if (bOnLeftSideOfDoor)
	{
		return bLeftSideBackOpenPointUsable || IsLeftSideFrontOpenPointUsable();
	}
	else
	{
		return bRightSideBackOpenPointUsable || IsRightSideFrontOpenPointUsable();
	}
}

simulated function bool AreSideOpenPointsUsable(Pawn Other)
{
	if (ActorIsToMyLeft(Other))
	{
		return AreSideOpenPointsUsableFromSide(true);
	}
	else
	{
		return AreSideOpenPointsUsableFromSide(false);
	}
}

simulated function bool IsOfficerAtSideOpenPoint(Pawn Officer, bool bOnLeftSide)
{
	local AIDoorUsageSide DoorUsageSide;
	local vector OpenPoint;

	if (AreSideOpenPointsUsableFromSide(bOnLeftSide))
	{
		if (bOnLeftSide)
		{
			OpenPoint = GetClosestLeftOpenPointTo(Officer.Location, DoorUsageSide);
		}
		else
		{
			OpenPoint = GetClosestRightOpenPointTo(Officer.Location, DoorUsageSide);
		}

		return Officer.ReachedLocation(OpenPoint);
	}

	return false;
}

private simulated function bool AreSideBreachPointsUsableFromSide(bool bOnLeftSideOfDoor)
{
	if (bOnLeftSideOfDoor)
	{
		return bLeftSideKnobBreachPointUsable || bLeftSideHingeBreachPointUsable;
	}
	else
	{
		return bRightSideKnobBreachPointUsable || bRightSideHingeBreachPointUsable;
	}
}

simulated function bool AreSideBreachPointsUsable(Pawn Other)
{
	if (ActorIsToMyLeft(Other))
	{
		return AreSideBreachPointsUsableFromSide(true);
	}
	else
	{
		return AreSideBreachPointsUsableFromSide(false);
	}
}

simulated private function vector GetClosestLeftBreachPointTo(vector TargetLocation)
{
	local float KnobDistance, HingeDistance;

	KnobDistance  = VSize(LeftSideKnobBreachPoint - TargetLocation);
	HingeDistance = VSize(LeftSideHingeBreachPoint - TargetLocation);

	// one of them has to be usable, and we shouldn't get to this function otherwise
	assert(bLeftSideKnobBreachPointUsable || bLeftSideHingeBreachPointUsable);

	if (bLeftSideKnobBreachPointUsable && ((KnobDistance < HingeDistance) || !bLeftSideHingeBreachPointUsable))
	{
		return LeftSideKnobBreachPoint;
	}
	else
	{
		return LeftSideHingeBreachPoint;
	}
}

simulated private function vector GetClosestRightBreachPointTo(vector TargetLocation)
{
	local float KnobDistance, HingeDistance;

	KnobDistance  = VSize(RightSideKnobBreachPoint - TargetLocation);
	HingeDistance = VSize(RightSideHingeBreachPoint - TargetLocation);

	// one of them has to be usable, and we shouldn't get to this function otherwise
	assert(bRightSideKnobBreachPointUsable || bRightSideHingeBreachPointUsable);

	if (bRightSideKnobBreachPointUsable && ((KnobDistance < HingeDistance) || !bRightSideHingeBreachPointUsable))
	{
		return RightSideKnobBreachPoint;
	}
	else
	{
		return RightSideHingeBreachPoint;
	}
}


simulated function vector GetSideBreachPoint(Pawn Other)
{
	if (ActorIsToMyLeft(Other))
	{
		return GetClosestLeftBreachPointTo(Other.Location);
	}
	else
	{
		return GetClosestRightBreachPointTo(Other.Location);
	}
}

simulated function vector GetBreachFromPoint(Pawn Other)
{
	local AIDoorUsageSide DummyUsageSide;
	local vector BreachPoint;

	if (! AreSideBreachPointsUsable(Other))
	{
		BreachPoint = GetCenterOpenPoint(Other, DummyUsageSide);
	}
	else
	{
		BreachPoint = GetSideBreachPoint(Other);
	}

	return BreachPoint;
}

simulated function vector GetBreachAimPoint(Pawn Other)
{
	local vector BreachAimPoint;

	if (ActorIsToMyLeft(Other))
	{
		BreachAimPoint = GetBoneCoords('BreachAimLeft', true).Origin;
	}
	else
	{
		BreachAimPoint = GetBoneCoords('BreachAimRight', true).Origin;
	}

	return BreachAimPoint;
}

simulated function AIDoorUsageSide GetOpenPositions(Pawn Other, bool bPreferSides, out vector OpenPoint, out rotator PawnOpenRotation)
{
	local AIDoorUsageSide DoorUsageSide;

	assert(Other != None);

	if (! bPreferSides || !AreSideOpenPointsUsable(Other))
	{
		// just do the center
		OpenPoint        = GetCenterOpenPoint(Other, DoorUsageSide);
		PawnOpenRotation = GetCenterOpenRotation(OpenPoint);
	}
	else
	{
		// find the side open point
		OpenPoint        = GetSidesOpenPoint(Other, DoorUsageSide);
		PawnOpenRotation = GetSidesOpenRotation(OpenPoint);
	}

	return DoorUsageSide;
}

simulated private function rotator GetCenterOpenRotation(vector CenterOpenPoint)
{
	return rotator(Location - CenterOpenPoint);
}

simulated function rotator GetSidesOpenRotation(vector OpenPoint)
{
	if ((vector(Rotation) Dot Normal(Location - OpenPoint)) > 0)
    {
		return Rotation;
    }
    else
    {
		return Inverse(Rotation);
    }
}

simulated private function vector GetClosestLeftOpenPointTo(vector TargetLocation, out AIDoorUsageSide DoorUsageSide)
{
	local float BackDistance, FrontDistance;

	BackDistance  = VSize(LeftSideBackOpenPoint - TargetLocation);
	FrontDistance = VSize(LeftSideFrontOpenPoint - TargetLocation);

	// one of them has to be usable, and we shouldn't get to this function otherwise
	assert(bLeftSideBackOpenPointUsable || IsLeftSideFrontOpenPointUsable());

	if (bLeftSideBackOpenPointUsable && ((BackDistance < FrontDistance) || !IsLeftSideFrontOpenPointUsable()))
	{
		assert(bLeftSideBackOpenPointUsable);

		DoorUsageSide = kUseDoorBack;
		return LeftSideBackOpenPoint;
	}
	else
	{
		assert(IsLeftSideFrontOpenPointUsable());

		DoorUsageSide = kUseDoorFront;
		return LeftSideFrontOpenPoint;
	}
}

simulated private function vector GetClosestRightOpenPointTo(vector TargetLocation, out AIDoorUsageSide DoorUsageSide)
{
	local float BackDistance, FrontDistance;

	BackDistance  = VSize(RightSideBackOpenPoint - TargetLocation);
	FrontDistance = VSize(RightSideFrontOpenPoint - TargetLocation);

	// one of them has to be usable, and we shouldn't get to this function otherwise
	assert(bRightSideBackOpenPointUsable || IsRightSideFrontOpenPointUsable());

	// only use the back point if it's the closer one and it's usable
	if (bRightSideBackOpenPointUsable && ((BackDistance < FrontDistance) || !IsRightSideFrontOpenPointUsable()))
	{
		assert(bRightSideBackOpenPointUsable);

		DoorUsageSide = kUseDoorBack;
		return RightSideBackOpenPoint;
	}
	else
	{
		assert(IsRightSideFrontOpenPointUsable());

		DoorUsageSide = kUseDoorFront;
		return RightSideFrontOpenPoint;
	}
}

simulated private function vector GetSidesOpenPoint(Pawn Officer, out AIDoorUsageSide DoorUsageSide)
{
	assert(Officer.IsA('SwatOfficer'));

	if (ActorIsToMyLeft(Officer))
	{
		return GetClosestLeftOpenPointTo(Officer.Location, DoorUsageSide);
	}
	else
	{
		return GetClosestRightOpenPointTo(Officer.Location, DoorUsageSide);
	}
}

// we are just returning the center open points
simulated function vector GetCenterOpenPoint(Pawn Other, out AIDoorUsageSide DoorUsageSide)
{
	DoorUsageSide = kUseDoorCenter;

	if (ActorIsToMyLeft(Other))
	{
		return LeftSideCenterOpenPoint;
	}
	else
	{
		return RightSideCenterOpenPoint;
	}
}

// if we close from the left, return how we can close the door from the left.
// otherwise we return how we can close the door from the right
simulated function vector GetClosePoint(bool bCloseFromLeft)
{
	if (bCloseFromLeft)
	{
        if (CurrentPosition == DoorPosition_OpenLeft)
        {
			return OpenLeftTowardsClosePoint;
        }
        else
        {
			return OpenRightAwayClosePoint;
        }
	}
	else
	{
		if (CurrentPosition == DoorPosition_OpenLeft)
        {
			return OpenLeftAwayClosePoint;
		}
		else
		{
			return OpenRightTowardsClosePoint;
		}
    }
}

simulated function name GetLeftSideFrontOpenAnimation()
{
	if (bIsPushable)
	{
		return LeftSideFrontPushOpenAnimation;
	}
	else
	{
		return LeftSideFrontKnobOpenAnimation;
	}
}

simulated function name GetLeftSideBackOpenAnimation()
{
	if (bIsPushable)
	{
		return LeftSideBackPushOpenAnimation;
	}
	else
	{
		return LeftSideBackKnobOpenAnimation;
	}
}

simulated function name GetLeftSideCenterFranticOpenAnimation()
{
	if (bIsPushable)
	{
		return LeftSideCenterFranticPushOpenAnimation;
	}
	else
	{
		return LeftSideCenterFranticKnobOpenAnimation;
	}
}

simulated function name GetLeftSideCenterOpenAnimation()
{
	if (bIsPushable)
	{
		return LeftSideCenterPushOpenAnimation;
	}
	else
	{
		return LeftSideCenterKnobOpenAnimation;
	}
}

simulated function name GetRightSideFrontOpenAnimation()
{
	if (bIsPushable)
	{
		return RightSideFrontPushOpenAnimation;
	}
	else
	{
		return RightSideFrontKnobOpenAnimation;
	}
}

simulated function name GetRightSideBackOpenAnimation()
{
	if (bIsPushable)
	{
		return RightSideBackPushOpenAnimation;
	}
	else
	{
		return RightSideBackKnobOpenAnimation;
	}
}

simulated function name GetRightSideCenterFranticOpenAnimation()
{
	if (bIsPushable)
	{
		return RightSideCenterFranticPushOpenAnimation;
	}
	else
	{
		return RightSideCenterFranticKnobOpenAnimation;
	}
}

simulated function name GetRightSideCenterOpenAnimation()
{
	if (bIsPushable)
	{
		return RightSideCenterPushOpenAnimation;
	}
	else
	{
		return RightSideCenterKnobOpenAnimation;
	}
}


// just returning the center points animations
simulated function name GetOpenAnimation(Pawn Other, AIDoorUsageSide DoorUsageSide, optional bool bIsFranticOpen)
{
	if (ActorIsToMyLeft(Other))
	{
		if (DoorUsageSide == kUseDoorFront)
			return GetLeftSideFrontOpenAnimation();
		else if (DoorUsageSide == kUseDoorBack)
			return GetLeftSideBackOpenAnimation();
		else
		{
			if (bIsFranticOpen)
			{
				assert(DoorUsageSide == kUseDoorCenter);
				return GetLeftSideCenterFranticOpenAnimation();
			}
			else
			{
				return GetLeftSideCenterOpenAnimation();
			}
		}
	}
	else
	{
		if (DoorUsageSide == kUseDoorFront)
			return GetRightSideFrontOpenAnimation();
		else if (DoorUsageSide == kUseDoorBack)
			return GetRightSideBackOpenAnimation();
		else
		{
			if (bIsFranticOpen)
			{
				assert(DoorUsageSide == kUseDoorCenter);
				return GetRightSideCenterFranticOpenAnimation();
			}
			else
			{
				return GetRightSideCenterOpenAnimation();
			}
		}
	}
}

simulated function name GetOLBackTowardsCloseAnimation()
{
	if (bIsPushable)
	{
		return OLBackTowardsPushCloseAnimation;
	}
	else
	{
		return OLBackTowardsKnobCloseAnimation;
	}
}

simulated function name GetOLFrontTowardsCloseAnimation()
{
	if (bIsPushable)
	{
		return OLFrontTowardsPushCloseAnimation;
	}
	else
	{
		return OLFrontTowardsKnobCloseAnimation;
	}
}

simulated function name GetOLFrontAwayCloseAnimation()
{
	if (bIsPushable)
	{
		return OLFrontAwayPushCloseAnimation;
	}
	else
	{
		return OLFrontAwayKnobCloseAnimation;
	}
}

simulated function name GetORBackTowardsCloseAnimation()
{
	if (bIsPushable)
	{
		return ORBackTowardsPushCloseAnimation;
	}
	else
	{
		return ORBackTowardsKnobCloseAnimation;
	}
}

simulated function name GetORFrontTowardsCloseAnimation()
{
	if (bIsPushable)
	{
		return ORFrontTowardsPushCloseAnimation;
	}
	else
	{
		return ORFrontTowardsKnobCloseAnimation;
	}
}

simulated function name GetORFrontAwayCloseAnimation()
{
	if (bIsPushable)
	{
		return ORFrontAwayPushCloseAnimation;
	}
	else
	{
		return ORFrontAwayKnobCloseAnimation;
	}
}

// just returning the cneter points animations -- todo: support all points when they are added in.
simulated function name GetCloseAnimation(Pawn Other, bool bCloseFromBehind)
{
	if (CurrentPosition == DoorPosition_OpenLeft)
	{
		if (ActorIsToMyLeft(Other))
		{
			if (bCloseFromBehind)
			{
				return GetOLBackTowardsCloseAnimation();
			}
			else
			{
				return GetOLFrontTowardsCloseAnimation();
			}
		}
		else
		{
			return GetOLFrontAwayCloseAnimation();
		}
	}
	else
	{
		assert(CurrentPosition == DoorPosition_OpenRight);

		if (ActorIsToMyLeft(Other))
		{
			return GetORBackTowardsCloseAnimation();
		}
		else
		{
			if (bCloseFromBehind)
			{
				return GetORFrontTowardsCloseAnimation();
			}
			else
			{
				return GetORFrontAwayCloseAnimation();
			}
		}
	}
}

simulated function name GetLeftSideFrontTryAnimation()
{
	if (bIsPushable)
	{
		return LeftSideFrontPushTryAnimation;
	}
	else
	{
		return LeftSideFrontKnobTryAnimation;
	}
}

simulated function name GetLeftSideBackTryAnimation()
{
	if (bIsPushable)
	{
		return LeftSideBackPushTryAnimation;
	}
	else
	{
		return LeftSideBackKnobTryAnimation;
	}
}

simulated function name GetLeftSideCenterTryAnimation()
{
	if (bIsPushable)
	{
		return LeftSideCenterPushTryAnimation;
	}
	else
	{
		return LeftSideCenterKnobTryAnimation;
	}
}

simulated function name GetRightSideFrontTryAnimation()
{
	if (bIsPushable)
	{
		return RightSideFrontPushTryAnimation;
	}
	else
	{
		return RightSideFrontKnobTryAnimation;
	}
}

simulated function name GetRightSideBackTryAnimation()
{
	if (bIsPushable)
	{
		return RightSideBackPushTryAnimation;
	}
	else
	{
		return RightSideBackKnobTryAnimation;
	}
}

simulated function name GetRightSideCenterTryAnimation()
{
	if (bIsPushable)
	{
		return RightSideCenterPushTryAnimation;
	}
	else
	{
		return RightSideCenterKnobTryAnimation;
	}
}

simulated function name GetTryDoorAnimation(Pawn Other, AIDoorUsageSide DoorUsageSide)
{
	if (ActorIsToMyLeft(Other))
	{
		if (DoorUsageSide == kUseDoorFront)
			return GetLeftSideFrontTryAnimation();
		else if (DoorUsageSide == kUseDoorBack)
			return GetLeftSideBackTryAnimation();
		else
			return GetLeftSideCenterTryAnimation();
	}
	else
	{
		if (DoorUsageSide == kUseDoorFront)
			return GetRightSideFrontTryAnimation();
		else if (DoorUsageSide == kUseDoorBack)
			return GetRightSideBackTryAnimation();
		else
			return GetRightSideCenterTryAnimation();
	}
}

simulated function Pawn GetLastInteractor()
{
	return LastInteractor;
}

simulated function Pawn GetPendingInteractor()
{
	if (! class'Pawn'.static.checkConscious(PendingInteractor) ||
		((AI_Resource(PendingInteractor.movementAI).findGoalByName("OpenDoor") == None) &&
	 	 (AI_Resource(PendingInteractor.movementAI).findGoalByName("CloseDoor") == None)))
	{
		PendingInteractor = None;
	}

	return PendingInteractor;
}

simulated function SetPendingInteractor(Pawn Interactor)
{
	PendingInteractor = Interactor;
}


// only for doors opening the opposite of the Other
simulated function bool IsBlockedFor(Pawn Other)
{
	if (ActorIsToMyLeft(Other))
	{
		return PositionIsBlocked(DoorPosition_OpenRight);
	}
	else
	{
		return PositionIsBlocked(DoorPosition_OpenLeft);
	}
}

// requires that the BlockingPawns array is "fresh",
// this should only be called after somebody tries to open the door
simulated function bool WasBlockedBy(name BlockedClassName)
{
	local int i;

	for(i=0; i<BlockingPawns.Length; ++i)
	{
		if (class'Pawn'.static.checkConscious(BlockingPawns[i]) && BlockingPawns[i].IsA(BlockedClassName))
			return true;
	}

	return false;
}

// return the placed throw point, if any (it's ok to return none), for a pawn
simulated function PlacedThrowPoint GetPlacedThrowPoint(vector Origin)
{
	if (PointIsToMyLeft(Origin))
	{
		return LeftPlacedThrowPoint;
	}
	else
	{
		return RightPlacedThrowPoint;
	}
}

simulated function float GetAdditionalGrenadeThrowDistance(vector Origin)
{
	if (PointIsToMyLeft(Origin))
	{
		return LeftAdditionalGrenadeThrowDistance;
	}
	else
	{
		return RightAdditionalGrenadeThrowDistance;
	}
}

simulated function bool CanBeLocked()
{
	return (bCanBeLocked && IsClosed() && !IsOpening() && !IsBroken() && !IsEmptyDoorway());
}

simulated function Lock()
{
	assertWithDescription(CanBeLocked(), "SwatDoor::Lock - CanBeLocked return false!");

    // Clients get their value replicated from the server.
    if ( Level.NetMode != NM_Client )
        bIsLocked = true;
}

simulated function float GetMoveAndClearPauseThreshold()
{
	return MoveAndClearPauseThreshold;
}

// deployed tactical aid support

// spawners

function SpawnDeployedWedge()
{
    // we expect this only to be run on the server, and called only once for
    // a given door's lifetime
    assert(Level.NetMode != NM_Client);
    assert(DeployedWedge == None);

    DeployedWedge = DeployedWedgeBase(Spawn(DeployedWedgeClass));

    assertWithDescription(DeployedWedge != None,
        "[tcohen] SwatDoor couldn't Spawn a DeployedWedge.  DeployedWedgeClassName="$DeployedWedgeClassName
        $", which resolves to DeployedWedgeClass="$DeployedWedgeClass
        $".");

    DeployedWedge.SetAssociatedDoor(self);
    DeployedWedge.SetLocation(GetBoneCoords('DoorWedge', true).Origin);
}

function SpawnDeployedC2ChargeLeft()
{
    assert(Level.NetMode != NM_Client);
    assert(DeployedC2ChargeLeft == None);

    DeployedC2ChargeLeft = DeployedC2ChargeBase(Spawn(DeployedC2ChargeClass));

    assertWithDescription(DeployedC2ChargeLeft != None,
        "[tcohen] SwatDoor couldn't Spawn a DeployedC2ChargeLeft.  DeployedC2ChargeClassName="$DeployedC2ChargeClassName
        $", which resolves to DeployedC2ChargeClass="$DeployedC2ChargeClass
        $".");

    DeployedC2ChargeLeft.SetAssociatedDoor(self);
    AttachToBone(DeployedC2ChargeLeft, 'C2ChargeLeft');
}

function SpawnDeployedC2ChargeRight()
{
    assert(Level.NetMode != NM_Client);
    assert(DeployedC2ChargeRight == None);

    DeployedC2ChargeRight = DeployedC2ChargeBase(Spawn(DeployedC2ChargeClass));

    assertWithDescription(DeployedC2ChargeRight != None,
        "[tcohen] SwatDoor couldn't Spawn a DeployedC2ChargeRight.  DeployedC2ChargeClassName="$DeployedC2ChargeClassName
        $", which resolves to DeployedC2ChargeClass="$DeployedC2ChargeClass
        $".");

    DeployedC2ChargeRight.SetAssociatedDoor(self);
    AttachToBone(DeployedC2ChargeRight, 'C2ChargeRight');
}

// accessors

simulated function DeployedWedgeBase GetDeployedWedge()
{
	if (DeployedWedge.IsDeployed())
	{
		return DeployedWedge;
	}
	else
	{
		return None;
	}
}

simulated function DeployedC2ChargeBase GetDeployedC2ChargeLeft()
{
	if (DeployedC2ChargeLeft.IsDeployed())
	{
		return DeployedC2ChargeLeft;
	}
	else
	{
		return None;
	}
}

simulated function DeployedC2ChargeBase GetDeployedC2ChargeRight()
{
	if (DeployedC2ChargeRight.IsDeployed())
	{
	    return DeployedC2ChargeRight;
	}
	else
	{
		return None;
	}
}

simulated event bool IsC2ChargeOnPlayersSide()
{
    if (ActorIsToMyLeft(Level.GetLocalPlayerController().Pawn))
        return IsChargePlacedOnLeft();
    else
        return IsChargePlacedOnRight();
}

// IAmUsedByToolkit implementation

// Return true iff this can be operated by a toolkit now
simulated function bool CanBeUsedByToolkitNow()
{
	return CanBeLocked();
}

// Called when qualifying begins.
function OnUsingByToolkitBegan( Pawn User );

// Called when qualifying completes successfully.
simulated function OnUsedByToolkit(Pawn User)
{
	if(bIsLocked || BelievesDoorLocked(User)) {
    OnUnlocked();
	} else {
		OnDoorLockedByOperator();
	}
}

// Called when qualifying is interrupted.
function OnUsingByToolkitInterrupted( Pawn User );


//return the time to qualify to use this with a Toolkit
simulated function float GetQualifyTimeForToolkit()
{
    return QualifyTimeForToolkit;
}

native function vector GetSkeletalRegionCenter(ESkeletalRegion Region);

// IAmUsedByWedge implementation

simulated function OnUsedByWedge()
{
    local bool CanDoorBeWedgedNow;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatDoor::OnUsedByWedge()." );

    CanDoorBeWedgedNow = IsClosed() && !IsOpening() && !IsBroken();
    if ( !CanDoorBeWedgedNow  )
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( "...door was not closed and stationary and not broken. Doing nothing..." );

        return;
    }

	if (Level.GetEngine().EnableDevTools)
		mplog( "...door was closed and stationary and not broken. Deploying wedge..." );

    DeployedWedge.OnDeployed();
    OnWedged();
}

//return the time to qualify to use this with a Wedge
simulated function float GetQualifyTimeForWedge()
{
    return QualifyTimeForWedge;
}

// IAmUsedByC2Charge implementation

simulated function OnUsedByC2Charge(ICanUseC2Charge Instigator)
{
    local DeployedC2ChargeBase Charge;

    if (ActorIsToMyLeft(Pawn(Instigator)))
    {
        Charge = DeployedC2ChargeLeft;
    }
    else
    {
        Charge = DeployedC2ChargeRight;
    }

    Instigator.SetDeployedC2Charge(Charge);
    Charge.OnDeployed(SwatPawn(Instigator));
}

//return the time to qualify to use this with a C2Charge
simulated function float GetQualifyTimeForC2Charge()
{
    return QualifyTimeForC2Charge;
}

// IHaveSkeletalRegions implementation

// Notification that we were hit
simulated function OnSkeletalRegionHit(ESkeletalRegion RegionHit, vector HitLocation, vector HitNormal, int Damage, class<DamageType> DamageType, Actor Instigator)
{
    //if a SwatDoor's REGION_Door_BreachingSpot is hit by a ShotgunDamageType, then the door has been blasted.
    if (RegionHit == REGION_Door_BreachingSpot)
    {
        assertWithDescription(Instigator.IsA('SwatPawn'),
            "[tcohen] SwatDoor::OnSkeletalRegionHit() RegionHit is REGION_Door_BreachingSpot and DamageType is FrangibleBreachingAmmo, but Instigator is not a SwatPawn.");
        Blasted(SwatPawn(Instigator));
    }
}


simulated event DesiredPositionChanged()
{
	if (Level.GetEngine().EnableDevTools)
	{
		mplog( self$"---SwatDoor::DesiredPositionChanged(). DesiredPosition="$DesiredPosition );

		mplog( "...CurrentPosition="$CurrentPosition );
		mplog( "...PendingPosition="$PendingPosition );
		mplog( "...DesiredPosition="$DesiredPosition );
    }

    // We don't want sounds to be played on empty doorways.
    if ( !IsEmptyDoorway() )
    {
        PendingPosition = DesiredPosition;
        Moved( false, true );
    }
}

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
//debugging
simulated function TestBlocking(Pawn Pawn, int Times)
{
    local vector TestLocation, PivotLocation;
    local DoorPosition TestSide;        //which side of the door do we need to test
    local int i;

    if (ActorIsToMyLeft(Pawn))
        TestSide = DoorPosition_OpenLeft;
    else
        TestSide = DoorPosition_OpenRight;

    PivotLocation = GetPivotLocation();

    for (i=0; i<Times; ++i)
    {
        TestLocation.X = Location.X + Rand(200) - 100;
        TestLocation.Y = Location.Y + Rand(200) - 100;
        TestLocation.Z = Location.Z - CollisionHeight + 10.0;

        if (LocationIsInSweep(PivotLocation, TestLocation, Pawn.CollisionRadius, TestSide))
            Level.GetLocalPlayerController().myHUD.AddDebugBox(
                TestLocation,
                1,      //size
                class'Engine.Canvas'.Static.MakeColor(255,128,128),
                10);    //lifespan
        else
            Level.GetLocalPlayerController().myHUD.AddDebugBox(
                TestLocation,
                1,      //size
                class'Engine.Canvas'.Static.MakeColor(128,255,128),
                10);    //lifespan
    }
}
#endif

// returns the width of the actual doorway...i.e., the distance from the hinge
// side to the knob side.
simulated function float GetDoorwayWidth()
{
    assert(false); // must be implemented in subclasses
    return 0;
}

// Returns the direction in which we should push the pawn away from this door
// when he dies so that it minimizes his chances of being trapped in the door.
simulated function Vector GetPushAwayDirection(SwatRagdollPawn thePawn)
{
    assert(false); // must be implemented in subclasses
    return vect(0,0,0);
}


simulated function InitializeRemainingUpdateAttachmentLocationsCounter()
{
    RemainingUpdateAttachmentLocationsCounter = 2; // Ugh.
}

defaultproperties
{
    //Note that DT_StaticMesh is used only for convenience in the editor;
    //  the type is changed to DT_Mesh in PostBeginPlay()
    DrawType=DT_StaticMesh
    //this is only used as the reference StaticMesh for the DoorModel and the DoorWay
    StaticMesh=StaticMesh'Doors_sm.TestDoorKarma78Wide'

    bDirectional=true
    bStaticLighting=false

    bHidden=false
    bStatic=false
	bPathColliding=true
    bIsMissionExit=false
    bEdShouldSnap=true

    //note that collision for SwatDoors is changed at runtime in SwatDoor::PostBeginPlay() and SingleDoor::BeginPlay()
    bCollideActors=false
    bBlockZeroExtentTraces=true
    //CollisionRadius is set in SwatDoor subclasses
    CollisionHeight=80

    AcceptsCommandsFrom=CD_BothSides
    ExternalFacingSide=ES_NeitherSide
    bPlayerCanUse=true

    CurrentPosition=DoorPosition_Closed

    DoorBufferVolumeCollisionMesh=StaticMesh'Doors_sm.door_phys_singleref'

    DeployedWedgeClassName="SwatDesignerClasses.DeployedWedge"
    DeployedC2ChargeClassName="SwatDesignerClasses.DeployedC2Charge"

    bNoDelete=true
    Physics=PHYS_MovingBrush
    bAlwaysRelevant=true
    RemoteRole=ROLE_SimulatedProxy

	bCanBeLocked=true
    bIsAntiPortal=true
    AntiPortalScaleFactor=(X=1.05f,Y=0.1f,Z=1.05f)
    bCollideWhenPlacing=false
	bBoobyTrapTripped=false

	MoveAndClearPauseThreshold=128.0

	LeftAdditionalGrenadeThrowDistance=100.0
	RightAdditionalGrenadeThrowDistance=100.0

    RemainingUpdateAttachmentLocationsCounter=0
}
