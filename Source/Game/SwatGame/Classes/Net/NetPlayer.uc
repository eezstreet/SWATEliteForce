///////////////////////////////////////////////////////////////////////////////
//
// Common base for a network player pawn
//

class NetPlayer extends SwatPlayer
    implements IAmUsedByToolkit
    dependsOn(OfficerLoadOut)
    config(SwatPawn)
    native;

import enum Pocket from Engine.HandheldEquipment;
import enum MaterialPocket from SwatGame.LoadOut;
import enum eVoiceType from SwatGame.SwatGUIConfig;

//
//
//

var bool bReplicateSkins;

var private DynamicLoadOutSpec DynamicLoadOutSpec;

// In a network game, the server replicates these to the clients, where they
// use them in PostNetBeginPlay.
var Material ReplicatedSkins[MaterialPocket.EnumCount];
var class<actor> ReplicatedLoadOutSpec[Pocket.EnumCount];
var String ReplicatedCustomSkinClassName;

var private bool bThisPlayerIsTheVIP;

var private bool bThisPlayerHasTheItem;

// Amount of time needed to unarrest a player with the toolkit.
var private float QualifyTime;

// Desired position values when this pawn is being cuffed.
var private vector  BeingCuffedTargetLocation;
var private rotator BeingCuffedTargetRotation;

var config private float IdealCuffingDistanceBetweenPawns;

var protected int TeamNumber;

// Mesh for VIP
var Mesh VIPMesh;

// Values for detecting when loadout spec replication is done.
var private bool bLoadOutInitialized;
var private int LoadOutSpecCount;
var private int SkinsCount;

//copied from ClipBasedAmmo
const MAX_CLIPS = 10;
//what weapon pocket is the server currently talking about
var private Pocket CurrentWeaponPocket;
//how much ammo is left in the clips for the current weapon
var private int CurrentAmmoCounts[MAX_CLIPS];
//which clip is currently being used
var private int CurrentClip;

var eVoiceType VoiceType;

var int SwatPlayerID;

var private config Material  ViewportOverlayMaterial;

#if 0 // Ryan: test code
var float DeltaAcc;
#endif

replication
{
    // I'm not replicating this bNetDirty, so make sure that the spec is set
    // immediately after spawning.
    reliable if ( Role == ROLE_Authority )
        LoadOutSpecCount, SkinsCount,
        ReplicatedLoadOutSpec, ReplicatedCustomSkinClassName, ReplicatedSkins, bThisPlayerIsTheVIP, SwatPlayerID, VoiceType;

    reliable if ( Role == ROLE_Authority )
        OnDoorUnlocked;

    //dkaplan: remote pawns also need to know the ammo amount to avoid empty clip -need reload problems
    //reliable if ( Role == ROLE_Authority && RemoteRole == ROLE_AutonomousProxy )
    reliable if ( Role == ROLE_Authority )
        CurrentWeaponPocket, CurrentAmmoCounts, CurrentClip, bThisPlayerHasTheItem;
}


simulated function String UniqueID()
{
    return ("SwatNetPlayer"$SwatPlayerID);
}


// Executes only on server.
function InitializeReplicatedCounts()
{
    local int i;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::InitializeReplicatedCounts()." );

    Assert( Level.NetMode != NM_Client );

    LoadOutSpecCount = 0;
    for ( i = 0; i < Pocket.EnumCount; ++i )
    {
		assert(i != Pocket.Pocket_CustomSkin || ReplicatedLoadOutSpec[i] == None);
        if ( ReplicatedLoadOutSpec[i] != None )
            ++LoadOutSpecCount;
    }

 	if (Level.GetEngine().EnableDevTools)
	    mplog( "...LoadOutSpecCount="$LoadOutSpecCount );

    SkinsCount = 0;
    for ( i = 0; i < MaterialPocket.EnumCount; ++i )
    {
        if ( ReplicatedSkins[i] != None )
            ++SkinsCount;
    }

 	if (Level.GetEngine().EnableDevTools)
	    mplog( "...SkinsCount="$SkinsCount );
}

native event bool AllVarsHaveReplicated();

//
// Member functions
//

simulated event PostNetBeginPlay()
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::PostNetBeginPlay()." );

    super.PostNetBeginPlay();

    if ( Level.NetMode == NM_Client )
    {
        if ( AllVarsHaveReplicated() )
        {
            PostReplication();
            bLoadOutInitialized = true;
        }
    }
    else
    {
        // If we're not on a client, the LoadOut was initialized in
        // AddDefaultInventory(), so set bLoadOutInitialized to true to turn
        // off the polling in ANetPlayer::Tick().
        bLoadOutInitialized = true;
    }

    if ( IsTheVIP() )
    {
	 	if (Level.GetEngine().EnableDevTools)
			mplog( "...Yo! This guy is the VIP." );

        SwitchToMesh( VIPMesh );
    }

    //mplog(self$" calling SwatPlayer.RefreshCameraEffects("$self$")");
    RefreshCameraEffects(self);
}

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();

    if( Level.NetMode != NM_Client )
    {
        VoiceType = SwatGamePlayerController(Controller).VoiceType;
    }
}


simulated event PostReplication()
{
    local OfficerLoadOut newLoadOut;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::PostReplication()." );

    bLoadOutInitialized = true;

    Assert( Level.NetMode == NM_Client );

    // If we're on a network client we Initialize the hands here. If on the
    // server or in a standalone game, initialize them in Possess().
    if ( Role == ROLE_AutonomousProxy )
    {
        InitializeHands();
    }

    // All of our members have been replicated, so create the loadout locally
    // from the spec above.
    //PrintLoadOutSpecToMPLog();

    //mplog( "...Level.NetMode="$Level.NetMode );
    //mplog( "...Controller="$Controller );
    //mplog( "...Level.GetLocalPlayerController()="$Level.GetLocalPlayerController() );
    // If we're not the owner of this pawn, create the whole loadout and all
    // of the relevant classes.
    //    if ( Level.NetMode == NM_Client && Controller != Level.GetLocalPlayerController() )

 	if (Level.GetEngine().EnableDevTools)
	    mplog( "...Spawning the loadout." );

    if ( GetTeamNumber() == 0 )
    {
        if ( IsTheVIP() )
            newLoadOut = Spawn(class'OfficerLoadOut', self, 'VIPLoadOut' );
        else
            newLoadOut = Spawn(class'OfficerLoadOut', self, 'EmptyMultiplayerOfficerLoadOut' );
    }
    else
    {
        newLoadOut = Spawn(class'OfficerLoadOut', self, 'EmptyMultiplayerSuspectLoadOut' );
    }
    assert( newLoadOut != None );

    // Add the items to the loadout based on the items in the loadout
    // spec.
    //mplog( self$"...in NetPlayer, about to initialize the loadout" );

    GetLoadoutSpec(); // force the NetPlayer to create one.
    CopyReplicatedSpecToDynamicSpec();

    //mplog( "dynamic loadout spec:" );
    //DynamicLoadOutSpec.PrintLoadoutspecToMPLog();

    newLoadOut.Initialize( DynamicLoadoutSpec, GetTeamNumber() == 1 );
    ReceiveLoadOut( newLoadOut );
    //mplog( "Should have completed spawning the loadout." );

    // Start equipping the desired equipment item here, if it's not equal to None.
    if ( GetDesiredItemPocket() != Pocket_Invalid )
        CheckDesiredItemAndEquipIfNeeded();

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$" has name: "$GetHumanReadableName() );
}


///////////////////////////////////////////////////////////////////////////////
//
// Animation Set Overriding

simulated function EAnimationSet GetStandingWalkAnimSet()
{
    local LoadOut theLoadOut;

    theLoadOut = GetLoadOut();
	if (theLoadOut != None && theLoadOut.HasHeavyArmor())
	{
		return kAnimationSetStealthStandingHeavyArmor;
	}
	else if (theLoadOut != None && theLoadOut.HasNoArmor())
	{
		return kAnimationSetStealthStandingNoArmor;
	}
	else
	{
		return kAnimationSetStealthStanding;
	}
}

simulated function EAnimationSet GetStandingRunAnimSet()
{
    local LoadOut theLoadOut;

    theLoadOut = GetLoadOut();
	if (theLoadOut != None && theLoadOut.HasHeavyArmor())
	{
		return kAnimationSetDynamicStandingHeavyArmor;
	}
	else if (theLoadOut != None && theLoadOut.HasNoArmor())
	{
		return kAnimationSetDynamicStandingNoArmor;
	}
	else
	{
		return kAnimationSetDynamicStanding;
	}
}

simulated function EAnimationSet GetCrouchingAnimSet()
{
    local LoadOut theLoadOut;

    theLoadOut = GetLoadOut();
	if (theLoadOut != None && theLoadOut.HasHeavyArmor())
	{
		return kAnimationSetCrouchingHeavyArmor;
	}
	else if (theLoadOut != None && theLoadOut.HasNoArmor())
	{
		return kAnimationSetCrouchingNoArmor;
	}
	else
	{
		return kAnimationSetCrouching;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// The arrestee is put in this state to move to the "perfect" location and
// rotation for being hand-cuffed
//

// @TODO: Rename, since this is used for uncuffed positioning too
state MovingIntoBeingCuffedPosition
{
    private function UpdateBeingCuffedRotation()
    {
        // Rotate the arrestee (this pawn) so that his back is facing the
        // arrester. This can be done in one step and the animation system
        // will smoothly rotate the model over several frames, using the
        // step animation
        FaceRotation(BeingCuffedTargetRotation);
        // Send an RPC to the client to do the same
        ClientFaceRotation(BeingCuffedTargetRotation);
    }

    private latent function UpdateBeingCuffedLocation()
    {
        local bool   HasReachedTargetLocation;
        local float  LastUpdateTime;
        local float  DeltaTime;
        local vector TargetLocationDelta;
        local vector MovementDelta;

        // Perform the movement over several steps
        LastUpdateTime = Level.TimeSeconds;
        while (!HasReachedTargetLocation)
        {
            // Yield
            Sleep(0);

            // Get time delta
            DeltaTime = Level.TimeSeconds - LastUpdateTime;
            LastUpdateTime = Level.TimeSeconds;

            // Find the movement delta for this tick
            TargetLocationDelta = BeingCuffedTargetLocation - Location;
            MovementDelta = Normal(TargetLocationDelta) * GroundSpeed * DeltaTime;

            // If the movement delta is greater than or equal to the target
            // location delta..
            if (VSizeSquared2D(MovementDelta) >= VSizeSquared2D(TargetLocationDelta))
            {
                // Make sure we don't overshoot the target location, and
                // consider ourselves successful
                MovementDelta = TargetLocationDelta;
                HasReachedTargetLocation = true;
            }

            // Now, perform the move for this tick
            Move(MovementDelta);
        }
    }

Begin:
    // Only the server should control the positioning while the pawn is being
    // cuffed
    if (Level.NetMode != NM_Client)
    {
        UpdateBeingCuffedRotation();
        UpdateBeingCuffedLocation();
    }
}

// @TODO: Rename, since this is used for uncuffed positioning too
function MoveIntoBeingCuffedPosition(Pawn Arrester)
{
    // BeingCuffedTargetLocation is found by taking the arrester's location,
    // and adding an offset (multiplied by IdealCuffingDistanceBetweenPawns)
    // in the direction the arrester is facing
    local float directionX;
    local float directionY;

    Assert( Level.NetMode != NM_Client );

    directionX = Cos(Arrester.Rotation.Yaw * TWOBYTE_TO_RADIANS);
    directionY = Sin(Arrester.Rotation.Yaw * TWOBYTE_TO_RADIANS);
    BeingCuffedTargetLocation = Arrester.Location;
    BeingCuffedTargetLocation.X += directionX * IdealCuffingDistanceBetweenPawns;
    BeingCuffedTargetLocation.Y += directionY * IdealCuffingDistanceBetweenPawns;
    // Only slide the arrestee in the X & Y directions. Modifying his Z to
    // match the arrester's Z can make him float.
    BeingCuffedTargetLocation.Z  = Location.Z;

    // BeingCuffedTargetRotation is found by simply matching the arrester's
    // rotation
    BeingCuffedTargetRotation = Arrester.Rotation;

    // Put the pawn into the MovingIntoBeingCuffedPosition state, which will
    // handle, over several frames, the movement of the pawn into the proper
    // position.
    GotoState('MovingIntoBeingCuffedPosition');
}

// @TODO: Rename, since this is used for uncuffed positioning too
function StopMovingIntoBeingCuffedPosition()
{
    Assert( Level.NetMode != NM_Client );
    GotoState('');
}

///////////////////////////////////////////////////////////////////////////////
//
// A netplayer will always get OnArrestingBegan() before being arrested.
//
simulated function OnArrestBegan(Pawn Arrester)
{
    local HandheldEquipment IAmCuffedEquipment;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnArrestBegan(). Arrester="$Arrester );

    Assert( Level.NetMode != NM_Standalone );

    Super.OnArrestBegan(Arrester);

    LastArrester = SwatPlayer(Arrester);

    // We need to first interrupt the current state.
    InterruptState('BeingCuffed');
    if ( Controller != None )
        Controller.InterruptState('BeingCuffed');

    // Now go to the BeingCuffed state. We use to call ClientGotoState() but
    // since we now need to call InterruptState() first, we now call
    // ClientInterruptAndGotoState().
    if ( Controller != None )
    {
        Controller.GotoState( 'BeingCuffed' );
        //PlayerController(Controller).ClientGotoState( 'BeingCuffed', 'Begin');
    }

    if ( Level.NetMode != NM_Client )
    {
        MoveIntoBeingCuffedPosition(Arrester);

        // Equip the IAmCuffed item, only on the server.
        IAmCuffedEquipment = HandheldEquipment(GetLoadOut().GetItemAtPocket( Pocket_IAmCuffed ));
        AssertWithDescription( IAmCuffedEquipment != None, "[mcj] I'm being arrested but have no IAmCuffed equipment." );

        // MCJ: Calling server request equip here has the bad side-effect of
        //not setting DesiredItem if validation fails---that is, if the
        //activeitem is busy or something like that. This is not good, since
        //we really want the IAmCuffed equipped, even under those
        //circumstances. Instead of calling ServerRequestEquip(), I'm going to
        //do what it does but minus the validation check code.
        //ServerRequestEquip( IAmCuffedEquipment.GetSlot() );

        SetDesiredItemPocket( Pocket_IAmCuffed );
        CheckDesiredItemAndEquipIfNeeded();
    }
}


///////////////////////////////////////////////////////////////////////////////
//
// If the arrester completes the qualification process, then the
// ICanBeArrested gets OnArrested().
//
simulated function OnArrestedSwatPawn(Pawn Arrester)
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnArrestedSwatPawn(). Arrester="$Arrester );

    Super.OnArrestedSwatPawn(Arrester);

    ChangeAnimation();

    if ( Level.NetMode != NM_Client )
    {
        StopMovingIntoBeingCuffedPosition();
        SwatGamePlayerController(Controller).OnArrested();
    }
}


///////////////////////////////////////////////////////////////////////////////
//
// If the arrester is interrupted during the qualification process, then the
// ICanBeArrested gets OnArrestInterrupted().
//
simulated function OnArrestInterrupted(Pawn Arrester)
{
    Super.OnArrestInterrupted(Arrester);

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnArrestInterrupted(). Arrester="$Arrester );

    if ( Controller != None )
    {
        Controller.GotoState( 'PlayerWalking' );
    }

    if ( Level.NetMode != NM_Client )
    {
        if ( Controller != Level.GetLocalPlayerController() )
            PlayerController(Controller).ClientGotoState( 'PlayerWalking', 'Begin' );

        StopMovingIntoBeingCuffedPosition();
        // Equip default weapon.
        DoDefaultEquip();
    }
}


///////////////////////////////////////////////////////////////////////////////

//
// IAmUsedByToolkit interface
//

// Return true iff this can be operated by a toolkit now
simulated function bool CanBeUsedByToolkitNow()
{
    //mplog( self$"---NetPlayer::CanBeUsedByToolkitNow()." );
    //mplog( "...IsArrested()="$IsArrested() );
    //mplog( "...IsTheVIP()="$IsTheVIP() );

    //a Toolkit can be used to unarrest a NetPlayer iff (s)he is arrested
    return IsArrested() && IsTheVIP();
}


// Called when qualifying begins. This is called when the NetPlayer begins to
// be unarrested.
simulated function OnUsingByToolkitBegan( Pawn Unarrester )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnUsingByToolkitBegan(). Unarrester="$Unarrester );

    Controller.GotoState( 'BeingUncuffed' );
    PlayerController(Controller).ClientGotoState( 'BeingUncuffed', 'Begin' );

    SwatGameInfo(Level.Game).GameEvents.PawnUnarrestBegan.Triggered( Unarrester, self );

    if ( Level.NetMode != NM_Client )
    {
        MoveIntoBeingCuffedPosition(Unarrester);
    }
}


// Called when qualifying completes successfully. The NetPlayer is now
// "unarrested."
simulated function OnUsedByToolkit( Pawn Unarrester )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnUsedByToolkit(). Unarrester="$Unarrester );

    // We probably want to send a game event here.

    OnUnarrestedSwatPawn( Unarrester );
    SwatGamePlayerController(Controller).OnUnarrested();
    SwatGameInfo(Level.Game).GameEvents.PawnUnarrested.Triggered( Unarrester, self );

    Controller.GotoState( 'PlayerWalking' );
    PlayerController(Controller).ClientGotoState( 'PlayerWalking', 'Begin' );

    if ( Level.NetMode != NM_Client )
    {
        StopMovingIntoBeingCuffedPosition();
        // Equip default weapon.
        DoDefaultEquip();
    }
}

// Called when qualifying is interrupted. The NetPlayer was not successfully
// unarrested and remains arrested.
simulated function OnUsingByToolkitInterrupted( Pawn Unarrester )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnUsingByToolkitInterrupted(). Unarrester="$Unarrester );

    Controller.GotoState( 'PlayerWalking' );
    PlayerController(Controller).ClientGotoState( 'PlayerWalking', 'Begin' );

    if ( Level.NetMode != NM_Client )
    {
        StopMovingIntoBeingCuffedPosition();
    }
}


//return the time it takes for a Player to "qualify" to unarrest me
simulated function float GetQualifyTimeForToolkit()
{
    return QualifyTime;
}


///////////////////////////////////////////////////////////////////////////////


simulated function SetPlayerSkins( OfficerLoadOut inLoadOut )
{
    Super.SetPlayerSkins( inLoadOut );

	if (Level.NetMode != NM_Client)
	{
		ReplicatedSkins[0] = inLoadOut.GetDefaultPantsMaterial();
		ReplicatedSkins[1] = inLoadOut.GetDefaultFaceMaterial();
		ReplicatedSkins[2] = inLoadOut.GetDefaultNameMaterial();
		ReplicatedSkins[3] = inLoadOut.GetDefaultVestMaterial();
	}
}


simulated function PrintLoadOutSpecToMPLog()
{
 	if (Level.GetEngine().EnableDevTools)
 	{
	    mplog( "DynamicLoadOutSpec of "$self$" contains:" );
	    GetLoadoutSpec().PrintLoadOutSpecToMPLog();
    }
}


simulated function SetPocketItemClass( Pocket Pocket, class<actor> Item )
{
    //mplog( self$"---NetPlayer::SetPocketItemClass(). Pocket="$Pocket$", Item="$Item );
    GetLoadoutSpec().LoadOutSpec[ Pocket ] = Item;
    ReplicatedLoadOutSpec[ Pocket ] = Item;
}


simulated function SetCustomSkinClassName( String CustomSkinClassName )
{
	GetLoadoutSpec().CustomSkinSpec = CustomSkinClassName;
	ReplicatedCustomSkinClassName = CustomSkinClassName;
}


simulated function SetPocketItemClassName( Pocket Pocket, string ItemClassName )
{
    local class<actor> ItemClass;

    //mplog( self$"---NetPlayer::SetPocketItemClassName(). Pocket="$Pocket$", ItemClassName="$ItemClassName );

    if ( ItemClassName != "" )
    {
        ItemClass = class<Actor>(DynamicLoadObject(ItemClassName, class'Class'));
    }
    SetPocketItemClass( Pocket, ItemClass );
}


simulated function class GetPocketItem( Pocket Pocket )
{

 	if (Level.GetEngine().EnableDevTools)
 	{
		if ( GetLoadoutSpec().LoadOutSpec[Pocket] == None )
			mplog( self$" in NetPlayer::GetPocketItem(). Item was 'None' in pocket="$Pocket );
	}

    return GetLoadoutSpec().LoadOutSpec[ Pocket ];
}

///////////////////////////////////////////////////////////////////////////////
//
// Misc

// Override superclass method so that in multiplayer games the player's name
// is "You" (if the player is locally controller) or it the player's chosen name
// (if it's the local manifestation of a remotely-controller pawn).
simulated function String GetHumanReadableName()
{
    // MCJ: This code wasn't working. Since the messages always originate on
    // the server, the word "You" was not used correctly: the server's player
    // was always "you" and no one else was. We need some way for the players
    // who are mentioned in the message to get a different message from the
    // other players.

//     if (IsControlledByLocalHuman())
//     {
//         return "You";  // returned for local player in *MP* games only
//     }

    // Superclass will return correct name for remotely controlled
	// pawns in MP games (implementation in Pawn.uc handles querying
	// player's chosen name in net games).
    return Super.GetHumanReadableName();
}


simulated event int GetTeamNumber()
{
    return TeamNumber;
}


simulated function NetTeam GetNetTeam()
{
    local SwatGameReplicationInfo SGRI;

    SGRI = SwatGameReplicationInfo(Level.GetGameReplicationInfo());

    return NetTeam(SGRI.Teams[ GetTeamNumber() ]);
}


function SetIsVIP()
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::SetIsVIP()." );

    bThisPlayerIsTheVIP = true;
    Label = 'VIP';
}

simulated function bool IsTheVIP()
{
    return bThisPlayerIsTheVIP;
}

function SetHasTheItem()
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::SetHasTheItem()." );

	bThisPlayerHasTheItem = true;
    ChangeAnimation();

	// switch to secondary weapon when picking up smash and grab item
	AIInterruptEquipment();
	GetActiveItem().AIInterrupt();
	AuthorizedEquipOnServer(Slot_SecondaryWeapon);
}

function UnsetHasTheItem()
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::UnsetHasTheItem()." );

	bThisPlayerHasTheItem = false;
    ChangeAnimation();
}

simulated function bool HasTheItem()
{
	return bThisPlayerHasTheItem;
}

#if 0	// Ryan: Test code for voip crash
simulated function Tick(float dTime)
{
	super.Tick(dTime);

	if (DeltaAcc > 1.0)
	{
		if (FRand() < 0.05)
			TakeDamage(100000, None, vect(0,0,0), vect(0,0,0), class'DamageType');

		DeltaAcc = 0.0;
	}
	else
	{
		DeltaAcc += dTime;
	}
}
#endif

simulated function bool ShouldPlayWalkingAnimations()
{
	return bIsWalking || HasTheItem();
}

simulated function OnDoorUnlocked( SwatDoor TheDoor )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnDoorUnlocked(). TheDoor="$TheDoor );

    // Doors are always relevant, so they should never be None.
    assert( TheDoor != None );

    TheDoor.OnUnlocked();
}

simulated function DynamicLoadOutSpec GetLoadoutSpec()
{
    //mplog( self$"---NetPlayer::GetLoadoutSpec()." );
    if( DynamicLoadOutSpec == None )
    {
        if ( IsTheVIP() )
            DynamicLoadOutSpec = Spawn(class'DynamicLoadOutSpec', None, 'DefaultVIPLoadOut');
        else
            DynamicLoadOutSpec = Spawn(class'DynamicLoadOutSpec', None, 'CurrentMultiPlayerLoadout');
        Assert( DynamicLoadOutSpec != None );
    }

    return DynamicLoadOutSpec;
}

simulated private function CopyReplicatedSpecToDynamicSpec()
{
    local int i;

    for ( i = 0; i < Pocket.EnumCount; i++ )
    {
        DynamicLoadOutSpec.LoadOutSpec[i] = ReplicatedLoadOutSpec[i];
    }
    for ( i = 0; i < MaterialPocket.EnumCount; i++ )
    {
        DynamicLoadOutSpec.MaterialSpec[i] = ReplicatedSkins[i];
    }

	DynamicLoadOutSpec.CustomSkinSpec = ReplicatedCustomSkinClassName;
}

// overridden from actor
//  this allows us to play "grunt" damage effects on the NetPlayer based off our local trace
//  this only plays on other pawns (other than the one owned by the localplayercontroller)
simulated function TakeDamageEffectsHook( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType )
{
    Super.TakeDamageEffectsHook(Damage, EventInstigator, HitLocation, Momentum, DamageType);

//log( self$"::TakeDamageEffectsHook()... Health = "$Health$", isAlive() = "$isAlive()$", Level.NetMode = "$Level.NetMode$", Controller = "$Controller$", Level.GetLocalPlayerController() = "$Level.GetLocalPlayerController() );

    //only play this on pawns other than the local PlayerController's pawn
    //if( Controller == Level.GetLocalPlayerController() )
    //    return;

    //we don't want to play grunts when less lethaled or non-damaged
    if( Damage <= 0 || DamageType.Name == 'LessLethalSG' )
        return;

    //only play the grunts if alive
    if( Health > 0 )
    {
        if( IsIntenseInjury() )
        {
			TriggerEffectEvent('ReactedInjuryIntense');
		}
		else
		{
			TriggerEffectEvent('ReactedInjuryNormal');
		}
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////
simulated function OnEquippingFinished()
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnEquippingFinished()." );

    Super.OnEquippingFinished();

    UpdateAmmoInfo();
}

// Overridden from Pawn.
simulated function OnUsingFinished()
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnUsingFinished()." );

    Super.OnUsingFinished();

    UpdateAmmoInfo();
}

// Overridden from Pawn.
simulated function OnReloadingFinished()
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetPlayer::OnReloadingFinished()." );

    Super.OnReloadingFinished();

    UpdateAmmoInfo();
}

simulated function UpdateAmmoInfo()
{
    local FiredWeapon Weapon;
    local int i;
	local string TheLog;

    if( Level.NetMode != NM_ListenServer && Level.NetMode != NM_DedicatedServer )
        return;

    Weapon = FiredWeapon(GetActiveItem());

    //only update the info if the ActiveItem is a fired weapon
    if( Weapon == None )
        return;

    CurrentWeaponPocket = Weapon.GetPocket();
	CurrentClip = Weapon.Ammo.GetCurrentClip();


 	if (Level.GetEngine().EnableDevTools)
		TheLog = self$"::UpdateAmmoInfo() ... CurrentWeaponPocket = "$CurrentWeaponPocket$", CurrentClip = "$CurrentClip$", CurrentAmmoCounts = ";

	for( i = 0; i < MAX_CLIPS; i++ )
	{
		CurrentAmmoCounts[i] = Weapon.Ammo.GetClip(i);

 	    if (Level.GetEngine().EnableDevTools)
			TheLog = TheLog$CurrentAmmoCounts[i]$" ";
	}

 	if (Level.GetEngine().EnableDevTools)
		log( TheLog );
}

simulated event OnAmmoInfoChanged()
{
    local FiredWeapon Weapon;
    local int i;
    //local string TheLog;

    if( Level.NetMode != NM_Client )
        return;

    Weapon = FiredWeapon(GetActiveItem());

    //only update the info if the ActiveItem is a fired weapon
    if( Weapon == None )
        return;

    //do not do any updates if the current weapon does not match the updated information
    if( CurrentWeaponPocket != Weapon.GetPocket() )
        return;

    Weapon.Ammo.SetCurrentClip(CurrentClip);

 	//TheLog = self$"::OnAmmoInfoChanged() ... CurrentWeaponPocket = "$CurrentWeaponPocket$", CurrentClip = "$CurrentClip$", CurrentAmmoCounts = ";

    for( i = 0; i < MAX_CLIPS; i++ )
    {
        Weapon.Ammo.SetClip( i, CurrentAmmoCounts[i] );

		//TheLog = TheLog$CurrentAmmoCounts[i]$" ";
    }

	//log( TheLog );

    Weapon.Ammo.UpdateHUD();
}

simulated function Material GetViewportOverlay()
{
    return ViewportOverlayMaterial;
}

// IControllableThroughViewport interface
simulated function Rotator GetViewportDirection()
{
    return GetAimRotation();
}

function OnTeamChanging(TeamInfo NewTeam)
{
}

function OnIncapacitated(Actor Incapacitator, class<DamageType> damageType)
{
	SwatGameInfo(Level.Game).Broadcast(self, GetHumanReadableName(), 'Fallen');
}

function OnKilled(Actor Killer, class<DamageType> damageType)
{
	SwatGameInfo(Level.Game).Broadcast(self, GetHumanReadableName(), 'Fallen');
}

simulated protected function bool CheckDesiredItemAndEquipIfNeeded()
{
	// We can't equip anything except a secondary weapon if we have the smash and grab case
	if (GetDesiredItemPocket() != POCKET_SecondaryWeapon && HasTheItem())
		SetDesiredItemPocket(POCKET_SecondaryWeapon);

	return Super.CheckDesiredItemAndEquipIfNeeded();
}

defaultproperties
{
    bThisPlayerIsTheVIP=false
	bThisPlayerHasTheItem=false
	bReplicateSkins=false
    QualifyTime=5.0
    IdealCuffingDistanceBetweenPawns=50.0

    TeamNumber=-1

    bLoadOutInitialized=false
    LoadOutSpecCount=0
    SkinsCount=0
	ReplicatedCustomSkinClassName=""

    VIPMesh=SkeletalMesh'SWATMaleAnimation2.MaleSuit2'
    ViewportOverlayMaterial=Material'HUD.officerviewport'
}
