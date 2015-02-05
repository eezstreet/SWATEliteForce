class SwatPlayer extends SwatRagdollPawn
    implements  ICanThrowWeapons,
                Engine.IReactToFlashbangGrenade,
                Engine.IReactToCSGas,
                Engine.IReactToStingGrenade,
                Engine.IReactToC2Detonation,
                Engine.IReactToDazingWeapon,
                ICanUseC2Charge,
                ICanQualifyForUse,
                Engine.ICanBeTased,
                Engine.ICanBePepperSprayed,
                IEffectObserver,
                IInterested_GameEvent_ReportableReportedToTOC,
                IControllableThroughViewport,
                IAmReportableCharacter
    native;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum ESkeletalRegion from Engine.Actor;

var private OfficerLoadOut LoadOut;

//the pitch above the camera rotation to throw
var config int ThrownProjectilePitch;

var config float MinimumLongThrowSpeed;         //if a ThrownWeapon is thrown at a speed less than this, then the 'short' animations are played, otherwise, 'long' animations are used

var config name PreThrowAnimation;
var config name ThrowShortAnimation;
var config name ThrowLongAnimation;

var config name	 ThrowAnimationRootBone;
var config float ThrowAnimationTweenTime;

var config float ThrowSpeedTimeFactor;      //when a ThrownWeapon is thrown, its speed will be this times the time that the throw button is held
var config Range ThrowSpeedRange;           //clamp the throw speed

var private Material SuspectHandsMaterial;
var private Material VIPHandsMaterial;

// NonLethal Effects
var config bool bTestingCameraEffects; // allow the player to be hit with nonlethals in standalone
var private Timer StungTimer;
var private Timer FlashbangedTimer;
var private Timer GassedTimer;
var private Timer PepperSprayedTimer;
var private Timer TasedTimer;

enum ELastStingWeapon
{
    StingGrenade,
    LessLethalShotgun,
	TripleBatonRound,
	DirectGrenadeHit,
	MeleeAttack
};
var ELastStingWeapon LastStingWeapon; // type of last thing to cause sting effect

var float                 LastStungTime;
var float                 LastStungDuration;

var float LastFlashbangedTime;

var float LastGassedTime;
var float LastGassedDuration;

var float LastPepperedTime;
var float LastPepperedDuration;

var float LastTasedTime;
var float LastTasedDuration;

// Holds the current triggered state of each non-lethal reaction effect event.
// These are bytes, instead of bools, for implementation purposes. The
// native implementation of UpdateNonLethalEffectEvents queries and modifies
// these values by reference, and you can't have a bitfield reference. [darren]
var private byte bIsTriggered_ReactedBang;
var private byte bIsTriggered_ReactedGas;
var private byte bIsTriggered_ReactedPepper;
var private byte bIsTriggered_ReactedSting;
var private byte bIsTriggered_ReactedTaser;

var private PerlinNoise PerlinNoiseAxisA;
var private PerlinNoise PerlinNoiseAxisB;
var config float StingEffectDropOffTimePercent;
var config float StingEffectFrequency;
//maximum angular offset in unreal angle units
var config Rotator StingViewEffectAmplitude;
var config float StingInputEffectMagnitude;

//in unreal distance units, the farthest shake distance
var config float TasedViewEffectAmplitude;
//how often to recenter
var config float TasedViewEffectFrequency;

var bool EquipOtherAfterUsed;                   //if true, 
var EquipmentSlot SlotForReequip;               //if TryToReequipAfterUsed is set, then SlotForReequip records the EquipmentSlot that should be used to try to reequip

var bool  DoneThrowing;    //mutex to enforce control over exits from state Throwing
var float ThrowHeldTime;   // The time that the player had held the fire button to place/throw the current agnostic item

var protected bool bForceCrouchWhileOptiwanding;

// Replicated from server to clients.
var protected bool bIsUsingOptiwand;

var private DeployedC2ChargeBase DeployedC2Charge;

var config float LowReadyFireTweenTime;

// Reporting-to-TOC state variables
var private IAmReportableCharacter CurrentReportableCharacter;

var private bool bNotifiedPlayerTheyAreVIP;

var SwatPlayer LastArrester;

// Allows external objects to nudge the pawn in a certain direction each frame.
var private vector OneFrameNudgeDirection;
const OneFrameNudgeDirectionStrength = 2.0;

var config const private float LimpThreshold;
var config private float       CurrentLimp;
var config private float       StandardLimpPenalty;
var private config localized string YouString;

var private config float PawnModelApparentBaseEyeHeight;        //the apparent Z distance between the pawn's origin and the eyes of the 3rd person model when standing
var private config float PawnModelApparentCrouchEyeHeight;      //the apparent Z distance between the pawn's origin and the eyes of the 3rd person model when standing

var private bool                        bHasBeenReportedToTOC;

var private CommandArrow    CommandArrow;

// Variables to keep track of cached qualifications for remote pawns on
// clients. We need this functionality to play the qualification if the player
// has been using the quick-equip interface.
var EquipmentUsedOnOther CachedQualifyEquipment;
var Actor CachedQualifyTarget;


replication
{
	// replicated functions sent to server by owning client
	reliable if( Role < ROLE_Authority )
        ServerRequestQualify, ServerRequestUse, ServerSetIsUsingOptiwand, ServerSetForceCrouchWhileOptiwanding;

    // replicated functions sent to client by server
    reliable if( Role == ROLE_Authority )
        ClientFaceRotation, CurrentLimp,
        ClientStartQualify, ClientFinishQualify, ClientUse,
        DeployedC2Charge,
        ClientOnFlashbangTimerExpired, ClientOnGassedTimerExpired, ClientOnStungTimerExpired,
        ClientOnPepperSprayedTimerExpired, ClientOnTasedTimerExpired,
        ClientDoFlashbangReaction, ClientDoGassedReaction, ClientDoStungReaction,
        ClientDoPepperSprayedReaction, ClientDoTasedReaction,
        bIsUsingOptiwand, bHasBeenReportedToTOC, ClientPlayEmptyFired;
}

///////////////////////////////////////////////////////////////////////////////
//
// IControllableThroughViewport Interface
simulated function Actor GetViewportOwner()
{
    return Self;
}

// Called to allow the viewport to modify mouse acceleration
simulated function            AdjustMouseAcceleration( out Vector MouseAccel );


// Called whenever the mouse is moving (and this controllable is being controlled)
function            OnMouseAccelerated( out Vector MouseAccel );

simulated function string GetViewportType()
{
    //return a filter string that wont match up for dead players (only for live players)
    if( checkDead(Self) || IsIncapacitated() )
        return "DeadPlayer";
    if( IsTheVIP() )
        return "VIP";
    else
        return string(class.name);
}

// Possibly offset from the controlled direction
function            OffsetViewportRotation( out Rotator ViewportRotation );

simulated function string  GetViewportDescription()
{
    return "";
}

simulated function string  GetViewportName()
{
    return GetHumanReadableName();
}

simulated function bool   CanIssueCommands()
{
    return false;
}

simulated function Vector  GetViewportLocation()
{
    return GetViewpoint();
}
simulated function Rotator GetViewportDirection()
{
    return GetViewRotation();
}

simulated function float   GetViewportPitchClamp()
{
    return 0.0;
}

simulated function float   GetViewportYawClamp()
{
    return 0.0;
}

simulated function        SetRotationToViewport(Rotator inNewRotation)
{
}

simulated function bool   ShouldDrawViewport()
{
    return !checkDead(Self) && !IsIncapacitated();
}

simulated function bool ShouldDrawReticle()
{
    return false;
}

simulated function Material GetViewportOverlay();
simulated function        float GetFOV();
simulated function        HandleFire();
simulated function        HandleAltFire();
simulated function        HandleReload();
simulated function Rotator    GetOriginalDirection();
simulated function float      GetViewportPitchSpeed();
simulated function float      GetViewportYawSpeed();
simulated function            OnBeginControlling();
simulated function            OnEndControlling();
///////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
//
// Functions
//

simulated event PreBeginPlay()
{
    Super.PreBeginPlay();
    
    Label = 'Player';

    //setup timers for non-lethal effects

    StungTimer          = Spawn(class'Timer');
    FlashbangedTimer    = Spawn(class'Timer');
    GassedTimer         = Spawn(class'Timer');
    PepperSprayedTimer  = Spawn(class'Timer');
    TasedTimer          = Spawn(class'Timer');

    StungTimer.TimerDelegate            = OnStungTimerExpired;
    FlashbangedTimer.TimerDelegate      = OnFlashbangedTimerExpired;
    GassedTimer.TimerDelegate           = OnGassedTimerExpired;
    PepperSprayedTimer.TimerDelegate    = OnPepperSprayedTimerExpired;
    TasedTimer.TimerDelegate            = OnTasedTimerExpired;
}

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();

    // so we get a base
	SetPhysics(PHYS_Falling);

    PerlinNoiseAxisA = new class'Engine.PerlinNoise';
    PerlinNoiseAxisB = new class'Engine.PerlinNoise';

    // Register for the reported to toc notification
	if (Level.NetMode == NM_Standalone || Level.IsCOOPServer)
	{
		SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.Register(self);
	}
	
	if( Level.NetMode != NM_Standalone )
	{
	    CommandArrow = Spawn(class'CommandArrow');
	    CommandArrow.Hide();
	}
}


simulated event PostNetBeginPlay()
{
    super.PostNetBeginPlay();
//    log( self$"---SwatPlayer::PostNetBeginPlay() called." );
}


simulated function InitializeHands()
{
    local Hands Hands;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::InitializeHands()." );
    
    Hands = Spawn(class'Engine.Hands', self);
    assert(Hands != None);

	if (Level.GetEngine().EnableDevTools)
		mplog( "...Hands="$Hands );

    // MCJ: I'm not sure if there's a better place to do this.
    if ( Level.NetMode != NM_Standalone && !Level.IsCOOPServer )
    {
        // The mesh defaults to the Swat officer hand mesh, so only bother to
        // change it if these hands belong to a suspect.
        if ( NetPlayerTeamB(self) != None )
        {
            Hands.SetMaterialForHands( SuspectHandsMaterial );
        }
        else if ( IsTheVIP() )
        {
            Hands.SetMaterialForHands( VIPHandsMaterial );
        }
    }

    SetHands(Hands);
}

simulated function InitAnimationForCurrentMesh()
{
    // Player pawns should always rotate their lower body quickly
    Super.InitAnimationForCurrentMesh();
    AnimSetRotationUrgency(kARU_Fast);
}

simulated function FaceRotation(rotator NewRotation)
{
    // The controller zeroes out pawn.rotation.pitch after this call is made,
    // so we hook here in order to preserve the aim pitch and feed it into the
    // animation aiming.
    AnimSetAimRotation(NewRotation);
    Super.FaceRotation(NewRotation);
}

// RPC sent from server to client, instructing it to call FaceRotation
simulated function ClientFaceRotation(rotator NewRotation)
{
    FaceRotation(NewRotation);
}

// Use extreme low ready aim poses if we're up against something
simulated function EAnimationSet GetHandgunLowReadyAimPoseSet()         { if (ReasonForLowReady == 'Obstruction') return kAnimationSetHandgunExtremeLowReady;        else return Super.GetHandgunLowReadyAimPoseSet(); }
simulated function EAnimationSet GetSubMachineGunLowReadyAimPoseSet()   { if (ReasonForLowReady == 'Obstruction') return kAnimationSetSubMachineGunExtremeLowReady;  else return Super.GetSubMachineGunLowReadyAimPoseSet(); }
simulated function EAnimationSet GetMachineGunLowReadyAimPoseSet()      { if (ReasonForLowReady == 'Obstruction') return kAnimationSetMachineGunExtremeLowReady;     else return Super.GetMachineGunLowReadyAimPoseSet(); }
simulated function EAnimationSet GetShotgunLowReadyAimPoseSet()         { if (ReasonForLowReady == 'Obstruction') return kAnimationSetShotgunExtremeLowReady;        else return Super.GetShotgunLowReadyAimPoseSet(); }
simulated function EAnimationSet GetThrownWeaponLowReadyAimPoseSet()    { if (ReasonForLowReady == 'Obstruction') return kAnimationSetThrownWeaponExtremeLowReady;   else return Super.GetThrownWeaponLowReadyAimPoseSet(); }
simulated function EAnimationSet GetTacticalAidLowReadyAimPoseSet()     { if (ReasonForLowReady == 'Obstruction') return kAnimationSetTacticalAidExtremeLowReady;    else return Super.GetTacticalAidLowReadyAimPoseSet(); }
simulated function EAnimationSet GetPepperSprayLowReadyAimPoseSet()     { if (ReasonForLowReady == 'Obstruction') return kAnimationSetPepperSprayExtremeLowReady;    else return Super.GetPepperSprayLowReadyAimPoseSet(); }
simulated function EAnimationSet GetM4LowReadyAimPoseSet()              { if (ReasonForLowReady == 'Obstruction') return kAnimationSetM4ExtremeLowReady;             else return Super.GetM4LowReadyAimPoseSet(); }
simulated function EAnimationSet GetUMPLowReadyAimPoseSet()             { if (ReasonForLowReady == 'Obstruction') return kAnimationSetUMPExtremeLowReady;            else return Super.GetUMPLowReadyAimPoseSet(); }
simulated function EAnimationSet GetP90LowReadyAimPoseSet()             { if (ReasonForLowReady == 'Obstruction') return kAnimationSetP90ExtremeLowReady;            else return Super.GetP90LowReadyAimPoseSet(); }
simulated function EAnimationSet GetOptiwandLowReadyAimPoseSet()        { if (ReasonForLowReady == 'Obstruction' && !IsUsingOptiwand()) return kAnimationSetOptiwandExtremeLowReady;       else return Super.GetOptiwandLowReadyAimPoseSet(); }
simulated function EAnimationSet GetPaintballLowReadyAimPoseSet()       { if (ReasonForLowReady == 'Obstruction') return kAnimationSetPaintballExtremeLowReady;      else return Super.GetPaintballLowReadyAimPoseSet(); }

simulated protected function bool CanPawnUseLowReady() { return true; }

simulated function SetLowReady(bool bEnable, optional name Reason)
{
    if (bEnable == IsLowReady()) return;        //already there

    Super.SetLowReady(bEnable, Reason);

    if (GetHands() != None)
        GetHands().SetLowReady(bEnable);
}


simulated function OfficerLoadOut GetLoadOut()
{
    return LoadOut;
}

simulated function ReceiveLoadOut(OfficerLoadOut inLoadOut)
{
    //mplog( self$"---SwatPlayer::ReceiveLoadOut(). LoadOut="$inLoadOut );

    AssertWithDescription(LoadOut == None,
        "[tcohen] Player received LoadOut more than once.");
    LoadOut = inLoadOut;

    //log( "------LoadOut.Owner="$LoadOut.Owner );

    SetPlayerSkins( inLoadOut );

	// make sure we have the correct animations to go with our loadout
	ChangeAnimation();

    DoDefaultEquip(); // Does nothing if NM_Client.
}

//returns true iff the SwatPlayer has any of the specified HandheldEquipment
native function bool HasA(name HandheldEquipmentName);

simulated function SetPlayerSkins( OfficerLoadOut inLoadOut )
{
    //mplog( self$"---SwatPlayer::SetPlayerSkins()." );
    
    Skins[0] = inLoadOut.GetPantsMaterial();
    Skins[1] = inLoadOut.GetFaceMaterial();
    Skins[2] = inLoadOut.GetNameMaterial();
    Skins[3] = inLoadOut.GetVestMaterial();
    
    //mplog( "...Skins[0]="$Skins[0] );
    //mplog( "...Skins[1]="$Skins[1] );
    //mplog( "...Skins[2]="$Skins[2] );
    //mplog( "...Skins[3]="$Skins[3] );
}


simulated function DoDefaultEquip()
{
    local FiredWeapon PrimaryWeapon, BackupWeapon;
    local FiredWeapon WeaponToEquip;

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::DoDefaultEquip()." );

    // Does nothing if on a network client.
    if ( Level.NetMode == NM_Client )
        return;

    // Which weapon should we use?
    PrimaryWeapon = LoadOut.GetPrimaryWeapon();
    BackupWeapon = LoadOut.GetBackupWeapon();
    WeaponToEquip = PrimaryWeapon;                                          //Normally, we prefer the primary weapon.

    if  (                                                                   //However,
            Level.IsTraining                                                //  - in Training, or
        ||  PrimaryWeapon == None                                           //  - if the player has no primary, or
        ||  (PrimaryWeapon.Ammo.IsEmpty() && !BackupWeapon.Ammo.IsEmpty())  //  - the primary is empty, but the backup is not (VUG bug 219)
        )                                                                   //
        WeaponToEquip = BackupWeapon;                                       //  we prefer the backup weapon.

    assertWithDescription(WeaponToEquip != None,
        "[tcohen] SwatPlayer::DoDefaultEquip() The selected weapon evaluates to None.");

    AuthorizedEquipOnServer( WeaponToEquip.GetSlot() );
}


simulated function bool ValidateEquipSlot( EquipmentSlot Slot )
{
	local HandheldEquipment NewItem;

    NewItem = GetEquipmentAtSlot( Slot );
    if ( NewItem == None )
        return false;

    return ValidateEquipPocket( NewItem.GetPocket() );
}


simulated function bool ValidateEquipPocket( Pocket thePocket )
{
	local Actor PocketContents;
	local HandheldEquipment NewItem;
	local HandheldEquipment PendingItem;
    local HandheldEquipment ActiveItem;

    PocketContents = LoadOut.GetItemAtPocket( thePocket );
    ActiveItem = GetActiveItem();
    PendingItem = GetPendingItem();
    
    //return if we can't equip now

    //nothing in the specified pocket
    if (PocketContents == None)
    {
		if (Level.GetEngine().EnableDevTools)
		{
			mplog( self$"---SwatPlayer::ValidateEquipPocket(). Validate failed. Pocket="$thePocket );
			mplog( "......Validate failed because there was nothing in the specified pocket." );
			mplog( "...PocketContents ="$PocketContents );
			mplog( "...ActiveItem     ="$ActiveItem );
			mplog( "...PendingItem    ="$PendingItem );
        }
        
        return false;
    }
	
	NewItem = HandheldEquipment(PocketContents);
	
    //no handheldequipment in the specified pocket
    if (NewItem == None)
    {
		if (Level.GetEngine().EnableDevTools)
		{
			mplog( self$"---SwatPlayer::ValidateEquipPocket(). Validate failed. Pocket="$thePocket );
			mplog( "......Validate failed because the thing in the specified pocket was not handheld equipment." );
			mplog( "...PocketContents ="$PocketContents );
			mplog( "...NewItem        ="$NewItem );
			mplog( "...ActiveItem     ="$ActiveItem );
			mplog( "...PendingItem    ="$PendingItem );
		}
		
        return false;
    }
    //one of those is already active
    if (NewItem == ActiveItem)
    {
		if (Level.GetEngine().EnableDevTools)
		{
			mplog( self$"---SwatPlayer::ValidateEquipPocket(). Validate failed. Pocket="$thePocket );
			mplog( "......Validate failed because requested item is the same as the active item." );
			mplog( "...PocketContents ="$PocketContents );
			mplog( "...NewItem        ="$NewItem );
			mplog( "...ActiveItem     ="$ActiveItem );
			mplog( "...PendingItem    ="$PendingItem );
        }
        return false;
    }

    // The item in that pocket has already been used.
    if ( !NewItem.IsAvailable() )
    {
		if (Level.GetEngine().EnableDevTools)
		{
			mplog( self$"---SwatPlayer::ValidateEquipPocket(). Validate failed. Pocket="$thePocket );
			mplog( "......Validate failed because requested item is unavailable." );
			mplog( "...PocketContents ="$PocketContents );
			mplog( "...NewItem        ="$NewItem );
			mplog( "...ActiveItem     ="$ActiveItem );
			mplog( "...PendingItem    ="$PendingItem );
        }
        
        return false;
    }

    if ( ActiveItem != None && !ActiveItem.IsIdle() )
    {
        //the current item is busy
        
		if (Level.GetEngine().EnableDevTools)
		{
			mplog( self$"---SwatPlayer::ValidateEquipPocket(). Validate failed. Pocket="$thePocket );
			mplog( "......Validate failed because active item is not idle." );
			mplog( "...PocketContents ="$PocketContents );
			mplog( "...NewItem        ="$NewItem );
			mplog( "...ActiveItem     ="$ActiveItem );
			mplog( "...PendingItem    ="$PendingItem );
        }
        
        return false;
    }

    if ( PendingItem != None && !PendingItem.IsIdle() )
    {
        //the pending item is busy
        
		if (Level.GetEngine().EnableDevTools)
		{
			mplog( self$"---SwatPlayer::ValidateEquipPocket(). Validate failed. Pocket="$thePocket );
			mplog( "......Validate failed because pending item was not idle." );
			mplog( "...PocketContents ="$PocketContents );
			mplog( "...NewItem        ="$NewItem );
			mplog( "...ActiveItem     ="$ActiveItem );
			mplog( "...PendingItem    ="$PendingItem );
        }
        
        return false;
    }

	if (Level.GetEngine().EnableDevTools)    
		mplog( self$"---SwatPlayer::ValidateEquipPocket(). Validate succeeded. Pocket="$thePocket$", NewItem="$NewItem );

    //okay, go ahead and equip
    return true;
}

simulated function SetProtection(ESkeletalRegion Region, ProtectiveEquipment Protection)
{
    local SwatGamePlayerController PC;

    //Log("SETPROTECTION ON "$Name$" "$int(Region)$" = "$Protection);

    Super.SetProtection(Region, Protection);

    PC = SwatGamePlayerController(Controller);
    
    if( PC == Level.GetLocalPlayerController() && PC.HasHUDPage())
    {
        PC.GetHUDPage().UpdateProtectiveEquipmentOverlay();
    }
}


//Pawn override
simulated function DestroyEquipment()
{
    //log( ".....SwatPlayer::DestroyEquipment()." );
    LoadOut.Destroy();

    Super.DestroyEquipment();
}

simulated event Destroyed()
{
    // Superclass method calls DestroyEquipment.
	Super.Destroyed();

    // Destroy hands so we don't have old hands lying around
    // in multiplayer after player is respawned.
    if ( GetHands() != None )
        GetHands().Destroy();

    StungTimer.Destroy();
    FlashbangedTimer.Destroy();
    GassedTimer.Destroy();
    PepperSprayedTimer.Destroy();
    TasedTimer.Destroy();

    PerlinNoiseAxisA.Delete(); PerlinNoiseAxisA = None;
    PerlinNoiseAxisB.Delete(); PerlinNoiseAxisB = None;

    Loadout.Destroy();

    UnTriggerAllNonLethalEffectEvents();

    // Unregister from the reported to toc notification
	if (Level.NetMode == NM_Standalone || Level.IsCOOPServer)
	{
		SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.UnRegister(self);
	}
}

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation, vector HitMomentum)
{
    //log( "........ in SwatPlayer::Died()." );
    Super.Died(Killer, damageType, HitLocation, HitMomentum);

	// this may need to be redone for COOP
	if (Level.NetMode == NM_Standalone || Level.IsCOOPServer)
	{
		SwatAIRepository(Level.AIRepo).GetHive().NotifyPlayerDied(self);
	}

    UnTriggerAllNonLethalEffectEvents();
}

// Executes only on the server and in standalone.
// Overrides Pawn::ServerRequestEquip().
function ServerRequestEquip( EquipmentSlot Slot )
{
    local HandheldEquipment NewEquipment;
	local HandheldEquipment PendingItem;
    local HandheldEquipment CurrentItem;

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::ServerRequestEquip(). Slot="$Slot );

    // If the pawn is in the process of throwing, they should not be allowed
    // to equip something new. When the throwing process is finished, the
    // server will do an authorized equip and force them to equip the
    // appropriate thing.
    if ( !RequestEquipShouldBeAllowed() )
        return;

    CurrentItem = GetActiveItem();
    PendingItem = GetPendingItem();
    
    // The player can't unequip certain items. If they request it, just do
    // nothing. If the server needs to force the player to unequip one of
    // these items, it should call ForceEquipOnServer() below.
    if (CurrentItem != None && !CurrentItem.PlayerCanUnequip)
        return;
    if (PendingItem != None && !PendingItem.PlayerCanUnequip)
        return;

// dbeswick: integrated 20/6/05
    // We don't want the player to be able to equip if he's currently under
    // the influence of nonlethals.
    // 
    // NOTE: we also check this on the client side in 
    // SwatGamePlayerController::InternalEquipSlot, but we put it here to prevent
    // clients who hack their .u files and are able to bypass the MD5 checks
    // from being able to cheat too egregiously.
    if ( IsNonlethaled() )
        return;

    if ( ValidateEquipSlot( Slot ) ) // || Slot == Slot_IAmCuffed )
    {
        NewEquipment = GetEquipmentAtSlot( Slot );

        if (Level.NetMode == NM_Standalone)
        {
            NewEquipment.Equip();
        }
        else
        {
            SetDesiredItemPocket( NewEquipment.GetPocket() );

            // And then do the equipping here on the server.
            CheckDesiredItemAndEquipIfNeeded();
        }
    }
}

simulated function OnActiveItemEquipped()
{
    Super.OnActiveItemEquipped();

    if ( Controller == Level.GetLocalPlayerController() )
    {
        if (GetActiveItem().ZoomedFOV > 0)
            PlayerController(Controller).ZoomedFOV = GetActiveItem().ZoomedFOV;
        else
            PlayerController(Controller).ZoomedFOV = PlayerController(Controller).BaseFOV;
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Does the same thing as ServerRequestEquip(), except that it can force the
// pawn to unequip an item even if that item is PlayerCanUnequip==false.
//
// Executes only on the server and in standalone.
function AuthorizedEquipOnServer( EquipmentSlot Slot )
{
    local HandheldEquipment NewEquipment;

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::AuthorizedEquipOnServer(). Slot="$Slot );

    Assert( Level.NetMode != NM_Client );

    if (Level.NetMode == NM_Standalone)
    {
        if ( ValidateEquipSlot( Slot ) )
        {
            NewEquipment = GetEquipmentAtSlot( Slot );
            NewEquipment.Equip();
        }
    }
    else
    {
        NewEquipment = GetEquipmentAtSlot( Slot );
        SetDesiredItemPocket( NewEquipment.GetPocket() );
        if ( ValidateEquipSlot( Slot ) )
        {
            CheckDesiredItemAndEquipIfNeeded();
        }    
    }
}

// Executes only on the server.
// Overrides Pawn::ServerRequestMelee().
function ServerRequestMelee( EquipmentSlot Slot )
{
	local HandheldEquipment ActiveItem, ItemToMelee;
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;

	log( "In SwatPlayer::ServerRequestMelee()." );

	ActiveItem = GetActiveItem();
    ItemToMelee = GetEquipmentAtSlot( Slot );
    log( "   ActiveItem="$ActiveItem$", ItemToMelee="$ItemToMelee );

    if ( ItemToMelee != ActiveItem || ActiveItem == None )
        return;

	if ( !ItemToMelee.bAbleToMelee )
		return;

	if ( Level.NetMode != NM_Standalone && !ActiveItem.PrevalidateMelee() )
        return;

	if ( ValidateMelee() )
	{
		// Do an RPC to all clients to initiate the melee on each one.

		// Tell all clients who don't own the weapon that the owner is meleeing.
        if ( Level.NetMode != NM_Standalone )
        {
            theLocalPlayerController = Level.GetLocalPlayerController();
            for ( i = Level.ControllerList; i != None; i = i.NextController )
            {
                current = SwatGamePlayerController( i );
                if ( current != None )
                {
                    //log( "                            i: "$i );
                    //log( "                        Owner: "$Owner );
                    //log( "     theLocalPlayerController: "$theLocalPlayerController );
                    
                    if ( (current != theLocalPlayerController) && (current.Pawn != None) )
                    {
						if (Level.GetEngine().EnableDevTools)
							mplog( self$" on server: calling ClientMeleeForPawn() on "$current.Pawn );
							
                        current.ClientMeleeForPawn( self, ItemToMelee.GetSlot() );
                    }
                }
            }
		}

		// And then do the melee here on the server.
        ItemToMelee.Melee();
	}
}

// Executes only on the server.
// Overrides Pawn::ServerRequestReload().
function ServerRequestReload( EquipmentSlot Slot )
{
    local FiredWeapon ActiveItem, ItemToReload;
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;

    log( "In SwatPlayer::ServerRequestReload()." );

    ActiveItem = FiredWeapon( GetActiveItem() );
    ItemToReload = FiredWeapon( GetEquipmentAtSlot( Slot ));
    log( "   ActiveItem="$ActiveItem$", ItemToReload="$ItemToReload );

    if ( ItemToReload != ActiveItem || ActiveItem == None )
        return;

    if ( Level.NetMode != NM_Standalone && !ActiveItem.PrevalidateReload() )
        return;

    // can't reload round-based weapons that are full
    if  ( ActiveItem.IsA('RoundBasedWeapon') && ActiveItem.Ammo.IsFull() )
        return;

    if ( ValidateReload() )
    {
        // Do an RPC to all clients to initiate the reload on each one.

        // Tell all clients who don't own the weapon that the owner is equipping it.
        if ( Level.NetMode != NM_Standalone )
        {
            // Get Level->ControllerList and walk it. If i->Pawn != Owner, call ClientEquipNotOwner().
            theLocalPlayerController = Level.GetLocalPlayerController();
            for ( i = Level.ControllerList; i != None; i = i.NextController )
            {
                current = SwatGamePlayerController( i );
                if ( current != None )
                {
                    //log( "                            i: "$i );
                    //log( "                        Owner: "$Owner );
                    //log( "     theLocalPlayerController: "$theLocalPlayerController );
                    
                    if ( (current != theLocalPlayerController) && (current.Pawn != None) )
                    {
						if (Level.GetEngine().EnableDevTools)
							mplog( self$" on server: calling ClientReloadForPawn() on "$current.Pawn );
							
                        current.ClientReloadForPawn( self, ItemToReload.GetSlot() );
                    }
                }
            }
        }

        // And then do the reload here on the server.
        ItemToReload.Reload();
    }
}



///////////////////////////////////////////////////////////////////////////////
//
// Executes only on the server. 
//

function ServerRequestUse( SwatPlayer inUsePawn )
{
    local SwatGamePlayerController current;
    local Controller iController, LocalPC;
    local NetPlayer theNetPlayer; 
    local HandheldEquipment Equipment;

    assert( Level.NetMode != NM_Standalone );

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::ServerRequestUse(). PawnUser="$inUsePawn );

    // The server should test here to make sure the request is valid, and then
    // RPC all the clients to initiate the arrest. It should also make sure to
    // initiate the arrest locally, too.
    Equipment = inUsePawn.GetActiveItem();

	if (Level.GetEngine().EnableDevTools)
		mplog( "...Equipment="$Equipment );
		
	if (Level.GetEngine().EnableDevTools)
	{
		// Begin: remove me once we get the equipment system thoroughly debugged.
		if ( Equipment != None )
		{
			if ( !Equipment.IsEquipped() )
			{    
				mplog( "...failing because equipment wasn't equipped." );
			}
			if ( !Equipment.IsIdle() )
			{    
				mplog( "...failing because equipment wasn't idle." );
			}
		}
		// End: remove me.
    }

    if ( Equipment == None || !Equipment.PrevalidateUse() )
        return;
        
	if (Level.GetEngine().EnableDevTools)
	    mplog( "...Equipment.PrevalidateUse()=True" );

    // Then, RPC to all clients.
    // Get Level->ControllerList and walk it. If i->Pawn != Owner, call ClientBeginArrest().
    LocalPC = Level.GetLocalPlayerController();
    for ( iController = Level.ControllerList; iController != None; iController = iController.NextController )
    {
        current = SwatGamePlayerController( iController );
        if ( current != None && current != LocalPC )
        {
            theNetPlayer = NetPlayer( current.Pawn );
            if ( theNetPlayer != None )
            {
                log( self$" on server: calling ClientUse() by "$theNetPlayer );
                theNetPlayer.ClientUse( inUsePawn );
            }
        }
    }
    Equipment.Use();
}

simulated function ClientUse( Pawn inUsePawn )
{
    local HandheldEquipment Equipment;

    Assert( Level.NetMode == NM_Client );

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::ClientUse(). PawnUser="$inUsePawn$", his equipment is: "$inUsePawn.GetActiveItem()$", inUsePawn.GetActiveItem().PrevalidateUse() = "$inUsePawn.GetActiveItem().PrevalidateUse() );

    if ( inUsePawn  == None )
        return;

    Equipment = inUsePawn.GetActiveItem();
    if ( Equipment == None || !Equipment.PrevalidateUse() )
        return;

//    mplog( self$"---SwatPlayer::ClientUse(). PawnUser="$inUsePawn$", his equipment is: "$Equipment );
    Equipment.Use();
}

function ServerRequestQualify( Actor DefaultFireFocusActor )
{
    local SwatGamePlayerController current;
    local Controller i, LPC;
    local NetPlayer theNetPlayer; //, QualifyTarget;
    local SwatAI theSwatAI;
    local Actor QualifyTarget;
    local HandheldEquipment theEquipment;

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::ServerRequestQualify(). TargetActor="$DefaultFireFocusActor );

    Assert( Level.NetMode != NM_Standalone );

    // The server should test here to make sure the request is valid, and then
    // RPC all the clients to initiate the qualification. It should also make
    // sure to initiate the qualification locally, too.

    QualifyTarget = DefaultFireFocusActor;
    if ( QualifyTarget == None )
        return;

    theEquipment = GetActiveItem();
    if ( theEquipment == None || !theEquipment.IsIdle() )
        return;

    theNetPlayer = NetPlayer( DefaultFireFocusActor );
    if ( theNetPlayer != None )
    {
        if ( theEquipment.IsA( 'Cuffs' ) && !theNetPlayer.CanBeArrestedNow() )
            return;

        if ( theEquipment.IsA( 'Toolkit' ) && !theNetPlayer.CanBeUnarrestedNow() )
            return;
    }

    theSwatAI = SwatAI( DefaultFireFocusActor );
    if ( theSwatAI != None )
    {
        if ( theEquipment.IsA( 'Cuffs' ) && !theSwatAI.CanBeArrestedNow() )
            return;
    }

    // Store the target, and then put the PlayerController into the Qualifying state.
    SwatGamePlayerController(Controller).OtherForQualifyingUse = DefaultFireFocusActor;
    SwatGamePlayerController(Controller).GotoState('QualifyingForUse');
    SwatGamePlayerController(Controller).ClientGotoState('QualifyingForUse', 'Begin');

    // Then, RPC to all clients.
    // Get Level->ControllerList and walk it. If i->Pawn != Owner, call ClientStartQualify().
    LPC = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = SwatGamePlayerController( i );
        if ( current != None )
        {
            theNetPlayer = NetPlayer( current.Pawn );
            if ( (current != LPC) && (theNetPlayer != None) && theNetPlayer != self )
            {
                //mplog( self$" on server: calling ClientStartQualify() by "$theNetPlayer$" on "$QualifyTarget );
                theNetPlayer.ClientStartQualify( self, QualifyTarget );
            }
        }
    }
}


simulated function ClientStartQualify( SwatPlayer Qualifier, Actor QualifyTarget )
{
    local EquipmentUsedOnOther theEquipment;

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::ClientStartQualify(). Qualifier="$Qualifier$", QualifyTarget="$QualifyTarget );

    Assert( Level.NetMode != NM_Standalone );

    // If neither of the args are None, and the Qualifier has the appropriate
    // item equipped, then call theEquipment.BeginQualifying( QualifyTarget ).
    if ( Qualifier == None || QualifyTarget == None )
        return;

    // If we were the pawn requesting the beginarrest, we'll call
    // BeginQualifying() when our playercontroller enters the QualifyForUse
    // state, so do nothing here.
    Assert( Qualifier != self );
    if ( Qualifier == self )
        return;

    theEquipment = EquipmentUsedOnOther(Qualifier.GetActiveItem());
    if ( theEquipment == None )
        return;

    // Rotate the lower body yaw to match the upper body yaw, so that the
    // upper body qualification animations line up to the intended target.
    Qualifier.AnimSnapBaseToAim();

    if ( theEquipment.IsIdle() )
    {
        theEquipment.BeginQualifying( QualifyTarget );
    }
    else
    {
		if (Level.GetEngine().EnableDevTools)
		    mplog( "...equipment was not idle. Caching request to qualify." );
		    
        // For remote pawns *only*, we want to save the info for a cached
        // qualification.
        Qualifier.CachedQualifyEquipment = theEquipment;
        Qualifier.CachedQualifyTarget = QualifyTarget;
    }
}


simulated function bool WeHaveACachedQualify()
{
    return CachedQualifyEquipment != None;
}

simulated function BeginCachedQualification()
{
	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::BeginCachedQualification()." );

    Assert( CachedQualifyEquipment != None );

    CachedQualifyEquipment.BeginQualifying( CachedQualifyTarget );

    // Clear out the cached values to denote that we've already initiated the
    // cached qualify that was pending.
    CachedQualifyEquipment = None;
    CachedQualifyTarget = None;    
}



///////////////////////////////////////////////////////////////////////////////
//
// Executes only on the server. 
//

// The following two functions will be needed when we implement VIP mode.

// Executes only on server
function NotifyClientsOfFinishQualify( Actor QualifyTarget, bool Success )
{
    local Controller i;
    local PlayerController current;
    local SwatPlayer playerPawn;
    local PlayerController theLocalPlayerController;
    
	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::NotifyClientsOfFinishQualify()" );

    assert( Level.NetMode != NM_Standalone );

    // Get Level->ControllerList and walk it. If i->Pawn != Owner, call ClientFinishQualify().
    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = PlayerController( i );
        if ( current != None )
        {
            playerPawn = SwatPlayer(i.Pawn);
            if ( (i != theLocalPlayerController) && (playerPawn != None) )
            {
                //mplog( "On server: calling ClientFinishQualify() on "$playerPawn );
                playerPawn.ClientFinishQualify( self, QualifyTarget, Success );
            }
        }
    }
}


// Success==true if the qualifying completed, false if interrupted.
simulated function ClientFinishQualify( SwatPlayer Qualifier, Actor QualifyTarget, bool Success )
{
    local QualifiedUseEquipment QualifiedUseEquipment;

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::ClientFinishQualify(). Qualifier="$Qualifier$", QualifyTarget="$QualifyTarget$", Success="$Success );

    assert( Level.NetMode != NM_Standalone );

    if ( Qualifier == None )
        return;

    QualifiedUseEquipment = QualifiedUseEquipment(Qualifier.GetActiveItem());
    if (QualifiedUseEquipment != None)
    {
        if (Success)
        {
            QualifiedUseEquipment.DoQualifyComplete();
        }
        else
        {
            QualifiedUseEquipment.DoInterrupt();
        }
    }
}


// Called when a new value for DesiredItem is replicated to us.
simulated event DesiredItemPocketChanged()
{
	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::DesiredItemPocketChanged()." );

    // If we're currently in the throwing process, we should ignore that the
    // desired item variable changed and this event fired. Once the throwing
    // process is done, we equip the desired item anyway.
    if ( !RequestEquipShouldBeAllowed() )
        return;

    CheckDesiredItemAndEquipIfNeeded();
}


// Overridden from Pawn.
simulated function OnEquippingFinished()
{
	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnEquippingFinished()." );

    Super.OnEquippingFinished();

    // MCJ: This is ugly. There is no good place to tell the server's player
    // that they are the VIP, but after the HUD is up. I'm putting this POS here
    // becuase we know the VIP status is valid and the HUD is up at the end of
    // equipping the first weapon. God this is ugly. I'm open to suggestions
    // for better places to do this, but beware---it's not as easy to find one
    // as you might think.
    NotifyPlayerHeIsVIPIfNecessary();

    if ( Controller == Level.GetLocalPlayerController() )
    {
        if  (
                !class'Pawn'.static.CheckDead( self )       //we're not dead yet
            &&  !CheckDesiredItemAndEquipIfNeeded()         //we didn't need to start equipping something else instead
            &&  SwatGamePlayerController(Controller).
                    EquipmentSlotForQualify != SLOT_Invalid //we finished equipping something in order to qualify with it
            &&  (
                GetActiveItem().GetSlot()
                ==  SwatGamePlayerController(Controller).EquipmentSlotForQualify
                )                                           //the thing we finally equipped is the thing we wanted to qualify with
            &&  Controller.bFire > 0                        //player is still holding the Fire button
            )
        {
			if (Level.GetEngine().EnableDevTools)
				mplog( "...complicated test succeeded and we're inside the if-block." );

            SwatGamePlayerController(Controller).EquipmentSlotForQualify = SLOT_Invalid;

            //we need to update focus because the player may have looked away, 
            //  and qualification is not appropriate anymore.
            SwatGamePlayerController(Controller).UpdateFocus();

            PlayerController(Controller).Fire();  //this will begin the qualification if appropriate
        }
    }
    else
    {
        if ( !class'Pawn'.static.CheckDead( self ))
        {
			if (Level.GetEngine().EnableDevTools)
				mplog( "...WeHaveACachedQualify()="$WeHaveACachedQualify() );
            
            if ( Level.NetMode == NM_Client && WeHaveACachedQualify() )
            {
                // If we get here, we know we're dealing with a remote pawn who
                // has a cached qualify.
                BeginCachedQualification();
            }
            else
            {
                CheckDesiredItemAndEquipIfNeeded();
            }
        }
    }
}


simulated function NotifyPlayerHeIsVIPIfNecessary()
{
    if ( Level.NetMode != NM_Standalone )
    {
        if ( Controller == Level.GetLocalPlayerController() )
        {
            if ( IsTheVIP() && !bNotifiedPlayerTheyAreVIP )
            {
                ClientMessage( "", 'YouAreVIP' );
                bNotifiedPlayerTheyAreVIP = true;
            }
        }
    }
}


simulated function OnUsingBegan()
{
	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnUsingBegan()." );

    SetupReequip();

    if ( IsLowReady() && GetActiveItem().ShouldUseWhileLowReady() )
    {
        SetLowReady(false);
    }
    if (IsControlledByLocalHuman())
        SwatGamePlayerController(Controller).BeginLowReadyRefractoryPeriod();    //don't go back to low-ready for some time, ie. avoid historesis
}

//make preparations for something else being equipped after the ActiveItem is done being used
simulated function SetupReequip()
{
    local HandheldEquipment ActiveItem;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::SetupReequip()." );

    ActiveItem = GetActiveItem();

    EquipOtherAfterUsed = ActiveItem.UnavailableAfterUsed || ActiveItem.EquipOtherAfterUsed;
    SlotForReequip = ActiveItem.GetSlotForReequip();
    //HandheldEquipment can return Slot_Invalid from GetSlotForReequip() to mean DoDefaultEquip() after used.
}

// Overridden from Pawn.
simulated function OnUsingFinished()
{
    local HandheldEquipment ItemToEquip;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnUsingFinished()." );

    if ( class'Pawn'.static.CheckDead( self ) )
        return;

    if  ( Level.NetMode != NM_Client )
    {
        if ( EquipOtherAfterUsed )
        {
            //try to equip another one of the item that was just used
            ItemToEquip = LoadOut.GetItemAtSlot(SlotForReequip);

            if (ItemToEquip != None)
            {
                AuthorizedEquipOnServer( SlotForReequip );
            }
            else
            {
                //no more of those... equip the default weapon
                DoDefaultEquip();
            }
        }
    }
    else 
    {
        CheckDesiredItemAndEquipIfNeeded();
    }
}


// Overridden from Pawn.
simulated function IWasNonlethaledAndFinishedSoDoAnEquipIfINeedToDoOne()
{
    local HandheldEquipment theActiveItem;
    local HandheldEquipment thePendingItem;
    
	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::IWasNonlethaledAndFinishedSoDoAnEquipIfINeedToDoOne()." );

    if ( class'Pawn'.static.CheckDead( self ) )
        return;

    // Do nothing if we are in the process of being arrested or have finished
    // being arrested.
    theActiveItem = GetActiveItem();
    if ( theActiveItem != None && theActiveItem.IsA('IAmCuffed') )
        return;

    thePendingItem = GetPendingItem();
    if ( thePendingItem != None && thePendingItem.IsA('IAmCuffed') )
        return;

    if ( IsArrested() )
        return;

    if  ( Level.NetMode != NM_Client )
    {
        theActiveItem = GetActiveItem();
        if ( theActiveItem == None || !theActiveItem.IsAvailable() || theActiveItem.IsA('Lightstick') )
            DoDefaultEquip();
    }
    else 
    {
        CheckDesiredItemAndEquipIfNeeded();
    }
}


// Overridden from Pawn.
simulated function OnReloadingFinished()
{
	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnReloadingFinished()." );

    if ( !class'Pawn'.static.CheckDead( self ))
    {
        if (!CheckDesiredItemAndEquipIfNeeded())
        {
            //we didn't need to start equipping something else
            SwatGamePlayerController(Controller).ConsiderAutoReloading();
        }
    }
}

//returns true iff it needed to begin equipping something else
simulated protected function bool CheckDesiredItemAndEquipIfNeeded()
{
    local Pocket DesiredItemPocket;
    local HandheldEquipment ActiveItem;
    local HandheldEquipment NewEquipment;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::CheckDesiredItemAndEquipIfNeeded()." );

    if ( Level.NetMode != NM_Standalone && LoadOut != None )
    {
        DesiredItemPocket = GetDesiredItemPocket();
        ActiveItem = GetActiveItem();

        // If the active item is the same as the desired item, do nothing.
        if ( ActiveItem != None && DesiredItemPocket == ActiveItem.GetPocket() )
        {
			if (Level.GetEngine().EnableDevTools)
				mplog( self$"...returning false: Pockets are same="$DesiredItemPocket );
				
            return false;
        }

		if (Level.GetEngine().EnableDevTools)
			mplog( self$"...Pockets differ:" );
			
		if (Level.GetEngine().EnableDevTools)
		{
			if ( ActiveItem != None )
				mplog( "...DesiredItemPocket="$DesiredItemPocket$", ActiveItemPocket="$ActiveItem.GetPocket() );
			else
				mplog( "...DesiredItemPocket="$DesiredItemPocket$", ActiveItem=None" );
		}

        if ( ValidateEquipPocket( DesiredItemPocket ))
        {
            NewEquipment = HandheldEquipment( LoadOut.GetItemAtPocket( DesiredItemPocket ) );

			if (Level.GetEngine().EnableDevTools)
				mplog( "...LoadOut.GetItemAtPocket( DesiredItemPocket ) = "$NewEquipment );

            NewEquipment.Equip();
        }

        return true;
    }
    else
        return false;
}

simulated function HandheldEquipment GetEquipmentAtSlot(EquipmentSlot Slot)
{
//    log( self$"... SwatPlayer::GetEquipmentAtSlot()." );
//    log( "   ... LoadOut="$LoadOut );
    return LoadOut.GetItemAtSlot(Slot);
}

simulated function bool ValidateMelee()
{
	local HandheldEquipment ActiveItem;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::ValidateMelee()." );

    ActiveItem = GetActiveItem();

	return ActiveItem.IsIdle(); //can only do one thing at a time
}

simulated function bool ValidateReload()
{
    local HandheldEquipment ActiveItem;
    local FiredWeapon Weapon;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::ValidateReload()." );

    ActiveItem = GetActiveItem();

    //TMC this assert is invalid because between unequipping and equipping, the ActiveItem is supposed to be None
    //
    //AssertWithDescription(ActiveItem != None,
    //    "[tcohen] Reload() was called on the PlayerController.  But either the Pawn is None, the Pawn has no ActiveItem, or the Pawn's ActiveItem is not a HandheldEquipment.");

    Weapon = FiredWeapon(ActiveItem);

    if (Weapon == None)
    {
        //can only reload a FiredWeapon
        return false;
    }

    if (!Weapon.IsIdle())
    {
        //can only do one thing at a time
        return false;
    }
    
    if (!Weapon.Ammo.CanReload() )
    {
        return false;
    }
        
    return true;
}


simulated function float GetFireTweenTime()
{
    if (IsLowReady())
        return LowReadyFireTweenTime;
    else
        return 0.0;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//Throwing is divided into three states, each one passing-off to the next:
//  1. ThrowingPrep
//      The player may release the throw button before the pre-throw animation is done.
//      In that case, we want to finish the pre-throw, and only then do the actual throw.
//  2. Throwing
//      Wait for player to release the throw button if they haven't already.
//  3. ThrowingFinish
//      Actually throw the item, and equip default weapon.
//      We need to wait for the throw to finish before equipping the default weapon; thus the additional state.


// Called by the SwatGamePlayerController. Used here so that we can disable
// idling while the pawn is throwing.
function bool HandsShouldIdle()
{
    return true;
}

simulated function bool IsInProcessOfThrowing()
{
    return !CanThrowPrep();
}

simulated function bool CanThrowPrep()
{
	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::CanThrowPrep()." );
		
    // NOTE: this function is typically overridden in other states
		
    return true;
}

simulated function bool RequestEquipShouldBeAllowed()
{
	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::RequestEquipShouldBeAllowed()." );
		
    // NOTE: this function is typically overridden in other states

    return true;
}

// If this is called, that means that the pawn needs to do a ThrowingFinish even
// though it hasn't done the ThrowingPrep and Throwing states. This will
// happen if a pawn becomes relevant after the ThrowingPrep but before the
// ThrowingFinish. If the pawn is in either of the ThrowingPrep or Throwing
// states, their versions of this function will get called.
simulated function EndThrow( float ThrowHeldTimeFromNetwork )
{
    local ThrownWeapon theItem;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::EndThrow()." );

    theItem = ThrownWeapon(GetActiveItem());

    // There's a chance on remote clients that we might get told to EndThrow()
    // before the ThrownWeapon has finished equipping. Ignore the request in
    // that situation.
    if ( theItem == None || !theItem.IsIdle() )
        return;

    ThrowHeldTime = ThrowHeldTimeFromNetwork;
    GotoState( 'ThrowingFinish' );
}


///////////////////////////////////////////////////////////////////////////////
///
///
simulated state ThrowingPrep
{    
    ignores HandsShouldIdle;

    simulated function bool CanThrowPrep()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---CanThrowPrep() of state 'ThrowingPrep'." );
			
        return false;
    }

    simulated function bool RequestEquipShouldBeAllowed()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---RequestEquipShouldBeAllowed() of state 'ThrowingPrep'." );
        
        return false;
    }

    simulated function BeginState()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---BeginState() of state 'ThrowingPrep'." );

        ThrowHeldTime = 0;
        DoneThrowing = false;

        assertWithDescription(ThrowSpeedTimeFactor > 0.0,
            "[tcohen] ThrowSpeedTimeFactor is not specified for the class "$class.name
            $".  Please set it in SwatGame.ini, section [SwatGame."$class.name
            $"].");

        assertWithDescription(ThrowSpeedRange.Min > 0.0,
            "[tcohen] ThrowSpeedRange.Min is not specified for the class "$class.name
            $".  Please set it in SwatGame.ini, section [SwatGame."$class.name
            $"].");
    }

    simulated function EndState()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---EndState() of state 'ThrowingPrep'." );
    }


    simulated latent function DoThrowingPrep()
    {
        local ThrownWeapon Grenade;
        local HandheldEquipmentModel GrenadeFirstPersonModel;
        local Hands Hands;
        local int PawnThrowAnimationChannel;

		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---SwatPlayer::DoThrowingPrep() in state 'ThrowingPrep'." );

        //play the pre-throw animation on the hands, pawn, and grenade
        Grenade = ThrownWeapon(GetActiveItem());
        assertWithDescription(Grenade != None,
            "[tcohen] SwatPlayer was called to PlayGrenadePreThrow(), but its Pawn's ActiveItem isn't a ThrownWeapon.");

        //hands
        Hands = GetHands();
        if ( Hands != None )
            Hands.PlayAnim(Grenade.GetHandsPreThrowAnimation(),,Hands.PreThrowTweenTime);
        //pawn
        PawnThrowAnimationChannel = AnimPlaySpecial(
            Grenade.GetThirdPersonPreThrowAnimation(), 
            GetPawnThrowTweenTime(), 
			GetPawnThrowRootBone());
        //grenade
        GrenadeFirstPersonModel = Grenade.GetFirstPersonModel();
        if ( GrenadeFirstPersonModel != None && Grenade.GetFirstPersonPreThrowAnimation() != '')
            GrenadeFirstPersonModel.PlayAnim(Grenade.GetFirstPersonPreThrowAnimation());
       
        //finish animations...

        //hands
        if ( Hands != None )
            Hands.FinishAnim();
        //pawn
        FinishAnim(PawnThrowAnimationChannel);
        //grenade
        if ( GrenadeFirstPersonModel != None )
            GrenadeFirstPersonModel.FinishAnim();

        //use the tactical aid aim pose set while holding a live grenade
        AnimSwapInSet(kAnimationSetTacticalAid);
    }

    simulated function Tick(float dTime)
    {
        Global.Tick(dTime);

        if (!DoneThrowing)
        {
            if ( Controller == Level.GetLocalPlayerController() )
            {
                if (Controller.bFire == 0)
                {
                    DoneThrowing = true; // need to set this here *and* below
                                         // in EndThrow().
                    SwatGamePlayerController(Controller).ServerEndThrow( ThrowHeldTime );
                }
                else
                {
                    ThrowHeldTime += dTime;
                }
            }
        }
        //else
        //  we're just waiting for the pre-throw animations to finish... we'll be releasing right after that
    }
    
    simulated function EndThrow( float ThrowHeldTimeFromNetwork )
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---EndThrow() of state 'ThrowingPrep'." );
			
        DoneThrowing = true;
        ThrowHeldTime = ThrowHeldTimeFromNetwork;
    }

Begin:

	if (Level.GetEngine().EnableDevTools)
		mplog( self$" Begin: of state 'ThrowingPrep'." );

    //we need to use some local variables
    DoThrowingPrep();

    GotoState('Throwing');
}


///////////////////////////////////////////////////////////////////////////////
///
///
simulated state Throwing
{
    ignores HandsShouldIdle;

    simulated function BeginState()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---BeginState() of state 'Throwing'." );
    }

    simulated function EndState()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---EndState() of state 'Throwing'." );
    }

    simulated function bool CanThrowPrep()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---CanThrowPrep() of state 'Throwing'." );

        return false;
    }

    simulated function bool RequestEquipShouldBeAllowed()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---RequestEquipShouldBeAllowed() of state 'Throwing'." );

        return false;
    }

    simulated function Tick(float dTime)
    {
        Global.Tick(dTime);

        if (!DoneThrowing)
        {
            if ( Controller == Level.GetLocalPlayerController() )
            {
                if (Controller.bFire == 0)
                {
                    DoneThrowing = true; // Need to set this here *and* below
                                         // in EndThrow().
                    SwatGamePlayerController(Controller).ServerEndThrow( ThrowHeldTime );
                }
                else
                {
                    ThrowHeldTime += dTime;
                }
            }
        }
        else
        {
			if (Level.GetEngine().EnableDevTools)
				mplog( self$" calling GotoState('ThrowingFinish') in Tick() of state 'Throwing'." );

            GotoState('ThrowingFinish');
        }
    }

    simulated function EndThrow( float ThrowHeldTimeFromNetwork )
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---EndThrow() of state 'Throwing'." );
			
        DoneThrowing = true;
        ThrowHeldTime = ThrowHeldTimeFromNetwork;
    }

    simulated function InterruptState(name Reason)
    {
        local HandheldEquipment ActiveItem;
        local ThrownWeapon ThrownWeapon;

		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---SwatPlayer::InterruptState() in state 'Throwing'." );

        //Throwing has been interrupted.  The pin is pulled, but the grenade is not yet thrown.

        //If the player is about to be arrested, then 
        //  we want to "forget" about the grenade altogether, to avoid the degenerate strategy
        //  of running around with a live grenade to avoid being arrested.
        //If the player is not affected by a non-lethal (ie. killed), then they should drop
        //  the grenade.

        if  ( Reason != 'BeingCuffed' || Reason != 'ReactingToNonlethal' )
        {
            //drop the grenade
            ActiveItem = GetActiveItem();
            assertWithDescription(ActiveItem != None,
                  "[tcohen] SwatPlayer@Throwing::InterruptState(), ActiveItem is None.");
            ThrownWeapon = ThrownWeapon(ActiveItem);
            assertWithDescription(ThrownWeapon != None,
                  "[tcohen] SwatPlayer@Throwing::InterruptState(), ActiveItem ("$ActiveItem
                  $") is not a ThrownWeapon.");

            ThrownWeapon.SetThrowSpeed(0);
            ThrownWeapon.OnUseKeyFrame( true ); // true == force use
            ThrownWeapon.AIInterrupt();
        }
    }
}


///////////////////////////////////////////////////////////////////////////////
///
///
simulated state ThrowingFinish
{
    simulated function bool CanThrowPrep()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---CanThrowPrep() of state 'ThrowingFinish'." );
			
        return false;
    }

    simulated function bool RequestEquipShouldBeAllowed()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---RequestEquipShouldBeAllowed() of state 'ThrowingFinish'." );
			
        return false;
    }

    simulated function BeginState()
    {
        local HandheldEquipment ActiveItem;
        local ThrownWeapon ThrownWeapon;
        local float ThrowSpeed;

		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---BeginState() of state 'ThrowingFinish'." );

        ActiveItem = GetActiveItem();
        assertWithDescription(ActiveItem != None,
                              "[tcohen] SwatPlayer in state Throwing noticed that the throw button was released.  But the ActiveItem is None.");
        ThrownWeapon = ThrownWeapon(ActiveItem);
        assertWithDescription(ThrownWeapon != None,
                              "[tcohen] SwatPlayer in state Throwing noticed that the throw button was released.  But the ActiveItem ("$ActiveItem
                              $") is not a ThrownWeapon.");

        //log("TMC Throwing: ThrowSpeedRange=(Max="$ThrowSpeedRange.Max$", Min="$ThrowSpeedRange.Min$")"
        //    $", ThrowSpeedTimeFactor="$ThrowSpeedTimeFactor
        //    $", ThrowHeldTime="$ThrowHeldTime
        //    $".  ThrowSpeedTimeFactor * ThrowHeldTime = "$ThrowSpeedTimeFactor * ThrowHeldTime
        //    $", FClamp(ThrowSpeedTimeFactor * ThrowHeldTime, ThrowSpeedRange.Min, ThrowSpeedRange.Max) = "$FClamp(ThrowSpeedTimeFactor * ThrowHeldTime, ThrowSpeedRange.Min, ThrowSpeedRange.Max));
        ThrowSpeed = ThrowSpeedTimeFactor * ThrowHeldTime + ThrowSpeedRange.Min;
        ThrownWeapon.SetThrowSpeed(FClamp(ThrowSpeed, ThrowSpeedRange.Min, ThrowSpeedRange.Max));
    }

    simulated function EndState()
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---EndState() of state 'ThrowingFinish'." );

        // MCJ: It turns out that EndState() is called by
        // ULevel::DestroyActor() if the pawn is destroyed. If this happens
        // due to the pawn becoming non-relevant, EndState() will be called
        // without the pawn ever dying. I'm leaving this assertion in so that
        // Terry can debug the throwing in standalone, but it should be
        // disabled for network clients.

        //we should control exits from this state
        if ( Level.NetMode != NM_Client )
            assert( DoneThrowing || class'Pawn'.static.CheckDead(self) );
    }

    simulated function EndThrow( float ThrowHeldTimeFromNetwork )
    {
		if (Level.GetEngine().EnableDevTools)
		{
			mplog( self$"---SwatPlayer::EndThrow() in state 'ThrowingFinish'." );
			mplog( "... *** This shouldn't happen. It's extremely unlikely unless network lag is horrible. ***" );
			mplog( "... The SwatPlayer was told to end a throw while a previous throw was still in the process of ending." );
        }
    }

    simulated function InterruptState(name Reason)
    {
        local HandheldEquipment ActiveItem;
        local ThrownWeapon ThrownWeapon;

		if (Level.GetEngine().EnableDevTools)
			mplog( self$"---SwatPlayer::InterruptState() in state 'ThrowingFinish'." );

        DoneThrowing = true;

        ActiveItem = GetActiveItem();
        if ( ActiveItem == None )
            return;
        assertWithDescription(ActiveItem != None,
              "[tcohen] SwatPlayer@ThrowingFinish::InterruptState(), ActiveItem is None.");
        ThrownWeapon = ThrownWeapon(ActiveItem);
        assertWithDescription(ThrownWeapon != None,
              "[tcohen] SwatPlayer@ThrowingFinish::InterruptState(), ActiveItem ("$ActiveItem
              $") is not a ThrownWeapon.");

        if (ThrownWeapon.IsAvailable() || ThrownWeapon.IsA('Lightstick')) //it hasn't been released yet
        {
            //interrupt it, and drop it

			if (Level.GetEngine().EnableDevTools)
				mplog( "...attempting to drop weapon." );

            ThrownWeapon.SetThrowSpeed(0);
            ThrownWeapon.OnUseKeyFrame( true ); // true == force use
            ThrownWeapon.AIInterrupt();
        }
    }

Begin:

	if (Level.GetEngine().EnableDevTools)
	{
		mplog( self$" Begin: of state 'ThrowingFinish'." );
		mplog( "...ActiveItem="$GetActiveItem() );
		mplog( "...ActiveItem's state="$GetActiveItem().GetStateName() );
	}

    GetActiveItem().LatentUse();
    DoneThrowing = true;

    GotoState('');     //TMC TODO we may not always want to return to the
                       //null state.
}


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//ICanThrowWeapons implementation
function GetThrownProjectileParams(out vector outLocation, out rotator outRotation)
{
    local PlayerController PC;
    local Actor ViewActor;

    PC = PlayerController(Controller);
    //assertWithDescription(Controller != None,
    //                      "[tcohen] The SwatPlayer was called to GetThrownProjectileParams(), but its Controller is not a PlayerController... it is "$Controller);

    if ( PC != None )
    {
        PC.PlayerCalcView(ViewActor, outLocation, outRotation);
        outRotation.Pitch += ThrownProjectilePitch;
    }
}

simulated function name GetPreThrowAnimation()
{
    return PreThrowAnimation;
}

simulated function name GetThrowAnimation(float ThrowSpeed)
{
    if (ThrowSpeed < MinimumLongThrowSpeed)
        return ThrowShortAnimation;
    else
        return ThrowLongAnimation;
}

simulated function name GetPawnThrowRootBone()
{
	return ThrowAnimationRootBone;
}

simulated function float GetPawnThrowTweenTime()
{
	return ThrowAnimationTweenTime;
}

//***************************************
// Interface to Pawn's Controller - overridden from Pawn.uc

// always return true
simulated function bool IsPlayerPawn()
{
	return true;
}

// always return true
simulated function bool IsHumanControlled()
{
	return true;
}


function ServerBeginFiringWeapon( EquipmentSlot ItemSlot )
{
    local Controller i;
    local SwatGamePlayerController current;
    local FiredWeapon theFiredWeapon;
    local PlayerController theLocalPlayerController;

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::ServerBeginFiringWeapon(). ItemSlot="$ItemSlot );

    theFiredWeapon = FiredWeapon(GetLoadOut().GetItemAtSlot( ItemSlot ));
    if ( theFiredWeapon == GetActiveItem() )
    {
        if ( theFiredWeapon.IsIdle() || Pawn(theFiredWeapon.Owner).IsControlledByLocalHuman() )
        {
            if ( Level.NetMode != NM_Standalone )
            {
                if ( !theFiredWeapon.Ammo.NeedsReload() )
                {
                    // Get Level->ControllerList and walk it. If i->Pawn != Owner, call ClientBeginFiringWeapon().
                    theLocalPlayerController = Level.GetLocalPlayerController();
                    for ( i = Level.ControllerList; i != None; i = i.NextController )
                    {
                        current = SwatGamePlayerController( i );
                        if ( current != None )
                        {
                            //log( "                            i: "$i );
                            //log( "                        Owner: "$Owner );
                            //log( "     theLocalPlayerController: "$theLocalPlayerController );
                    
                            if ( (i.Pawn != self) && (i != theLocalPlayerController) )
                            {
                                //mplog( "On server: calling ClientBeginFiringWeapon() on "$current );
                                if ( current.IsNetRelevant( self ))
                                    current.ClientBeginFiringWeapon( self , theFiredWeapon.GetSlot(), theFiredWeapon.GetCurrentFireMode() );
                            }
                        }
                    }
                }
            }
            if ( !IsControlledByLocalHuman() )
            {
                theFiredWeapon.OnPlayerUse();
            }
        }
    }
    else
    {
		if (Level.GetEngine().EnableDevTools)
			mplog( self$" was told to begin firing with "$theFiredWeapon$", but the ActiveItem="$GetActiveItem() );
    }
}

function BroadcastEmptyFiredToClients()
{
    local Controller i;
    local SwatGamePlayerController current;
    local PlayerController theLocalPlayerController;

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::BroadcastEmptyFiredToClients()." );

    Assert( Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer );
    
    // Broadcast to all pawns except the LocalPlayerController's and the pawn
    // who fired (which is self).

    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = SwatGamePlayerController( i );
        if ( current != None )
        {
            if ( (i.Pawn != self) && (i != theLocalPlayerController) )
            {
                if ( current.IsNetRelevant( self ))
                {
                    //mplog( "On server: calling ClientPlayEmptyFired() on "$current.Pawn );
                    SwatPlayer(current.Pawn).ClientPlayEmptyFired( self );
                }
            }
        }
    }
}


simulated function ClientPlayEmptyFired( Pawn PawnWhoFired )
{
    local FiredWeapon theActiveItem;
    local HandheldEquipmentModel EffectsSource;
    local Pawn OtherForEffectEvents;
    local Name EffectSubsystemToIgnore; // initialized by default to ''

	if (Level.GetEngine().EnableDevTools)
		mplog( "---ClientPlayEmptyFired(). PawnWhoFired="$PawnWhoFired );

    // Trigger the EmptyFired effect event on the activeitem of the pawn who
    // fired.

    if ( PawnWhoFired == None )
        return;

    theActiveItem = FiredWeapon(PawnWhoFired.GetActiveItem());
    if ( theActiveItem == None )
        return;

    EffectsSource = theActiveItem.ThirdPersonModel;
    if ( EffectsSource != None )
    {
        if ( EffectsSource.LastRenderTime < Level.TimeSeconds - 1.0f )
        {
            //the EffectsSource wasn't rendered recently, so we'll fall-back to
            //playing the effects on this FiredWeapon's Owner (Pawn)
            OtherForEffectEvents = PawnWhoFired;
        }

        EffectsSource.TriggerEffectEvent( 'EmptyFired', OtherForEffectEvents,,,, (OtherForEffectEvents != None),,,, EffectSubsystemToIgnore );
    }
}


function ServerEndFiringWeapon()
{
     local Controller i;
     local SwatGamePlayerController current;
     local FiredWeapon theFiredWeapon;
     local PlayerController theLocalPlayerController;

	 if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::ServerEndFiringWeapon()." );

     assert( Level.NetMode != NM_Standalone );

     // If this pawn IsControlledByLocalHuman(), this variable will already
     // have been set to false in SGPC::PlayerTick(). If this function was
     // called as an RPC from another client, bWantsToContinueFiring will
     // still be true, so set it to false here to make the pawn stop firing.
     bWantsToContinueAutoFiring = false;

     theFiredWeapon = FiredWeapon(GetActiveItem());

     // Get Level->ControllerList and walk it. If i->Pawn != Owner, call ClientEndFiringWeapon().
     theLocalPlayerController = Level.GetLocalPlayerController();
     for ( i = Level.ControllerList; i != None; i = i.NextController )
     {
         current = SwatGamePlayerController( i );
         if ( current != None )
         {
             //log( "                            i: "$i );
             //log( "                        Owner: "$Owner );
             //log( "     theLocalPlayerController: "$theLocalPlayerController );
                    
             if ( (i.Pawn != self) && (i != theLocalPlayerController) )
             {
                 //mplog( "On server: calling ClientEndFiringWeapon() on "$current );
                 if ( current.IsNetRelevant( self ))
                     current.ClientEndFiringWeapon( self );
             }
         }
     }
}

///////////////////////////////////////////////////////////////////////////////
//
// AFFECTED BY NON-LETHAL
//
// Non-lethal reaction interface implementations
//
///////////////////////////////////////////////////////////////////////////////

//IReactToFlashbangGrenade implementation

Function ReactToFlashbangGrenade(
    SwatGrenadeProjectile Grenade, 
	Pawn  Instigator,
    float Damage, float DamageRadius, 
    Range KarmaImpulse, 
    float KarmaImpulseRadius, 
    float StunRadius, 
    float PlayerFlashbangStunDuration,
    float AIStunDuration,
    float MoraleModifier)
{
    local vector Direction, GrenadeLocation;
    local float Distance;
    local name Reason;
    local name NewControllerState;
    local name NewPawnState;
    local Actor ViewTarget;
    local vector CameraLocation;
    local rotator CameraRotation;
    local bool FOVMatters;          //the player's field-of-view affects flashbang reaction in SP and in CoOp, but not in regular MP
    local bool CanSee;

    if ( Level.NetMode == NM_Client )
        return;

    if ( HasProtection( 'IProtectFromFlashbang' ) )
        return;

    //cheat
    if (Controller != None && Controller.bGodMode)
        return;

	if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
        return;

	if (Grenade != None)
	{
		GrenadeLocation = Grenade.Location;
		Direction       = Location - Grenade.Location;
		Distance        = VSize(Direction);
		if (Instigator == None)
			Instigator = Pawn(Grenade.Owner);
	}
	else
	{
		GrenadeLocation = Location; // we were hit by a cheat command without an actual grenade
		                            // so the hit location is the player's location
		Distance        = 0;
	}

    PlayerController(Controller).PlayerCalcView(ViewTarget, CameraLocation, CameraRotation);
    FOVMatters = Level.NetMode == NM_Standalone || Level.IsPlayingCOOP;
    CanSee =    !FOVMatters
            ||  PointWithinInfiniteCone(
					 CameraLocation,
					 Vector(CameraRotation),
					 GrenadeLocation, 
					 Controller.FOVAngle * DEGREES_TO_RADIANS);
log("TMC FOVMatters="$FOVMatters$", CanSee="$CanSee);
    if  ( 
            bTestingCameraEffects
        ||  (Distance <= StunRadius && CanSee)
		)
    {
        if (Level.NetMode != NM_Client)
        {
            FlashbangedTimer.StartTimer(PlayerFlashbangStunDuration, false, true);   //don't loop, reset if already running
            
            if ( Controller.GetStateName() != 'BeingCuffed' && Controller.GetStateName() != 'BeingUncuffed' )
            {
                Reason = 'ReactingToNonlethal';
                NewControllerState = 'PlayerWalking';
                NewPawnState = '';

                if ( Level.NetMode != NM_Standalone )
                {
                    // We are the server
                    SwatGameReplicationInfo(Level.GetGameReplicationInfo()).NotifyClientsToInterruptAndGotoState( self, Reason, NewControllerState, NewPawnState );
                }

                // Executes on server or in standalone
                InterruptState( Reason );
                Controller.InterruptState( Reason );
                GotoState( NewPawnState );
                Controller.GotoState( NewControllerState );
            }
        }

        LastFlashbangedTime = Level.TimeSeconds;

        SetIsFlashbanged(true);
        RefreshCameraEffects(self);

        ChangeAnimation();
        bIsTriggered_ReactedBang = 0; // Causes UpdateNonLethalEffectEvents to retrigger the event
        UpdateNonLethalEffectEvents();

        // RPC to client who is AutonomousProxy.
        if ( Controller != Level.GetLocalPlayerController() )
            ClientDoFlashbangReaction();
    }

    //damage - Damage should be applied constantly over DamageRadius
    if (Distance <= DamageRadius)
    {
        // event Actor::TakeDamage()
        TakeDamage( Damage,                               // int Damage
                    Instigator,                           // Pawn EventInstigator
                    GrenadeLocation,                      // vector HitLocation
                    vect(0,0,0),                          // vector Momentum
                    class'Engine.GrenadeDamageType' );    // class<DamageType> DamageType
    }
}


simulated function ClientDoFlashbangReaction()
{
    if ( Level.NetMode == NM_Client
         && Controller == Level.GetLocalPlayerController() )
    {
        if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
            return;

        LastFlashbangedTime = Level.TimeSeconds;

        SetIsFlashbanged(true);
        RefreshCameraEffects(self);

        ChangeAnimation();
        bIsTriggered_ReactedBang = 0; // Causes UpdateNonLethalEffectEvents to retrigger the event
        UpdateNonLethalEffectEvents();
    }
}


///////////////////////////////////////////////////////////////////////////////
// IReactToCSGas implementation
//

function ReactToCSGas( Actor GasContainer,
                       float Duration,
                       float SPPlayerProtectiveEquipmentDurationScaleFactor,
                       float MPPlayerProtectiveEquipmentDurationScaleFactor )
{
    local name Reason;
    local name NewControllerState;
    local name NewPawnState;

    if ( Level.NetMode == NM_Client )
        return;

    if ( HasProtection( 'IProtectFromCSGas' ) )
    {        
		// Protects from the effects of gas, so no sense in doing this
        return;
    }
	
	if ( GetLoadOut().HasRiotHelmet() )
	{
		// Riot helmet reduces by the argument, as opposed to original method (since gas masks will ALWAYS provide immunity to CS gas)
		if (Level.NetMode == NM_Standalone)
			Duration *= SPPlayerProtectiveEquipmentDurationScaleFactor;
		else
			Duration *= MPPlayerProtectiveEquipmentDurationScaleFactor;
			
		if (Duration <= 0)
			return; // no sense bothering to set up effects if no duration
	}

    //cheat
    if (Controller != None && Controller.bGodMode)
        return;

	if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
        return;

    //mplog(Self$", is going to be gassed for: "$Duration);

    if (Level.NetMode != NM_Client)
    {
        GassedTimer.StartTimer(Duration, false, true);              //don't loop, reset if already running

        if ( Controller.GetStateName() != 'BeingCuffed' && Controller.GetStateName() != 'BeingUncuffed' )
        {
            Reason = 'ReactingToNonlethal';
            NewControllerState = 'PlayerWalking';
            NewPawnState = '';

            if ( Level.NetMode != NM_Standalone )
            {
                // We are the server
                SwatGameReplicationInfo(Level.GetGameReplicationInfo()).NotifyClientsToInterruptAndGotoState( self, Reason, NewControllerState, NewPawnState );
            }
            
            // Executes on server or in standalone
            InterruptState( Reason );
            Controller.InterruptState( Reason );
            GotoState( NewPawnState );
            Controller.GotoState( NewControllerState );
        }
    }

	LastGassedTime     = Level.TimeSeconds;
	LastGassedDuration = Duration;

    SetIsGassed(true);
    RefreshCameraEffects(self);

    ChangeAnimation();
    UpdateNonLethalEffectEvents();

    // RPC to client who is AutonomousProxy.
    if ( Controller != Level.GetLocalPlayerController() )
        ClientDoGassedReaction( Duration );
}


simulated function ClientDoGassedReaction( float Duration )
{
    if ( Level.NetMode == NM_Client
         && Controller == Level.GetLocalPlayerController() )
    {
        if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
            return;

        LastGassedTime     = Level.TimeSeconds;
        LastGassedDuration = Duration;

        SetIsGassed(true);
        RefreshCameraEffects(self);

        ChangeAnimation();
        UpdateNonLethalEffectEvents();
    }
}

private function bool CantBeDazed()
{
	return ( Level.NetMode == NM_Client ) ||												// Clients handle their own dazing
		   ( HasProtection( 'IProtectFromSting' ) ) ||										// Has protection from sting effects
		   ( Controller != None && Controller.bGodMode ) ||									// Gods can not be dazed!
		   ( class'Pawn'.static.CheckDead( self ) );										// Dead people are beyond dazing
}

// This function assumes LastStingWeapon has be correctly set before being called
private function ApplyDazedEffect(float PlayerStingDuration, float HeavilyArmoredPlayerStingDuration, float NonArmoredPlayerStingDuration)
{
	local float StingDuration;
	local name Reason;
    local name NewControllerState;
    local name NewPawnState;

    //reinitialize the noise generator to prepare for a new effect
    PerlinNoiseAxisA.Reinitialize();
    PerlinNoiseAxisB.Reinitialize();

	if (GetLoadOut().HasHeavyArmor())
        StingDuration = HeavilyArmoredPlayerStingDuration;
	else if (GetLoadOut().HasNoArmor())
		StingDuration = NonArmoredPlayerStingDuration;
    else
        StingDuration = PlayerStingDuration;

	if (Level.TimeSeconds > (LastStungTime + LastStungDuration))
	{
		// if we are done with any previous effect, just set the duration
		LastStungDuration = StingDuration;
	}
	else
	{
		// otherwise, do the max of the new duration and time that is left from the current effect
		LastStungDuration = FMax(StingDuration, LastStungDuration - (Level.TimeSeconds - LastStungTime));
	}

	LastStungTime = Level.TimeSeconds;

    if (Level.NetMode != NM_Client)
    {
        StungTimer.StartTimer(LastStungDuration, false, true);    //don't loop, reset if already running

        if ( Controller.GetStateName() != 'BeingCuffed' && Controller.GetStateName() != 'BeingUncuffed' )
        {
            Reason = 'ReactingToNonlethal';
            NewControllerState = 'PlayerWalking';
            NewPawnState = '';

            if ( Level.NetMode != NM_Standalone )
            {
                // We are the server
                SwatGameReplicationInfo(Level.GetGameReplicationInfo()).NotifyClientsToInterruptAndGotoState( self, Reason, NewControllerState, NewPawnState );
            }

            // Executes on server or in standalone
            InterruptState( Reason );
            Controller.InterruptState( Reason );
            GotoState( NewPawnState );
            Controller.GotoState( NewControllerState );
        }
    }

    SetIsStung(true);
    RefreshCameraEffects(self);

    ChangeAnimation();
    bIsTriggered_ReactedSting = 0; // Causes UpdateNonLethalEffectEvents to retrigger the event
    UpdateNonLethalEffectEvents();

    // RPC to client who is AutonomousProxy.
    if ( Controller != Level.GetLocalPlayerController() )
        ClientDoStungReaction( LastStungDuration, LastStingWeapon );
}

private function DirectHitByGrenade(
	Pawn  Instigator,
	ELastStingWeapon LastStingWeaponType,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration)
{
	if ( CantBeDazed() )
		return;

	// Set LastStingWeapon before RefreshCameraEffects so that the OnAdded call in
	// StingCameraEffect will know which grenade type that this grenade was
	// The OnAdded call is a side effect of RefreshCameraEffects in ApplyDazedEffect called below.
	LastStingWeapon = LastStingWeaponType;
	ApplyDazedEffect(PlayerStingDuration, HeavilyArmoredPlayerStingDuration, NonArmoredPlayerStingDuration);

    if (Damage > 0.0)
    {
        // event Actor::TakeDamage()
        TakeDamage( Damage,                               // int Damage
                    Instigator,                           // Pawn EventInstigator
                    Location,							  // vector HitLocation
                    vect(0,0,0),                          // vector Momentum
														  // class<DamageType> DamageType
                    class<DamageType>(DynamicLoadObject("SwatEquipment.HK69GrenadeLauncher", class'Class')) );
    }
}

///////////////////////////////////////////////////////////////////////////////
// IReactToDazingWeapon implementation
//

function ReactToLessLeathalShotgun(
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration)
{
	if ( CantBeDazed() )
		return;

	// Set LastStingWeapon before RefreshCameraEffects so that the OnAdded call in
	// StingCameraEffect will know that this target was hit by the less leathal shotgun
	// The OnAdded call is a side effect of RefreshCameraEffects in ApplyDazedEffect called below.
	LastStingWeapon = LessLethalShotgun;
	ApplyDazedEffect(PlayerStingDuration, HeavilyArmoredPlayerStingDuration, NonArmoredPlayerStingDuration);
}

function ReactToGLTripleBaton(
	Pawn  Instigator,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration)
{
	DirectHitByGrenade(Instigator, TripleBatonRound, Damage, PlayerStingDuration, HeavilyArmoredPlayerStingDuration, NonArmoredPlayerStingDuration);
}

// React to a direct hit from a grenade from the grenade launcher
function ReactToGLDirectGrenadeHit(
	Pawn  Instigator,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration)
{
	DirectHitByGrenade(Instigator, DirectGrenadeHit, Damage, PlayerStingDuration, HeavilyArmoredPlayerStingDuration, NonArmoredPlayerStingDuration);
}

function ReactToMeleeAttack(
	class<DamageType> MeleeDamageType,
	Pawn  Instigator,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration)
{
	if ( CantBeDazed() )
		return;

	// Set LastStingWeapon before RefreshCameraEffects so that the OnAdded call in
	// StingCameraEffect will know that this target was hit by a melee attack
	// The OnAdded call is a side effect of RefreshCameraEffects in ApplyDazedEffect called below.
	LastStingWeapon = MeleeAttack;
	ApplyDazedEffect(PlayerStingDuration, HeavilyArmoredPlayerStingDuration, NonArmoredPlayerStingDuration);

	// Only apply damage if the damage wont kill the target. You can't kill someone with the melee attack.
    if (Damage > 0.0 && Damage < Health)
    {
        // event Actor::TakeDamage()
        TakeDamage( Damage,                               // int Damage
                    Instigator,                           // Pawn EventInstigator
                    Location,							  // vector HitLocation
                    vect(0,0,0),                          // vector Momentum
					MeleeDamageType);					  // class<DamageType> DamageType
    }
}

///////////////////////////////////////////////////////////////////////////////
// IReactToStingGrenade implementation
//

function ReactToStingGrenade(
    SwatProjectile Grenade, 
	Pawn  Instigator,
    float Damage, float DamageRadius, 
    Range KarmaImpulse, 
    float KarmaImpulseRadius, 
    float StingRadius, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration,
    float MoraleModifier)
{
    local vector Direction, GrenadeLocation;
    local float Distance;

	if ( Grenade == None || CantBeDazed() )
		return;

	GrenadeLocation = Grenade.Location;
	Direction       = Location - Grenade.Location;
	Distance        = VSize(Direction);

	if (Instigator == None)
		Instigator = Pawn(Grenade.Owner);

    if (Distance <= StingRadius)
    {
		// Set LastStingWeapon before RefreshCameraEffects so that the OnAdded call in
		// StingCameraEffect will know that this grenade was a StingGrenade
		// The OnAdded call is a side effect of RefreshCameraEffects in ApplyDazedEffect called below.
		LastStingWeapon = StingGrenade;
		ApplyDazedEffect(PlayerStingDuration, HeavilyArmoredPlayerStingDuration, NonArmoredPlayerStingDuration);
    }

    //damage - Damage should be applied constantly over DamageRadius
    if (Distance <= DamageRadius)
    {
        // event Actor::TakeDamage()
        TakeDamage( Damage,                               // int Damage
                    Instigator,                           // Pawn EventInstigator
                    GrenadeLocation,                      // vector HitLocation
                    vect(0,0,0),                          // vector Momentum
                    class'Engine.GrenadeDamageType' );    // class<DamageType> DamageType
    }
}


simulated function ClientDoStungReaction( float PlayerDuration, ELastStingWeapon iLastStingWeapon )
{
    if ( Level.NetMode == NM_Client
         && Controller == Level.GetLocalPlayerController() )
    {
        if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
            return;

        //reinitialize the noise generator to prepare for a new effect
        PerlinNoiseAxisA.Reinitialize();
        PerlinNoiseAxisB.Reinitialize();

        LastStingWeapon = iLastStingWeapon;

        LastStungDuration = PlayerDuration;
        LastStungTime     = Level.TimeSeconds;

        SetIsStung(true);
        RefreshCameraEffects(self);

        ChangeAnimation();
        bIsTriggered_ReactedSting = 0; // Causes UpdateNonLethalEffectEvents to retrigger the event
        UpdateNonLethalEffectEvents();
    }
}


//ICanBePepperSprayed implementation

function ReactToBeingPepperSprayed( Actor PepperSpray,
                                    float PlayerDuration,
                                    float AIDuration,
                                    float SPPlayerProtectiveEquipmentDurationScaleFactor,
                                    float MPPlayerProtectiveEquipmentDurationScaleFactor )
{
    local name Reason;
    local name NewControllerState;
    local name NewPawnState;

    if ( Level.NetMode == NM_Client )
        return;

	if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
        return;

	//log(Self$", is testing whether it should be pepper sprayed; hasprotection="$HasProtection( 'IProtectFromPepperSpray' ));
    if ( HasProtection( 'IProtectFromPepperSpray' ) || GetLoadOut().HasRiotHelmet())
    {
        //mplog(Self$", is protected by from Pepper and so actual duration will be lower than original duration of "$PlayerDuration);     
        if (Level.NetMode == NM_Standalone) // singleplayer
            PlayerDuration *= SPPlayerProtectiveEquipmentDurationScaleFactor;
        else // multiplayer
            PlayerDuration *= MPPlayerProtectiveEquipmentDurationScaleFactor;

        if (PlayerDuration <= 0)
            return; // no sense bothering to set up effects if no duration
    }
    
	//log(Self$", is going to be pepper sprayed for: "$PlayerDuration);

    if (Level.NetMode != NM_Client)
    {
        PepperSprayedTimer.StartTimer(PlayerDuration, false, true);     //don't loop, reset if already running

        if ( Controller.GetStateName() != 'BeingCuffed' && Controller.GetStateName() != 'BeingUncuffed' )
        {
            Reason = 'ReactingToNonlethal';
            NewControllerState = 'PlayerWalking';
            NewPawnState = '';
        
            if ( Level.NetMode != NM_Standalone )
            {
                // We are the server
                SwatGameReplicationInfo(Level.GetGameReplicationInfo()).NotifyClientsToInterruptAndGotoState( self, Reason, NewControllerState, NewPawnState );
            }
        
            // Executes on server or in standalone
            InterruptState( Reason );
            Controller.InterruptState( Reason );
            GotoState( NewPawnState );
            Controller.GotoState( NewControllerState );
        }
    }

	LastPepperedTime     = Level.TimeSeconds;
	LastPepperedDuration = PlayerDuration;

    SetIsPepperSprayed(true);
    RefreshCameraEffects(self);

    ChangeAnimation();  
    UpdateNonLethalEffectEvents();

    // RPC to client who is AutonomousProxy.
    if ( Controller != Level.GetLocalPlayerController() )
        ClientDoPepperSprayedReaction( PlayerDuration );
}


simulated function ClientDoPepperSprayedReaction( float PlayerDuration )
{
    if ( Level.NetMode == NM_Client
    && Controller == Level.GetLocalPlayerController() )
    {
        if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
            return;

        LastPepperedTime     = Level.TimeSeconds;
        LastPepperedDuration = PlayerDuration;

        SetIsPepperSprayed(true);
        RefreshCameraEffects(self);

        ChangeAnimation();  
        UpdateNonLethalEffectEvents();
    }
}


//ICanBeTased implementation

function ReactToBeingTased( Actor Taser, float PlayerDuration, float AIDuration )
{
    local name Reason;
    local name NewControllerState;
    local name NewPawnState;

    if ( Level.NetMode == NM_Client )
        return;

	if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
        return;

    //reinitialize the noise generator to prepare for a new effect
    PerlinNoiseAxisA.Reinitialize();
    PerlinNoiseAxisB.Reinitialize();

    if (Level.NetMode != NM_Client)
    {
        TasedTimer.StartTimer(PlayerDuration, false, true);             //don't loop, reset if already running

        if ( Controller.GetStateName() != 'BeingCuffed' && Controller.GetStateName() != 'BeingUncuffed' )
        {
            Reason = 'ReactingToNonlethal';
            NewControllerState = 'PlayerWalking';
            NewPawnState = '';
        
            if ( Level.NetMode != NM_Standalone )
            {
                // We are the server
                SwatGameReplicationInfo(Level.GetGameReplicationInfo()).NotifyClientsToInterruptAndGotoState( self, Reason, NewControllerState, NewPawnState );
            }
        
            // Executes on server or in standalone
            InterruptState( Reason );
            Controller.InterruptState( Reason );
            GotoState( NewPawnState );
            Controller.GotoState( NewControllerState );
        }
    }

    LastTasedTime     = Level.TimeSeconds;
    LastTasedDuration = PlayerDuration;

    SetIsTased(true);
    SetForceCrouchState(true);
    RefreshCameraEffects(self);

    ChangeAnimation();
    UpdateNonLethalEffectEvents();

    // RPC to client who is AutonomousProxy.
    if ( Controller != Level.GetLocalPlayerController() )
        ClientDoTasedReaction( PlayerDuration );
}

simulated function ClientDoTasedReaction( float PlayerDuration )
{
    if ( Level.NetMode == NM_Client
         && Controller == Level.GetLocalPlayerController() )
    {
        if (class'Pawn'.static.CheckDead( self ))  //Can't hurt me if I'm dead
            return;

        //reinitialize the noise generator to prepare for a new effect
        PerlinNoiseAxisA.Reinitialize();
        PerlinNoiseAxisB.Reinitialize();

        LastTasedTime     = Level.TimeSeconds;
        LastTasedDuration = PlayerDuration;

        SetIsTased(true);
        SetForceCrouchState(true);
        RefreshCameraEffects(self);

        ChangeAnimation();
        UpdateNonLethalEffectEvents();
    }
}


//returns false if the ICanBeTased has some inherent protection from Taser
simulated function bool IsVulnerableToTaser()
{
    //Fix 2436: Spec says that taser should only affect players with no armor, but this makes no sense
    //
    //Paul wants players to always be vulnerable to Taser:
//    //heavy armor protects from taser
//    return (!GetLoadOut().HasHeavyArmor());
    return true;
}

//IReactToC2Detonation Implementation

//Players do react to c2 detonation, but they only take damage;
//  they don't do anything else.
function ReactToC2Detonation(   
    Actor C2Charge, 
    float StunRadius,
    float AIStunDuration);

///////////////////////////////////////////////////////////////////////////////
//
// NON-LETHAL EFFECT EXPIRED
//
// Non-lethal reaction expiration callbacks. Should only be called in
// standalone or on the server (not on clients).
//
///////////////////////////////////////////////////////////////////////////////

// Keep these two functions in sync.
function OnFlashbangedTimerExpired()
{
    Assert( Level.NetMode != NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnFlashbangedTimerExpired()." );

    SetIsFlashbanged(false);
    RefreshNonlethalCommon();

    if ( Controller != Level.GetLocalPlayerController() )
        ClientOnFlashbangTimerExpired();
}

simulated function ClientOnFlashbangTimerExpired()
{
    //Assert( Level.NetMode == NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::ClientOnFlashbangedTimerExpired()." );

    SetIsFlashbanged(false);
    RefreshNonlethalCommon();
}

///////////

// Keep these two functions in sync.
function OnGassedTimerExpired()
{
    Assert( Level.NetMode != NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnGassedTimerExpired()." );

    SetIsGassed(false);
    RefreshNonlethalCommon();

    if ( Controller != Level.GetLocalPlayerController() )
        ClientOnGassedTimerExpired();
}

simulated function ClientOnGassedTimerExpired()
{
    //Assert( Level.NetMode == NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::ClientOnGassedTimerExpired()." );

    SetIsGassed(false);
    RefreshNonlethalCommon();
}

///////////

// Keep these two functions in sync.
function OnStungTimerExpired()
{
    Assert( Level.NetMode != NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnStungTimerExpired()." );

    SetIsStung(false);
    RefreshNonlethalCommon();

    if ( Controller != Level.GetLocalPlayerController() )
        ClientOnStungTimerExpired();
}

simulated function ClientOnStungTimerExpired()
{
    //Assert( Level.NetMode == NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::ClientOnStungTimerExpired()." );

    SetIsStung(false);
    RefreshNonlethalCommon();
}

///////////

// Keep these two functions in sync.
function OnPepperSprayedTimerExpired()
{
    Assert( Level.NetMode != NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnPepperSprayedTimerExpired()." );

    SetIsPepperSprayed(false);
    RefreshNonlethalCommon();

    if ( Controller != Level.GetLocalPlayerController() )
        ClientOnPepperSprayedTimerExpired();
}


simulated function ClientOnPepperSprayedTimerExpired()
{
    //Assert( Level.NetMode == NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::ClientOnPepperSprayedTimerExpired()." );

    SetIsPepperSprayed(false);
    RefreshNonlethalCommon();
}


///////////

// Keep these two functions in sync.
function OnTasedTimerExpired()
{
    Assert( Level.NetMode != NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnTasedTimerExpired()." );

    SetIsTased(false);
    SetForceCrouchState(false);
    RefreshNonlethalCommon();

    if ( Controller != Level.GetLocalPlayerController() )
        ClientOnTasedTimerExpired();
}


simulated function ClientOnTasedTimerExpired()
{
    //Assert( Level.NetMode == NM_Client );

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::ClientOnTasedTimerExpired()." );

    SetIsTased(false);
    SetForceCrouchState(false);
    RefreshNonlethalCommon();
}


///////////

function RefreshNonlethalCommon()
{
    RefreshCameraEffects( self );
    ChangeAnimation();
    UpdateNonLethalEffectEvents();

    if ( !IsNonlethaled() )
        IWasNonlethaledAndFinishedSoDoAnEquipIfINeedToDoOne();
}


///////////////////////////////////////////////////////////////////////////////


//forward to local player controller
//  (LPC will ignore the call if Pawn is not the current ViewTarget)
simulated function RefreshCameraEffects(SwatPlayer Pawn)
{
    //mplog("SwatPlayer.RefreshCameraEffects("$pawn$") called");
    if( Level.GetLocalPlayerController() != None )
        SwatGamePlayerController(Level.GetLocalPlayerController()).RefreshCameraEffects(Pawn);
}

// Triggers or untriggers the non-lethal reaction effect events based on the
// pawn's current state.
simulated native function UpdateNonLethalEffectEvents();
simulated native function UnTriggerAllNonLethalEffectEvents();

// On the server, this is called from PlayDying() (for players; not AI's)
// right before going ragdoll. Reset all the nonlethal effect so the player
// stops coughing, etc. We don't bother doing this on clients, since the
// server's changes will propagate to them.
function ResetNonlethalEffects()
{
    if ( Level.NetMode != NM_Client )
    {
        SetIsFlashbanged( false );
        SetIsGassed( false );
        SetIsPepperSprayed( false );
        SetIsStung( false );
        SetIsTased( false );
        RefreshNonlethalCommon();
    }
}


// These two functions should only execute on clients for remote pawns.
simulated event OnbIsTasedChanged()
{
    Assert( Level.NetMode == NM_Client );
    Assert( Controller == None );

    // On clients, we need to set bForceCrouch to false when bIsTased goes to
    // false, since the Tased timer only executes on the server.
    if ( !bIsTased )
        SetForceCrouchState( false );

    OnNonlethalEffectChanged();
}

simulated event OnNonlethalEffectChanged()
{
    Assert( Level.NetMode == NM_Client );
    Assert( Controller == None );

	if (Level.GetEngine().EnableDevTools)
	{
		mplog( self$"---SwatPlayer::OnNonlethalEffectChanged()." );
		mplog( "...bIsFlashbanged   ="$bIsFlashbanged );
		mplog( "...bIsGassed        ="$bIsGassed );
		mplog( "...bIsPepperSprayed ="$bIsPepperSprayed );
		mplog( "...bIsStung         ="$bIsStung );
		mplog( "...bIsTased         ="$bIsTased );
    }
    
    Super.OnNonlethalEffectChanged();
    RefreshCameraEffects( self );
    UpdateNonLethalEffectEvents();
}

simulated event OnCurrentLimpChanged()
{
    //mplog( self$"---SwatPlayer::OnCurrentLimpChanged()." );
    //mplog( "...CurrentLimp="$CurrentLimp );

    // This function gets called only on clients. OnSkeletalRegionHit() calls
    // ChangeAnimation() in standalone and on servers.

    // Make the call to change the movement anims here.
    ChangeAnimation();
}


//ICanQualifyForUse implementation

simulated function OnQualifyInterrupted()
{

	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---SwatPlayer::OnQualifyInterrupted()." );

    if ( Controller != None )
        SwatGamePlayerController(Controller).OnQualifyInterrupted();

    EquipOtherAfterUsed = false;  //because we were interrupted!
}

simulated function OnQualifyCompleted()
{
	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SwatPlayer::OnQualifyCompleted()." );

    if ( Controller != None )
        SwatGamePlayerController(Controller).OnQualifyCompleted();
}

//ICanUseC2Charge Implementation

simulated function SetDeployedC2Charge(DeployedC2ChargeBase Charge)
{
    //shouldn't get a new DeployedC2Charge when one is already out there
    assertWithDescription(Charge == None || DeployedC2Charge == None,
        "[tcohen] SwatPlayer::SetDeployedC2Charge() tried to set DeployedC2Charge="$Charge
        $", but DeployedC2Charge is already "$DeployedC2Charge
        $".");

    DeployedC2Charge = Charge;
}

simulated function DeployedC2ChargeBase GetDeployedC2Charge()
{
    return DeployedC2Charge;
}

// ICanBeArrested implementation

//returns true if I can be arrested now according to my current state
simulated function bool CanBeArrestedNow()
{
    local HandheldEquipment theActiveItem;
    local HandheldEquipment thePendingItem;
    
    if (checkDead(self))
        return false;

    theActiveItem = GetActiveItem();
    if ( theActiveItem != None && theActiveItem.IsA('IAmCuffed') )
        return false;

    thePendingItem = GetPendingItem();
    if ( thePendingItem != None && thePendingItem.IsA('IAmCuffed') )
        return false;

    //mplog( "...IsFlashbanged()="$IsFlashbanged() );
    //mplog( "........IsGassed()="$IsGassed() );
    //mplog( "........IsPepperSprayed()="$IsPepperSprayed() );
    //mplog( ".........IsStung()="$IsStung() );
    //mplog( ".........IsTased()="$IsTased() );

    return IsNonlethaled();
}


// The focus interface should take care of all the usual cases. However, we
// need this function so that ServerRequestQualify() can ignore inappropriate
// requests that the client may have given without having complete
// information. Note that it's really hard for the client to know whether
// someone is being unarrested because it's their controller that goes into
// the BeginUncuffed state and that's not present on the client. We might need
// to create a new variable in the SwatPawn and replicate it to clients if the
// focus interface needs to take this into account.
simulated function bool CanBeUnarrestedNow()
{
    Assert( Level.NetMode != NM_Client );

    // We want this function to return false if another player is in the
    // process of unarresting him.
    if ( Controller.GetStateName() == 'BeingUncuffed' )
        return false;

    return true;
}


//return the time it takes for a Player to "qualify" to arrest me
simulated function float GetQualifyTimeForArrest()
{
    return QualifyTimeForArrest;
}

// Executes only on server
function AuthorizedInterruptQualification()
{
    Assert( Level.NetMode != NM_Client );
    SwatGamePlayerController(Controller).AuthorizedInterruptQualification();
}

// Overriden from SwatPawn to return the world space location of where this SwatPlayer's head is currently, taking into account leaning/crouching/etc...
native function vector GetViewPoint();

//returns an approximation of the location of the pawn's eyes based on
//  the appearance of the 3rd person pawn model.  Note that this is different
//  from GetViewPoint() above, which returns an approximate of the player's
//  first-person camera location.
//Ideally, these two values would be equal.  But the Pawn's BaseEyeHeight
//  and CrouchEyeHeight don't reflect the proper locations on the 3rd-person
//  pawn model, and the maps have already been built assuming the current
//  camera locations.
simulated function vector GetThirdPersonEyesLocation()
{
    local float EyeHeightCompensation;      //the difference, given the player's current crouching, between the EyeHeight, and the EyeHeight compensated for the 3rd-person model appearance
    local vector ThirdPersonEyesLocation;

    ThirdPersonEyesLocation = GetViewPoint();

    if (bIsCrouched)
        EyeHeightCompensation = PawnModelApparentCrouchEyeHeight - default.CrouchEyeHeight;
    else
        EyeHeightCompensation = PawnModelApparentBaseEyeHeight - default.BaseEyeHeight;

    //compensate for the difference between where the player's camera would be, and where the Pawn model's eyes appear to be
    ThirdPersonEyesLocation.Z += EyeHeightCompensation;

    return ThirdPersonEyesLocation;
}

//overridden from Pawn, called by PlayerController::CalcFirstPersonView(), so
// the camera is at the proper offset according to lean
simulated event rotator ViewRotationOffset()
{
    return GetStungRotationOffset() + GetLeanRotationOffset();
}
simulated function vector ViewLocationOffset(Rotator CameraRotation)
{
    return GetTasedViewLocationOffset(CameraRotation);
}

//overridden from Pawn, so the gun is drawn at the proper offset according to lean
simulated function vector CalcDrawOffset()
{
    return Super.CalcDrawOffset() + GetLeanPositionOffset();
}

//overridden from Pawn, so the gun is drawn at the proper offset according to lean
simulated function rotator GetViewRotation()
{
    local rotator baseRotation;

    // If we have a controller for this pawn, then get the view rotation from
    // it. If we don't have a controller (ie, we're a network client and this
    // is another pawn), then the pawn's pitch is zeroed out. Therefore, we
    // use GetAimRotation, which gets replicated to us and preserves pitch.
    if (Controller != None)
    {
        baseRotation = Controller.GetViewRotation();
    }
    else
    {
        baseRotation = GetAimRotation();
    }
    
    return baseRotation + GetStungRotationOffset() + GetLeanRotationOffset();
}

simulated event ApplyRotationOffset(out Vector Acceleration)
{
    Super.ApplyRotationOffset(Acceleration);
    ApplyStungRotationOffset(Acceleration);
    ApplyOneFrameNudgeRotationOffset(Acceleration);
}

function Rotator GetStungRotationOffset()
{
    local float Now;
    local float Alpha;
    local float Ordinate;      //input into the PerlinNoise function
    local float RollAndYawAbcissa;  //value of the perlin noise function at RollAndYawOrdinate
    local Rotator Result;
    
    if (bDeleteMe)
    {
        log("ERROR: attempt to GetStungRotationOffset() on destroyed actor "$name);
        return Result;
    }

    //if we're stung, then add noise to our view rotation
    if (IsStung())
    {
        Now = Level.TimeSeconds;

        //scale the StingDuration over the range [0,1]
        Alpha = (Now - LastStungTime) / LastStungDuration;
        Alpha = FClamp(Alpha, 0.0, 1.0);

        //calculate the ordinate for evaluation of the noise function
        Ordinate = Alpha * StingEffectFrequency;
        //apply noise to the pitch
        Result.Pitch = ScaleStingEffectAmplitude(StingViewEffectAmplitude.Pitch, Alpha) * PerlinNoiseAxisA.Noise1(Ordinate);
        //calculate the value of the perlin noise function at the RollAndYawOrdinate
        RollAndYawAbcissa = PerlinNoiseAxisB.Noise1(Ordinate);
        //apply noise to the roll and yaw
        Result.Roll = RollAndYawAbcissa * ScaleStingEffectAmplitude(StingViewEffectAmplitude.Roll, Alpha);
        Result.Yaw = RollAndYawAbcissa * ScaleStingEffectAmplitude(StingViewEffectAmplitude.Yaw, Alpha);
    }

    return Result;
}

simulated event ApplyStungRotationOffset(out Vector Acceleration)
{
    local Rotator StungRotation;

    if (IsStung())
    {
        StungRotation = GetStungRotationOffset();
        StungRotation.Pitch = 0;

        Acceleration = Acceleration << (StungRotation * StingInputEffectMagnitude);
    }
}

function vector GetTasedViewLocationOffset(Rotator CameraRotation)
{
    local float Now;
    local float Alpha;
    local vector LocalXAxis;
    local vector Result;

    if (bDeleteMe)
    {
        log("ERROR: attempt to GetTasedViewLocationOffset() on destroyed actor "$name);
        return Result;
    }

    if (IsTased())
    {
        Now = Level.TimeSeconds;

        //scale the TasedDuration over the range [0,1]
        Alpha = (Now - LastTasedTime) / LastTasedDuration;
        Alpha = FClamp(Alpha, 0.0, 1.0);
        
        LocalXAxis = vect(0, 1, 0) >> CameraRotation;

        Result = LocalXAxis * TasedViewEffectAmplitude * PerlinNoiseAxisA.Noise1(Alpha * TasedViewEffectFrequency);
        Result.Z = TasedViewEffectAmplitude * PerlinNoiseAxisB.Noise1(Alpha * TasedViewEffectFrequency);
    }

    return Result;
}

//cause the StingEffect to drop-off over the last x% of its duration
function float ScaleStingEffectAmplitude(float Amplitude, float DurationAlpha)
{
    local float NormalTime;
    local float DropOffAlpha;

    NormalTime = 1.0 - StingEffectDropOffTimePercent;

    if (DurationAlpha < NormalTime)
        return Amplitude;     //not dropping-off yet

    DropOffAlpha = (DurationAlpha - NormalTime) / StingEffectDropOffTimePercent;

    return Amplitude * (1.0 - DropOffAlpha);
}

native function vector GetLeanPositionOffset();
native function Rotator GetLeanRotationOffset();

///////////////////////////////////////////////////////////////////////////////
//
// Misc

// Override superclass method so that in single player games the player's name
// is "You" instead of "SwatPlayer0".
simulated function String GetHumanReadableName()
{
	if (Level.NetMode == NM_StandAlone) 
    {
        return YouString; // returned for local player in SP games only
    }

	// Superclass will deal non-standalone games, etc
    return Super.GetHumanReadableName();
}

// Override in NetPlayer for network games. For standalone games, always
// return false.
simulated function bool IsTheVIP()
{
    return false;
}

// Override in NetPlayer for network games. For standalone games, always
// return false.
simulated function bool HasTheItem()
{
	return false;
}

simulated function bool IsLowerBodyInjured()
{
    return CurrentLimp > LimpThreshold;
}

///////////////////////////////////////////////////////////////////////////////
simulated function OnSkeletalRegionHit(ESkeletalRegion RegionHit, vector HitLocation, vector HitNormal, int Damage, class<DamageType> DamageType, Actor Instigator)
{
    local SkeletalRegionInformation RegionInfo;

    if ( Level.NetMode != NM_Client )
    {
        // Notify player controller for hud notification
        if ( Controller != None )
            SwatGamePlayerController(Controller).ClientSkeletalRegionHit(RegionHit, Damage);
    
        // Modify damage...s
        if ( Damage > 0 )
        {
            RegionInfo = SkeletalRegionInformation[RegionHit];

            CurrentLimp += StandardLimpPenalty * RandRange(RegionInfo.LimpModifier.Min, RegionInfo.LimpModifier.Max);

            // MCJ: On clients, this will get called in
            // OnCurrentLimpChanged(). This doesn't get called in standalone
            // and on servers, so we need to call it here explicitly.
            ChangeAnimation();
        }
    }
}

//
// Pickup Support
//

function HandheldEquipment FindItemForPickupToReplace(HandheldEquipment PickedUp)
{
    return LoadOut.FindItemToReplace(PickedUp);
}

function OnPickedUp(HandheldEquipment PickedUp)
{
    LoadOut.OnPickedUp(PickedUp);
}

///////////////////////////////////////////////////////////////////////////////

event EndCrouch(float HeightAdjust)
{
    Super.EndCrouch(HeightAdjust);
    
    if( Controller == Level.GetLocalPlayerController() && SwatGamePlayerController(Controller).HasHUDPage() )
        SwatGamePlayerController(Controller).GetHUDPage().SetCrouched(false);
}

event StartCrouch(float HeightAdjust)
{
    Super.StartCrouch(HeightAdjust);

    if( Controller == Level.GetLocalPlayerController() && SwatGamePlayerController(Controller).HasHUDPage() )
        SwatGamePlayerController(Controller).GetHUDPage().SetCrouched(true);
}

///////////////////////////////////////////////////////////////////////////////

simulated function SetForceCrouchState(bool inbForceCrouch)
{
    // This function has special knowledge about what systems could want to
    // keep the pawn in a forced-crouched state. It uses this knowledge to
    // try and keep one system from stomping out another system's desire to
    // be force-crouched. It ain't pretty, but 2.5 weeks before gold just
    // called my phone, and it wants it's bugs fixed. [darren]
    if (inbForceCrouch == false)
    {
        if ((IsTheVIP() && IsArrested())
         || (IsTased())
         || (bForceCrouchWhileOptiwanding))
        {
            inbForceCrouch = true;
        }
    }

    Super.SetForceCrouchState(inbForceCrouch);
}

///////////////////////////////////////

// Sets the extra state to track force-crouching due to optiwanding.
simulated function SetForceCrouchWhileOptiwanding(bool b)
{
    bForceCrouchWhileOptiwanding = b;
    SetForceCrouchState(b);

    if (bForceCrouchWhileOptiwanding)
    {
        // We need this extra call because, when we're optiwanding, physics is
        // off so we must manually update the crouch
        ForceCrouchThisTick();
    }

    // If we're a client, tell the server that we want to force-crouch due to optiwanding
    if (Level.NetMode == NM_Client)
    {
        ServerSetForceCrouchWhileOptiwanding(b);
    }
}

///////////////////////////////////////

// * SERVER ONLY
function ServerSetForceCrouchWhileOptiwanding(bool b)
{
    SetForceCrouchWhileOptiwanding(b);
}

///////////////////////////////////////////////////////////////////////////////

simulated function bool IsUsingOptiwand()
{
    return bIsUsingOptiwand;
}

///////////////////////////////////////

simulated function SetIsUsingOptiwand(bool b)
{
    bIsUsingOptiwand = b;
    // Locally change animations for this pawn
    ChangeAnimation();
    // Let the server know that this SwatPlayer is optiwanding, so it can let
    // all other clients know.
    ServerSetIsUsingOptiwand(b);
}

///////////////////////////////////////

// * SERVER ONLY
function ServerSetIsUsingOptiwand(bool b)
{
    // By setting the replicated bIsUsingOptiwand variable, all other clients
    // will know that this pawn is using the optiwand.
    bIsUsingOptiwand = b;
    // Locally change animations for this pawn
    ChangeAnimation();
}

///////////////////////////////////////////////////////////////////////////////

// Direction need not be normalized
simulated function SetOneFrameNudgeDirection(vector Direction)
{
    OneFrameNudgeDirection = Direction;
}

simulated event ApplyOneFrameNudgeRotationOffset(out Vector Acceleration)
{
    local vector NormalizedOneFrameNudgeDirection;

    if (!IsNearlyZero(OneFrameNudgeDirection))
    {
        // Multiply the normalized nudge direction, so it has high precedence
        // than the passed in acceleration. We assume that the passed in
        // Acceleration is already normalized.
        NormalizedOneFrameNudgeDirection = Normal(OneFrameNudgeDirection);
        Acceleration = Normal(Acceleration + (NormalizedOneFrameNudgeDirection * OneFrameNudgeDirectionStrength));

        // Reset to zero for next frame
        OneFrameNudgeDirection.X = 0.0;
        OneFrameNudgeDirection.Y = 0.0;
        OneFrameNudgeDirection.Z = 0.0;
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Sound effect event manager for reporting to TOC
//

// IIInterested_GameEvent_ReportableReportedToTOC implementation

function OnReportableReportedToTOC(IAmReportableCharacter ReportableCharacter, Pawn Reporter)
{
    local string PlayerTag;
    
    if( Reporter != Self )
        return;

    CurrentReportableCharacter = ReportableCharacter;

    Assert( Reporter.IsA('SwatPlayer') );

    PlayerTag = string( SwatPlayer(Reporter).GetPlayerTag() );

    BroadcastReportableReportedToTOC( ReportableCharacter, ReportableCharacter.UniqueID(), PlayerTag, Reporter.GetHumanReadableName() );
}

function BroadcastReportableReportedToTOC( IAmReportableCharacter ReportableCharacter, string inUniqueID, string PlayerTag, string PlayerName )
{
    local Controller i;
    local SwatGamePlayerController current;

    // Walk the controller list here to notify all clients 
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = SwatGamePlayerController( i );
        if ( current != None )
        {
            log( self$"::BroadcastReportableReportedToTOC( "$ReportableCharacter$", "$inUniqueID$" ), current = "$current$", PlayerTag = "$PlayerTag$", PlayerName = "$PlayerName );
            current.ClientReportableReportedToTOC( ReportableCharacter, inUniqueID, PlayerTag, PlayerName );
        }
    }
}

simulated function OnClientReportableReportedToTOC( IAmReportableCharacter ReportableCharacter, string inUniqueID, string PlayerTag, string PlayerName )
{
    local name EffectEventName;

    CurrentReportableCharacter = ReportableCharacter;
    
    if( CurrentReportableCharacter == None )
        CurrentReportableCharacter = IAmReportableCharacter(FindByUniqueID(class'Pawn', inUniqueID ));

log( self$"::OnClientReportableReportedToTOC() ... CurrentReportableCharacter = "$CurrentReportableCharacter );

    EffectEventName = CurrentReportableCharacter.GetEffectEventForReportingToTOC();
       
    if (EffectEventName != '')
    {
        SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).OverrideCaptionSpeakerNameForNextEffectEvent = PlayerName;
        TriggerEffectEvent( EffectEventName, Actor(CurrentReportableCharacter), , , , , , self, name(PlayerTag) );
    }
}

simulated event TriggerNonLethaledEffectEvent( Name EffectEventName )
{
    if (EffectEventName != '')
    {
        TriggerEffectEvent( EffectEventName, , , , , , , , GetPlayerTag() );
    }
}

simulated event UnTriggerNonLethaledEffectEvent( Name EffectEventName )
{
    if (EffectEventName != '')
    {
        UnTriggerEffectEvent( EffectEventName, GetPlayerTag() );
    }
}

simulated function Name GetPlayerTag()
{
    if( NetPlayer(Self) == None )
        return '';
        
    if( NetPlayer(Self).IsTheVIP() )
        return 'VIP';

    return SwatRepo(Level.GetRepo()).GuiConfig.GetTagForVoiceType( NetPlayer(Self).VoiceType );
}

// IEffectObserver implementation

simulated function OnEffectStarted(Actor inStartedEffect);

simulated function OnEffectStopped(Actor inStoppedEffect, bool Completed)
{
    local name EffectEventName;

    if (Completed)
    {
        EffectEventName = CurrentReportableCharacter.GetEffectEventForReportResponseFromTOC();
        if (EffectEventName != '')
        {
            log("TOC is responding with "$EffectEventName);
            TriggerEffectEvent(EffectEventName, Actor(CurrentReportableCharacter),
                , , , , , , 'TOC');
        }
    }

    CurrentReportableCharacter = None;
}

simulated function OnEffectInitialized(Actor inInitializedEffect);


///////////////////////////////////////////////////////////////////////////////
//
// ICanBeUsed implementation
//
// Allows the player to report the status of an unconscious or arrested player to
// toc.

simulated function bool CanBeUsedNow()
{
//log( self$"::CanBeUsedNow() ... bHasBeenReportedToTOC = "$bHasBeenReportedToTOC$", class.static.checkConscious(self) = "$class.static.checkConscious(self) );
    return Level.IsPlayingCOOP && !bHasBeenReportedToTOC && (!class.static.checkConscious(self));
}

simulated function OnUsed(Pawn Other)
{
    assert(!bHasBeenReportedToTOC);

    SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.Triggered(self, Other);
}

simulated function PostUsed()
{
    bHasBeenReportedToTOC = true;
}

///////////////////////////////////////
// IAmReportableCharacter implementation

// Provides the effect event name to use when this ai is being reported to TOC
simulated final function name GetEffectEventForReportingToTOC()
{
    return 'ReportedOfficerDownToTOC'; //Placeholder
}

// Provides the effect event name to use when TOC is responding to a report
// about this ai
simulated final function name GetEffectEventForReportResponseFromTOC()
{
    return 'RepliedOfficerDown';
}

///////////////////////////////////////////////////////////////////////////////

simulated function ShowCommandArrow( float inLifeSpan, Actor inSource, Actor inTarget, optional Vector inSourceLocation, optional Vector inTargetLocation, optional bool inPointAtSource )
{
    CommandArrow.ShowArrow( inLifeSpan, inSource, inTarget, inSourceLocation, inTargetLocation, inPointAtSource );
}

///////////////////////////////////////////////////////////////////////////////

simulated function bool ReadyToTriggerEffectEvents()
{
    return HasEquippedFirstItemYet;
}

///////////////////////////////////////////////////////////////////////////////

simulated function OnLightstickKeyFrame()
{
	if (GetActiveItem() != None)
		GetActiveItem().OnUseKeyFrame();
}
///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    SuspectHandsMaterial=Material'SWAT1stPersonTex.HandGang_aShader'
    VIPHandsMaterial=Material'SWAT1stPersonTex.HandVIPshader'
    LeanTransitionDuration=0.3
    LeanHorizontalDistance=44.0f
    LeanVerticalDistance=-16.0f
    LeanRollDegrees=8.0f
    LeanBezierPt1X=0.4f
    LeanBezierPt1Y=0.0f
    LeanBezierPt2X=0.6f
    LeanBezierPt2Y=1.0f

    // Players should have snappier visual aim transitions
    AimBlendChangeTime      =   0.05
    // Default inertial aiming values
    InertialAimAcceleration =  80.0
    InertialAimDeceleration = -20.0
    InertialAimMaxVelocity  =  40.0

    LimpThreshold=10
    CurrentLimp=0
    StandardLimpPenalty=3
    bTestingCameraEffects=false
    YouString="You"

	// so AIs know when the player is blocking something
	// the Reached Destination Threshold is the same size as the collision radius for players
	// and includes the AI's collision radius as well (so is 2x the collision radius)
	ReachedDestinationThreshold=48.0
}

