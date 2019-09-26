class SwatGamePlayerController extends SwatPlayerController
    implements  IInterested_GameEvent_PawnIncapacitated,
                IInterested_GameEvent_PawnDamaged,
                IInterestedInDoorOpening
	dependson(AnimationSetManager)
    dependson(PlayerFocusInterface)
    native;

import enum EAnimationSet from AnimationSetManager;
import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;
import enum ECommandInterfaceStyle from SwatGUIConfig;
import enum ESkeletalRegion from Engine.Actor;
import enum EMaterialVisualType from Engine.Material;
import enum AimPenaltyType from Engine.FiredWeapon;
import enum FireMode from Engine.FiredWeapon;
import enum DoorPosition from Engine.Door;
import enum eVoiceType from SwatGame.SwatGUIConfig;

var int FlashbangRetinaImageTextureWidth;
var int FlashbangRetinaImageTextureHeight;
var private FlashbangCameraEffect   FlashbangCameraEffect;
var private CSGasCameraEffect       CSGasCameraEffect;
var private StingCameraEffect       StingCameraEffect;
var private PepperSprayCameraEffect PepperSprayCameraEffect;
var private NVGogglesCameraEffect	NVGogglesCameraEffect;

var SwatPlayer SwatPlayer;

//
// Death cam constants and state variables
//

const kDeathCamDurationSeconds    = 2.0;
const kDeathCamEndRotationDownPitch = -4563;
// Distance scales are multiplied by the ViewTarget's radius to find the camera distance
const kDeathCamStartDistanceScale = 3.0;
const kDeathCamEndDistanceScale   = 12.0;
const kDeathCamZOffset            = 12.0;

var private bool    bIsKillerLocationValid;
var private vector  KillerLocation;
var private bool    bShouldStartDeathCam;
var private bool    bIsDeathCamRunning;

var private float   DeathCamStartTimeSeconds;
var private Rotator DeathCamStartRotation;
var private Rotator DeathCamEndRotation;
var private float   DeathCamStartDistance;
var private float   DeathCamEndDistance;

var private Timer ForceObserverTimer;
var private float ForceObserverTime;

var private Timer ComplianceTimer;
var private float ComplianceTime;
var private Timer CommandTimer;
var private float CommandTime;

//
// End-game cam constants and state variables
//

// Preserve the yaw's decimal accumulation using this float
var private float EndGameCamYaw;
const kEndGameCamDesiredDistScale            =    10.0;
const kEndGameCamRotationPitch               = -4563;
const kEndGameCamZOffset                     =    12.0;

// Linearly scale the yaw delta speed within a given distance scale range. This
// allows the camera to rotate faster when it gets very close to its target,
// and therefore minimize the amount of time the player has to see an extreme
// up-close (or even embedded) game-end camera angle of the target. [darren]
const kEndGameCamSlowestYawDeltaPerSecond    =  3000.0;
const kEndGameCamFastestYawDeltaPerSecond    = 20000.0;
const kEndGameCamDistScaleForSlowestYawDelta =     7.5;
const kEndGameCamDistScaleForFastestYawDelta =     0.0;
var private float EndGameCamLastDist;
var private float EndGameCamYawLastUpdateTime;

//
//accuracy
//

var private float LastMouseX, LastMouseY;
var private float MouseDistancePerSecond;

//
//recoil
//

var private bool Recoiling;
var private float RecoilStartTime;
var private float RecoilBackDuration;
var private float RecoilForeDuration;
var private float RecoilMagnitude;
var private float LastRecoilFunctionValue;
var bool DebugShouldRecoil;
var bool SpecialInteractionsDisabled;

//
//interaction
//

var config float FocusTestDistance;
var config float FocusTestInterval;    //how often to look for a focus

var private Timer FocusPollTimer;

var private name LastFocusSource;

// PlayerFocusInterface support...
// Carlos: Refactored the seperate FireInterface/UseInterface/CommandInterface into an array of PlayerFocusInterfaces

enum EFocusInterface
{
    Focus_Use,
    Focus_Fire,
    Focus_ClassicCommand,
    Focus_GraphicCommand,
    Focus_PlayerTag,
    Focus_LowReady,
	Focus_SpeechRecognition
};

enum FocusInterfaceNetMode
{
    FNET_All,
    FNET_StandaloneOnly,
    FNET_MultiplayerOnly
};

struct native PlayerFocusInterfaceInfo
{
    var config EFocusInterface              Focus;
    var config class<PlayerFocusInterface>  FocusClass;
    var config name                         Label;
    var config FocusInterfaceNetMode        ValidNetMode;
};

var config private array<PlayerFocusInterfaceInfo> FocusInterfaceInfos; // List of classes used to generate the FocusInterfaces array.
                                                                        // Should be populated in defaultproperties.
var private array<PlayerFocusInterface> FocusInterfaces;                // List of currently active player focus interfaces.

var private CommandInterface CurrentCommandInterface;

enum NumberRow
{
    Row_FunctionKeys,
    Row_NumberKeys
};

/*  TMC 1/23/2004 disabled support for GCIOpen & GiveCommand on the same button (GCIOpen after delay)
var input byte bGCIOpen;                //the Engine will set to non-zero while the GrapihcCommandInterface Open button (right-mouse) is down
var bool GiveCommandIsDown;             //keep track of button transitions
var Timer GiveCommandTimer;             //manage delay from the time bGCIOpen is pressed until the GraphicCommandInterface is called to Open()
//the delay (in seconds) after the GiveCommand button is pressed, before the GraphicCommandInterface opens...
//if the GiveCommand button is released before this time elapses, then the Default command is given,
// and the GCI does not open.
var config float GraphicCommandInterfaceDelay;
*/

// GUI HUD

var private HUDPageBase HUDPage;
var private Material ZoomBlurFader; // Fades in/out the HandheldEquipment's ZoomBlurOverlay as equipment zooms in and out

// The Repo
var private SwatRepo Repo;

// Observer cam stuff
var private Pawn ReplicatedObserverCamTarget;

// External Viewport stuff...
#define MP_SERVER_VIEWPORTS 1
var private ExternalViewportManager ViewportManager;

// After the server selects the next teammate to view from in the viewport,
// this replicated variable is set, so it propagates to the client. Because
// the server makes the viewport teammate relevant, this will eventually
// change on the client, even for a teammate who is not initially relevant.
var private IControllableThroughViewport ReplicatedViewportTeammate;

// Timer for sniper alerts so we can pop up the right SniperPawn in the ExternalViewportManager if there is an sniper alert pending
var Timer  SniperAlertTimer;
var config float SniperAlertTime;
var string SniperAlertFilter;

var input byte bControlViewport;

// remember the rooted vector of the most recent focus trace
var vector FocusTraceOrigin;
var vector FocusTraceVector;

enum MovingMode
{
    Moving_Standing,
    Moving_Walking,
    Moving_Running
};
var private MovingMode LastMovingMode;  //how was the player moving the last time HandleMoving() was called

var input byte bReload;

//
// debug
//

var vector LastDebugPoint;      //for general debug purposes
#if IG_SWAT_AUDIT_FOCUS
var bool bAuditFocus;
#endif

//
//constants
//

const HALF_PI = 1.5707963268;


/////////////////////////////////////
// Loadout
var public OfficerLoadOut  theLoadOut;

// This value is assigned to the player by the server in a network game. When
// switching levels, the clients have to disconnect and then reconnect.
var int SwatPlayerID;

var SwatRepoPlayerItem SwatRepoPlayerItem;

var bool ThisPlayerIsTheVIP;

// MCJ: Kluge. See the qualifying code for an explanation.
var private bool HaveCalledInterruptYet;

//dkaplan: determination of whether the bomb exploded in an SP game
var bool SPBombExploded;

/////////////////////////////////////
// View change notification
var private bool LastBehindView; // the value of bBehindView during the previous call to PlayerTick()

///////////////////////////////////////////////////////////////////////////////
#if IG_BATTLEROOM
var private BattleRoomManager BattleRoomManager;
var private FLOAT BattleRoomZ;
var private int   BattleRoomPitch;
var private input byte bBattleRoomRotation;
var input byte bBattleRoomControl;
#endif // IG_BATTLEROOM

// Used to cache the target for when we go to state QualifyingForUse.
var Actor OtherForQualifyingUse;

var EquipmentSlot EquipmentSlotForQualify;

// true if the playercontroller has been successfully cuffed, false if not.
var private bool bPlayerIsCuffed;

// Amount of time from the moment we start being cuffed to when our pawn is
// destroyed.
var config private float BeingCuffedTimeout;

var(DEBUG) bool DebugLocationFrozen;

// Each player controller gets this value from the settings and caches it.
// Clients tell the server with an RPC the value they want to use.
var private bool bAlwaysRun;

//flag for whent this player is changing teams
var private bool bChangingTeams;


var private bool bHaveAlreadyInterruptedOptiwand;

//the origin (start) of the trace the last time that the FocusInterfaces were updated
var vector LastFocusUpdateOrigin;

var private name TeamSelectedBeforeControllingOfficerViewport;

var eVoiceType VoiceType;

replication
{
    // Things the server should send to the client
    reliable if ( bNetOwner && bNetDirty && (Role == ROLE_Authority) )
        SwatPlayer, DoorCannotBeLocked, DoorIsLocked, DoorIsNotLocked, SpecialInteractionsNotification;

    // replicated functions sent to client by server
    reliable if( Role == ROLE_Authority )
        ClientBroadcastStopAllSounds,
        ClientSetEndRoundTarget, ClientStartEndRoundSequence,
        ClientOnLoggedIn, ClientRoundStarted, ClientMeleeForPawn, ClientReloadForPawn,
        ClientThrowPrep, ClientEndThrow, ClientPlayDoorBlocked, ClientDestroyPawnsForRespawn, ClientDestroyAllPawns,
        ClientPlayDoorBreached, ClientViewportChange, ClientSkeletalRegionHit,
        ClientBeginFiringWeapon, ClientEndFiringWeapon,
		ClientPreQuickRoundRestart,
		ClientStartConversation, ClientSetTrainingText, ClientTriggerDynamicMusic,
        ClientReceiveCommand, /*ClientOnTargetUsed,*/
		ClientSentOrReceivedEquipment,
        ClientAITriggerEffectEvent, ClientAIDroppedAllWeapons, ClientAIDroppedActiveWeapon, ClientAIDroppedAllEvidence,
        ClientInterruptAndGotoState, ClientInterruptState, ClientSetObjectiveVisibility, ClientReportableReportedToTOC,
        ClientAddPrecacheableMaterial, ClientAddPrecacheableMesh, ClientAddPrecacheableStaticMesh, ClientPrecacheAll,
        ClientViewFromLocation, ClientForceObserverCam, ReplicatedObserverCamTarget, ReplicatedViewportTeammate;

    // replicated functions sent to server by owning client
    reliable if( Role < ROLE_Authority )
        ServerSetPlayerTeam, ServerAutoSetPlayerTeam, ServerSetPlayerReady, ServerSetPlayerNotReady,
        ServerSetMPLoadOutPocketItem, ServerSetMPLoadOutPocketWeapon, ServerSetMPLoadOutPocketCustomSkin, ServerSetMPLoadOutSpecComplete, ServerChangePlayerTeam,
        ServerRequestThrowPrep, ServerEndThrow, ServerRequestQualifyInterrupt, /*ServerRequestInteract,*/
        ServerRequestViewportChange, ServerSetAlwaysRun, ServerActivateOfficerViewport,
        ServerGiveCommand, ServerIssueCompliance, ServerOnEffectStopped, ServerSetVoiceType,
		ServerRetryStatsAuth, ServerSetMPLoadOutPrimaryAmmo, ServerSetMPLoadOutSecondaryAmmo,
        ServerViewportActivate, ServerViewportDeactivate,
        ServerHandleViewportFire, ServerHandleViewportReload,
		ServerDisableSpecialInteractions, ServerMPCommandIssued,
		ServerDiscordTest, ServerDiscordTest2, ServerGiveItem;
}

///////////////////////////////////////////////////////////////////////////////

simulated function PreBeginPlay()
{
    Repo = SwatRepo(Level.GetRepo());

    Super.PreBeginPlay();

    Label = 'PlayerController';

    //TMC moved MCJ's code up to Engine.PlayerController for shared codebase purposes

    // Create camera effects for later use
    //
    // NOTE: these are cleaned up in native PostScriptDestroyed().
    // If you add any more you must also clean them up in there or
    // risk crashes during GC.
    FlashbangCameraEffect   = new class'FlashbangCameraEffect';
    FlashbangCameraEffect.Initialize(self);
    CSGasCameraEffect       = new class'CSGasCameraEffect';
    CSGasCameraEffect.Initialize(self);
    PepperSprayCameraEffect = new class'PepperSprayCameraEffect';
    PepperSprayCameraEffect.Initialize(self);
    StingCameraEffect       = new class'StingCameraEffect';
    StingCameraEffect.Initialize(self);
    NVGogglesCameraEffect   = new class'NVGogglesCameraEffect';
    NVGogglesCameraEffect.Initialize(self);
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    SPBombExploded=false;

    if ( self == Level.GetLocalPlayerController() )
    {
        InitializePlayerHUD();
    }

    // Moved creation of the viewport manager into here so it happens for every playercontroller on the server
    //if ( Level.NetMode != NM_DedicatedServer )
    //{
        // Only spawn the viewportmanager in standalone
        ViewportManager = Spawn(class'ExternalViewportManager', Self);
    //}

    if( Level.NetMode == NM_Standalone || Level.IsCOOPServer )
    {
        SwatGameInfo(Level.Game).GameEvents.PawnIncapacitated.Register(self);
        SwatGameInfo(Level.Game).GameEvents.PawnDamaged.Register(self);
    }

    if( Level.NetMode != NM_Client && Level.NetMode != NM_Standalone )
    {
        ForceObserverTimer = Spawn(class'Timer');
        assert(ForceObserverTimer != None);
        ForceObserverTimer.TimerDelegate = ForceObserverTimerCallback;
    }

	// Initialize stats
	if (Role == ROLE_Authority)
	{
		log(self@"creating stats class"@SwatGameInfo(Level.Game).StatsClass());
		Stats = new class<StatsInterface>(DynamicLoadObject(SwatGameInfo(Level.Game).StatsClass(), class'class'));
		Stats.SetPlayer(self);
		Stats.SetLevel(Level);
	}
	else
	{
		Stats = new class'StatsInterface';
	}
}

simulated function PostNetBeginPlay()
{
    local DynamicLoadOutSpec CurrentMultiplayerLoadOut;

    Super.PostNetBeginPlay();

    if ( self == Level.GetLocalPlayerController() )
    {
        // On the server, we don't want to use our value for other players'
        // playercontrollers.
        SetAlwaysRun( Repo.GuiConfig.bAlwaysRun );

        UpdateVoiceType();
    }

    // Dan: notify GuiController here that the loadout needs to be transmitted
    // to the server.

    if( Level.NetMode == NM_Client )
    {
        CurrentMultiplayerLoadOut = Spawn(class'SwatGame.DynamicLoadOutSpec', , name("CurrentMultiplayerLoadOut"));
        SetMPLoadOut(CurrentMultiplayerLoadOut);
        CurrentMultiplayerLoadOut.Destroy();
    }
}

simulated function InitializePlayerHUD()
{
    local int ct;
    local PlayerFocusInterface CurrentFocusInterface;

    //periodically check for an object to Focus, to update HUD

    FocusPollTimer = Spawn(class'Timer');
    assert(FocusPollTimer != None);
    FocusPollTimer.TimerDelegate = UpdateFocus;
    FocusPollTimer.StartTimer(FocusTestInterval, true);         //loop

    // create player focus interfaces
    for ( ct = 0; ct < FocusInterfaceInfos.Length; ct ++ )
    {
        if ( FocusInterfaceInfos[ct].ValidNetMode == FNET_All
             || (FocusInterfaceInfos[ct].ValidNetMode == FNET_StandaloneOnly && ( Level.NetMode == NM_Standalone ) )
             || (FocusInterfaceInfos[ct].ValidNetMode == FNET_MultiplayerOnly && Level.NetMode > NM_Standalone) )
        {
            CurrentFocusInterface = Spawn(FocusInterfaceInfos[ct].FocusClass, Self);
            assertWithDescription(CurrentFocusInterface != None,
                "[tcohen] SwatGamePlayerController::InitializePlayerHUD() Failed to Spawn the PlayerFocusInterface labeled "$FocusInterfaceInfos[ct].Label);
            FocusInterfaces[int(FocusInterfaceInfos[ct].Focus)] = CurrentFocusInterface;
        }
    }

    //command interface is only available in single-player
    SetCommandInterface(Repo.GUIConfig.CurrentCommandInterfaceStyle);

	//add speech recognition interface if required


#if IG_BATTLEROOM
    BattleRoomManager = Spawn(class'BattleRoomManager', Self);
#endif
}


simulated function PausePlayerFocusInterfaces()
{
    // MCJ: haven't fully implemented this yet. Only used in network games.
    FocusPollTimer.StopTimer();
}


simulated function ResumePlayerFocusInterfaces()
{
    // MCJ: haven't fully implemented this yet. Only used in network games.
}


simulated function SetCommandInterface(ECommandInterfaceStyle Style)
{
    local CommandInterface LastCommandInterface, ClassicCommandInterface, GraphicCommandInterface;

    ClassicCommandInterface = CommandInterface(FocusInterfaces[int(EFocusInterface.Focus_ClassicCommand)]);
    GraphicCommandInterface = CommandInterface(FocusInterfaces[int(EFocusInterface.Focus_GraphicCommand)]);

    LastCommandInterface = CurrentCommandInterface;

    switch (Style)
    {
        case CommandInterface_Classic:
            CurrentCommandInterface = ClassicCommandInterface;
            break;
        case CommandInterface_Graphic:
            CurrentCommandInterface = GraphicCommandInterface;
            break;
        default:
            assertWithDescription(false,
                "[tcohen] The SwatGamePlayerController's CurrentCommandInterfaceStyle is invalid.  Please check it in SwatGame.ini [SwatGame.SwatGamePlayerController].");
    }

    //dkaplan: this assertion is invalid- CurrentCommandInterface may be None in multiplayer if gametype != CO-OP
    //Assert( CurrentCommandInterface != None );

    log("CommandInterface set to "$GetCommandInterface());

    if (CurrentCommandInterface != LastCommandInterface)
    {
        ClassicCommandInterface.OnSelectedCommandInterfaceChanged(CurrentCommandInterface);
        GraphicCommandInterface.OnSelectedCommandInterfaceChanged(CurrentCommandInterface);

        UpdateFocus();
    }
}



// We use this for when we are *not* dying, and we need to actually get the
// pawn and controller out of the state they're in
simulated function ClientInterruptAndGotoState( Pawn ThePlayer, name Reason, name NewControllerState, name NewPawnState )
{
    local SwatPlayer PlayerPawn;

    PlayerPawn = SwatPlayer(ThePlayer);

    if ( PlayerPawn == None )
        return;

    // In general I like to put log statements at the beginning of the
    // function, but clients get lots of calls to this function with
    // ThePlayer=None during the normal course of gameplay, so I'm putting the
    // log statements after the test so the logs won't fill up with calls that
    // do nothing anyway. --MCJ

    if (Level.GetEngine().EnableDevTools)
    {
        mplog( self$"---SGPC::ClientInterruptAndGotoState()." );
        mplog( "...Pawn="$ThePlayer );
        mplog( "...Reason="$Reason );
        mplog( "...NewControllerState="$NewControllerState );
        mplog( "...NewPawnState="$NewPawnState );
    }

    PlayerPawn.InterruptState( Reason );
    if ( PlayerPawn.Controller != None )
        PlayerPawn.Controller.InterruptState( Reason );

    PlayerPawn.GotoState( NewPawnState );
    if ( PlayerPawn.Controller != None )
        PlayerPawn.Controller.GotoState( NewControllerState );
}


// We use this for dying, since we want to interrupt whatever state we're in,
// but the normal dying mechanisms will take care of putting us into the
// correct state.
simulated function ClientInterruptState( Pawn ThePlayer, name Reason )
{
    local SwatPlayer PlayerPawn;

    if (Level.GetEngine().EnableDevTools)
    {
        mplog( self$"---SGPC::ClientInterruptState()." );
        mplog( "...Pawn="$ThePlayer );
        mplog( "...Reason="$Reason );
    }

    PlayerPawn = SwatPlayer(ThePlayer);

    PlayerPawn.InterruptState( Reason );
    if ( PlayerPawn.Controller != None )
    PlayerPawn.Controller.InterruptState( Reason );
}


///////////////////////////////////////////////////////////////////////////////
// This is called after SwatGameInfo.PostLogin(), after the player pawn
// has been possessed by the player controller.
function Restart()
{
	local SwatPlayer SwatPlayerPawn;

    //Log("In SwatGamePlayerController.Restart()"); LogGuardStack();

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::Restart()." );

	bChangingTeams=false;

    Super.Restart();

	// dbeswick: stats
	SwatPlayerPawn = SwatPlayer(Pawn);
	if (SwatPlayerPawn != None && SwatPlayerPawn.IsTheVIP())
	{
		Stats.StatInt("isvip", 1);
	}
}


// The player controller is guaranteed to have it's new pawn assigned and
// set as its viewtarget after Super.ClientRestart() returns.
// MCJ: Actually, I'm not sure that this is correct. We had a bug where
// the camera effects didn't reset correctly when a player respawned, and I
// think what might have happened is that the pawn had not been replicated by
// the time ClientRestart() made it across. That is, when the PlayerController
// goes into the 'WaitingForPawn' state, our RefreshCameraEffects would fail.
function ClientRestart()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientRestart()." );

    Super.ClientRestart();

    // Reset things on the HUD.
	if( self == Level.GetLocalPlayerController() && HasHudPage() )
		GetHUDPage().OnPlayerRespawned();

	// Tell the HUD to hide the "viewing from" text and the respawn timer,
	// because we just respawned
    ClientMessage( "", 'ViewingFromEvent' );

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"...ClientRestart is calling SwatPlayer.RemoveAllCameraEffects()." );

    RemoveAllCameraEffects();

    //dkaplan - ugly ugly ugly HACK HACK Hack
    if( self == Level.GetLocalPlayerController() )
        UpdateVoiceType();
}

///////////////////////////////////////
simulated function ClientPreQuickRoundRestart()
{
    // Clean up garbage when quick restarting.
    // The server also does this in SwatGameInfo.PreQuickRoundRestart()
    if (Level.GetEngine().EnableDevTools)
        Log("Client in ClientPreQuickRoundRestart: Collecting garbage.");

    ConsoleCommand( "obj garbage" );
}
///////////////////////////////////////

function InitPlayerReplicationInfo()
{
    local SwatPlayerReplicationInfo SwatPlayerReplicationInfo;

    Super.InitPlayerReplicationInfo();

    SwatPlayerReplicationInfo= SwatPlayerReplicationInfo(PlayerReplicationInfo);
    SwatPlayerReplicationInfo.NetScoreInfo = Spawn(class'NetScoreInfo');
}

//an extra check to ensure we get properly logged out when disconnecting
simulated event OnConnectionFailed()
{
    if ( Role == ROLE_Authority )
    {
        Repo.Logout( self );
    }
}

simulated event Destroyed()
{
	local int ct;

	// dbeswick: focus interfaces must be destroyed when used with speech recognition
	// prevents garbage collection errors
    for ( ct = 0; ct < FocusInterfaces.Length; ct++ )
    {
        if  ( FocusInterfaces[ct] != None )
			FocusInterfaces[ct].Destroy();
	}

    if ( FocusPollTimer != None )
    {
        FocusPollTimer.Destroy();
    }
    Super.Destroyed();

    SwatGameInfo(Level.Game).GameEvents.PawnIncapacitated.UnRegister(self);
    SwatGameInfo(Level.Game).GameEvents.PawnDamaged.UnRegister(self);

    if ( Role == ROLE_Authority )
    {
        Repo.Logout( self );
    }
}


//simulated event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )

simulated function SpawnDefaultHUD()
{
    // note that myHUD is a variable defined in PlayerController
    myHUD = Spawn(class'SwatHUD', self);
}
simulated function CalcViewForFocus(out Actor ViewActor, out Vector ViewLocation, out Rotator ViewRotation)
{
    local IControllableThroughViewport ControllableThroughViewport;
    local Actor ViewportOwner;

    // If we have a viewport that we're controlling through, use that to determine the camera location and rotation
    if ( ActiveViewport != None && ActiveViewport.CanIssueCommands() )
    {
        LastFocusSource = '';
        ControllableThroughViewport = ActiveViewport.GetCurrentControllable();
        if (ControllableThroughViewport != None)
        {
            ViewportOwner = ControllableThroughViewport.GetViewportOwner();
            if (ViewportOwner != None)
            {
                LastFocusSource = ViewportOwner.Label;
            }
        }

        ActiveViewport.ViewportCalcView(ViewLocation, ViewRotation);
    }
    else
    {
        LastFocusSource = 'Player';
        PlayerCalcView(ViewActor, ViewLocation, ViewRotation);
    }
}

simulated function name GetLastFocusSource()
{
    return LastFocusSource;
}

simulated function UpdateFocus()
{
    local vector HitLocation, HitNormal;
    local Material HitMaterial;
    local Actor Candidate;
    local vector CameraLocation;
    local rotator CameraRotation;
    local float Distance;
    local bool Transparent;
    local HUDPageBase LocalHUDPage;
    local ESkeletalRegion SkeletalRegionHit;
    local HandheldEquipment ActiveItem;
    local array<byte> FocusInterfaceWantsUpdate;    //used as an array<bool>, but that doesn't work
    local int ct;
	local bool HitTransparent;

	HitTransparent = false;

    // MCJ: I'm putting this here for now. In an MP game, while sitting at the
    // Debriefing screen, we don't yet have a Pawn. I'll talk to Dan about not
    // enabling the timer until we enter the level, but for now just return
    // here if there's no pawn.
    // TMC TODO check this
    if ( Pawn == None )
    {
        return;
    }

    if (bBehindView) return;    //help debugging... retain previous focus when going into 3rd person

    CalcViewForFocus(Candidate, CameraLocation, CameraRotation );
    LastFocusUpdateOrigin = CameraLocation;

    LocalHUDPage = GetHUDPage();

#if IG_SWAT_AUDIT_FOCUS
    if (bAuditFocus) log("[FOCUS] T"$Level.TimeSeconds$" Auditing Focus...");
#endif

    ActiveItem = Pawn.GetActiveItem();

#if IG_SWAT_AUDIT_FOCUS
    if (bAuditFocus) log("[FOCUS] ... ActiveItem="$ActiveItem.Class.name$", IsIdle="$ActiveItem.IsIdle());
#endif

    //give each FocusInterface a PreUpdate() call, and remember if it wants to be updated
    FocusInterfaceWantsUpdate[FocusInterfaces.length-1] = 0;    //initialize wants to false (also initializes array size to avoid out-of-bounds accesses)
    for ( ct = 0; ct < FocusInterfaces.Length; ct++ )
    {
        if  (
                FocusInterfaces[ct] != None
            &&  FocusInterfaces[ct].PreUpdate(self, LocalHUDPage)
            )
        {
            FocusInterfaceWantsUpdate[ct] = 1;
            FocusInterfaces[ct].ResetFocus(self, LocalHUDPage);
        }
    }

    FocusTraceOrigin = CameraLocation;
    FocusTraceVector = vector(CameraRotation) * FocusTestDistance;

    foreach TraceActors(
        class'Actor',
        Candidate,
        HitLocation,
        HitNormal,
        HitMaterial,
        FocusTraceOrigin + FocusTraceVector,   //vector end
        FocusTraceOrigin,   //vector start
        vect(0,0,0),      //optional vector extent
        true,             //optional trace skeletal mesh boxes
        SkeletalRegionHit,
        true)             //optional get HitMaterial
    {
        Distance = VSize(HitLocation - CameraLocation);

        Transparent =   (
                            HitMaterial != None
                        &&  (
                                HitMaterial.MaterialVisualType == MVT_ThinGlass
                            ||  HitMaterial.MaterialVisualType == MVT_ThickGlass
                            )
                        );

#if IG_SWAT_AUDIT_FOCUS
        if (bAuditFocus) log("[FOCUS] ... Considering Candidate="$Candidate$" at Distance="$Distance$"...");
#endif

        if (class'PlayerFocusInterface'.static.StaticRejectFocus(
                    self,
                    Candidate,
                    HitLocation,
                    HitNormal,
                    HitMaterial,
                    SkeletalRegionHit,
                    Distance,
                    Transparent,
                    bAuditFocus))
            continue;

        //for each PlayerFocusInterface...
        for ( ct = 0; ct < FocusInterfaces.Length; ct++ )
        {
            if (FocusInterfaces[ct] == None)
                continue;

            //does it want to be updated?
            if (FocusInterfaceWantsUpdate[ct] == 0)
            {
#if IG_SWAT_AUDIT_FOCUS
                if (bAuditFocus) log("[FOCUS] ... ... Skipping the "$FocusInterfaces[ct].class.name$" because it doesn't want to be updated.");
#endif
                continue;
            }

            //does it care about the candidate?
            if (FocusInterfaces[ct].RejectFocus(
                        self,
                        Candidate,
                        HitLocation,
                        HitNormal,
                        HitMaterial,
                        SkeletalRegionhit,
                        Distance,
                        Transparent))
            {
#if IG_SWAT_AUDIT_FOCUS
                if (bAuditFocus) log("[FOCUS] ... ... Skipping the "$FocusInterfaces[ct].class.name$" because it rejected the candidate.");
#endif
                continue;
            }

            //is the candidate within range?
            if (Distance > FocusInterfaces[ct].default.Range)
            {
#if IG_SWAT_AUDIT_FOCUS
                if (bAuditFocus) log("[FOCUS] ... ... Skipping the "$FocusInterfaces[ct].class.name$" because the candidate is out of range.");
#endif
                continue;
            }

#if IG_SWAT_AUDIT_FOCUS
            if (bAuditFocus) log("[FOCUS] ... ... The "$FocusInterfaces[ct].class.name$" is getting to ConsiderNewFocus()");
#endif

            FocusInterfaces[ct].ConsiderNewFocus(
                    SwatPlayer(Pawn),
                    Candidate,
                    Distance,
                    HitLocation,
                    HitNormal,
                    HitMaterial,
                    SkeletalRegionHit,
                    Transparent,
					HitTransparent );
        }

		// HitTransparent will be true *after* hitting something which is transparent.
		// That way, we can differentiate between looking through glass and focusing on glass
		if(Transparent)
		{
			HitTransparent = true;
		}

    }

    for ( ct = 0; ct < FocusInterfaces.Length; ct++ )
        if (FocusInterfaceWantsUpdate[ct] == 1 || (FocusInterfaces[ct] != None &&
			FocusInterfaces[ct].AlwaysPostUpdate))
            FocusInterfaces[ct].PostUpdate(self);

    LocalHUDPage.Feedback.UpdateCaption();

#if IG_SWAT_AUDIT_FOCUS
    bAuditFocus = false;    //only audit for one UpdateFocus()
#endif
}

simulated function BeginLowReadyRefractoryPeriod()
{
    LowReadyInterface(GetFocusInterface(Focus_LowReady)).BeginLowReadyRefractoryPeriod();
}


//////////////////////////////////////////////////////

// Only ever used for the Optiwand
simulated event InitiateViewportUse( IControllableViewport inNewViewport )
{
    if ( Level.NetMode == NM_Standalone )
    {
        log ( "ActiveViewport actor is: "$Actor(ActiveViewport) );
        log ( "IControllableViewport of Actor is: "$IControllableViewport(Actor(ActiveViewport)) );
        //ActiveViewport = inNewViewport;
        if ( !SwatPlayer.IsNonLethaled() )
            ActivateViewport( inNewViewport );
    }
    else
    {
        if ( Level.NetMode == NM_Client )
        {
            log ( "ActiveViewport actor is: "$Actor(ActiveViewport) );
            log ( "IControllableViewport of Actor is: "$IControllableViewport(Actor(ActiveViewport)) );
            if ( VSize(Pawn.Velocity) < 0.05 )
            {
                //ActiveViewport = inNewViewport;
                ServerRequestViewportChange( inNewViewport == Pawn.GetActiveItem() );
            }
        }
        else
        {
            // We're on the server.
            if ( VSize(Pawn.Velocity) < 0.05 )
            {
                log ( "ActiveViewport actor is: "$Actor(ActiveViewport) );
                log ( "IControllableViewport of Actor is: "$IControllableViewport(Actor(ActiveViewport)) );
                //ActiveViewport = inNewViewport;
                if ( !SwatPlayer.IsNonLethaled() )
                    ActivateViewport( inNewViewport );
            }
        }
    }
}

// This client->server RPC will, if ShouldActivate is true, choose the next
// available teammate to use as the viewport target. Or, reset the viewport
// if ShouldActivate is false.
function ServerActivateOfficerViewport( bool ShouldActivate, optional string ViewportType )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"--ServerActivateOfficerViewport - ShouldActivate: "$ShouldActivate );

    if ( ShouldActivate )
    {
        if( Pawn == None || NetPlayer(Pawn) == None )
            return;

        ServerOfficerViewport = ViewportManager;

        // Should call initialize every time the viewport is brought up to catch any players that join the game since the last time initialization was done
        ///if ( !ViewportManager.HasOfficers("") )
        ViewportManager.Initialize();

        // MCJ: this function went away, but we're not calling this code
        // anymore. If we ever need this code to work again, see me and we'll
        // renetwork it.
        //ServerSetActiveViewport( false, ViewportManager );

        if (Level.GetEngine().EnableDevTools)
            mplog( "Setting viewporttype manually for netgame");

        log(self$"--ServerActivateOfficerViewport - ShouldActivate :"$ShouldActivate$", ViewportType = "$ViewportType);

        // We need to convert the viewport type into co-op teams
        if(ViewportType ~= "Red")
          ViewportType = "TeamB";
        else if(ViewportType ~= "Blue")
          ViewportType = "TeamA";

        if (Level.GetEngine().EnableDevTools)
            mplog( "Setting viewporttype manually for netgame to "$ViewportType );

        if ( ViewportManager.HasOfficers( ViewportType ) )
        {
            ViewportManager.ShowViewport(ViewportType, "");
        }

        ReplicatedViewportTeammate = ViewportManager.GetCurrentControllable();
    }

    // If we should deactivate, or we tried to activate but no current
    // controllable was found, reset some viewport manager state.
    if ( !ShouldActivate || ReplicatedViewportTeammate == None )
    {
        ServerOfficerViewport = None;
        ReplicatedViewportTeammate = None;
        ViewportManager.SetFilter("");
        ViewportManager.HideViewport();
    }
}

simulated private event OnReplicatedViewportTeammateChanged()
{
    // Show or hide the viewport, depending on what the server->client
    // replicated variable 'ReplicatedViewportTeammate' has changed to.
    if (ReplicatedViewportTeammate != None)
    {
        ViewportManager.Initialize();
        GetHUDPage().ExternalViewport.Show();
        ViewportManager.SetCurrentControllable(ReplicatedViewportTeammate);
    }
    else
    {
        HideViewportInternal();
    }
}

function ServerRequestViewportChange( bool ActivateActiveItemViewport )
{
    local HandheldEquipment theActiveItem;

    log("SwatGamePlayerController::ServerRequestViewportChange("$ActivateActiveItemViewport$")");

    // Don't ever activate if we're non-lethaled!
    if ( SwatPlayer.IsNonLethaled() && ActivateActiveItemViewport )
        return;

    if ( ActivateActiveItemViewport )
    {
        theActiveItem = Pawn.GetActiveItem();
        if ( theActiveItem != None
             && theActiveItem.IsA( 'IControllableViewport' )
             && theActiveItem.IsIdle() )
        {
            // Set the server's item viewport to the active item
            ServerItemViewport = IControllableViewport(theActiveItem);
            // Let the client update what it needs to
            ClientViewportChange( ActivateActiveItemViewport );
        }

    }
	else
    {
        ServerItemViewport = None;
        ClientViewportChange( ActivateActiveItemViewport );
    }

    if (Level.GetEngine().EnableDevTools)
        log( "ServerRequestUseOptiwand on: "$Self$" ActiveViewport is: "$ActiveViewport );
}


simulated function ClientViewportChange( bool ActivateActiveItemViewport )
{
    local HandheldEquipment theActiveItem;

    mplog("ClientViewportChange("$ActivateActiveItemViewport$")");

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientViewportChange()." );

    if ( ActivateActiveItemViewport )
    {
        theActiveItem = Pawn.GetActiveItem();
        if ( theActiveItem != None
             && theActiveItem.IsA( 'IControllableViewport' )
             && theActiveItem.IsIdle() )
        {
            ActivateViewport( IControllableViewport(theActiveItem) );
        }
    }
    else
    {
        ActiveViewport = None;
    }
}

// Called on the server side
simulated function ServerViewportActivate(name StateName, Actor ControllableViewport)
{
  ActiveViewport = ViewportManager;

  GotoState(StateName);
}

simulated function ServerViewportDeactivate()
{
  EndState();
}

// Set the activate viewport and pipe commands into it
// Usually occurs on the client only!
simulated event ActivateViewport(IControllableViewport inNewViewport)
{
    ActiveViewport = inNewViewport;

    log("ActivateViewport("$inNewViewport$")");

    log ( "ActiveViewport actor is: "$Actor(ActiveViewport) );
    log ( "IControllableViewport of Actor is: "$IControllableViewport(Actor(ActiveViewport)) );
    log("GetControllingStateName:"$inNewViewport.GetControllingStateName());
    log("GetCurrentControllable:"$inNewViewport.GetCurrentControllable());

    if ( ActiveViewport != None )
    {
        log("Going to state: "$ActiveViewport.GetControllingStateName());
        GotoState(ActiveViewport.GetControllingStateName());
        if(!inNewViewport.IsA('Optiwand'))
          ServerViewportActivate(ActiveViewport.GetControllingStateName(), Actor(ActiveViewport));
    }
    else if(Level.NetMode != NM_Standalone && !inNewViewport.IsA('Optiwand'))
    {
      ServerViewportDeactivate();
    }
}

exec function EnableMirrors( bool bInEnabledMirrors )
{
    class'Mirror'.Static.SetMirrorsEnabled( bInEnabledMirrors );
}

exec function Echo(string s)
{
	Player.Console.Message(s, 0);
}

exec function ServerDiscordTest()
{
	SwatGameInfo(Level.Game).SendDiscordMessage("One small step for man...one giant leap for SWAT-kind.");
}

exec function ServerDiscordTest2()
{
	SwatGameInfo(Level.Game).TestDiscord();
}

// Called when the player is holding down the button to Control the viewport.
exec function ControlOfficerViewport()
{
	local string ViewportFilter;

    if ( !IsDead() && ViewportManager.ShouldControlViewport() )
    {
        if ( GetHUDPage().ExternalViewport.bVisible )
        {
            TeamSelectedBeforeControllingOfficerViewport = GetCommandInterface().GetCurrentTeam();

            ViewportFilter = ViewportManager.GetFilter();

            if (ViewportFilter == "Red")
                SetPlayerCommandInterfaceTeam('RedTeam');
            else
            if (ViewportFilter == "Blue")
                SetPlayerCommandInterfaceTeam('BlueTeam');

            ActivateViewport(ViewportManager);
        }
    }
}


exec function Fire()
{
    local HandheldEquipment ActiveItem;

    ActiveItem = Pawn.GetActiveItem();

    if ( EquipmentSlotForQualify != SLOT_Invalid && EquipmentSlotForQualify != ActiveItem.GetSlot() )
    {
        InternalEquipSlot( EquipmentSlotForQualify );
    }
    else if ( ActiveItem != None && ActiveItem.IsA('IControllableViewport') && ActiveItem.IsIdle() )
    {
        // HandheldEquipments can also be controllableviewports, like the optiwand.
        InitiateViewportUse( IControllableViewport(ActiveItem) );
    }
    else if ( Level.NetMode == NM_Standalone
              || (!SwatPlayer.IsNonlethaled() && !SwatPlayer.IsArrested()) )
    {
        Super.Fire();
    }
}


// Executes only on the client.
simulated function ClientBeginFiringWeapon( Pawn PawnWhoFired, EquipmentSlot ItemSlot, FireMode CurrentFireMode )
{
    local NetPlayer theNetPlayer;
    local FiredWeapon theFiredWeapon;

    // temp, for testing.
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientBeginFiringWeapon(). PawnWhoFired="$PawnWhoFired$", ItemSlot="$ItemSlot );

    Assert( Level.NetMode == NM_Client );

    if ( PawnWhoFired != None )
    {
        //mplog( self$"---SGPC::ClientBeginFiringWeapon(). PawnWhoFired="$PawnWhoFired$", ItemSlot="$ItemSlot );
        theNetPlayer = NetPlayer( PawnWhoFired );
        theFiredWeapon = FiredWeapon(theNetPlayer.GetLoadOut().GetItemAtSlot( ItemSlot ));
        if ( theFiredWeapon == theNetPlayer.GetActiveItem() && theFiredWeapon.IsEquipped() && theFiredWeapon.IsIdle() )
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "...Calling OnPlayerUse() on "$theFiredWeapon );

            theFiredWeapon.SetCurrentFireMode( CurrentFireMode );
            theFiredWeapon.OnPlayerUse();
        }
        else
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "...Was told to fire, but the Item was not the ActiveItem. PawnWhoFired="$PawnWhoFired$", theFiredWeapon="$theFiredWeapon );
        }
    }
}

// Executes only on the client.
simulated function ClientAIBeginFiringWeapon( Pawn theAIPawn, int CurrentFireMode )
{
    local FiredWeapon theFiredWeapon;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientAIBeginFiringWeapon(). PawnWhoFired="$theAIPawn$", FireMode="$CurrentFireMode );

    Assert( Level.NetMode == NM_Client );

    if ( theAIPawn == None )
        return;

    theFiredWeapon = FiredWeapon( theAIPawn.GetActiveItem() );
    if ( theFiredWeapon == None )
        return;

    if ( theFiredWeapon.IsEquipped() && theFiredWeapon.IsIdle() )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...Calling OnPlayerUse() on "$theFiredWeapon );

        theFiredWeapon.SetCurrentFireMode( FireMode(CurrentFireMode) );
        theFiredWeapon.OnPlayerUse();
    }
}


// Executes only on the client.
simulated function ClientEndFiringWeapon( Pawn PawnWhoFired )
{
    local NetPlayer theNetPlayer;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientEndFiringWeapon(). PawnWhoFired="$PawnWhoFired );

    Assert( Level.NetMode == NM_Client );

    if ( PawnWhoFired != None )
    {
        theNetPlayer = NetPlayer( PawnWhoFired );

        if (Level.GetEngine().EnableDevTools)
            mplog( "...Stopping autofiring." );

        theNetPlayer.bWantsToContinueAutoFiring = false;
    }
}

// Executes only on the client.
simulated function ClientAIEndFiringWeapon( Pawn theAIPawn )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientAIEndFiringWeapon(). PawnWhoFired="$theAIPawn );

    Assert( Level.NetMode == NM_Client );

    if ( theAIPawn != None )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...Stopping autofiring." );

        SwatPawn(theAIPawn).bWantsToContinueAutoFiring = false;
    }
}


simulated function ClientAIDroppedAllWeapons( SwatEnemy theDropper )
{
    mplog( "---SGPC::ClientAIDroppedAllWeapons(). dropper="$theDropper );

    if ( theDropper != None )
    {
        theDropper.DropAllWeapons();
    }
}

simulated function ClientAIDroppedActiveWeapon( SwatEnemy theDropper )
{
    mplog( "---SGPC::ClientAIDroppedActiveWeapon(). dropper="$theDropper );

    if ( theDropper != None )
    {
        theDropper.DropActiveWeapon();
    }
}

simulated function ClientAIDroppedAllEvidence( SwatEnemy theDropper, bool bIsDestroying )
{
    mplog( "---SGPC::ClientAIDroppedAllEvidence(). dropper="$theDropper );

    if ( theDropper != None )
    {
        theDropper.DropAllEvidence(bIsDestroying);
    }
}

simulated function ClientAIDroppedWeapon( string WeaponUniqueID,
                                          vector ServerLocation,
                                          rotator ServerRotation,
                                          vector ThrowDirectionImpulse,
                                          class<HandheldEquipmentModel> WeaponModelClass )
{
    local HandheldEquipmentModel WeaponModel;
    local bool PhysicsError;

    if (Level.GetEngine().EnableDevTools)
    {
        mplog( "---SGPC::ClientAIDroppedWeapon(). UniqueID="$WeaponUniqueID$", ServerLocation="$ServerLocation$", ServerRotation="$ServerRotation );
        mplog( "...ServerLocation="$ServerLocation );
        mplog( "...ServerRotation="$ServerRotation );
        mplog( "...ThrowDirectionImpulse="$ThrowDirectionImpulse );
        mplog( "...WeaponModelClass="$WeaponModelClass );
    }
    Assert( WeaponUniqueID != "" );

    WeaponModel = HandheldEquipmentModel(FindByUniqueID( class'HandheldEquipmentModel', WeaponUniqueID ));
    if ( WeaponModel == None )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...There was not a weapon in the level with that UniqueID, so we're spawning it." );

        WeaponModel = Spawn( WeaponModelClass );
        Assert( WeaponModel != None );

        if (Level.GetEngine().EnableDevTools)
            mplog( "WeaponModel="$WeaponModel );

        WeaponModel.bHidden = false;
        WeaponModel.bIsDropped = true;

        WeaponModel.bBlockNonZeroExtentTraces = true;
        WeaponModel.bBlockZeroExtentTraces = true;
        WeaponModel.bProjTarget = true;
        WeaponModel.SetCollision(true, false, false);
        WeaponModel.SetLocation( ServerLocation );
        WeaponModel.SetRotation( ServerRotation );

        WeaponModel.SetUniqueID( WeaponUniqueID );

        // Then initiate the Havok Physics. See SwatEnemy::DropWeapon to see what
        // to do.
        PhysicsError = false;
        // Make sure there's havok params set for the weapon model.
        if (WeaponModel.HavokDataClass == None)
        {
            assertWithDescription(false, "SwatEnemy::DropWeapon - HavokDataClass for WeaponModel " $ WeaponModel.Name $ " is NULL.");
            PhysicsError = true;
        }

        // set the physics and give the model an impulse
        if (!PhysicsError)
        {
            // if the weapon model doesn't have a static mesh, use the DroppedStaticMesh property
            //		log("WeaponModel: " $ WeaponModel.Name $ " WeaponModel.StaticMesh: " $ WeaponModel.StaticMesh);
            if (WeaponModel.StaticMesh == None)
            {

                if (Level.GetEngine().EnableDevTools)
                {
                    assertWithDescription((WeaponModel.DroppedStaticMesh != None), "WeaponModel " $ WeaponModel.Name $ " does not have a Dropped static mesh set for it.  It must!  Bug Shawn!!!");
                    log("Setting static mesh for "$WeaponModel.Name$" to: " $ WeaponModel.DroppedStaticMesh);
                }

                WeaponModel.SetStaticMesh(WeaponModel.DroppedStaticMesh);
                WeaponModel.SetDrawType(DT_StaticMesh);
            }

            WeaponModel.HavokSetBlocking(true);
            WeaponModel.SetPhysics(PHYS_Havok);

            // Drop the weapon with the impulse specified by the server
            WeaponModel.HavokImpartCOMImpulse( ThrowDirectionImpulse );
        }

        // Regardless of drawtype, use collision cylinder so reporting will be easier for the player
        WeaponModel.bUseCylinderCollision = true;
    }
    else
    {
        if (Level.GetEngine().EnableDevTools)
        {
            mplog( "...WeaponModel was not None: the weapon already existed in the Level. WeaponModel="$WeaponModel );
            mplog( "...WeaponModel.UniqueID()="$WeaponModel.UniqueID() );
        }
    }
}


simulated function ClientWeaponFellOutOfWorld( string WeaponUniqueID )
{
    local HandheldEquipmentModel theModel;

    if (Level.GetEngine().EnableDevTools)
        mplog( "---SGPC::ClientWeaponFellOutOfWorld(). UniqueID="$WeaponUniqueID );

    // Look up and destroy the model here.
    Assert( WeaponUniqueID != "" );

    theModel = HandheldEquipmentModel(FindByUniqueID( class'HandheldEquipmentModel', WeaponUniqueID ));

    // The model may be none if the client joined the server after the weapon
    // had been dropped.
    if ( theModel != None )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...calling Destroy() on the theModel." );

        theModel.Destroy();
    }
    else
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...not calling Destroy() because theModel was None." );
    }
}

simulated function ClientDroppedWeaponAtRest( string WeaponUniqueID, float ServerLocation_X, float ServerLocation_Y, float ServerLocation_Z, rotator ServerRotation )
{
    local HandheldEquipmentModel theModel;
    local vector ServerLocation;

    if (Level.GetEngine().EnableDevTools)
        mplog( "---SGPC::ClientDroppedWeaponAtRest(). UniqueID="$WeaponUniqueID );

    Assert( WeaponUniqueID != "" );

    // MCJ: We have to pass these as separate floats, since otherwise the
    // vector's values are compressed and lose some resolution. As a result,
    // sometimes the client places the weapon under the floor.
    ServerLocation.X = ServerLocation_X;
    ServerLocation.Y = ServerLocation_Y;
    ServerLocation.Z = ServerLocation_Z;
    if (Level.GetEngine().EnableDevTools)
    {
        mplog( "...ServerLocation="$ServerLocation );
        mplog( "...ServerRotation="$ServerRotation );
    }

    theModel = HandheldEquipmentModel(FindByUniqueID( class'HandheldEquipmentModel', WeaponUniqueID ));

    // The model may be none if the client joined the server after the weapon
    // had been dropped.
    if ( theModel != None )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...calling ProcessAtRestValuesFromServer()." );

        theModel.ProcessAtRestValuesFromServer( ServerLocation, ServerRotation );
    }
    else
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...theModel was None, so we're not calling ProcessAtRestValuesFromServer()." );
    }
}


simulated function EquipmentSlot GetEquipmentSlotForQualify()
{
    return EquipmentSlotForQualify;
}

exec function NextFireMode()
{
    local HandheldEquipment ActiveItem;

    ActiveItem = Pawn.GetActiveItem();

    if (ActiveItem != None && ActiveItem.IsA('FiredWeapon'))
        FiredWeapon(ActiveItem).NextFireMode();
}

exec function SetWeaponFlashlightPos(vector offset)
{
	local HandheldEquipment ActiveItem;
	local SwatWeapon ActiveWeapon;

	log("Setting flashlight to "$offset);

    ActiveItem = Pawn.GetActiveItem();
	ActiveWeapon = SwatWeapon(ActiveItem);
	if (ActiveWeapon != None) {
		ActiveWeapon.FlashlightPosition_1stPerson = offset;
	}
}

exec function SetWeaponFlashlightRotation(rotator Rotation)
{
	local HandheldEquipment ActiveItem;
	local SwatWeapon ActiveWeapon;

	log("Setting weapon flashlight rotation to "$Rotation);

    ActiveItem = Pawn.GetActiveItem();
	ActiveWeapon = SwatWeapon(ActiveItem);
	if (ActiveWeapon != None) {
		ActiveWeapon.FlashlightRotation_1stPerson = Rotation;
	}
}

exec function SetWeaponViewOffset(vector offset)
{
	local HandheldEquipment ActiveItem;
	local SwatWeapon ActiveWeapon;

	log("Setting default view offset to "$offset);

    ActiveItem = Pawn.GetActiveItem();
	ActiveWeapon = SwatWeapon(ActiveItem);
	if (ActiveWeapon != None) {
		ActiveWeapon.DefaultLocationOffset = offset;
	}
}

exec function SetWeaponViewRotation(rotator Rotation)
{
	local HandheldEquipment ActiveItem;
	local SwatWeapon ActiveWeapon;

	log("Setting default weapon rotation to "$Rotation);

    ActiveItem = Pawn.GetActiveItem();
	ActiveWeapon = SwatWeapon(ActiveItem);
	if (ActiveWeapon != None) {
		ActiveWeapon.DefaultRotationOffset = Rotation;
	}
}

exec function SetIronSightOffset(vector offset)
{
	local HandheldEquipment ActiveItem;
	local SwatWeapon ActiveWeapon;

    ActiveItem = Pawn.GetActiveItem();
	ActiveWeapon = SwatWeapon(ActiveItem);
	if (ActiveWeapon != None) {
		ActiveWeapon.IronSightLocationOffset = offset;
	}
}

exec function SetIronSightRotation(rotator Rotation)
{
	local HandheldEquipment ActiveItem;
	local SwatWeapon ActiveWeapon;

    ActiveItem = Pawn.GetActiveItem();
	ActiveWeapon = SwatWeapon(ActiveItem);
	if (ActiveWeapon != None) {
		ActiveWeapon.IronSightRotationOffset = Rotation;
	}
}

exec function SetWeaponViewInertia(float Inertia)
{
	local HandheldEquipment ActiveItem;
	local SwatWeapon ActiveWeapon;

    ActiveItem = Pawn.GetActiveItem();
	ActiveWeapon = SwatWeapon(ActiveItem);
	if (ActiveWeapon != None) {
		ActiveWeapon.ViewInertia = Inertia;
	}
}

simulated function SwatDoor GetDoorInWay()
{
    local SwatDoor DoorActor;

    DoorActor = SwatDoor(GetFocusInterface(Focus_Fire).GetDefaultFocusActor());

    // umm tried using vsizesquared here but got a compiler error wtf
    if ( DoorActor != None &&  VSize(DoorActor.Location - Pawn.Location) < 100.0 )
        return DoorActor;
    return None;
}

simulated function bool DoorInWay()
{
    local SwatDoor DoorActor;

    DoorActor = SwatDoor(GetFocusInterface(Focus_Fire).GetDefaultFocusActor());

    // umm tried using vsizesquared here but got a compiler error wtf
    if ( DoorActor != None &&  VSize(DoorActor.Location - Pawn.Location) < 100.0 )
        return true;
    return false;
}

//ignore in states to prevent opening the GCI while in those states
simulated function bool CanOpenGCI() { return true; }

// Server wrappers to handle the reload and fire events for snipers
simulated function ServerHandleViewportFire(vector CameraLocation, rotator CameraRotation)
{
  ActiveViewport.HandleFire(true, CameraLocation, CameraRotation);
}

simulated function ServerHandleViewportReload()
{
  ActiveViewport.HandleReload();
}

// special interactions thingie
simulated function ServerDisableSpecialInteractions()
{
	SpecialInteractionsDisabled = !SpecialInteractionsDisabled;
	SpecialInteractionsNotification(SpecialInteractionsDisabled);
}

simulated function ServerMPCommandIssued(string CommandText)
{
	Level.Game.AdminLog(CommandText,
		'CommandGiven',
		GetPlayerNetworkAddress());
}

exec function ToggleSpecialInteractions()
{
	ServerDisableSpecialInteractions();
}

simulated function SpecialInteractionsNotification(bool NewInteractions)
{
	// all this does is print a message to the chat
	if(NewInteractions)
	{
		ClientMessage("[c=FFFFFF]Special melee interactions are now disabled.", 'SpeechManagerNotification');
	}
	else
	{
		ClientMessage("[c=FFFFFF]Special melee interactions are now enabled.", 'SpeechManagerNotification');
	}
}

exec function ThrowLightstick()
{
	local HandheldEquipment ActiveItem;

	ActiveItem = SwatPlayer.GetActiveItem();
	if(ActiveItem.IsA('Lightstick'))
	{
		// Don't allow us to drop a lightstick while we have it equipped
		return;
	}

	// Flag the lightstick as being in a "fast use" state.
	SwatPlayer.FlagLightstickFastUse();

	// Equip slot 14, which will drop the lightstick instantly just like vanilla TSS
	EquipSlot(14);
}

// State ControllingViewport takes the player's control away from the playerpawn and onto the active
// viewport.  The actual implementation the instances of IControllableViewport handle all implementation
// details.
state ControllingViewport
{
ignores ActivateViewport;

    exec function ToggleFlashLight()
    {
    }

    event WindowFocusRegained()
    {
        ViewportManager.InstantMinimize();
        GotoState('PlayerWalking');
        bControlViewport = 0;
        mplog("ControllingViewport-->WindowFocusRegained()");
    }

    exec function HideViewport()
    {
        mplog("ControllingViewport-->HideViewport()");
        Global.HideViewport();
        GotoState('PlayerWalking');
    }

    exec function GiveCommand(int CommandIndex)
    {
        if ( ActiveViewport.CanIssueCommands() )
            Global.GiveCommand(CommandIndex);
    }

    exec function GiveDefaultCommand()
    {
        if  (
                ActiveViewport.CanIssueCommands()
            &&  GetCommandInterface().Enabled
            )
            GetCommandInterface().GiveDefaultCommand(bHoldCommand > 0);
    }

    exec function OpenGraphicCommandInterface()
    {
        if ( ActiveViewport.CanIssueCommands() )
            Global.OpenGraphicCommandInterface();
    }

    exec function Reload()
    {
        //ActiveViewport.HandleReload();
        ServerHandleViewportReload();
    }

	// Zooming is handled the same as alt fire for the viewport
    exec function ToggleZoom()
    {
        ActiveViewport.HandleAltFire();
    }

    exec function Fire()
    {
      local vector CameraLocation;
      local Rotator CameraDirection;

      if(ActiveViewport == None)
      {
        return;
      }

      if(ActiveViewport.IsA('Optiwand'))
      {
        ActiveViewport.HandleFire();
        return;
      }

      ActiveViewport.ViewportCalcView(CameraLocation, CameraDirection);

      ServerHandleViewportFire(CameraLocation, CameraDirection);
    }

    exec function ViewportRightMouse ()
    {
        ActiveViewport.HandleAltFire();
    }

    simulated function BeginState()
    {
        Pawn.SetPhysics(PHYS_None);
        ActiveViewport.OnBeginControlling();
    }

    simulated function EndState()
    {
        Pawn.SetPhysics(PHYS_Walking);
        ActiveViewport.OnEndControlling();

        // Not necessary to do this if we are the server
        if(Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Host)
        {
          Global.ActivateViewport( None );
        }

        bControlViewport = 0;

        SetPlayerCommandInterfaceTeam(TeamSelectedBeforeControllingOfficerViewport);

        if(Repo.GuiConfig.SwatGameRole == GAMEROLE_MP_Host)
        {
          GotoState('PlayerWalking');
        }
    }

    simulated function PlayerTick(float DeltaTime)
    {
    	Super.PlayerTick(DeltaTime);
        ActiveViewport.SetInput(aTurn, aLookUp);


        if (!ActiveViewport.ShouldControlViewport())
        {
            GotoState('PlayerWalking');
        }
	    ViewShake(deltaTime);
	    ViewFlash(deltaTime);
    }
}

state ControllingSniperViewport extends ControllingViewport
{
  exec function Fire()
  {

  }
}

// Control the optiwand viewport, NOTE: we're only in this state while actually using an optiwand...
simulated state ControllingOptiwandViewport
{
    ignores Fire, HandsShouldIdle, ActivateViewport;

    simulated function BeginState()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "ControllingOptiwandViewport::BeginState()");

        bHaveAlreadyInterruptedOptiwand = false;
        Pawn.SetPhysics(PHYS_None);
        ActiveViewport.OnBeginControlling();
        SwatPlayer.CachedPlayerControllerForOptiwand = self;
        SwatPlayer.SetIsUsingOptiwand(true);
    }

    // Keep EndState() and InterruptState() in sync.
    simulated function EndState()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "ControllingOptiwandViewport::EndState()");

        CleanupOptiwandingState();
    }

    simulated function InterruptState( name PendingState )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"---SGPC::InterruptState() in state 'ControllingOptiwandViewport'." );

        if ( !bHaveAlreadyInterruptedOptiwand )
        {
            CleanupOptiwandingState();
            // aaarrrrgghhh! Dying won't reliably take you out of this state on clients, so
            // we have to force the Controller out of it. Nasty.
            GotoState( 'PlayerWalking' );
        }
    }

    simulated function CleanupOptiwandingState()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "ControllingOptiwandViewport::CleanupOptiwandingState()");

        if ( !bHaveAlreadyInterruptedOptiwand )
        {
            bHaveAlreadyInterruptedOptiwand = true;
            // Go out of crouching in case we were in a doorway
            SwatPlayer.SetForceCrouchWhileOptiwanding(false);
            SwatPlayer.SetIsUsingOptiwand(false);
            Pawn.SetPhysics(PHYS_Walking);
            ActiveViewport.OnEndControlling();
            ServerRequestViewportChange( false );

            Pawn.GetActiveItem().InterruptUsing();
        }
    }

    simulated function PlayerTick(float DeltaTime)
    {
    	Super.PlayerTick(DeltaTime);
        ActiveViewport.SetInput(aTurn, aLookUp);
    }

    exec function GiveCommand(int CommandIndex)
    {
        if ( ActiveViewport.CanIssueCommands() )
            Global.GiveCommand(CommandIndex);
    }

    exec function GiveDefaultCommand()
    {
        if  (
                ActiveViewport.CanIssueCommands()
            &&  GetCommandInterface().Enabled
            )
            GetCommandInterface().GiveDefaultCommand(bHoldCommand > 0);
    }

    exec function OpenGraphicCommandInterface()
    {
        if ( ActiveViewport.CanIssueCommands() )
            Global.OpenGraphicCommandInterface();
    }

    exec function OpenHudChat(bool bGlobal)
    {
        if ( SwatGuiControllerBase(Repo.GUIController).CanChat() )
        {
            GotoState('PlayerWalking');
            Global.OpenHudChat(bGlobal);
        }
    }

Begin:
    // Make sure we're using the optiwand here!
    assert( Pawn.GetActiveItem().IsA( 'Optiwand' ) );

    // Go into crouching if we're in front of a door to "mirror under it"
    if ( DoorInWay() )
    {
        SwatPlayer.SetForceCrouchWhileOptiwanding(true);
    }

    // Use the optiwand...
    Pawn.GetActiveItem().LatentUse();

    // Go out of crouching in case we were in a doorway
    SwatPlayer.SetForceCrouchWhileOptiwanding(false);

    // Go back to walking
    GotoState('PlayerWalking');

}



///////////////////////////////////////////////////////////////////////

simulated function ClientPlayDoorBlocked( SwatDoor TheDoor, bool OpeningBlocked, DoorPosition NewPendingPosition )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientPlayDoorBlocked(). TheDoor="$TheDoor$", OpeningBlocked="$OpeningBlocked$", NewPendingPosition="$NewPendingPosition );

    TheDoor.PendingPosition = NewPendingPosition;
    if ( OpeningBlocked )
    {
        TheDoor.GotoState( 'OpeningBlocked' );
    }
    else
    {
        TheDoor.GotoState( 'ClosingBlocked' );
    }
}


simulated function ClientPlayDoorBreached( SwatDoor TheDoor, DeployedC2ChargeBase TheCharge )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientPlayDoorBreached(). TheDoor="$TheDoor$", TheCharge="$TheCharge );

    Assert( TheDoor != None );
    Assert( TheCharge != None );
    TheDoor.PlayDoorBreached( TheCharge );
}


///////////////////////////////////////////////////////////////////////

// This is a kluge for testing. On a network client, if I'm in
// QualifyingForUse and get an OnQualifyInterrupted(), I do a gotostate
// PlayerWalking, but I get several subsequent PlayerTick()'s before the state
// change occurs. What's up with that?
// I'm adding a guard variable here so I don't call Interrupt() more than once
// for the same qualification.

simulated function OnQualifyInterrupted()
{
    if ( Level.NetMode == NM_Standalone )
    {
        assertWithDescription(false,
            "[tcohen] SwatGamePlayerController::OnQualifyInterrupted() but we're not QualifyingForUse.");
    }
}

simulated function OnQualifyCompleted()
{
    // This isn't a valid assert on the client, since we may complete
    // qualifying on the server and leave the QualifyingForUse state before
    // the client's equipment finishes a valid qualification.
    if ( Level.NetMode != NM_Client )
    {
        assertWithDescription(false,
                              "[tcohen] SwatGamePlayerController::OnQualifyCompleted() but we're not QualifyingForUse.");
    }
}

// Do nothing. Override in QualifyingForUse state below.
function ServerRequestQualifyInterrupt()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerRequestQualifyInterrupt() in global state. Ignoring request." );
}

//it is not an error to call InterruptQualification() when not Qualifying
simulated function AuthorizedInterruptQualification();

// IInterestedInDoorOpening implementation
function NotifyDoorOpening(Door TargetDoor)
{
    assertWithDescription(false,
        "[tcohen] SGPC::NotifyDoorOpening() We only expect to get this notification in state QualifyingForUse.  But we're in the Global state now.");
}

state QualifyingForUse
{
    ignores CanOpenGCI;

    ///////////////////////////////////////////////////////////////////
    simulated function BeginState()
    {
        local EquipmentUsedOnOther theEquipmentUsedOnOther;
        local SwatDoor TargetDoor;

        // Rotate the lower body yaw to match the upper body yaw, so that the
        // upper body qualification animations line up to the intended target.
        SwatPlayer.AnimSnapBaseToAim();

        if (Level.GetEngine().EnableDevTools)
            mplog( self$" entering state 'QualifyingForUse'." );

        Pawn.SetPhysics(PHYS_None);

        HaveCalledInterruptYet = false;
        //don't show a hud preview icon while qualifying
        if ( self == Level.GetLocalPlayerController() )
            GetHUDPage().Reticle.CenterPreviewImage = None;

        // MCJ: Kluge alert! I'm only doing this for equipment that can be
        // used on others for now. Terry and I need to figure out how
        // BeginQualifying() should work for QualifiedUseEquipment that isn't
        // used on an other. This will happen after the Dec. 12 milestone
        // build is done.
        if ( Level.NetMode != NM_Standalone )
        {
            theEquipmentUsedOnOther = EquipmentUsedOnOther(Pawn.GetActiveItem());
            if ( theEquipmentUsedOnOther != None )
                theEquipmentUsedOnOther.BeginQualifying( OtherForQualifyingUse );
        }

        if (Level.NetMode != NM_Client)
        {
            TargetDoor = SwatDoor(OtherForQualifyingUse);
            if (TargetDoor != None)     //qualifying on a door
                TargetDoor.RegisterInterestedInDoorOpening(self);
        }
    }

    function NotifyDoorOpening(Door TargetDoor)
    {
        assert(Level.NetMode != NM_Client); //we shouldn't have registered for this notification on clients in the first place

        InterruptState('');
    }

    ///////////////////////////////////////////////////////////////////
    simulated function EndState()
    {
        local SwatDoor TargetDoor;

        if (Level.GetEngine().EnableDevTools)
            mplog( self$" leaving state 'QualifyingForUse'." );

        Pawn.SetPhysics(PHYS_Walking);

        if (Level.NetMode != NM_Client)
        {
            TargetDoor = SwatDoor(OtherForQualifyingUse);
            if (TargetDoor != None)     //qualifying on a door
                TargetDoor.UnRegisterInterestedInDoorOpening(self);
        }
    }

    ///////////////////////////////////////////////////////////////////
    simulated function PlayerTick(float dTime)
    {
        Global.PlayerTick(dTime);

        if ( self == Level.GetLocalPlayerController() )
            if ( !HaveCalledInterruptYet && bFire == 0)
                PlayerRequestOrInitiateInterrupt();
    }

    simulated function PlayerRequestOrInitiateInterrupt()
    {
        assertWithDescription(Pawn.GetActiveItem().IsA('QualifiedUseEquipment'),
                              "[tcohen] While QualifyingForUse, SwatGamePlayerController found that the Fire button was released.  But the ActiveItem ("$Pawn.GetActiveItem()
                              $") is no longer a QualifiedUseEquipment.");

        HaveCalledInterruptYet = true;

        if (Level.GetEngine().EnableDevTools)
            mplog( self$"......Calling Interrupt() on Item: "$QualifiedUseEquipment(Pawn.GetActiveItem()) );

        QualifiedUseEquipment(Pawn.GetActiveItem()).Interrupt();
    }

    function ServerRequestQualifyInterrupt()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"---SGPC::ServerRequestQualifyInterrupt() in state 'QualifyingForUse'." );

        Assert( Level.NetMode != NM_Client );

        AuthorizedInterruptQualification();
    }

    // Executes on server only
    // We basically want to do here the same thing as ServerRequestQualifyInterrupt().
    simulated function InterruptState(name PendingState)
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"---SGPC::InterruptState() in state 'QualifyingForUse'." );

        AuthorizedInterruptQualification();
    }

    simulated function AuthorizedInterruptQualification()
    {
        if (Level.GetEngine().EnableDevTools)
        {
            mplog( self$"---SGPC::AuthorizedInterruptQualification() in state 'QualifyingForUse'." );
            mplog ( "...HaveCalledInterruptYet="$HaveCalledInterruptYet );
        }

        // The client requested that we interrupt.
        assertWithDescription(Pawn.GetActiveItem().IsA('QualifiedUseEquipment'),
                            "[tcohen] While QualifyingForUse, SwatGamePlayerController found that the Fire button was released.  But the ActiveItem ("$Pawn.GetActiveItem()
                            $") is no longer a QualifiedUseEquipment.");

        HaveCalledInterruptYet = true;
        QualifiedUseEquipment(Pawn.GetActiveItem()).DoInterrupt();
    }

    ///////////////////////////////////////////////////////////////////

    simulated function OnQualifyInterrupted() { Done( false ); }
    simulated function OnQualifyCompleted()   { Done( true );  }

    simulated function Done( bool Completed )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"---SGPC::Done() in state 'QualifyingForUse'. Completed="$Completed );

        if ( Level.NetMode != NM_Client )
        {
            if ( Level.NetMode != NM_Standalone )
                SwatPlayer(Pawn).NotifyClientsOfFinishQualify( OtherForQualifyingUse, Completed );
            GotoState( 'PlayerWalking' );
            ClientGotoState( 'PlayerWalking', 'Begin' );
        }
    }

    ///////////////////////////////////////////////////////////////////

Begin:

    assertWithDescription(Pawn.GetActiveItem().IsA('QualifiedUseEquipment'),
        "[tcohen] SwatGamePlayerController began QualifyingForUse.  But the ActiveItem ("$Pawn.GetActiveItem()
        $") is not a QualifiedUseEquipment.");
}

///////////////////////////////////////////////////////////////////////

simulated function PawnDied(Pawn P)
{
    Super.PawnDied(P);
}

// ----------------------
// Viewport Exec functions
exec function CycleOfficer()
{
    //ViewportManager.CycleOfficerViewport();
}

exec function ShowViewport(string ViewportType)
{
    local string SpecificOfficer;
    local IControllableThroughViewport SavedReplicatedViewportTeammate;

    log("ShowViewport: "$ViewportType);

    if ( !GetHUDPage().ExternalViewport.bVisible )
        bControlViewport = 0;

    if ( Level.NetMode != NM_Standalone )
    {
  		SavedReplicatedViewportTeammate = ReplicatedViewportTeammate;

  		// Ask the server to choose the next viewport teammate. The teammate's
  		// pawn is assigned to the replicated variable
  		// ReplicatedViewportTeammate. OnReplicatedViewportTeammateChanged is
  		// called on the client whenever that variable changes.
  		ServerActivateOfficerViewport( true, ViewportType );

  		// If we're on a listen server, PostNetReceive is not called on us so we'll
  		// never detect a change in ReplicatedViewportTeammate there, like we do
  		// for clients. Therefore, we perform the test here, and just show the
  		// viewport if it's changed.
  		if (Level.NetMode == NM_ListenServer &&
  			SavedReplicatedViewportTeammate != ReplicatedViewportTeammate)
  		{
  			GetHUDPage().ExternalViewport.Show();
  		}
    }
    else
    {
        if ( ViewportManager.HasOfficers( ViewportType ) )
        {
            if ( ViewportType ~= "sniper" && !(ViewportManager.GetFilter() ~= "sniper") )
			{	// SEF: only go to the sniper viewport if we don't have the sniper filter up
                SpecificOfficer = SniperAlertFilter;
			}


            GetHUDPage().ExternalViewport.Show();
            ViewportManager.ShowViewport(ViewportType, SpecificOfficer);

            if (ActiveViewport != None)
            {
                if (ViewportType == "Red")
                    SetPlayerCommandInterfaceTeam('RedTeam');
                else
                if (ViewportType == "Blue")
                    SetPlayerCommandInterfaceTeam('BlueTeam');
            }
        }
    }
}

exec function HideViewport()
{
    if ( Level.NetMode == NM_Client )
    {
        ServerActivateOfficerViewport( false );
    }

    HideViewportInternal();
}

simulated private function HideViewportInternal()
{
    // Clear the filter...
    ViewportManager.SetFilter("");
    ViewportManager.HideViewport();
    GetHUDPage().ExternalViewport.Hide();
    bControlViewport = 0;
    ActivateViewport(None);
}

function ExternalViewportManager GetExternalViewportManager()
{
    return ViewportManager;
}

function OnSniperTimerEnded()
{
    SniperAlertTimer.Destroy();
    SniperAlertTimer = None;
    SniperAlertFilter = "";
}

function OnSniperAlerted(SniperPawn AssociatedSniper)
{
    // If there's an active SniperAlertTimer kill it
    if ( SniperAlertTimer != None )
        OnSniperTimerEnded();

    SniperAlertTimer = Spawn(class'Timer');
    assert(SniperAlertTimer!= None);

    // Start the timer for how long the alert lasts
    SniperAlertTimer.TimerDelegate = OnSniperTimerEnded;
    SniperAlertTimer.StartTimer( SniperAlertTime );
    SniperAlertFilter = string(AssociatedSniper.Name);

    ClientMessage("",'SniperAlerted');
}

function IssueMessage(string Message, name Type)
{
    Log("IssueMessage: "$Message);
    ClientMessage(Message, Type);
}

exec function ToggleSpeechManager()
{
  Level.GetEngine().SpeechManager.ToggleSpeech();
  if(Level.GetEngine().SpeechManager.IsEnabled()) {
    ClientMessage("[c=FFFFFF]Speech Recognition enabled", 'SpeechManagerNotification');
  } else {
    ClientMessage("[c=FFFFFF]Speech Recognition disabled", 'SpeechManagerNotification');
  }
}

// ----------------------

//for debugging only!  Normal gameplay should call Interact()
exec function Use()
{
    local ReactiveWorldObject Candidate;

    ClientMessage("Using!");

    foreach RadiusActors(class'ReactiveWorldObject', Candidate, 400)
            Candidate.ReactToUsed(self);
}

//for debugging only!
exec function UseAmmo(string newAmmoClass)
{
    local FiredWeapon Weapon;
    local class<Ammunition> AmmoClass;
    local Ammunition Ammo;

    Weapon = FiredWeapon(Pawn.GetActiveItem());
    assertWithDescription(Weapon != None,
        "[tcohen] UseAmmo: Pawn's ActiveItem isn't a FiredWeapon.");

    newAmmoClass = "SwatAmmo."$newAmmoClass;

    AmmoClass = class<Ammunition>(DynamicLoadObject(newAmmoClass, class'class'));
    assertWithDescription(AmmoClass != None,
        "[tcohen] UseAmmo: couln't load the ammunition class "$newAmmoClass$".");

    Ammo = Spawn(AmmoClass, Weapon);  //owned by weapon

    AssertWithDescription(Ammo != None,
        "[tcohen] UseAmmo: failed to spawn ammunition of class "$AmmoClass$".");

    Weapon.Ammo = Ammo;

    Weapon.Ammo.InitializeAmmo(8);
}

//for debugging only!
exec function AddRegionInjury(ESkeletalRegion Region)
{
    local SkeletalRegionInformation SkeletalRegionInformation;
    local float LimbInjuryAimErrorPenalty;

    SkeletalRegionInformation = Pawn.GetSkeletalRegionInformation(Region);

    AssertWithDescription(SkeletalRegionInformation.AimErrorPenalty.Min == SkeletalRegionInformation.AimErrorPenalty.Max,
        "AddRegionInjury: The AimErrorPenalty for the "$Region
        $" SkeletalRegion randomly varies from "$SkeletalRegionInformation.AimErrorPenalty.Min
        $" to "$SkeletalRegionInformation.AimErrorPenalty.Max
        $", so the result of TakeHit() will not be deterministic.");

    LimbInjuryAimErrorPenalty = RandRange(SkeletalRegionInformation.AimErrorPenalty.Min, SkeletalRegionInformation.AimErrorPenalty.Max);
    Pawn.AccumulatedLimbInjury += LimbInjuryAimErrorPenalty;

    log("AddRegionInjury:   Region="$GetEnum(ESkeletalRegion, int(Region)));
    log("...                SkeletalRegionInformation.AimErrorPenalty=(Min="$SkeletalRegionInformation.AimErrorPenalty.Min$", Max="$SkeletalRegionInformation.AimErrorPenalty.Max$")");
    log("...                LimbInjuryAimErrorPenalty="$LimbInjuryAimErrorPenalty);
    log("...                Pawn.AccumulatedLimbInjury="$Pawn.AccumulatedLimbInjury);
}

simulated function Possess(Pawn NewPawn)
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::Possess() called. Pawn="$Pawn );

    Super.Possess(NewPawn);

    SwatPlayer = SwatPlayer(NewPawn);
    AssertWithDescription(SwatPlayer != None,
        "[tcohen] SwatPlayerController::Possess("$NewPawn$") NewPawn is not a SwatPlayer.");

    // If we're on a server or in a standalone game, initialize the hands
    // here. Otherwise (on a network client), initialize them in
    // SwatPlayer::PostNetBeginPlay().
    if ( self == Level.GetLocalPlayerController() )
    {
        assert( Level.NetMode != NM_Client );
        SwatPlayer.InitializeHands();
    }
}


simulated private function InternalEquipSlot(coerce EquipmentSlot Slot)
{
    local HandheldEquipment PendingItem;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::InternalEquipSlot(). Slot="$Slot );

    // If we have no Pawn, or our Pawn is dead, then we can't Equip
    if ( SwatPlayer == None || class'Pawn'.static.CheckDead( SwatPlayer ))
        return;

    // We don't want the player to be able to equip if he's currently under
    // the influence of nonlethals.
    if ( SwatPlayer.IsNonlethaled() )
        return;

    // And we also don't want them to be able to equip while they are in the
    // process of prepping or throwing a grenade.
    if ( SwatPlayer.IsInProcessOfThrowing() )
        return;

	// We can't equip anything except a secondary weapon if we have the smash and grab case
	if (Slot != SLOT_SecondaryWeapon && NetPlayer(SwatPlayer) != None && NetPlayer(SwatPlayer).HasTheItem())
		return;

    PendingItem = SwatPlayer.GetPendingItem();
    if ( PendingItem != None && PendingItem.GetSlot() == Slot)
        return;     //already in the process of equipping that

    // If the player has none of the requested item then
    //  show a message on the HUD
    if ( SwatPlayer.GetEquipmentAtSlot(Slot) == None )
        ClientMessage(string(int(Slot)), 'EquipNotAvailable');

    if ( SwatPlayer.ValidateEquipSlot( Slot ))
    {
        SetZoom(false, true);

        if (Level.GetEngine().EnableDevTools)
            mplog( "...calling ServerRequestEquip()." );

        SwatPlayer.ServerRequestEquip( Slot );
    }
}

simulated function bool CheckDoorLock(SwatDoor Door)
{
  return Door.TryDoorLock(self);
}

simulated function InternalMelee(optional bool UseMeleeOnly, optional bool UseCheckLockOnly, optional bool UseGiveItemOnly)
{
	local HandheldEquipment Item;
  local HandheldEquipment PendingItem;
  local Actor Candidate;
  local vector HitLocation, HitNormal, CameraLocation, TraceEnd;
  local rotator CameraRotation;
  local Material HitMaterial;

	if (Level.GetEngine().EnableDevTools)
        log( "...in SwatGamePlayerController::InternalMelee()" );

	// We don't want the player to be able to melee if he's currently under
    // the influence of nonlethals.
    if ( SwatPlayer.IsNonlethaled() )
        return;

	// And we also don't want them to be able to melee while they are in the
    // process of prepping or throwing a grenade.
    if ( SwatPlayer.IsInProcessOfThrowing() )
        return;

	Item = Pawn.GetActiveItem();
	PendingItem = SwatPlayer.GetPendingItem();

	// TSS bugfix: don't allow us to melee while changing weapons --eez
	if(PendingItem != None && PendingItem != Item)
	{
	    return;
	}

	if(WantsZoom)
	    return; // Not allowed while zooming

	// Determine if we are trying to check the lock or if we are trying to punch someone
	CalcViewForFocus(Candidate, CameraLocation, CameraRotation);
	TraceEnd = CameraLocation + vector(CameraRotation) * (Item.MeleeRange / 2.0);
	foreach TraceActors(
	    class'Actor',
	    Candidate,
	    HitLocation,
	    HitNormal,
	    HitMaterial,
	    TraceEnd,
	    CameraLocation
	    )
	{
		if(((!UseMeleeOnly && !UseCheckLockOnly) || !SpecialInteractionsDisabled) &&
			(Candidate.IsA('SwatPlayer') || Candidate.IsA('SwatOfficer')))
		{
			if(TryGiveItem(SwatPawn(Candidate)))
			{
				return;
			}
		}
	    else if(((!UseMeleeOnly && !UseGiveItemOnly) || !SpecialInteractionsDisabled) &&
			Candidate.IsA('SwatPawn'))
	    {
	    	break; // We intend to melee.
	    }
	    else if(!SpecialInteractionsDisabled &&
			Candidate.IsA('DoorModel'))
	    {
	      if(CheckDoorLock(DoorModel(Candidate).Door))
	        return;
	    }
	}

	if(UseCheckLockOnly || UseGiveItemOnly)
		return; // we were actually using the Check Lock or Give Item dedicated commands

	if (!Item.bAbleToMelee)
		return;

	if ( SwatPlayer.ValidateMelee() )
	{
		if (Level.GetEngine().EnableDevTools)
            mplog( "...calling ServerRequestMelee()." );

		SwatPlayer.ServerRequestMelee( SwatPlayer.GetActiveItem().GetSlot() );
	}
}

// We just received a new piece of equipment. Deal with it!
function ClientSentOrReceivedEquipment()
{
	GetHUDPage().UpdateWeight();
	SwatPlayer.GetActiveItem().UpdateHUD();
}

// Tries to give the currently equipped item to a SwatOfficer/SwatPlayer.
// Returns true if we should halt the melee trace
simulated function bool TryGiveItem(SwatPawn Other)
{
	local HandheldEquipment ActiveItem;
	
	local float AddedWeight;
	local float AddedBulk;

	ActiveItem = SwatPlayer.GetActiveItem();

	// If we aren't allowed to pass the item, continue with the trace
	if(!ActiveItem.AllowedToPassItem())
	{
		log("Tried to give "$ActiveItem$" to "$Other$" but failed because NotAllowedToPassItem");
		return false;
	}

	// If the target is unconscious, continue with the trace
	if(!class'Pawn'.static.checkConscious(Other))
	{
		return false;
	}

	AssertWithDescription(Other != SwatPlayer, "Somehow, you tried to give the item '"$ActiveItem$"' to yourself. How did you do this?");
	if(Other == SwatPlayer)
	{
		// just die I guess
		return false;
	}
	// From this point on, we will --always-- block the trace

	AddedWeight = ActiveItem.GetWeight();
	AddedBulk = ActiveItem.GetBulk();
	if(AddedWeight + Other.GetTotalWeight() > Other.GetMaximumWeight())
	{
		// this item adds too much weight, tell the client but still block the trace
		ClientMessage(Other.GetHumanReadableName()$"\t"$ActiveItem.GetFriendlyName(), 'CantGiveTooMuchWeight');
		return true;
	}
	else if(AddedBulk + Other.GetTotalBulk() > Other.GetMaximumBulk())
	{
		// this item adds too much bulk, tell the client but still block the trace
		ClientMessage(Other.GetHumanReadableName()$"\t"$ActiveItem.GetFriendlyName(), 'CantGiveTooMuchBulk');
		return true;
	}

	/////////////////////////////////////////////////////////////////
	//
	//	Give the other person the equipment
	//	When we give the other person equipment, it does not get assigned to a pocket.
	//	This is because it is only temporarily in our inventory.

	// Don't give the other person an optiwand if they already have one
	if(ActiveItem.IsA('Optiwand'))
	{
		if((SwatPlayer(Other) != None && SwatPlayer(Other).GetEquipmentAtSlot(Slot_Optiwand) != None) ||
			(SwatOfficer(Other) != None && SwatOfficer(Other).GetItemAtSlot(Slot_Optiwand) != None))
		{
			// the other player has an optiwand already, don't give it to them
			ClientMessage("", 'CantGiveAlreadyHasOptiwand');
			return true;
		}

	}

	ServerGiveItem(Other);
	return true;
}

function ServerGiveItem(SwatPawn Other)
{
    local HandheldEquipment NewItem;
    local HandheldEquipment ActiveItem;

    ActiveItem = SwatPlayer.GetActiveItem();

    mplog("Given item was "$ActiveItem);

    // Spawn in the actual equipment and give it to the other player
    Other.GivenEquipmentFromPawn(class<HandheldEquipment>(ActiveItem.static.GetGivenClass()));

    /////////////////////////////////////////////////////////////////
    //
    //  Remove the equipment from our inventory
    //  All we need to do is reduce the available count by 1
    ActiveItem.DecrementAvailableCount();
    if(!ActiveItem.IsAvailable())
    {
        // Switch to another weapon
        EquipNextSlot();
        ActiveItem.UnequippedHook();
    }

    ////////////////////////////////////////////////////////////////
    //
    //  Tell the client we gave our equipment away
    ClientMessage(ActiveItem.GetGivenEquipmentName()$"\t1\t"$Other.GetHumanReadableName(), 'GaveEquipment');
    if(Other.IsA('SwatPlayer'))
    {
        SwatGamePlayerController(Other.Controller).ClientMessage(
            ActiveItem.GetGivenEquipmentName()$"\t1\t"$SwatPlayer.GetHumanReadableName(), 'GaveYouEquipment');
        SwatGamePlayerController(Other.Controller).ClientSentOrReceivedEquipment();
    }
    ClientSentOrReceivedEquipment();
}

// Overridden from PlayerController::Reload().
simulated function InternalReload()
{
    local FiredWeapon Weapon;

    if (Level.GetEngine().EnableDevTools)
        log( "...in SwatGamePlayerController::InternalReload()" );

    // We don't want the player to be able to reload if he's currently under
    // the influence of nonlethals.
    if ( SwatPlayer.IsNonlethaled() )
        return;

    // And we also don't want them to be able to reload while they are in the
    // process of prepping or throwing a grenade.
    if ( SwatPlayer.IsInProcessOfThrowing() )
        return;

    Weapon = FiredWeapon(Pawn.GetActiveItem());

    if (Weapon.Ammo.IsFull()) return;   //can't reload a weapon when it is full

    if  (
            Weapon == None
        ||  (   //can't reload round-based weapons that are full
                Weapon.IsA('RoundBasedWeapon')
            &&  Weapon.Ammo.IsFull()
            )
        )
        return;

    if ( SwatPlayer.ValidateReload() )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...calling ServerRequestReload()." );

        SwatPlayer.ServerRequestReload( SwatPlayer.GetActiveItem().GetSlot() );
    }
}

//called from SwatPlayer::OnReloadingFinished()
simulated function ConsiderAutoReloading()
{
    if (bReload > 0)
        Reload();
}

simulated exec function EquipSlot(int Slot)
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::EquipSlot(). Slot="$Slot );

// dbeswick: integrated 20/6/05
    // Don't let the player manually equip IAmCuffed; this happens automatically
    // when the pawn is arrested, and if the player is able to do this manually
    // then he can cheat in MP by appearing to be arrested when he isn't.
    //
    // This function is not called when you are arrested (OnArrestedBegan() uses
    // a different mechanism for equipping the IAmCuffed), only when you switch
    // equipment manually by using the "EquipSlot XXX" console command (which is
    // is bound to various keys in User.ini).
    if (EquipmentSlot(Slot) == Slot_IAmCuffed)
    {
        mplog( self$"---SGPC::EquipSlot(). Player tried to manually equip IAmCuffed; preventing this" );
        return;
    }


    InternalEquipSlot(EquipmentSlot(Slot));
}

simulated exec function EquipNextSlot()
{
    local HandheldEquipment ActiveItem;
    local EquipmentSlot CurrentSlot;

    ActiveItem = Pawn.GetActiveItem();

    if( ActiveItem != None )
        CurrentSlot = ActiveItem.GetSlot();

    if( CurrentSlot == Slot_PrimaryWeapon )
        InternalEquipSlot( Slot_SecondaryWeapon );
    else
        InternalEquipSlot( Slot_PrimaryWeapon );
}

simulated exec function EquipPrevSlot()
{
    local HandheldEquipment ActiveItem;
    local EquipmentSlot CurrentSlot;

    ActiveItem = Pawn.GetActiveItem();

    if( ActiveItem != None )
        CurrentSlot = ActiveItem.GetSlot();

    if( CurrentSlot == Slot_SecondaryWeapon )
        InternalEquipSlot( Slot_PrimaryWeapon );
    else
        InternalEquipSlot( Slot_SecondaryWeapon );
}

simulated function PlayerFocusInterface GetFocusInterface(EFocusInterface FocusInterface)
{
    return FocusInterfaces[int(FocusInterface)];
}

simulated function CommandInterface GetCommandInterface()
{
    return CurrentCommandInterface;
}

// clear the "held command" (placed here so it can be called from AICommon)
simulated function ClearHeldCommand(Actor Team)
{
	CurrentCommandInterface.ClearHeldCommand(OfficerTeamInfo(Team));
}

// clear the "held command" caption display (placed here so it can be called from AICommon)
simulated function ClearHeldCommandCaptions(Actor Team)
{
	CurrentCommandInterface.ClearHeldCommandCaptions(OfficerTeamInfo(Team));
}

///////////////////////////////////////////////////////////////////////////////
// Arrests the SwatPawn that is the default focus, if there is one.
// Note: this is just for testing purposes during development, and isn't
// meant to be used in the shipping game.
exec function Arrest()
{
    local SwatPawn thePawn;

    //log( "   FireInterface="$GetFocusInterface(Focus_Fire) );
    //log( "      GetDefaultFocusActor()="$GetFocusInterface(Focus_Fire).GetDefaultFocusActor() );

    thePawn = SwatPawn(GetFocusInterface(Focus_Fire).GetDefaultFocusActor());
    //log( "   thePawn="$thePawn );
    //log( "   thePawn.CanBeArrestedNow()="$thePawn.CanBeArrestedNow() );
    if ( thePawn != None && thePawn.CanBeArrestedNow() )
    {
        thePawn.OnArrestBegan( SwatPlayer );
    }
}

///////////////////////////////////////////////////////////////////////////////
// Finishes the arrest that was begun using the above function. The parameter
// should be true if the arrest succeeded and false if it failed.
// Note: this is just for testing purposes during development, and isn't
// meant to be used in the shipping game. In particular, no sanity checking is
// done to make sure that this is only called on pawns for which arresting has
// already been initiated.
exec function FinishArrest( bool Success )
{
    local SwatPawn thePawn;

    thePawn = SwatPawn(GetFocusInterface(Focus_Fire).GetDefaultFocusActor());
    if ( thePawn != None )
    {
        if ( Success )
            thePawn.OnArrested( SwatPlayer );
        else
            thePawn.OnArrestInterrupted( SwatPlayer );
    }
}


exec function Interact()
{
    if (!class'Pawn'.static.CheckDead(Pawn))
        UseInterface(GetFocusInterface(Focus_Use)).Interact();
}


// This is only called to initiate the throwing process for the local player
// throwing.
simulated function Throw()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::Throw()." );

    ServerRequestThrowPrep();
}


// Executes only on server.
function ServerRequestThrowPrep()
{
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;
    local SwatPlayer PawnWhoIsThrowing;
    local ThrownWeapon theItem;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerRequestThrowPrep()." );

    PawnWhoIsThrowing = SwatPlayer;
    if ( !PawnWhoIsThrowing.CanThrowPrep() )
        return;

    theItem = ThrownWeapon( PawnWhoIsThrowing.GetActiveItem() );
    if ( theItem == None || !theItem.IsIdle() )
        return;

    // Walk the controller list here to notify all clients about the
    // ThrowPrep, except don't make the call for the server and don't make it
    // for the client who is throwing.
    if ( Level.NetMode != NM_Standalone )
    {
        theLocalPlayerController = Level.GetLocalPlayerController();
        for ( i = Level.ControllerList; i != None; i = i.NextController )
        {
            current = SwatGamePlayerController( i );
            if ( current != None && current != theLocalPlayerController )
            {
                if (Level.GetEngine().EnableDevTools)
                    mplog( "...on server: calling ClientThrowPrep() on "$current$", PawnWhoIsThrowing="$PawnWhoIsThrowing );

                current.ClientThrowPrep( PawnWhoIsThrowing );
            }
        }
    }

    // Then start it here on the server.
    SwatPlayer(Pawn).GotoState('ThrowingPrep');
}


// Do we need to check the pawn to make sure it's in an o.k. state to start throwing?
simulated function ClientThrowPrep( SwatPlayer PawnWhoIsThrowing )
{
    local ThrownWeapon Grenade;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientThrowPrep(). PawnWhoIsThrowing="$PawnWhoIsThrowing );

    if ( PawnWhoIsThrowing != None )
    {
        if ( PawnWhoIsThrowing.CanThrowPrep() )
        {
            Grenade = ThrownWeapon(PawnWhoIsThrowing.GetActiveItem());
            if ( Grenade != None && Grenade.IsIdle() )
                PawnWhoIsThrowing.GotoState( 'ThrowingPrep' );
        }
    }
}


// Executes only on server.
function ServerEndThrow( float ThrowHeldTime )
{
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;
    local SwatPlayer PawnWhoIsThrowing;

    // This is called by the SwatPlayer.

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerEndThrow(). ThrowHeldTime="$ThrowHeldTime );

    // Walk the controller list here to notify all clients about the
    // EndThrow.

    // Walk the controller list here to notify all clients about the
    // ThrowPrep, except don't make the call for the server and don't make it
    // for the client who is throwing.
    if ( Level.NetMode != NM_Standalone )
    {
        PawnWhoIsThrowing = SwatPlayer;

        theLocalPlayerController = Level.GetLocalPlayerController();
        for ( i = Level.ControllerList; i != None; i = i.NextController )
        {
            current = SwatGamePlayerController( i );
            if ( current != None && (current != self) && (current != theLocalPlayerController) )
            {
                if (Level.GetEngine().EnableDevTools)
                    mplog( self$"...on server: calling ClientEndThrow() on "$current$", PawnWhoIsThrowing="$PawnWhoIsThrowing );

                current.ClientEndThrow( PawnWhoIsThrowing, ThrowHeldTime );
            }
        }
    }

    // Now tell the pawn to finish the throw.
    SwatPlayer(Pawn).EndThrow( ThrowHeldTime );
}


simulated function ClientEndThrow( SwatPlayer PawnWhoIsThrowing, float ThrowHeldTime )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientEndThrow(). PawnWhoIsThrowing="$PawnWhoIsThrowing$", ThrowHeldTime="$ThrowHeldTime );

    if ( PawnWhoIsThrowing != None && ThrownWeapon(PawnWhoIsThrowing.GetActiveItem()) != None )
    {
        PawnWhoIsThrowing.EndThrow( ThrowHeldTime );
    }
}


function ClientOnLoggedIn(optional EMPMode CurrentGameMode)
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientOnLoggedIn()." );

//    log( "   Level="$Level );
//    log( "   Repo="$Level.GetRepo() );
//    log( "   SwatRepo="$Repo );

    Repo.PostPlayerLogin( self, CurrentGameMode );
}


simulated function SetMPLoadOut( DynamicLoadOutSpec LoadOut )
{
    local int i;

    // This just walks the LoadOut and sends the contents of each pocket to
    // the server.
    //mplog( self$"---SGPC::SetMPLoadOut(). LoadOut="$LoadOut );
    SetMPLoadOutPocketWeapon( Pocket_PrimaryWeapon, LoadOut.LoadOutSpec[Pocket.Pocket_PrimaryWeapon], LoadOut.LoadOutSpec[Pocket.Pocket_PrimaryAmmo] );

    SetMPLoadOutPocketWeapon( Pocket_SecondaryWeapon, LoadOut.LoadOutSpec[Pocket.Pocket_SecondaryWeapon], LoadOut.LoadOutSpec[Pocket.Pocket_SecondaryAmmo] );

    SetMPLoadOutPrimaryAmmo(LoadOut.GetPrimaryAmmoCount());
    SetMPLoadOutSecondaryAmmo(LoadOut.GetSecondaryAmmoCount());

    log("Loadout ammo: Primary ("$LoadOut.GetPrimaryAmmoCount()$"), secondary ("$LoadOut.GetSecondaryAmmoCount()$")");

    for( i = 4; i < Pocket.EnumCount; i++ )
    {
		if( Pocket(i) == Pocket_CustomSkin )
			SetMPLoadOutPocketCustomSkin( Pocket(i), String(LoadOut.LoadOutSpec[i]) );
		else
			SetMPLoadOutPocketItem( Pocket(i), LoadOut.LoadOutSpec[i] );
    }

    ServerSetMPLoadOutSpecComplete();

	//dkaplan - ugly ugly ugly HACK HACK Hack
	if( self == Level.GetLocalPlayerController() )
		UpdateVoiceType();
}

simulated function SetMPLoadOutPrimaryAmmo(int Amount) {
  ServerSetMPLoadOutPrimaryAmmo(Amount);
}

simulated function SetMPLoadOutSecondaryAmmo(int Amount) {
  ServerSetMPLoadOutSecondaryAmmo(Amount);
}

simulated function SetMPLoadOutPocketWeapon( Pocket Pocket, class<actor> WeaponItem, class<actor> AmmoItem )
{
    //mplog( self$"---SGPC::SetMPLoadOutPocketWeapon(). Pocket="$Pocket$", WeaponItem="$WeaponItem$", AmmoItem="$AmmoItem );
    ServerSetMPLoadOutPocketWeapon( Pocket, WeaponItem, AmmoItem );
}


simulated function SetMPLoadOutPocketCustomSkin( Pocket Pocket, String CustomSkinClassName )
{
	//mplog( self$"---SGPC::SetMPLoadOutPocketWeapon(). Pocket="$Pocket$", CustomSkinClassName="$CustomSkinClassName );
    ServerSetMPLoadOutPocketCustomSkin( Pocket, CustomSkinClassName );
}


simulated function SetMPLoadOutPocketItem( Pocket Pocket, class<actor> Item )
{
    //mplog( self$"---SGPC::SetMPLoadOutPocketItem(). Pocket="$Pocket$", Item="$Item );

    assert( Pocket != Pocket_PrimaryWeapon );
    assert( Pocket != Pocket_PrimaryAmmo );
    assert( Pocket != Pocket_SecondaryWeapon );
    assert( Pocket != Pocket_SecondaryAmmo );
    ServerSetMPLoadOutPocketItem( Pocket, Item );
}

// Executes only on the server
function ServerSetMPLoadOutPrimaryAmmo(int Amount)
{
  SwatRepoPlayerItem.SetPrimaryAmmoCount(Amount);
}

// Executes only on the server
function ServerSetMPLoadOutSecondaryAmmo(int Amount)
{
  SwatRepoPlayerItem.SetSecondaryAmmoCount(Amount);
}

// Executes only on the server
function ServerSetMPLoadOutPocketWeapon( Pocket Pocket, class<actor> WeaponItem, class<actor> AmmoItem )
{
    //mplog( self$"---SGPC::ServerSetMPLoadOutPocketWeapon(). Pocket="$Pocket$", WeaponItem="$WeaponItem$", AmmoItem="$AmmoItem );
    if( WeaponItem == None || AmmoItem == None )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...weaponitem or ammoitem was None. Returning..." );

        return;
    }
    assert( Pocket == Pocket_PrimaryWeapon || Pocket == Pocket_SecondaryWeapon );

    // We don't have a Pawn at this point, so just set it in the RepoItem.
    if ( Pocket == Pocket_PrimaryWeapon )
    {
        SwatRepoPlayerItem.SetPocketItemClass( Pocket_PrimaryWeapon, WeaponItem );
        SwatRepoPlayerItem.SetPocketItemClass( Pocket_PrimaryAmmo, AmmoItem );
    }
    else
    {
        SwatRepoPlayerItem.SetPocketItemClass( Pocket_SecondaryWeapon, WeaponItem );
        SwatRepoPlayerItem.SetPocketItemClass( Pocket_SecondaryAmmo, AmmoItem );
    }
}


function ServerSetMPLoadOutPocketCustomSkin( Pocket Pocket, String CustomSkinClassName )
{
	SwatRepoPlayerItem.SetPocketItemClass( Pocket_CustomSkin, None );
	SwatRepoPlayerItem.SetCustomSkinClassName( CustomSkinClassName );
}


// Executes only on the server
function ServerSetMPLoadOutPocketItem( Pocket Pocket, class<actor> Item )
{
    //mplog( self$"---SGPC::ServerSetMPLoadOutPocketItem(). Pocket="$Pocket$", Item="$Item );

    //NOTE: None may be valid!!!!!
    //if( Item == None )
    //    return;
    assert( Pocket != Pocket_PrimaryWeapon );
    assert( Pocket != Pocket_PrimaryAmmo );
    assert( Pocket != Pocket_SecondaryWeapon );
    assert( Pocket != Pocket_SecondaryAmmo );

    // We don't have a Pawn at this point, so just set it in the RepoItem.
    SwatRepoPlayerItem.SetPocketItemClass( Pocket, Item );
}

// Executes only on the server
function ServerSetMPLoadOutSpecComplete()
{
    //mplog( self$"---SGPC::ServerSetMPLoadOutSpecComplete()." );
    SwatRepoPlayerItem.SetReadyToSpawn();
}

//this will call an RPC on the server to set the voice type for this player
simulated function UpdateVoiceType()
{
//log( self$"::UpdateVoiceType()" );
    ServerSetVoiceType( SwatRepo(Level.GetRepo()).GuiConfig.GetVoiceTypeForCurrentPlayer() );
}

//executes only on the server, sets the voice type for the current player
function ServerSetVoiceType( eVoiceType inVoiceType )
{
//log( self$"::ServerSetVoiceType() .. inVoiceType = "$inVoiceType );
    VoiceType = inVoiceType;

    //update the voice type of the current NetPlayer, if applicable
    if( Pawn != None && Pawn.IsA('NetPlayer') )
        NetPlayer(Pawn).VoiceType = VoiceType;
}

simulated function ClientDestroyPawnsForRespawn( int TeamID )
{
    local SwatGameReplicationInfo SGRI;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientDestroyPawnsForRespawn(). TeamID="$TeamID );

    SGRI = SwatGameReplicationInfo(GameReplicationInfo);
    if( SGRI != None )
    NetTeam(SGRI.Teams[TeamID]).DestroyPawnsForRespawn();
}

// dbeswick: stats
function ServerRetryStatsAuth()
{
	SwatPlayerReplicationInfo(PlayerReplicationInfo).bStatsRequestSent = false;
}

///////////////////////////////////////

simulated function ClientAITriggerEffectEvent(
    SwatAI SwatAI,
    string UniqueIdentifier,
    string EffectEvent,                   //The name of the effect event to trigger.  Should be a verb in past tense, eg. 'Landed'.
    // -- Optional Parameters --        // -- Optional Parameters --
    optional Actor Other,               //The "other" Actor involved in the effect event, if any.
    optional Material TargetMaterial,   //The Material involved in the effect event, eg. the matterial that a 'BulletHit'.
    optional vector HitLocation,        //The location in world-space (if any) at which the effect event occurred.
    optional rotator HitNormal,         //The normal to the involved surface (if any) at the HitLocation.
    optional bool PlayOnOther,          //If true, then any effects played will be associated with Other rather than Self.
    optional string ReferenceTag,
    optional bool MoveMouth,            //If true, the AI will move its mouth for the duration of the effect
    optional int Seed)                  //seed value used for determining effect responses
{
    if (SwatAI == None)
    {
        SwatAI = SwatAI(FindByUniqueID(None, UniqueIdentifier));
    }

    if (SwatAI != None)
    {
        SwatAI.AITriggerEffectEvent(name(EffectEvent), Other, TargetMaterial, HitLocation, HitNormal, PlayOnOther, name(ReferenceTag), MoveMouth, Seed);
    }
}

function ServerOnEffectStopped( SwatAI SourceActor,
                                String UniqueIdentifier,
                                string EffectName,
                                int Seed )
{
    if (SourceActor == None)
    {
        SourceActor = SwatAI(FindByUniqueID(None, UniqueIdentifier));
    }

    if (SourceActor != None)
    {
        SourceActor.ServerOnEffectStopped( EffectName, Seed );
    }
}

///////////////////////////////////////

// This is the state a player controller will be in when it first enters a
// multiplayer game. From there, the player can choose gear, and if
// multiplayer, choose a team.

auto state NetPlayerLimbo
{
    exec function Fire()
    {
        // Intentionally empty
    }

    exec function AltFire()
    {
        // Intentionally empty
    }

    exec function Use()
    {
        // Intentionally empty
    }
}

///////////////////////////////////////

function WasKilledBy(Controller Other)
{
    if (SwatGameInfo(Level.Game) != None)
    {
        SwatGameInfo(Level.Game).GameEvents.PlayerDied.Triggered(Self, Other);
	}
}

///////////////////////////////////////

simulated function SetKillerLocation(vector inKillerLocation)
{
    KillerLocation = inKillerLocation;
    bIsKillerLocationValid = true;
}

///////////////////////////////////////

simulated function StartDeathCam()
{
    bShouldStartDeathCam = true;
}

///////////////////////////////////////

simulated function ForceObserverTimerCallback();

state Dead
{
    function BeginState()
    {
        Super.BeginState();

        // Make sure the officerviewports are invisible if the pawn
        // that died was the player
        if (self == Level.GetLocalPlayerController())
            HideViewport();

        // Set up the beginning death cam view
        PrepareDeathCam();
        // If StartDeathCam() was called before we got into this state, call
        // Dead::StartDeathCam() now.
        if (bShouldStartDeathCam)
        {
            StartDeathCam();
            bShouldStartDeathCam = false;
        }

	    if( self == Level.GetLocalPlayerController() && HasHudPage() )
		    GetHUDPage().OnPlayerDied();

        if( ForceObserverTimer != None )
        {
            ForceObserverTimer.StartTimer(ForceObserverTime);
        }
    }

    function EndState()
    {
        bIsDeathCamRunning = false;
    }

    // Sets the beginning rotation for the death cam
    function PrepareDeathCam()
    {
        // Start out facing the front of the ViewTarget
        DeathCamStartRotation.Yaw   = ViewTarget.Rotation.Yaw + 32768;
        DeathCamStartRotation.Pitch = 0;

        // The end rotation is not finalized until StartDeathCam() is called.

        // Set the death cam start & end distances
        DeathCamStartDistance = ViewTarget.Default.CollisionRadius * kDeathCamStartDistanceScale;
        DeathCamEndDistance   = ViewTarget.Default.CollisionRadius * kDeathCamEndDistanceScale;

        // We want to allow the death cam to get close to the viewtarget, it
        // will zoom out over time
        bBlockCloseCamera = false;
    }

    // Sets the end rotation for the death cam, and starts the death cam
    // sequence.
    function StartDeathCam()
    {
        local bool bEndRotationWasFound;
        local vector  KillerDirection;
        local rotator KillerDirectionRotator;

        if (!bIsDeathCamRunning)
        {
            // Set the death cam end rotation
        if (bIsKillerLocationValid)
        {
            // Use a yaw that points toward the killer's location.
            KillerDirection = KillerLocation - ViewTarget.Location;
            if (KillerDirection.X != 0.0 || KillerDirection.Y != 0.0)
            {
                    KillerDirectionRotator    = rotator(KillerDirection);
                    DeathCamEndRotation.Yaw   = KillerDirectionRotator.Yaw;
                    DeathCamEndRotation.Pitch = KillerDirectionRotator.Pitch;
                    // Only add the extra down-pitch if the killer direction pitch
                    // is less than 45 degrees up. Otherwise, if the killer is far
                    // above us, the extra down-pitch might tilt the camera too low.
                    if (WrapAngleNegPiToPi(DeathCamEndRotation.Pitch) < (65536 / 8))
                    {
                        DeathCamEndRotation.Pitch += kDeathCamEndRotationDownPitch;
                    }

                bEndRotationWasFound      = true;
            }

                // Set bIsKillerLocationValid back to false, for the next death cam
                bIsKillerLocationValid = false;
        }

        if (!bEndRotationWasFound)
        {
            // No valid killer location. End up facing the back of the
            // ViewTarget, with a slight pitch
            DeathCamEndRotation.Yaw   = ViewTarget.Rotation.Yaw;
                DeathCamEndRotation.Pitch = kDeathCamEndRotationDownPitch;
        }

            // Start the death cam sequence
            bIsDeathCamRunning = true;
            DeathCamStartTimeSeconds = Level.TimeSeconds;
        }
    }

    exec function Fire()
    {
        if (Level.NetMode == NM_Standalone)
        {
            Super.Fire();
        }
        else
        {
            // If multiplayer, if the death cam is zoomed all the way out,
            // allow dead players to view through teammates' eyes.
            if (GetDeathCamZoomAlpha() == 1.0)
            {
                if (Level.GetEngine().EnableDevTools)
                    mplog(self$"--Dead::Fire() ... calling ForceObserverCam");

                ForceObserverCam();
            }
        }
    }

    simulated function ForceObserverTimerCallback()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog(self$"--Dead::ForceObserverTimerCallback() ... calling ForceObserverCam");

        ForceObserverCam();
    }

    function CalcBehindView(out vector CameraLocation, out rotator CameraRotation, float Dist)
    {
        local float DeathCamZoomAlpha;

        // Makes the assumption that super.CalcBehindView does not overwrite
        // the in-value of CameraLocation.
        CameraLocation.Z += kDeathCamZOffset;

        DeathCamZoomAlpha = GetDeathCamZoomAlpha();
        Dist = Lerp(DeathCamZoomAlpha, DeathCamStartDistance, DeathCamEndDistance);
        // Only apply the locked death cam rotation if we're still doing the
        // transition
        if (DeathCamZoomAlpha < 1.0)
        {
            // Makes the assumption that super.CalcBehindView uses the set
            // rotation to calculate its behindview-rotation
            SetRotation(RotatorLerp(DeathCamStartRotation, DeathCamEndRotation, DeathCamZoomAlpha));
        }

        Super.CalcBehindView(CameraLocation, CameraRotation, Dist);
    }

    // Returns a value from 0 to 1, based on time since the death cam began
    private function float GetDeathCamZoomAlpha()
    {
        local float LinearAlpha;
        local float CubicAlpha;

        if (bIsDeathCamRunning)
        {
            // Simple linear equation
            LinearAlpha = (Level.TimeSeconds - DeathCamStartTimeSeconds) / kDeathCamDurationSeconds;
            LinearAlpha = FClamp(LinearAlpha, 0.0, 1.0);

            // Take the linear alpha, and put it through a cubic equation that
            // ends the alpha smoothly as LinearAlpha approaches 1.0
            CubicAlpha = (-2.0 * LinearAlpha * LinearAlpha * LinearAlpha) + (3.0 * LinearAlpha * LinearAlpha);

            return CubicAlpha;
        }
        else
        {
            return 0.0;
        }
    }

    exec function TeamSay( string Msg )
    {
		if(SwatGameInfo(Level.Game).PlayerMuted(self))
		{
			ClientMessage("", 'YouAreMuted');
			return;
		}

log( self$"::TeamSay( "$Msg$" )" );
        SwatGameInfo(Level.Game).BroadcastObservers( self, Msg, 'TeamSay');
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Allows dead players to view through their teammates' eyes.

simulated function ForceObserverCam()
{
    if (Level.GetEngine().EnableDevTools)
        mplog(self$"--ForceObserverCam() ... calling ClientForceObserverCam");

    // The state switch should always be initiated by the client.
    ClientForceObserverCam();
}

simulated private function ClientForceObserverCam()
{
    if (Level.GetEngine().EnableDevTools)
        mplog(self$"--ClientForceObserverCam() ... about to GotoState('ObserveTeam')");

    GotoState('ObserveTeam');
}

simulated private event OnReplicatedObserverCamTargetChanged()
{
    if (Level.GetEngine().EnableDevTools)
        mplog(self$"--OnReplicatedObserverCamTargetChanged(), ReplicatedObserverCamTarget = "$ReplicatedObserverCamTarget$", GetStateName() returned \'"$GetStateName()$"\'");

    // Only respond to this variable changing if we're already in observer cam.
    if (ReplicatedObserverCamTarget != None && GetStateName() == 'ObserveTeam')
    {
        ViewFromPlayer(ReplicatedObserverCamTarget);
    }
}


state ObserveFromTeamOrLocation
{
    simulated function BeginState()
    {
        bIsObserving = true;
    }

    ///////////////

    simulated function EndState()
    {
        bIsObserving = false;
    }

    ///////////////

    simulated function bool IsDead()
    {
        return true;
    }

    ///////////////

    exec function TeamSay( string Msg )
    {
		if(SwatGameInfo(Level.Game).PlayerMuted(self))
		{
			ClientMessage("", 'YouAreMuted');
		}

        log( self$"::TeamSay( "$Msg$" )" );
        SwatGameInfo(Level.Game).BroadcastObservers( self, Msg, 'TeamSay');
    }
}



state ObserveTeam extends ObserveFromTeamOrLocation
{
    simulated function BeginState()
    {
        Super.BeginState();

        if (Level.GetEngine().EnableDevTools)
            mplog(self$"--entering state ObserveTeam.");

        if (self == Level.GetLocalPlayerController())
            ServerViewNextPlayer();
    }

    ///////////////

    simulated function EndState()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog(self$"--leaving state ObserveTeam., setting ReplicatedObserverCamTarget to None");

        ReplicatedObserverCamTarget = None;

        Super.EndState();
    }

    ///////////////

    simulated event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
    {
        local Pawn ViewTargetPawn;
        local Coords HeadCoords;

        if (ViewTarget != None)
        {
            ViewActor = ViewTarget;

            // If this pawn is dead, attach the camera location and rotation
            // to the head bone for a good effect death effect when observing.
            ViewTargetPawn = Pawn(ViewTarget);
            if (Level.NetMode == NM_DedicatedServer
             || ViewTargetPawn == None
             || ViewTargetPawn.IsConscious())
            {
                CameraLocation = TargetViewLocation;
                CameraRotation = TargetViewRotation;
            }
            else
            {
                HeadCoords = ViewTargetPawn.GetBoneCoords('Bone01Eye', true);
                CameraLocation = HeadCoords.Origin;
                CameraRotation = Rotator(HeadCoords.XAxis);
            }
        }
        else
        {
            Global.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
        }
    }

    ///////////////

    exec function Fire()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"--ObserveTeam::Fire, calling ServerViewNextPlayer." );

        ServerViewNextPlayer();
    }
}

state ObserveLocation extends ObserveFromTeamOrLocation
{
    simulated event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
    {
      if (ViewTarget != None)
        {
            ViewActor         = ViewTarget;
            CameraLocation    = ViewTarget.Location;
            CameraRotation    = ViewTarget.Rotation;
        }
        else
        {
            Global.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
        }
    }

    exec function Fire()
    {
    }
}

state GameEnded
{
    simulated function BeginState()
    {
        bBehindView = true;
        Super.BeginState();
    }

    ///////////////

    exec function Fire()
    {
        //do nothing
    }

    ///////////////

    simulated event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
    {
        local Rotator FinalTargetRotation;
        local float ViewDist;

        if (ViewTarget != None)
        {
            EndGameCamYaw += GetEndGameCamYawDelta();

            FinalTargetRotation.Pitch = kEndGameCamRotationPitch;
            FinalTargetRotation.Yaw   = int(EndGameCamYaw);

            ViewActor      = ViewTarget;
            ViewDist  = ViewTarget.Default.CollisionRadius * kEndGameCamDesiredDistScale;

            if( Pawn(ViewTarget) != None )
            {
                CameraRotation = TargetViewRotation + FinalTargetRotation;
                CameraLocation = TargetViewLocation;
                CameraLocation.Z += kEndGameCamZOffset;
            }
            else
            {
                CameraRotation = ViewTarget.Rotation + FinalTargetRotation;
                CameraLocation = ViewTarget.Location;
            }

            //CameraLocation = TargetViewLocation - (ViewTarget.Default.CollisionRadius * kEndGameCamDesiredDistScale) * vector(CameraRotation);
            //log( "dkaplan: PlayerCalcView: ViewTarget = "$ViewTarget$", TargetViewRotation = "$TargetViewRotation$", TargetViewLocation = "$TargetViewLocation$", vector(CameraRotation) = "$vector(CameraRotation)$", CameraLocation = "$CameraLocation );

            CalcBehindView(CameraLocation, CameraRotation, ViewDist);
        }
        else
        {
            Global.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
        }
    }

    //ripped from engine
    simulated function CalcBehindView(out vector CameraLocation, out rotator CameraRotation, float Dist)
    {
	    local vector View,HitLocation,HitNormal;
        local float ViewDist;

	    View = vect(1,0,0) >> CameraRotation;

        if( Trace( HitLocation, HitNormal, CameraLocation - Dist * vector(CameraRotation), CameraLocation,false,vect(10,10,10) ) != None )
		    ViewDist = FMin( (CameraLocation - HitLocation) Dot View, Dist );
	    else
		    ViewDist = Dist;

        CameraLocation = CameraLocation - ViewDist * View;
        EndGameCamLastDist = ViewDist;
    }

    simulated function float GetEndGameCamYawDelta()
    {
        local float LastDistScale;
        local float LastDistScaleAlpha;
        local float YawDeltaPerSecond;
        local float YawDelta;

        // Determine the distance scale from the last update
        LastDistScale = EndGameCamLastDist / ViewTarget.Default.CollisionRadius;
        // Determine the alpha within the slowest-fastest yaw delta range
        LastDistScaleAlpha = (kEndGameCamDistScaleForSlowestYawDelta - LastDistScale)
                           / (kEndGameCamDistScaleForSlowestYawDelta - kEndGameCamDistScaleForFastestYawDelta);
        LastDistScaleAlpha = FClamp(LastDistScaleAlpha, 0.0, 1.0);
        // Lerp the yaw delta based on the distance scale alpha
        YawDeltaPerSecond = Lerp(LastDistScaleAlpha, kEndGameCamSlowestYawDeltaPerSecond, kEndGameCamFastestYawDeltaPerSecond);

        YawDelta = YawDeltaPerSecond * (Level.TimeSeconds - EndGameCamYawLastUpdateTime);
        EndGameCamYawLastUpdateTime = Level.TimeSeconds;

        return YawDelta;
    }

}

///////////////////

// Observer helper functions

private simulated function ViewFromPlayer(Pawn PlayerPawn)
{
	local SwatPlayer SwatPlayerPawn;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ViewFromPlayer(). PlayerPawn="$PlayerPawn );

    if( PlayerPawn != None && PlayerPawn != ViewTarget )
    {
        SetViewTarget(PlayerPawn);
        RefreshCameraEffects(SwatPlayer(PlayerPawn));

        bBehindView = false;

        //the player name should not be updated by the client, since it should already be rpc'd from the server (via ClientMessage)
        if( Level.NetMode != NM_Client )
        {
		    SwatPlayerPawn = SwatPlayer(PlayerPawn);
		    if (SwatPlayerPawn != None && SwatPlayerPawn.IsTheVIP())
		    {
			    ClientMessage(PlayerPawn.GetHumanReadableName(),'ViewingFromVIPEvent');
		    }
		    else
		    {
                ClientMessage(PlayerPawn.GetHumanReadableName(),'ViewingFromEvent');
		    }
        }

        GotoState('ObserveTeam');
    }
}

simulated function ViewFromLocation( Name PositionMarkerLabel )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ViewFromLocation(). PositionMarkerLabel="$PositionMarkerLabel );

    // Clear the "viewing from" text while keeping the respawn timer onscreen,
    // because we're waiting to respawn and viewing from a default location
    ClientMessage("",'ViewingFromNoneEvent');
    GotoState('ObserveLocation');
    SetViewTarget(GetStaticLevelPositionMarker(PositionMarkerLabel));
}

// Since this is an RPC, we need to send the name as a string
simulated function ClientViewFromLocation( String PositionMarkerLabel )
{
    ViewFromLocation(Name(PositionMarkerLabel));
}

private simulated function Actor GetStaticLevelPositionMarker( Name CameraPositionLabel )
{
    local Actor Marker;

    Marker = findStaticByLabel(class'Actor',CameraPositionLabel);

    return Marker;
}

///////////////////

// Overridden from PlayerController
function ServerViewNextPlayer()
{
    local PlayerController Player;
    local Pawn PlayerPawn;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerViewNextPlayer()." );

    // If the server respawned the player and then this RPC comes in from the
    // client, ignore the call.
    if ( Pawn != None && !class'Pawn'.static.CheckDead( Pawn ))
        return;

    Player = FindNextOtherPlayerOnTeam();

    if ( Player != None )
        PlayerPawn = Player.Pawn;

    if (Level.GetEngine().EnableDevTools)
    {
        mplog( "...ViewTarget="$ViewTarget );
        mplog( "...Player="$Player$", PlayerPawn="$PlayerPawn );
    }

    if (PlayerPawn != None)
    {
        ViewFromPlayer(PlayerPawn);

        // If this controller is not the server's local player controller,
        // assign the replicated variable ReplicatedObserverCamTarget to the
        // desired target.
        if (self != Level.GetLocalPlayerController())
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "...assigning ReplicatedObserverCamTarget to "$PlayerPawn );

            ReplicatedObserverCamTarget = PlayerPawn;
        }
    }
    else
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...viewing from DefaultPositionMarker" );

        ViewFromLocation( 'DefaultPositionMarker' );
        ClientViewFromLocation( "DefaultPositionMarker" );
    }
}

///////////////////

function DoorCannotBeLocked()
{
  ClientMessage("[c=FFFFFF]This door cannot be locked.", 'SpeechManagerNotification');
}

function DoorIsLocked()
{
  ClientMessage("[c=FFFFFF]The door is locked.", 'SpeechManagerNotification');
}

function DoorIsNotLocked()
{
  ClientMessage("[c=FFFFFF]The door is not locked.", 'SpeechManagerNotification');
}

function DoSetEndRoundTarget( Actor Target, string TargetName, bool TargetIsOnSWAT )
{
    Assert( Level.NetMode != NM_Client );

    SetEndRoundTarget( Target, TargetName, TargetIsOnSWAT );

    // If this controller is not the server's local player controller,
    // send an RPC to the client
    if (self != Level.GetLocalPlayerController())
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...calling ClientSetEndRoundTarget()." );

        ClientSetEndRoundTarget( Target, TargetName, TargetIsOnSWAT );
    }
}

// RPC on clients that actually triggers the dynamic music change
simulated function ClientTriggerDynamicMusic()
{
    local SoundEffectsSubsystem SoundSys;

    SoundSys = SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem'));

    DynamicMusicManager(SoundSys.GetMusicManager()).TriggerDynamicMusic();
}

// Called from the client-side RPC ClientBroadcastSoundEffectSpecification.  Written here so we have access to the
// sound effect subsystem.
simulated function TriggerSoundEffectSpecification( name EffectSpecification,
                                                    Actor Source,
                                                    Actor Target,
                                                    int inSpecificSoundRef,
                                                    optional Material Material,
                                                    optional Vector overrideWorldLocation,
                                                    optional Rotator overrideWorldRotation,
                                                    optional IEffectObserver Observer )
{
    local SoundEffectsSubsystem SoundSys;
    local SoundEffectSpecification SoundSpec;

    SoundSys = SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem'));
	// Do the lookup of the effect spec locally
    SoundSpec = SoundEffectSpecification(SoundSys.FindEffectSpecification(EffectSpecification));

	// If a specific sound was specified, play that directly...
    if ( inSpecificSoundRef >= 0 )
        SoundSys.PlaySpecificSoundFromSchema( SoundSpec, Source, inSpecificSoundRef, Target, Material, overrideWorldLocation, overrideWorldRotation, Observer );
    else
        SoundSys.PlayEffectSpecification( SoundSpec, Source, Target, Material, overrideWorldLocation, overrideWorldRotation, Observer );
}

private simulated function ClientSetEndRoundTarget(Actor Target, string TargetName, bool TargetIsOnSWAT)
{
    Assert( Level.NetMode == NM_Client );

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientSetEndRoundTarget(). Target="$Target$", TargetName="$TargetName );

    SetEndRoundTarget(Target, TargetName, TargetIsOnSWAT);
}

private simulated function SetEndRoundTarget( Actor Target, string TargetName, bool TargetIsOnSWAT )
{
    UnPossess();

    //set the end of round player tag
    if( self == Level.GetLocalPlayerController() )
        UpdatePlayerTag( TargetName, TargetIsOnSWAT );

    GotoState('GameEnded');

    if( Target != None )
    {
        if( SwatPlayer(Target) != None )
            RefreshCameraEffects(SwatPlayer(Target));

        SetViewTarget(Target);
    }

    if( self == Level.GetLocalPlayerController() )
        SwatGUIControllerBase(Player.GUIController).FinishEndRoundSequence();
}

simulated function UpdatePlayerTag( string TargetPlayerTag, bool TargetIsOnSWAT )
{
    local HudPageBase CachedHUDPage;

    CachedHUDPage = GetHudPage();

    AssertWithDescription( CachedHUDPage != None, "Could not find the Hud Page in UpdatePlayerTag." );

    // Determine style...
    if( TargetIsOnSWAT )
        CachedHUDPage.PlayerTag.Style = CachedHUDPage.Controller.GetStyle(class'PlayerTagInterface'.default.FriendlyTagStyle);
    else
        CachedHUDPage.PlayerTag.Style = CachedHUDPage.Controller.GetStyle(class'PlayerTagInterface'.default.EnemyTagStyle);

    // Update the caption
    CachedHUDPage.PlayerTag.SetCaption( TargetPlayerTag );
    CachedHUDPage.PlayerTag.Show();
}

///////////////////
// destroy all the pawns on this client - used for quick round resets
//////////////
simulated function ClientDestroyAllPawns()
{
    local Pawn P;

    foreach AllActors( class'Pawn', P )
    {
        P.Destroy();
    }
}

///////////////////

function DoStartEndRoundSequence()
{
    Assert( Level.NetMode != NM_Client );

    StartEndRoundSequence();

    // If this controller is not the server's local player controller,
    // send an RPC to the client
    if (self != Level.GetLocalPlayerController())
    {
        ClientStartEndRoundSequence();
    }
}

private simulated function ClientStartEndRoundSequence()
{
    Assert( Level.NetMode == NM_Client );

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientStartEndRoundSequence()." );

    StartEndRoundSequence();
}

private simulated function StartEndRoundSequence()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::StartEndRoundSequence()." );

    if( self == Level.GetLocalPlayerController() )
        SwatGUIControllerBase(Player.GUIController).StartEndRoundSequence();

    // Shut off autofiring for me. The server will tell me to stop autofiring
    // for other pawn with the normal mechanisms.
    SwatPlayer.bWantsToContinueAutoFiring = false;
}

///////////////////

private function PlayerController FindNextOtherPlayerOnTeam()
{
    local Controller NewController;
    local Controller CurrentController;

    if( bChangingTeams )
        return None;

    // Find the current viewtarget's controller
    CurrentController = Controller(ViewTarget);

    if (CurrentController == None)
    {
        // If current viewtarget a pawn? If so, get the controller for it
        if (Pawn(ViewTarget) != None)
        {
            CurrentController = Pawn(ViewTarget).Controller;
        }
    }

    // If we have a current controller, move to the next one. Otherwise, use
    // the first controller in the level list
    if (CurrentController != None)
    {
        CurrentController = CurrentController.NextController;
    }

    // Search till end of list for new target
    for (NewController = CurrentController; NewController != None; NewController = NewController.NextController)
    {
        if (IsOtherControllerObservable(NewController))
        {
            return PlayerController(NewController);
        }
    }

    // Loop to head of list, and search until FirstController is reached
    for (NewController = Level.ControllerList; NewController != CurrentController; NewController = NewController.NextController)
    {
        if (IsOtherControllerObservable(NewController))
        {
            return PlayerController(NewController);
        }
    }

    return None;
}

///////////////////////////////////////

private function bool IsOtherControllerObservable(Controller Other)
{
    return Other.bIsPlayer
        && SwatGamePlayerController(Other) != None
        && SwatGamePlayerController(Other).SwatPlayer != None
        && !SwatGamePlayerController(Other).SwatPlayer.IsTheVIP()                                 //dkaplan: do not view through VIP's helmet cam
        && Other != Self
        && PlayerController(Other).IsDead() == false
        && (Level.IsCOOPServer || PlayerReplicationInfo.Team == Other.PlayerReplicationInfo.Team);
}

///////////////////////////////////////////////////////////////////////////////

simulated function bool IsCuffed()
{
    return false;
}

simulated function OnArrested()
{
    AssertWithDescription( false, "[mcj] OnArrested() called on SwatGamePlayerController, and was not in BeginCuffed state." );
}

simulated function PostArrested()
{
    AssertWithDescription( false, "[mcj] PostArrested() called on SwatGamePlayerController, and was not in BeginCuffed state." );
}

///////////////////////////////////////////////////////////////////////////////
//
// The PlayerController is put in this state when its pawn starts being
// cuffed. Basically, all it does is disable input and do the equivalent of a
// behindview, just like the Dead state does.
//
state BeingCuffed
{
    simulated function bool IsCuffed()
    {
        return bPlayerIsCuffed;
    }

    simulated function OnArrested()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"---SGPC::OnArrested() in state 'BeingCuffed'." );

        bPlayerIsCuffed = true;
    }

    simulated function PostArrested()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"---SGPC::PostArrested() in state 'BeingCuffed'." );

        if ( SwatPlayer.IsTheVIP() )
        {
            SwatPlayer.SetForceCrouchState(true);
            GotoState( 'PlayerWalking' );
            ClientGotoState( 'PlayerWalking', 'Begin' );
        }
        else
        {
            Pawn.Unpossessed();
            Pawn = None;
            if( ForceObserverTimer != None )
            {
                ForceObserverTimer.StartTimer(ForceObserverTime);
            }
        }
    }

    exec function Fire()
    {
        // Only allow the player to go to observer cam if he's cuffed, and if
        // he's not the VIP
        if (bPlayerIsCuffed && !SwatPlayer.IsTheVIP())
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( self$"::Fire()  in state BeingCuffed... about to ForceObserverCam();" );

            ForceObserverCam();
        }
    }

    simulated function ForceObserverTimerCallback()
    {
        ForceObserverCam();
    }

    function BeginState()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$" entering state 'BeingCuffed'." );

        bPlayerIsCuffed = false;

        // Go to third person viewpoint like dying state here.

        // From PlayerController's Dead state
		//if ( (Pawn != None) && (Pawn.Controller == self) )
		//	Pawn.Controller = None;
        SetZoom(false, true);   //unzoom instantly
		//Pawn = None;
		//Enemy = None;
		bBehindView = true;
		bFrozen = true;
		bJumpStatus = false;
		bPressedJump = false;
        bBlockCloseCamera = true;
		bValidBehindCamera = false;
		FindGoodView();
        //SetTimer(1.0, false);
		StopForceFeedback();
		//ClientPlayForceFeedback("Damage");  // jdf
		CleanOutSavedMoves();
        Pawn.SetPhysics(PHYS_None);
        Pawn.UnLean();
        if( self == level.GetlocalPlayerController() )
            GetHudPage().Overlay.Hide();
    }

    function EndState()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$" leaving state 'BeingCuffed'." );

        // Go back to first person viewpoint.

        // From PlayerController's Dead state
		bBlockCloseCamera = false;
		CleanOutSavedMoves();
		Velocity = vect(0,0,0);
		Acceleration = vect(0,0,0);
        if ( !PlayerReplicationInfo.bOutOfLives )
			bBehindView = false;
		bPressedJump = false;
		//myHUD.bShowScores = false;

        Pawn.SetPhysics(PHYS_Walking);
        if( self == level.GetlocalPlayerController() )
            GetHudPage().Overlay.Show();

        if ( !SwatPlayer.IsTheVIP() )
        {
            if ( bPlayerIsCuffed )
            {
                // Since the pawn is not the VIP, he is effectively dead.
                GetRidOfPawn();
            }

            // reset to regular value
            bPlayerIsCuffed = false;
        }
        else
        {
            // The pawn is the VIP. Undo all the weird behindview setting and
            // stuff so that the player can do the right thing in the OnKnees
            // state.
            bBehindView = false;
            bFrozen = false;
            bJumpStatus = false;
            bPressedJump = false;
            bBlockCloseCamera = false;
            bValidBehindCamera = true;
            CleanOutSavedMoves();
        }
    }

    simulated function GetRidOfPawn()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"---SGPC::GetRidOfPawn() in state 'BeingCuffed'." );

        if (SwatPlayer != None)
        {
            SwatPlayer.Destroy();
			SwatPlayer = None;
        }
    }

    simulated function InterruptState(name PendingState)
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"---SGPC::InterruptState() in state 'BeingCuffed'. PendingState="$PendingState );

        AssertWithDescription(SwatPlayer(Pawn).LastArrester != None,
            "[tcohen] SwatGamePlayerController@BeingCuffed::InterruptState() BeingCuffed is interrupted, but we don't know who's Arresting us.");

        if ( Level.NetMode != NM_Client )
            SwatPlayer(Pawn).LastArrester.AuthorizedInterruptQualification();
    }
}


simulated function OnUnarrested()
{
    AssertWithDescription( false, "[mcj] OnUnarrested() called on SwatGamePlayerController, and was not in BeginUncuffed state." );
}

///////////////////////////////////////////////////////////////////////////////
//
// The PlayerController is put in this state when its pawn starts being
// uncuffed. It's basically a copy of BeingCuffed with some things changed.
//
state BeingUncuffed
{
    // Ripped off from the PlayerController's Dead state.
	function FindGoodView()
	{
		local vector cameraLoc;
		local rotator cameraRot, ViewRotation;
		local int tries, besttry;
		local float bestdist, newdist;
		local int startYaw;
		local actor ViewActor;

		////log("Find good death scene view");
		ViewRotation = Rotation;
		ViewRotation.Pitch = 56000;
		tries = 0;
		besttry = 0;
		bestdist = 0.0;
		startYaw = ViewRotation.Yaw;

		for (tries=0; tries<16; tries++)
		{
			cameraLoc = ViewTarget.Location;
			SetRotation(ViewRotation);
			PlayerCalcView(ViewActor, cameraLoc, cameraRot);
			newdist = VSize(cameraLoc - ViewTarget.Location);
			if (newdist > bestdist)
			{
				bestdist = newdist;
				besttry = tries;
			}
			ViewRotation.Yaw += 4096;
		}

		ViewRotation.Yaw = startYaw + besttry * 4096;
		SetRotation(ViewRotation);
	}

    simulated function bool IsCuffed()
    {
        return bPlayerIsCuffed;
    }

    simulated function OnUnarrested()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$"---SGPC::OnUnarrested() in state 'BeingUncuffed'." );

        bPlayerIsCuffed = false;
        SwatPlayer.SetForceCrouchState(false);
        SwatPlayer.ShouldCrouch( false );

        //GotoState( 'PlayerWalking' );
        //ClientGotoState( 'PlayerWalking', 'Begin' );
    }

    function BeginState()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$" entering state 'BeingUncuffed'." );

        Assert( SwatPlayer.IsTheVIP() );

        //bPlayerIsCuffed = false;

        // Go to third person viewpoint like dying state here.

        // From PlayerController's Dead state
		//if ( (Pawn != None) && (Pawn.Controller == self) )
		//	Pawn.Controller = None;
		SetZoom(false, true);   //unzoom instantly
		//Pawn = None;
		//Enemy = None;
		bBehindView = true;
		bFrozen = true;
		bJumpStatus = false;
		bPressedJump = false;
        bBlockCloseCamera = true;
		bValidBehindCamera = false;
		FindGoodView();
        //SetTimer(1.0, false);
		StopForceFeedback();
		//ClientPlayForceFeedback("Damage");  // jdf
		CleanOutSavedMoves();
        Pawn.SetPhysics(PHYS_None);
        if( self == level.GetlocalPlayerController() )
            GetHudPage().Overlay.Hide();
    }

    function EndState()
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( self$" leaving state 'BeingUncuffed'." );

        // Go back to first person viewpoint.

        // From PlayerController's Dead state
		bBlockCloseCamera = false;
		CleanOutSavedMoves();
		Velocity = vect(0,0,0);
		Acceleration = vect(0,0,0);
        if ( !PlayerReplicationInfo.bOutOfLives )
			bBehindView = false;
		bPressedJump = false;
		//myHUD.bShowScores = false;

        Pawn.SetPhysics(PHYS_Walking);
        if( self == level.GetlocalPlayerController() )
            GetHudPage().Overlay.Show();

        // The pawn is the VIP. Undo all the weird behindview setting and
        // stuff so that the player can do the right thing in the OnKnees
        // state.
        bBehindView = false;
        bFrozen = false;
        bJumpStatus = false;
        bPressedJump = false;
        bBlockCloseCamera = false;
        bValidBehindCamera = true;
        CleanOutSavedMoves();
    }

Begin:

    if (Level.GetEngine().EnableDevTools)
        mplog( self$" Begin: of state 'BeingUncuffed'." );
}


///////////////////////////////////////////////////////////////////////////////
exec function GotoPlayerWalking()
{
    GotoState('PlayerWalking');
}

// Toggle whether or not the first person hands (and consequently the weapon) is rendered
exec function HandsDown() { ShowHands(); }
exec function ShowHands()
{
	Pawn.bRenderHands = !Pawn.bRenderHands;
	if (Pawn.bRenderHands)
		ClientMessage("Hand/Weapon rendering is now ON", 'DebugMessage');
	else
		ClientMessage("Hand/Weapon rendering is now OFF", 'DebugMessage');
}

#if IG_BATTLEROOM
exec function BattleRoom()
{
    GotoState('BattleRooming');
}

state BattleRooming extends BaseSpectating
{
    ignores Fire;

    function InputOffset(out float aForward, out float aStrafe)
    {
    }

    simulated function UpdateLooking(float dTime)
    {
    }

    exec function BattleRoomToggleSimulation()
    {
        Level.bPlayersOnly = !Level.bPlayersOnly;
    }

    exec function BattleRoom()
    {
        GotoState('PlayerWalking');
    }

    exec function BattleSelectedHealth(int Health)
    {
        BattleRoomManager.SetSelectedHealth(Health);
    }

    simulated function CalcViewForFocus(out Actor ViewActor, out Vector ViewLocation, out Rotator ViewRotation)
    {
        ViewLocation = Location;
        ViewRotation = Rotator(BattleRoomManager.GetMouseLookDir());
        ViewActor = Self;
    }

    function BeginState()
    {
        local Rotator Rot;

        SetCollision(true,true,true);
        SetCollisionSize(32,32);

        BattleRoomZ = Pawn.Location.Z + 200;

        SetLocation(Pawn.Location);

        Rot = Rotation;
        Rot.Pitch = -65 * DEGREES_TO_TWOBYTE;
        SetRotation(Rot);

        GetHudPage().bActiveInput = true;
        GetHudPage().BattleRoom.Activate();
        GetHudPage().BattleRoom.Show();
        GetHudPage().bHideMouseCursor = false;

        BattleRoomManager.Open();
        log("Starting battleroom!");

        bBehindView = true;
        Pawn.bHidden = false;
        bGodMode = true;
    }

    event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
    {
        CameraLocation = Location;
        CameraRotation = Rotation;
        CameraLocation.Z = BattleRoomZ;

        SetLocation(CameraLocation);
        ViewActor=Self;
    }

    exec function BattleSelectAllPawns()
    {
        BattleRoomManager.SelectAllPawns();
    }

    function UpdateRotation(float DeltaTime, float maxPitch)
    {
	    local rotator newRotation, ViewRotation;

	    ViewRotation = Rotation;
	    DesiredRotation = ViewRotation; //save old rotation

		TurnTarget = None;
		bRotateToDesired = false;
		bSetTurnRot = false;

        if ( bBattleRoomRotation != 0 )
        {
            ViewRotation.Yaw += 32.0 * DeltaTime * aTurn;
		    ViewRotation.Pitch += 32.0 * DeltaTime * aLookUp;

            if ( ViewRotation.Pitch != Rotation.Pitch )
                ViewRotation.Pitch = Clamp(ViewRotation.Pitch, -80 * DEGREES_TO_TWOBYTE, 20 * DEGREES_TO_TWOBYTE);

            SetRotation(ViewRotation);
        }
	    NewRotation = ViewRotation;
	    NewRotation.Roll = Rotation.Roll;
    }

 	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;

        UpdateRotation(DeltaTime, 1);

		GetAxes(Rotation,X,Y,Z);
		Acceleration = 80 * DeltaTime  * (aForward*X + aStrafe*Y + aUp*vect(0,0,1));

        if ( bRun != 0 )
            BattleRoomZ = Clamp( BattleRoomZ + aLookUp*0.4*DeltaTime, Pawn.Location.Z, Pawn.Location.Z + 1000 );

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
	}

    exec function BattleRoomSelect()
    {
        log("Alt fire!!");
        BattleRoomManager.RightClickBattleRoom();
    }

    function EndState()
    {
        GetHudPage().BattleRoom.Hide();
        GetHudPage().Deactivate();
        bBehindView = false;
        Level.bPlayersOnly = false;
        bGodMode = false;
        log("Ending battleroom!!");
    }
}
#endif // IG_BATTLEROOM

///////////////////////////////////////////////////////////////////////////////

// Returns true if Player is part of a network game AND has actually entered
// his first round (i.e., returns false if the player has joined a game but is
// only observing)
//
// Note: This is only valid on the server!
function bool HasEnteredFirstRoundOfNetworkGame()
{
	// this method is not valid on clients
	assert(Role == ROLE_Authority);

	// If HasEnteredFirstRound() is true, it means that the player has already
	// entered a round and had its pawn created. If it is false, it means that
	// the player has not yet entered a round (which likely means the player
	// joined the game after a round had started, and is currently spectating
	// until the round ends).
	return SwatRepoPlayerItem.HasEnteredFirstRound();
}

function bool IsAReconnectingClient()
{
    assert( Level.NetMode != NM_Standalone );
	return SwatRepoPlayerItem.bIsAReconnectingClient;
}


///////////////////////////////////////////////////////////////////////////////

// Team changing functions. These should be used rather than the engine's
// ChangeTeam functions.

function SetPlayerTeam(int TeamID)
{
    ServerSetPlayerTeam(TeamID);
}

///////////////////////////////////////

function AutoSetPlayerTeam()
{
    // Places player on team with fewest players, or team 0
    ServerAutoSetPlayerTeam();
}

///////////////////////////////////////

private function ServerSetPlayerTeam(int TeamID)
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerSetPlayerTeam(). TeamID="$TeamID );

    SwatGameInfo(Level.Game).SetPlayerTeam(Self, TeamID);
}

///////////////////////////////////////

private function ServerAutoSetPlayerTeam()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerAutoSetPlayerTeam()." );

    SwatGameInfo(Level.Game).AutoSetPlayerTeam(Self);
}


// Executes only on the server
function ServerChangePlayerTeam()
{
    local SwatRepo theRepo;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerChangePlayerTeam()" );

    theRepo = SwatRepo(Level.GetRepo());
    Assert( theRepo != None );

    if ( SwatPlayer != None
         && SwatPlayer.IsTheVIP()
         && theRepo.GuiConfig.SwatGameState == GAMESTATE_MidGame )
    {
        return;
    }

    // To prevent degenerate game playing strategies, we prevent changing
    // teams during the round while non-lethaled or being arrested
    if( SwatPlayer != None &&
        ( SwatPlayer.IsNonlethaled() || SwatPlayer.IsBeingArrestedNow() ) )
    {
        return;
    }

    // To prevent degenerate game playing strategies, we prevent changing
    // teams during the round if no respawn is true.
    //if ( theRepo.GuiConfig.theServerSettings.bNoRespawn
    //     && theRepo.GuiConfig.SwatGameState == GAMESTATE_MidGame )
    //{
    //    return;
    //}

    bChangingTeams=True;
    SwatGameInfo(Level.Game).ChangePlayerTeam( Self );
}


function ServerSetPlayerReady()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerSetPlayerReady()." );

    SwatGameInfo(Level.Game).SetPlayerReady( Self );
}

function ServerSetPlayerNotReady()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerSetPlayerNotReady()." );

    SwatGameInfo(Level.Game).SetPlayerNotReady( Self );
}


///////////////////////////////////////////////////////////////////////////////

function ClientGameEnded()
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientGameEnded()." );

    Super.ClientGameEnded();
	Repo.OnMissionEnded();
	LogScores();
}

///////////////////////////////////////////////////////////////////////////////

//function ClientNetGameCompleted()
//{
//    log( "SwatGamePlayerController::NetGameCompleted() called." );
//    SwatGUIControllerBase(Player.GUIController).NetGameCompleted(); //should pass game ending condition here
//}

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////

function ClientRoundStarted()
{
    local Actor Marker;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientRoundStarted()." );

    //clean up bomb exploded for the next round
    Marker = findStaticByLabel(class'Actor','BombExplodedMarker');
    if( Marker != None )
        Marker.UnTriggerEffectEvent('PostBombExploded');

    if (Level.GetEngine().EnableDevTools)
    {
        mplog( "...Level   ="$Level );
        mplog( "...Repo    ="$Level.GetRepo() );
        mplog( "...SwatRepo="$Repo );
    }

	Repo.OnMissionStarted();
}


///////////////////////////////////////////////////////////////////////////////

exec function Say( string Msg )
{
//  log(self$"::Say - "$Pawn.GetRoomName()$" - ("$Msg$")");
	if(SwatGameInfo(Level.Game).PlayerMuted(self))
	{
		ClientMessage("", 'YouAreMuted');
		return;
	}

	if (PlayerReplicationInfo.bAdmin && left(Msg,1) == "#" )
	{
		Level.Game.AdminSay(right(Msg,len(Msg)-1));
		return;
	}

    // On a dedicated server, no one gets TeamMessage(), so we need to print
    // it here. We don't do it for listen servers, because we'd get double log
    // messages (since listen servers do get TeamMessage() ).
    if ( Level.NetMode == NM_DedicatedServer )
    {
        mplog( "ChatMessage( "$Msg$", Say )" );
    }

	if(!SwatGameInfo(Level.Game).LocalizedChatIsDisabled() && Pawn != None)
	{
		Level.Game.BroadcastLocation(self, Msg, 'Say', None, string(Pawn.GetRoomName()));
	}
	else
	{
		Level.Game.Broadcast(self, Msg, 'Say');
	}

	Level.Game.AdminLog(PlayerReplicationInfo.PlayerName$"\t"$Msg, 'Say', GetPlayerNetworkAddress());
}

exec function TeamSay( string Msg )
{
//  log(self$"::TeamSay("$msg$")");
	if(SwatGameInfo(Level.Game).PlayerMuted(self))
	{
		ClientMessage("", 'YouAreMuted');
		return;
	}

	if( !GameReplicationInfo.bTeamGame )
	{
		Say( Msg );
		return;
	}

	if(!SwatGameInfo(Level.Game).LocalizedChatIsDisabled())
	{
		Level.Game.BroadcastTeam( self, Level.Game.ParseMessageString( Level.Game.BaseMutator , self, Msg ), 'TeamSay', string(Pawn.GetRoomName()));
	}
	else
	{
		Level.Game.BroadcastTeam( self, Level.Game.ParseMessageString( Level.Game.BaseMutator, self, Msg), 'TeamSay', "");
	}

	Level.Game.AdminLog(PlayerReplicationInfo.PlayerName$"\t"$Msg, 'TeamSay', GetPlayerNetworkAddress());
}

event ClientMessage( coerce string S, optional Name Type )
{
    //log("[dkaplan] >>> "$self$"::ClientMessage( "$S$", "$Type$" )" );
	TeamMessage(PlayerReplicationInfo, S, Type);
  ConsoleMessage(S);
}

event TeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional string Location)
{
    //log("[dkaplan] >>> "$self$"::TeamMessage( "$PRI$", "$S$", "$Type$" "$Location$" )" );

    if (Type == 'Say' || Type == 'TeamSay')
    {
        if(Location != "" && Location != "None")
        {
          // If we have a RoomName of None, we are spectating
          if(Type == 'Say') {
            Type = 'SayLocalized';
          } else {
            Type = 'TeamSayLocalized';
          }

          S = PRI.PlayerName$"\t"$Location$"\t"$S;
        }
        else
        {
          S = PRI.PlayerName$"\t"$S;
        }

        if (Level.GetEngine().EnableDevTools)
            mplog( "ChatMessage( "$S$", "$Type$" )" );
    }

    switch (Type)
    {
        case '':
            Type = 'Event';
            break;
        case 'OneMinWarning':
            OnOneMinWarning();
            break;
        case 'BombExploded':
            OnBombExploded();
            break;
        case 'MissionEnded':
            dispatchMessage(new class'MessageMissionEnded'());
            break;
        case 'MissionCompleted':
            dispatchMessage(new class'MessageMissionCompleted'());
            break;
        case 'MissionFailed':
            dispatchMessage(new class'MessageMissionFailed'());
            break;
    }

    // hook for effect events for any type of message
    TriggerEffectEvent( Type,,,,,,,, GetEnum( EMPMode, ServerSettings(Level.CurrentServerSettings).GameType ) );

    // GUI gets first crack
    //
    // Note: Player.GUIController can be None at early stage of some single-player
    // levels (like when launching from UnrealEd)
    if( Player == None || Player.GUIController == None ||
        SwatGUIControllerBase(Player.GUIController).OnMessageRecieved( S, Type ) )
        return;

    if (myHUD != None)
    {
        if (Type == 'Say' || Type == 'SayLocalized' || Type == 'WebAdminChat')
        {
            myHUD.AddTextMessage(s, class'ChatGlobalMessage', PRI);
        }
        else if (Type == 'TeamSay' || Type == 'TeamSayLocalized')
        {
            myHUD.AddTextMessage(s, class'ChatTeamMessage', PRI);
        }
    		else
    		{
    	    	myHUD.Message( PRI, S, Type );
    		}
    }

	SwatGameInfo(Level.Game).AdminLog(S, Type, GetPlayerNetworkAddress());
    Player.Console.Message(S, 6.0);
}

///////////////////////////////////////////////////////////////////////////////

// Multiplayer-related commands

exec function Talk()
{
    local Console Console;
    Console = Console(Player.InteractionMaster.Console);
    if (Console != None)
    {
        Console.Talk();
    }
}

///////////////////////////////////////

exec function TeamTalk()
{
    local Console Console;
    Console = Console(Player.InteractionMaster.Console);
    if (Console != None)
    {
        Console.TeamTalk();
    }
}

///////////////////////////////////////

exec function JoinTeam(String TeamName)
{
    if (TeamName ~= "A")
    {
        SetPlayerTeam(0);
    }
    else if (TeamName ~= "B")
    {
        SetPlayerTeam(1);
    }
}

///////////////////////////////////////

exec function AutoJoinTeam()
{
    AutoSetPlayerTeam();
}

///////////////////////////////////////

exec function ChangeTeam(int N)
{
    // Intentionally empty.
    // Stubbed out so that the base PlayerController::ChangeTeam has no effect.
}

///////////////////////////////////////

exec function LogScores()
{
    local int i;
    local SwatGameReplicationInfo   GameInfo;
    local SwatPlayerReplicationInfo PlayerInfo;
    local SwatGamePlayerController SGPC;

    GameInfo = SwatGameReplicationInfo(GameReplicationInfo);
    if (GameInfo != None)
    {
        log("=====================================");
        log("Scores");
        log("");
        log("-- Teams --");
        log("");
        log("Team A"$GameInfo.Teams[0].TeamIndex$" (SWAT):     "$NetTeam(GameInfo.Teams[0]).NetScoreInfo.GetScore());
        log("Team B"$GameInfo.Teams[1].TeamIndex$" (Bad Guys): "$NetTeam(GameInfo.Teams[1]).NetScoreInfo.GetScore());
        log("");

        log("");
        log("-- Players --");
        log("");

        for (i = 0; i < ArrayCount(GameInfo.PRIStaticArray); ++i)
        {
            PlayerInfo = GameInfo.PRIStaticArray[i];
            if (PlayerInfo != None)
            {
                log(PlayerInfo.PlayerName$" ["$PlayerInfo.Team.TeamName$"]: "$PlayerInfo.NetScoreInfo.GetScore());
            }
        }

        log("=====================================");
        log(" Mapping of names to playercontrollers:" );
        log("");

        foreach AllActors( class 'SwatGamePlayerController', SGPC )
        {
            log( SGPC$" has name: "$SGPC.PlayerReplicationInfo.PlayerName );
        }

        log("");
        log("=====================================");
    }
}

exec function LogBestClusters()
{
    local GameModeMPBase GameModeMPBase;

    GameModeMPBase = GameModeMPBase(SwatGameInfo(Level.Game).GetGameMode());
    if (GameModeMPBase != None)
    {
        GameModeMPBase.SetStartClusterForRespawn(0);
        GameModeMPBase.SetStartClusterForRespawn(1);
    }
}

///////////////////////////////////////

//
// accuracy support
//

event PlayerTick(float dTime)
{
#if 0	// Ryan: Test code for voip crash
	if (bVoiceTalk > 0)
	{
		if (FRand() < 0.01)
			bVoiceTalk = 0;
	}
	else
	{
		if (FRand() < 0.01)
			bVoiceTalk = 1;
	}
#endif
#if 0   //TMC test sting grenade view offset
    local vector CameraLocation;
    local rotator CameraRotation;
    local Actor ViewTarget;
    local vector CurrentDebugPoint;
    if (Level.TimeSeconds< SwatPlayer(Pawn).LastStungTime + SwatPlayer(Pawn).StingDuration)
    {
        PlayerCalcView(ViewTarget, CameraLocation, CameraRotation);
        CurrentDebugPoint = CameraLocation + 100 * Normal(Vector(CameraRotation));
        if (LastDebugPoint != vect(0,0,0))
            MyHud.AddDebugLine(LastDebugPoint, CurrentDebugPoint, class'Engine.Canvas'.Static.MakeColor(0,0,255));
        LastDebugPoint = CurrentDebugPoint;
    }
    else
        LastDebugPoint = vect(0,0,0);
#endif

    Super.PlayerTick(dTime);

    UpdateLooking(dTime);

    UpdateRecoil();

/*  TMC 1/23/2004 disabled support for GCIOpen & GiveCommand on the same button (GCIOpen after delay)
    if (CommandInterface == GraphicCommandInterface)
    {
        // monitor the 'give command' button (right-mouse by default)
        if (GiveCommandIsDown)
        {
            if (bGCIOpen == 0)  //button was released this frame
                OnGiveCommandReleased();
        }
        else
        {
            if (bGCIOpen > 0)   //button was pressed this frame
                OnGiveCommandPressed();
        }
    }
*/

    // In a network game, we connect to the server and have a playercontroller
    // but no pawn at first. If we don't have a pawn yet, return early so we
    // don't get accessed None's.
    if (Pawn == None)
        return;

    //we should continue auto-firing until the fire button is released
    if ( SwatPawn(Pawn).bWantsToContinueAutoFiring )
    {
        //mplog( "...currently autofiring in SGPC::PlayerTick().");
        SwatPawn(Pawn).bWantsToContinueAutoFiring = bFire > 0;
        if ( !SwatPawn(Pawn).bWantsToContinueAutoFiring && Level.NetMode != NM_Standalone && Pawn.IsControlledByLocalHuman() )
        {
            //mplog( Pawn$" is  no longer pressing the Fire key on an AutoFire weapon...calling Pawn::ServerEndFiringWeapon().");
            Pawn.ServerEndFiringWeapon();
        }
    }

    if (LastBehindView != bBehindView)
    {
		//Log("!!!! bBehindView changed from "$LastBehindView$" to "$bBehindView$" for "$self);

		LastBehindView = bBehindView;

		// Notify the pawn so it can do any necessary tasks (like switching
		// flashlight from 1st to 3rd person weapon model)
		SwatPawn(Pawn).OnPlayerViewChanged();
    }

    /*  tcohen: uncomment to diagnose EyeHeight
    if (int(Pawn.EyeHeight + 0.5) == int(Pawn.default.BaseEyeHeight + 0.5))
        log("TMC PlayerPawn at default BASEEyeHeight="$Pawn.default.BaseEyeHeight);
    else
    if (int(Pawn.EyeHeight + 0.5) == int(Pawn.default.CrouchEyeHeight + 0.5))
        log("TMC PlayerPawn at default CROUCHEyeHeight="$Pawn.default.CrouchEyeHeight);
    else
        log("TMC PlayerPawn's EyeHeight="$Pawn.EyeHeight$" doesn't match default BaseEyeHeight="$Pawn.default.BaseEyeHeight$" OR default CrouchEyeHeight="$Pawn.default.CrouchEyeHeight);
    */
}

simulated function RefreshCameraEffects(SwatPlayer Victim)
{
    //mplog(self$" got SwatGamePlayerController.RefreshCameraEffects("$victim$") call");
    if (Victim != SwatPlayer(ViewTarget))
    {
        //mplog(self$" ignoring RefreshCameraEffects because ViewTarget != Pawn being refreshed");
        //mplog(" -> "$ViewTarget$" != "$Victim);
        return; //we're not seeing thru his eyes, so we don't care what camera effects he would have
    }

    RemoveAllCameraEffects();

    if ( Victim == None || Victim.bDeleteMe )
    {
        //mplog( "...NOT refreshing camera effects because the victim was bDeleteMe!!" );
        return;
    }

    if (Victim.IsFlashbanged())
    {
        //mplog(self$" adding FB CameraEffect because "$victim$" is affected");
        AddCameraEffect(FlashbangCameraEffect, true, true, false);   //enforce unique class and object, and don't replace if already exists
    }

    if (Victim.IsPepperSprayed())
    {
        //mplog(self$" adding Pepper CameraEffect because "$victim$" is affected");
        AddCameraEffect(PepperSprayCameraEffect, true, true, false);   //enforce unique class and object, and don't replace if already exists
    }

    if (Victim.IsGassed())
    {
        //mplog(self$" adding Gassed CameraEffect because "$victim$" is affected");
        AddCameraEffect(CSGasCameraEffect, true, true, false);   //enforce unique class and object, and don't replace if already exists
    }

    if (Victim.IsStung())
    {
        //mplog(self$" adding Stung CameraEffect because "$victim$" is affected");
        AddCameraEffect(StingCameraEffect, true, true, false);   //enforce unique class and object, and don't replace if already exists
    }

	if (Victim.bIsWearingNightvision)
	{
		AddCameraEffect(NVGogglesCameraEffect, true, true, false);   //enforce unique class and object, and don't replace if already exists
	}
}

event RenderTexture(ScriptedTexture inTexture)
{
    local Actor ViewTarget;
    local vector CameraLocation;
    local rotator CameraRotation;

    PlayerCalcView(ViewTarget, CameraLocation, CameraRotation);
    //TMC TODO change render settings
    inTexture.DrawPortal(0, 0, FlashbangRetinaImageTextureWidth, FlashbangRetinaImageTextureHeight, self, CameraLocation, CameraRotation, FOVAngle);
}

simulated function UpdateLooking(float dTime)
{
    local float LastMouseDistance;

    LastMouseDistance = Square(aMouseX - LastMouseX) + Square(aMouseY - LastMouseY);
    MouseDistancePerSecond = LastMouseDistance * dTime;

    LastMouseX = aMouseX;
    LastMouseY = aMouseY;
}

simulated function UpdateRecoil()
{
    local float Time;

    if (!Recoiling) return;

    Time = Level.TimeSeconds;

    if (Time > RecoilStartTime + RecoilBackDuration + RecoilForeDuration)
    {
        FinishRecoiling();
        return;
    }

    if (Time < RecoilStartTime + RecoilBackDuration)
        UpdateRecoilBack(Time);
    else
        UpdateRecoilFore(Time);
}

simulated function FinishRecoiling()
{
    local float Time;

    //we'll spoof the time, so that we can do an update at the precise moment that the recoil should end

    Time = RecoilStartTime + RecoilBackDuration + RecoilForeDuration;

    UpdateRecoilFore(Time);

    Recoiling = false;
}

simulated function UpdateRecoilBack(float Time)
{
    local float ElapsedRecoilBackTime;
    local float CurrentValue;    //value of the recoil function
    local float DeltaPitch;
    local rotator NewRotation;

    ElapsedRecoilBackTime = Time - RecoilStartTime;

    CurrentValue = Sin(ScaleRecoilDuration(ElapsedRecoilBackTime, RecoilBackDuration)) * RecoilMagnitude;

    DeltaPitch = CurrentValue - LastRecoilFunctionValue;

    //apply delta pitch to our rotation
    NewRotation = Rotation;
    if (NewRotation.Pitch <= 18000)  //looking up
        NewRotation.Pitch = Min(NewRotation.Pitch + DeltaPitch, 18000); //fix 467 - cap pitch
    else
        NewRotation.Pitch += DeltaPitch;
    SetRotation(NewRotation);

/*
    log("TMC T"$Pad(7, Level.TimeSeconds)
        $" UpdateRecoilBack()"
        $"  ElapsedRecoilBackTime="$Pad(7, ElapsedRecoilBackTime)
        $", RecoilBackDuration="$Pad(7, RecoilBackDuration)
        $", TrigValue="$Pad(7, CurrentValue / RecoilMagnitude)
        $", CurrentValue="$Pad(7, CurrentValue)
        $", DeltaPitch="$Pad(7, DeltaPitch)
        $", NewPitch="$Pad(7, Rotation.Pitch));
*/

    LastRecoilFunctionValue = CurrentValue;
}

simulated function UpdateRecoilFore(float Time)
{
    local float ElapsedRecoilForeTime;
    local float CurrentValue;    //value of the recoil function
    local float DeltaPitch;
    local rotator NewRotation;

    ElapsedRecoilForeTime = Time - RecoilStartTime - RecoilBackDuration;

    CurrentValue = Cos(ScaleRecoilDuration(ElapsedRecoilForeTime, RecoilForeDuration)) * RecoilMagnitude;

    DeltaPitch = CurrentValue - LastRecoilFunctionValue;

    //apply delta pitch to our rotation
    NewRotation = Rotation;
    if (NewRotation.Pitch <= 18000)  //looking up
        NewRotation.Pitch = Min(NewRotation.Pitch + DeltaPitch, 18000); //fix 467 - cap pitch
    else
        NewRotation.Pitch += DeltaPitch;
    SetRotation(NewRotation);

/*
    log("TMC T"$Pad(7, Level.TimeSeconds)
        $" UpdateRecoilFore()"
        $"  ElapsedRecoilForeTime="$Pad(7, ElapsedRecoilForeTime)
        $", RecoilForeDuration="$Pad(7, RecoilForeDuration)
        $", TrigValue="$Pad(7, CurrentValue / RecoilMagnitude)
        $", CurrentValue="$Pad(7, CurrentValue)
        $", DeltaPitch="$Pad(7, DeltaPitch)
        $", NewPitch="$Pad(7, Rotation.Pitch));
*/

    LastRecoilFunctionValue = CurrentValue;
}

//scales (ElapsedTime / Duration) on the range [0, Pi/2]
simulated function float ScaleRecoilDuration(float ElapsedTime, float Duration)
{
    return HALF_PI * ElapsedTime / Duration;
}

function AddRecoil(float inRecoilBackDuration, float inRecoilForeDuration, float inRecoilMagnitude, optional float AutoFireRecoilMagnitudeIncrement, optional int AutoFireShotIndex)
{
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
    if (!DebugShouldRecoil) return;
#endif

    //we're starting a new recoil
    //it doesn't matter if there's already a recoil in effect... we're just starting over from where we are

    RecoilStartTime = Level.TimeSeconds;
    RecoilBackDuration = inRecoilBackDuration;
    RecoilForeDuration = inRecoilForeDuration;
    RecoilMagnitude = inRecoilMagnitude + AutoFireRecoilMagnitudeIncrement * AutoFireShotIndex;
    LastRecoilFunctionValue = 0;

    Recoiling = true;
}

native simulated event float GetLookAroundSpeed();

///////////////////////////////////////////////////////////////////////////////

// @TEMP command to enable or disable collision on pawns

exec function PawnCollision(int on)
{
    local Pawn pawn;
    local bool bOn;

    bOn = (on != 0);

    pawn = None;
    foreach AllActors(class 'Pawn', pawn)
    {
        pawn.bBlockPlayers = bOn;
        pawn.bBlockActors  = bOn;
    }
}

// @TEMP command to force toggle SetLowReady on the player
exec function ToggleLowReady()
{
    local SwatPlayer playerPawn;
    playerPawn = SwatPlayer(Pawn);
    if (playerPawn != None)
    {
        playerPawn.SetLowReady(!playerPawn.IsLowReady());
    }
}

///////////////////////////////////////////////////////////////////////////////

//utility

//pad string out to Length characters - for output formatting
//SLOW
//TMC TODO consider moving Pad() into Object
final function string Pad(int Length, coerce string S)
{
    while (Len(S) < Length)
        S = S $ " ";

    return S;
}


// Used for getting the PlayerID needed to match back up with RepoItem after
// reconnecting.
function int GetSwatPlayerID()
{
    return SwatPlayerID;
}

//called by Hands when they finish an anim, to decide if they should play an Idle
//(overridden in throwing states)
function bool HandsShouldIdle()
{
    local HandheldEquipment Item;

    Item = Pawn.GetActiveItem();

    return  (
                Item != None
            && Item.IsIdle()
            && Item.IsAvailable()
            && SwatPlayer.HandsShouldIdle()
            );
}

//
// Command Interface
//

//in SP, this changes the currently selected team
//in MP, this changes the currently selected main menu
exec function CommandInterfaceNextGroup()
{
    local CommandInterface CCI, GCI;

    //need to notify both because DefaultCommand style is managed by the GCI
    CCI = CommandInterface(GetFocusInterface(Focus_ClassicCommand));
    GCI = CommandInterface(GetFocusInterface(Focus_GraphicCommand));

//log( self$"::CommandInterfaceNextGroup() ... CCI = "$CCI$", GCI = "$GCI );

#if IG_SWAT_TESTING_MP_CI_IN_SP //tcohen: testing MP CommandInterface behavior in SP
    if (false)
#else
    if (Level.NetMode == NM_Standalone)
#endif
    {
		if (CCI != None)
			CCI.NextTeam();
		if (GCI != None)
			GCI.NextTeam();
	}
    else
    {
        if (CCI != None)
            CCI.NextMainPage();
        if (GCI != None)
            GCI.NextMainPage();
    }
}

simulated function SetPlayerCommandInterfaceTeam(name Team)
{
    local CommandInterface CCI, GCI;

    //need to notify both because DefaultCommand style is managed by the GCI
    CCI = CommandInterface(GetFocusInterface(Focus_ClassicCommand));
    GCI = CommandInterface(GetFocusInterface(Focus_GraphicCommand));

    if (CCI != None)
        CCI.SetCurrentTeam(Team);
    if (GCI != None)
        GCI.SetCurrentTeam(Team);
}

exec function PlayerCommandInterfaceBack()
{
    GetCommandInterface().Back();
}

//only applies to the CCI
exec function GiveCommand(int CommandIndex)
{
    local ClassicCommandInterface CCI;

    if (Repo.GUIConfig.CurrentCommandInterfaceStyle != CommandInterface_Classic)
        return;

    if (Pawn == None || class'Pawn'.static.CheckDead(Pawn))
        return;

    CCI = ClassicCommandInterface(GetCommandInterface());
    assert(CCI != None);    //since Repo.GUIConfig.CurrentCommandInterfaceStyle==CommandInterface_Classic, GetCommandInterface() should be the ClassicCommandInterface

    if (!CCI.Enabled)
        return;

    CCI.GiveCommandIndex(CommandIndex, bHoldCommand > 0);
}

//only applies to the GCI
exec function OpenGraphicCommandInterface()
{
    local GraphicCommandInterface GCI;

    if (Repo.GUIConfig.CurrentCommandInterfaceStyle != CommandInterface_Graphic)
        return;

    if (Pawn == None || class'Pawn'.static.CheckDead(Pawn))
        return;

    GCI = GraphicCommandInterface(GetCommandInterface());
    assert(GCI != None);    //since Repo.GUIConfig.CurrentCommandInterfaceStyle==CommandInterface_Graphic, GetCommandInterface() should be the GraphicCommandInterface

    GCI.Open();
}

exec function CommandOrEquip(NumberRow Row, int Number)
{
    if  (
            Row == Row_NumberKeys
        &&  Repo.GUIConfig.CurrentCommandInterfaceStyle == CommandInterface_Classic
        )
        GiveCommand(Number);
    else
    if  (
            Row == Row_FunctionKeys
        &&  Repo.GUIConfig.CurrentCommandInterfaceStyle == CommandInterface_Graphic
        )
        return;     //can't operate the GCI with keys
    else
        EquipSlot(Number);
}

function ServerGiveCommand(
        int CommandIndex,           //index into Commands array of the command that is being given
        bool IsTaunt,               //is this command a taunt.  This will be used to determine which players receive the command, and on whom effects should be played.
        Pawn Source,                //the player giving the command
        string SourceID,            //unique ID of the source
        Actor TargetActor,          //the actor that the command refers to
        string TargetID,            //unique ID of the target
        Vector TargetLocation,      //the location that the command refers to.
                                    //  Note: will not be PendingCommandTargetActor.Location, because the focus trace will be blocked before that location
        eVoiceType VoiceType)
{
    local SwatGamePlayerController PC;
    local Controller Controller;
    local String SourceActorName;

    if (Level.GetEngine().EnableDevTools)
    {
        mplog("SwatGamePlayerController::ServerGiveCommand() Sending to clients CommandIndex="$CommandIndex
                $", TargetActor="$TargetActor
                $", TargetLocation="$TargetLocation
                $", Source="$Source);
    }

    if( Source == None )
        Source = Pawn(FindByUniqueID( class'Pawn', SourceID ));

    SourceActorName = Source.Controller.GetHumanReadableName();

    //Walk the controller list, and call each client (except the local one) to ClientReceiveCommand()
    for (Controller = Level.ControllerList; Controller != None; Controller = Controller.NextController)
    {
        PC = SwatGamePlayerController(Controller);
        if (PC != None && PC != self)   //we want to skip the client who gave the command because it will take care of itself for instant feedback
        {
            if( PC.Pawn == None || NetPlayer(PC.Pawn) == None )
            {
                if (Level.GetEngine().EnableDevTools)
                    mplog("... skipping ClientReceiveCommand() for PC="$PC$" because the PC doesnt have a pawn.");

                continue;
            }

            //only taunts are played for opponents
            if  (
                    !IsTaunt
                &&  NetPlayer(PC.Pawn).GetTeamNumber() != NetPlayer(Pawn).GetTeamNumber()
                )
            {
                if (Level.GetEngine().EnableDevTools)
                    mplog("... skipping ClientReceiveCommand() for PC="$PC$" because the command is not a Taunt, and PC is on a different team.");

                continue;
            }

            if (Level.GetEngine().EnableDevTools)
                mplog("... calling ClientReceiveCommand() on PC="$PC);

            PC.ClientReceiveCommand(
                    CommandIndex,
                    Source,
                    SourceID,
                    SourceActorName,
                    TargetActor,
                    TargetID,
                    TargetLocation,
                    VoiceType );
        }
    }
}

simulated function ClientReceiveCommand(
        int CommandIndex,
        Actor Source,
        string SourceID,
        String SourceActorName,
        Actor TargetActor,
        string TargetID,
        Vector TargetLocation,
        eVoiceType VoiceType )
{
    GetCommandInterface().ReceiveCommandMP(
            CommandIndex,
            Source,
            SourceID,
            SourceActorName,
            TargetActor,
            TargetID,
            TargetLocation,
            VoiceType);
}

//when a Officer dies, we want to check if any team has no officers.
//  If so, then we want to switch teams or disable the CommandInterface altogether.
private function OnOfficerIncapacitated()
{
    local CommandInterface CCI, GCI;

    CCI = CommandInterface(GetFocusInterface(Focus_ClassicCommand));
    GCI = CommandInterface(GetFocusInterface(Focus_GraphicCommand));

    if (CCI != None)
        CCI.CheckTeam();
    if (GCI != None)
        GCI.CheckTeam();
}

/*  TMC 1/23/2004 disabled support for GCIOpen & GiveCommand on the same button (GCIOpen after delay)

function OnGiveCommandPressed()
{
    GiveCommandIsDown = true;

    if (CommandInterface != GraphicCommandInterface) return;    //default command only applies to GraphicCommandInterface

    if (GiveCommandTimer == None)
    {
        GiveCommandTimer = new class'Timer';
        GiveCommandTimer.TimerDelegate = GraphicCommandInterfaceDelayElapsed;
    }

    GiveCommandTimer.StartTimer(GraphicCommandInterfaceDelay, false, true); //don't loop, do reset
}

function OnGiveCommandReleased()
{
    GiveCommandIsDown = false;

    assertWithDescription(GiveCommandTimer != None,
        "[tcohen] SwatGamePlayerController::OnGiveCommandReleased() but GiveCommandTimer==None so we must have missed the OnGiveCommandPressed().");

    if (GiveCommandTimer.IsRunning())
    {
        //The timer is still running, so the GraphicCommandInterfaceDelay hasn't elapsed.
        //Stop the timer, and give the DefaultCommand

        GiveCommandTimer.StopTimer();

        CommandInterface.GiveDefaultCommand();
    }
    //else, the GiveCommandTimer already elapsed, and called GiveCommandTimeElapsed().
    //  We don't need to do anything more
}

//called by the GiveCommandTimer when its time has elapsed
function GraphicCommandInterfaceDelayElapsed()
{
    assert(GiveCommandTimer != None);   //we should only be called by the GiveCommandTimer

    GiveCommandTimer.StopTimer();

    OpenGraphicCommandInterface();
}

*/

// Executes on the client only
simulated function ClientMeleeForPawn( SwatPlayer theSwatPlayer, EquipmentSlot ItemSlot )
{
    local HandheldEquipment Item;
    local OfficerLoadOut theLoadOut;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientMeleeForPawn(). Told by server to melee with item. Pawn="$theSwatPlayer$", Slot="$ItemSlot );

    if ( theSwatPlayer == None )
        return;

    theLoadOut = theSwatPlayer.GetLoadOut();
    if ( theLoadOut == None )
        return;

    Item = theLoadOut.GetItemAtSlot( ItemSlot );
    if ( Item == None )
        return;

	if ( !Item.bAbleToMelee )
		return;

    if ( Level.NetMode != NM_Standalone && !Item.PrevalidateMelee() )
        return;

	if ( theSwatPlayer.ValidateMelee() )
	{
		if (Level.GetEngine().EnableDevTools)
			mplog( "...Calling Melee() on: "$Item );

		Item.Melee();
	}
}

// Executes on the client only
simulated function ClientReloadForPawn( SwatPlayer theSwatPlayer, EquipmentSlot ItemSlot )
{
    local FiredWeapon Item;
    local OfficerLoadOut theLoadOut;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientReloadForPawn(). Told by server to reload item. Pawn="$theSwatPlayer$", Slot="$ItemSlot );

    if ( theSwatPlayer == None )
        return;

    theLoadOut = theSwatPlayer.GetLoadOut();
    if ( theLoadOut == None )
        return;

    Item = FiredWeapon( theLoadOut.GetItemAtSlot( ItemSlot ));
    if ( Item == None )
        return;

    if ( Level.NetMode != NM_Standalone && !Item.PrevalidateReload() )
        return;

    if ( theSwatPlayer.ValidateReload() )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...Calling Reload() on: "$Item );

        Item.Reload();
    }
}


// Executes only on client during COOP. Forces an AI to reload their current
// weapon, if the weapon is idle.
simulated function ClientDoAIReload( Pawn theAIPawn )
{
    local FiredWeapon Item;

    if (Level.GetEngine().EnableDevTools)
        mplog( "---SGPC::ClientDoAIReload(). Told by server to reload. Pawn="$theAIPawn );

    Assert( Level.NetMode == NM_Client );
    Assert( Level.IsPlayingCOOP );

    if ( theAIPawn == None )
        return;

    Item = FiredWeapon(theAIPawn.GetActiveItem());
    AssertWithDescription( Item != None, "Was told to reload for an AI, but the active item was None. Pawn="$theAIPawn );
    if ( Item == None )
        return;

    // We should really be doing something equivalent to
    // SwatPlayer::ValidateReload(), so that we can tell if the pawn is in the
    // process of doing something that would make reloading impossible, even
    // though the active item is idle. In practice, I think that doing
    // the PrevalidateReload() should be sufficient, since AI's only have
    // primary and backup weapons, not things like grenades, etc.
    if ( Item.PrevalidateReload() )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...Calling Reload() on: "$Item );

        Item.Reload();
    }
}


//
// GUI HUD
//

simulated function HUDPageBase GetHUDPage()
{
    if (HUDPage == None)
    {
        if( self == Level.GetLocalPlayerController() &&
            Repo.GUIController != None )
        {
            HUDPage = SwatGUIControllerBase(Repo.GUIController).GetHUDPage();
        }
    }

    return HUDPage;
}

simulated function bool HasHUDPage()
{
    if (HUDPage == None)
    {
        GetHUDPage();
    }
    return (HUDPage != None);
}

// Toggle the player's flashlight
exec function ToggleFlashlight()
{
    SwatPawn(Pawn).ToggleDesiredFlashlightState();
}

// modifier to hold the next command was pressed
exec function HoldCommand(bool bPressed)
{
	local OfficerTeamInfo Team;
    local GraphicCommandInterface GCI;

	if (Level.NetMode != NM_Standalone)
		return;

	Team = GetCommandInterface().CurrentCommandTeam;
    GCI = GraphicCommandInterface(GetCommandInterface());

	//LOG("HOLDCOMMAND:" @ bPressed @ "GDC:" @ GCI != None && GCI.IsOpen() @ "DEF:" @ GetCommandInterface().GetDefaultCommand());
	if (bPressed)
		bHoldCommand = 1;
	else
		bHoldCommand = 0;

	if (bPressed)
	{
		if (GCI != None && GCI.IsOpen())
		{
			if (GCI.IsCurrentCommandHoldable())
				GetCommandInterface().SetHeldCommandCaptions(GCI.GetCurrentCommand(), Team);
		}
		else
		{
			if (GetCommandInterface().GetDefaultCommand().Command != Command_Zulu)
				GetCommandInterface().SetHeldCommandCaptions(GetCommandInterface().GetDefaultCommand(), Team);
		}
	}
	else
		GetCommandInterface().RestoreHeldCommandCaptions();
}

// issue compliance (using our pawn)
exec function IssueCompliance()
{
    local name PlayerTag;

    //set the voice tag for the player issuing compliance
    if( NetPlayer(Pawn) != None )
    {
        if( NetPlayer(Pawn).IsTheVIP() )
            PlayerTag = 'VIP';
        else
            PlayerTag = Repo.GuiConfig.GetTagForVoiceType( NetPlayer(Pawn).VoiceType );
    }

	ServerIssueCompliance( string(PlayerTag) );
}

function ServerIssueCompliance( optional string VoiceTag )
{
	   local bool ACharacterHasAWeaponEquipped;
     local NetPlayer theNetPlayer;
     local int TargetIsSuspect;
     local int TargetIsAggressiveHostage;
     local vector CameraLocation;
     local rotator CameraRotation;
     local Actor Candidate;

     CalcViewForFocus(Candidate, CameraLocation, CameraRotation );

     if(ViewTarget != Pawn) {
       log("ServerIssueCompliance: ViewTarget ("$ViewTarget$") != Pawn ("$Pawn$")");
     }
    if( CanIssueCompliance() )
    {
        StartIssueComplianceTimer();

        theNetPlayer = NetPlayer(Pawn);
        if( theNetPlayer != None && !Level.IsPlayingCOOP )
        {
            if( theNetPlayer.IsTheVIP() && theNetPlayer.IsArrested() && !theNetPlayer.IsNonlethaled() )
            {
                //dkaplan: note, the voice tag should always be 'VIP' in this case
                Assert( name(VoiceTag) == 'VIP' );
                Pawn.BroadcastEffectEvent('VIPHelp',,,,,,,,name(VoiceTag));
            }
            return;
        }

	    // IssueCompliance returns true if any character that listens to us has a weapon equipped
	    ACharacterHasAWeaponEquipped = SwatPawn(Pawn).IssueCompliance();

      if (VoiceTag != "") { // Might be legitimately None, because it could be issued through the Speech Command Interface
        if (ACharacterHasAWeaponEquipped)
        {
            Pawn.BroadcastEffectEvent('AnnouncedComplyWithGun',,,,,,,,name(VoiceTag));
        }
        else if(!SwatPawn(Pawn).ShouldIssueTaunt(CameraLocation, vector(CameraRotation), FocusTestDistance, TargetIsSuspect, TargetIsAggressiveHostage))
		{
          Pawn.BroadcastEffectEvent('AnnouncedComply',,,,,,,,name(VoiceTag));
        }
        else if(TargetIsSuspect == 1)
		{
          Pawn.BroadcastEffectEvent('ArrestedSuspect',,,,,,,,name(VoiceTag));
        }
        else if((TargetIsSuspect == 0) && (TargetIsAggressiveHostage == 1))
		{
          Pawn.BroadcastEffectEvent('ReassuredAggressiveHostage',,,,,,,,name(VoiceTag));
        }
        else
		{
          Pawn.BroadcastEffectEvent('ReassuredPassiveHostage',,,,,,,,name(VoiceTag));
        }
      } else
	  {
        log("[SPEECH] Issued compliance.");
      }
    }
}

simulated function bool CanIssueCompliance()
{
    return ComplianceTimer == None || !ComplianceTimer.IsRunning();
}

simulated function StartIssueComplianceTimer()
{
    if( ComplianceTimer == None )
        ComplianceTimer = Spawn(class'Timer');
    assert(ComplianceTimer != None);
    ComplianceTimer.StartTimer( ComplianceTime, false, true );
}

simulated function bool CanIssueCommand()
{
    return CommandTimer == None || !CommandTimer.IsRunning();
}

simulated function StartIssueCommandTimer()
{
    if( CommandTimer == None )
        CommandTimer = Spawn(class'Timer');
    assert(CommandTimer != None);
    CommandTimer.StartTimer( CommandTime, false, true );
}

exec function IssueComplianceOrInteract()
{
    //if there's currently something to interact with, then do that
    //otherwise, issue compliance

    if (GetFocusInterface(Focus_Use).GetDefaultFocusActor() != None)
        Interact();
    else
        IssueCompliance();
}

exec function GiveDefaultCommand()
{
    if (Pawn == None || class'Pawn'.static.CheckDead(Pawn))
        return;

    if (GetCommandInterface().Enabled)
        GetCommandInterface().GiveDefaultCommand(bHoldCommand > 0);
}

simulated function OnStateChange( eSwatGameState oldState, eSwatGameState newState )
{
    local DynamicLoadOutSpec CurrentMultiplayerLoadOut;

log("[dkaplan] >>> OnStateChange of (SwatGamePlayerController) "$self$" from state "$GetEnum(eSwatGameState,oldState)$" to state "$GetEnum(eSwatGameState, newState));
    if( newState == GAMESTATE_PreGame &&
       (Repo.GuiConfig.SwatGameRole == GAMEROLE_MP_Client ||
        Repo.GuiConfig.SwatGameRole == GAMEROLE_MP_Host) )
    {
        CurrentMultiplayerLoadOut = Spawn(class'SwatGame.DynamicLoadOutSpec', , name("CurrentMultiplayerLoadOut"));
        SetMPLoadOut(CurrentMultiplayerLoadOut);
        CurrentMultiplayerLoadOut.Destroy();

        ViewFromLocation( 'InitialPositionMarker' );
    }

    //set the game to paused if not actually playing the round, SP only

    //if( newState == GAMESTATE_PreGame &&
    //   (Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Client) )
    //{
    //    SetPause(true);
    //}

    else if( newState == GAMESTATE_MidGame &&
       (Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Client) &&
       (Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Host) )
    {
        SetPause(false);
    }
    else if( newState == GAMESTATE_PostGame &&
       (Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Client) &&
       (Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Host) )
    {
        // Mark ourselves as observing, so that AHands::Tick will know
        // not to render the first person hands if we can see ourselves from
        // the in the splash camera viewpoint (e.g., if we abort the
        // mission and happen to be standing in the splash camera's view --
        // the camera position is set in SwatGUIPage.Show() when the
        // mission is aborted).
        bIsObserving = true;

        SetPause(!SPBombExploded);
    }
    else if ( newState == GAMESTATE_PostGame &&
        (Repo.GuiConfig.SwatGameRole == GAMEROLE_MP_Client || Repo.GuiConfig.SwatGameRole == GAMEROLE_MP_Host) )
    {
        SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).StopAllLoopingSchemas();
    }
}

event PreClientTravel()
{
    Repo.PreClientTravel();
    Super.PreClientTravel();
}


exec function TestStung()
{
    local Range Range;

    Range.Min = 0;  Range.Max = 0;

    SwatPlayer(Pawn).ReactToStingGrenade(
        None,           //Grenade - None will make the effect think it was a LessLethal Shotgun
        None,           //Instigator Pawn (who shot the grenade?)
        0, 0,           //DamageRadius
        Range,          //KarmaImpulse
        0,              //KarmaImpulseRadius
        0,              //StingRadius
        10.0,           //PlayerStingDuration
        6.0,            //HeavilyArmoredPlayerStingDuration
		14.0,           //NonArmoredPlayerStingDuration
        0,              //AIStingDuration
        0);             //MoraleModifier
}


exec function Loc()
{
    local Actor Act;
    local vector Loc;
    local rotator Rot;

    PlayerCalcView( Act, Loc, Rot );

    log( "Player == "$Act$", Location == "$Loc$", Rotation == "$Rot );
}

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
exec function TestDoorBlocking(int Times)
{
    GetCommandInterface().TestDoorBlocking(Pawn, Times);
}
#endif

///////////////////////////////////////////////////////////////////////////////

simulated function SetAlwaysRun( bool NewValue )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::SetAlwaysRun(). NewValue="$NewValue );

    bAlwaysRun = NewValue;
    ServerSetAlwaysRun( NewValue );
}

function ServerSetAlwaysRun( bool NewValue )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerSetAlwaysRun(). NewValue="$NewValue );

    bAlwaysRun = NewValue;
}


// Override HandleWalking in Engine.PlayerController so that the player
// is running when the 'bRun' button is down, instead of when it is up
function HandleWalking()
{
    local bool WantsToWalk; //versus run
    local HandheldEquipment ActiveItem;

    if ( IsLocationFrozen() )
    {
        //null-out any positional input
        aForward = 0;
        aStrafe = 0;
    }
    if ( IsRotationFrozen() )
    {
        //null-out any rotational input
        aLookUp = 0;
        aTurn = 0;
    }

	if ( Pawn != None )
    {
		ActiveItem = Pawn.GetActiveItem();
        //WantsToWalk = bool(bRun) == Repo.GuiConfig.bAlwaysRun; // MCJ: old version.
        WantsToWalk = (WantsZoom && ActiveItem.ShouldWalkInIronsights()) || bool(bRun) == bAlwaysRun;
		Pawn.SetWalking( WantsToWalk && !Region.Zone.IsA('WarpZoneInfo') );

        if (aForward == 0 && aStrafe == 0)
        {
            if (LastMovingMode != Moving_Standing)
                TransitionToStanding(LastMovingMode);
        }
        else
        if (WantsToWalk)
        {
            if (LastMovingMode != Moving_Walking)
                TransitionToWalking(LastMovingMode);
        }
        else //wants to run
        {
            if (LastMovingMode != Moving_Running)
                TransitionToRunning(LastMovingMode);
        }
    }
}

function TransitionToStanding(MovingMode inLastMovingMode)
{
    LastMovingMode = Moving_Standing;
}

function TransitionToWalking(MovingMode inLastMovingMode)
{
    LastMovingMode = Moving_Walking;

    //if going from running to walking, don't add error
    if (inLastMovingMode == Moving_Standing && Pawn.LeanState == kLeanStateNone)
        ConsiderAddingAimError(AimPenalty_StandToWalk);
}

function TransitionToRunning(MovingMode inLastMovingMode)
{
    LastMovingMode = Moving_Running;

    if (Pawn.LeanState == kLeanStateNone)
    {
        ConsiderAddingAimError(AimPenalty_WalkToRun);

        //if we were standing, then we need to apply the StandToWalk penalty too
        if (inLastMovingMode == Moving_Standing)
            ConsiderAddingAimError(AimPenalty_StandToWalk);
    }
}

function ConsiderAddingAimError(AimPenaltyType Penalty)
{
    local HandheldEquipment ActiveItem;

    ActiveItem = Pawn.GetActiveItem();
    if (ActiveItem != None && ActiveItem.IsA('FiredWeapon'))
        FiredWeapon(ActiveItem).AddAimError(Penalty);
}

///////////////////////////////////////////////////////////////////////////////
function ClientSkeletalRegionHit(ESkeletalRegion RegionHit, int damage)
{
    Assert( self == Level.GetLocalPlayerController() );
    GetHUDPage().SkeletalRegionHit(RegionHit, damage);
}

///////////////////////////////////////////////////////////////////////////////

simulated function OnBombExploded()
{
    local BombBase Bomb;
    local Actor Marker;
    local pawn p;

    Marker = findStaticByLabel(class'Actor','BombExplodedMarker');
    Marker.TriggerEffectEvent('PostBombExploded');

    foreach DynamicActors(class'BombBase', Bomb)
    {
        Bomb.TriggerEffectEvent('BombExploded');
        Bomb.Hide();
    }

    foreach DynamicActors(class'Pawn', p)
    {
		p.Died(None, class'GenericDamageType', Vect(0,0,0)
#if IG_SWAT
            , Vect(0,0,0)
#endif
            );
    }

    dispatchMessage(new class'MessageBombExploded'());

    //if in SP - do special game ended handling
    if( (Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Client) &&
        (Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Host) )
    {
        SPBombExploded = true;
        SetViewTarget(Marker);
        UnPossess();
        GotoState('GameEnded');
    }
}

//update the sound effect played on the bomb when we get a 'OneMinWarning'
simulated function OnOneMinWarning()
{
    local BombBase Bomb;

    foreach DynamicActors(class'BombBase', Bomb)
    {
        if( Bomb.IsActive() )
            Bomb.TriggerEffectEvent('OneMinWarning');
    }
}

//Used by SpeechCommand interface
simulated function SwatPlayer GetSwatPlayer()
{
	local SwatPlayer Player;

	if( pawn != None )
    {
        Player = SwatPlayer(Pawn);
    }
    if( Player == None && ViewTarget != None )
    {
        Player = SwatPlayer(ViewTarget);
    }

    return Player;
}

simulated function bool HasAWeaponEquipped()
{
	local HandheldEquipment Equipment;

	Equipment = Pawn.GetActiveItem();

	return Equipment.IsA('FiredWeapon') && !Equipment.IsA('PepperSpray');
}

simulated function bool IsLocationFrozen()
{
    local SwatPlayer thePlayer;

    thePlayer = SwatPlayer(Pawn);

    if ( Pawn != None )
    {
        if ( thePlayer.IsTheVIP() )
            return DebugLocationFrozen || thePlayer.IsTased() || (thePlayer.IsNonlethaled() && thePlayer.IsArrested());
        else
            return DebugLocationFrozen || thePlayer.IsTased();
    }
    else
    {
        return false;
    }
}

simulated function bool IsRotationFrozen()
{
    local SwatPlayer thePlayer;

    thePlayer = SwatPlayer(Pawn);

    if ( Pawn != None )
    {
        return DebugLocationFrozen || ( thePlayer.IsTased() && !thePlayer.IsArrested() );
    }
    else
    {
        return false;
    }
}

// IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if( Level.NetMode == NM_Standalone && Pawn.IsA('SwatOfficer') )
    OnOfficerIncapacitated();
}

// IInterested_GameEvent_PawnDamaged implementation
function OnPawnDamaged(Pawn Pawn, Actor Damager)
{
//log( self$"::OnPawnDamaged( "$Pawn$" )... Pawn.Health = "$Pawn.Health );
    if( Level.IsCOOPServer && Pawn.IsA('SwatPlayer') )
        OnPlayerDamaged( Pawn );
}

function OnPlayerDamaged( Pawn Pawn )
{
    local SwatPlayerReplicationInfo SPRI;

    if (Pawn.Controller != None)
    {
        SPRI = SwatPlayerReplicationInfo(SwatGamePlayerController(Pawn.Controller).PlayerReplicationInfo);

        if( SPRI != None &&
            SPRI.COOPPlayerStatus != STATUS_Incapacitated )
            SPRI.COOPPlayerStatus = STATUS_Injured;
    }
}

// RPC on the client that triggers the given effect event on the given source actor.
// If the SourceActor is not relevant and cannont be referenced by uniqueID, the call is ignored.
simulated function ClientBroadcastStopAllSounds(  SwatPawn SourceActor,
                                                  String UniqueIdentifier )
{
    if( SourceActor == None )
    {
        SourceActor = SwatPawn(FindByUniqueID( None, UniqueIdentifier ));

        if( SourceActor == None )
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "Warning!  ClientBroadcastStopAllEffectEvents called with a non-relevant source actor!" );

            return;
        }
    }

    if (Level.GetEngine().EnableDevTools)
        mplog( "Client: "$Self$", stopping all effect events on source actor: "$SourceActor );

    SourceActor.StopAllSounds();
}

//Debugging:

exec function GCIButtons(int Mode)
{
    Repo.GuiConfig.GCIButtonMode = Mode;
}

exec function GCICancelPad(bool Show)
{
    Repo.GuiConfig.bUseExitMenu = Show;
}

exec function TestClientMessage( name type, string Msg )
{
    ClientMessage( Msg, type );
}

/*
//For debugging. These can be considered cheats and probably should
be moved to SwatCheatManager
exec function SetFlashlightRadius(float radius)
{
	local HandheldEquipment ActiveItem;
	local FiredWeapon ActiveWeapon;

	ActiveItem = Pawn.GetActiveItem();
	ActiveWeapon = FiredWeapon(ActiveItem);
	if (ActiveWeapon != None) {
		ActiveWeapon.SetFlashlightRadius(radius);
	}
}
exec function SetFlashlightCone(float cone)
{
	local HandheldEquipment ActiveItem;
	local FiredWeapon ActiveWeapon;

	ActiveItem = Pawn.GetActiveItem();
	ActiveWeapon = FiredWeapon(ActiveItem);
	if (ActiveWeapon != None) {
		ActiveWeapon.SetFlashlightCone(cone);
	}
}
*/

#if IG_SWAT_AUDIT_FOCUS
//causes an audit of the PlayerFocusInterfaces for one call to UpdateFocus()
exec function AuditFocus()
{
    bAuditFocus = true;
}
#endif

exec function EditAtFocus()
{
    local name it;

    it = FocusInterfaces[int(EFocusInterface.Focus_GraphicCommand)].GetDefaultFocusActor().name;
    log("EditAtFocus: name="$it);
    ConsoleCommand("editactor name="$it);
}

function PostGameStarted()
{
    if( SwatGameInfo(Level.Game) != None )
    SwatGameInfo(Level.Game).PostGameStarted();
}

function OnServerSettingsUpdated()
{
    SwatGameInfo(Level.Game).OnServerSettingsUpdated( self );
}

exec function LogScoring()
{
    local SwatGameReplicationInfo SGRI;

    SGRI = SwatGameReplicationInfo(GameReplicationInfo);
    if( SGRI != None )
        SGRI.LogScoring( Repo );
}

function ClientStartConversation( Name ConversationName )
{
    Repo.GetConversationManager().ClientStartConversation( ConversationName );
}

function ClientSetTrainingText( Name TrainingText )
{
    Repo.GetTrainingTextManager().ClientSetTrainingText( TrainingText );
}

function ClientSetObjectiveVisibility( string ObjectiveName, bool Visible )
{
    Repo.SetObjectiveVisibility( name(ObjectiveName), Visible );
}

simulated function ClientReportableReportedToTOC( IAmReportableCharacter ReportableCharacter, string inUniqueID, string PlayerTag, string PlayerName )
{
    local SwatPlayer Player;

    if( pawn != None )
    {
        Player = SwatPlayer(Pawn);
    }
    if( Player == None && ViewTarget != None )
    {
        Player = SwatPlayer(ViewTarget);
    }
    if( Player != None )
    {
        Player.OnClientReportableReportedToTOC( ReportableCharacter, inUniqueID, PlayerTag, PlayerName );
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
// GUI EXECs
///////////////////////////////////////////////////////////////////////////////////////////

//open the popup as a popup
exec function ShowInGamePopup()
{
    SwatGUIControllerBase(Repo.GUIController).ShowGamePopup( false );
}

//open the popup as a sticky
exec function GUICloseMenu()
{
//log( "dkaplan .......... "$self$"::GUICloseMenu()... Repo = "$Repo$", Repo.GUIController = "$Repo.GUIController );
    SwatGUIControllerBase(Repo.GUIController).ShowGamePopup( true );
}

// open the swap weapon page
exec function SwapWeapon()
{
	if(Level.NetMode == NM_Standalone)
	{
		SwatGUIControllerBase(Repo.GUIController).ShowWeaponCabinet();
	}
}

exec function OpenHudChat(bool bGlobal)
{
    SwatGUIControllerBase(Repo.GUIController).OpenChat( bGlobal );
}


exec function ScrollChatPageUp()
{
    SwatGUIControllerBase(Repo.GUIController).ScrollChatPageUp();
}

exec function ScrollChatPageDown()
{
    SwatGUIControllerBase(Repo.GUIController).ScrollChatPageDown();
}

exec function ScrollChatUp()
{
    SwatGUIControllerBase(Repo.GUIController).ScrollChatUp();
}

exec function ScrollChatDown()
{
    SwatGUIControllerBase(Repo.GUIController).ScrollChatDown();
}

exec function ScrollChatToHome()
{
    SwatGUIControllerBase(Repo.GUIController).ScrollChatToHome();
}

exec function ScrollChatToEnd()
{
    SwatGUIControllerBase(Repo.GUIController).ScrollChatToEnd();
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

function GivenEquipmentFromMenu(class<SwatWeapon> Weapon, class<SwatAmmo> Ammo)
{
	local HandheldEquipment ActiveItem;
	local HandheldEquipment NewItem;
	local SwatWeapon WeaponItem;

	ActiveItem = SwatPlayer.GetActiveItem();

	NewItem = Spawn(Weapon, SwatPlayer);
	WeaponItem = SwatWeapon(NewItem);
	WeaponItem.AmmoClass = Ammo;
	NewItem.SetAvailable(true);
	WeaponItem.OnGivenToOwner();
	NewItem.Pickup = None;
	NewItem.Equip();

	SwatPlayer.OnPickedUp(NewItem);
}

simulated function ClientAddPrecacheableMaterial( string MaterialName )
{
    local Material Precacheable;

    Precacheable = Material( DynamicLoadObject( MaterialName, class'Material' ) );

    if( Precacheable != None )
        Level.AddPrecacheMaterial( Precacheable );
}

simulated function ClientAddPrecacheableMesh( string MeshName )
{
    local Mesh Precacheable;

    Precacheable = Mesh( DynamicLoadObject( MeshName, class'Mesh' ) );

    if( Precacheable != None )
        Level.AddPrecacheMesh( Precacheable );
}

simulated function ClientAddPrecacheableStaticMesh( string StaticMeshName )
{
    local StaticMesh Precacheable;

    Precacheable = StaticMesh( DynamicLoadObject( StaticMeshName, class'StaticMesh' ) );

    if( Precacheable != None )
        Level.AddPrecacheStaticMesh( Precacheable );
}

simulated function ClientPrecacheAll( bool LoadFemaleAnimSets )
{
    local array<string> AnimSetNames;

    //generate a list on animation set names to precache
    class'SwatPawn'.static.StaticGetAnimPackageGroups( AnimSetNames, LoadFemaleAnimSets );

    //DLO but dont link animation sets (will maintain refrences to the anim sets locally)
    LoadAnimationSets( AnimSetNames, true );
}

native simulated function FlagForPrecache();

native simulated function bool IsNetRelevant( Pawn PawnInQuestion );

///////////////////////////////////////////////////////////////////////////////

// Render the blur that appears when you are zoomed in with your weapon.
simulated event RenderOverlays( canvas Canvas )
{
	local HandheldEquipment ActiveItem;

	if (ZoomAlpha > 0 && ZoomBlurFader != None)
	{
		ActiveItem = Pawn.GetActiveItem();
		if ( ActiveItem != None &&                  // don't draw if nothing in hand
		     ActiveItem.ZoomedFOV != BaseFOV &&     // don't draw overlay if desired zoom is same as default FOV
             ActiveItem.ZoomedFOV != 0 &&           // don't draw overlay if zoom is unset (i.e., is 0)
			 ActiveItem.ZoomBlurOverlay != None)    // don't draw if no overlay
		{
			//log("ZoomAlpha = "$ZoomAlpha$" ZoomAlpha*255="$ZoomAlpha * 255$" ActiveItem.ZoomedFOV = "$ActiveItem.ZoomedFOV$" BaseFOV = "$BaseFOV);
			//log("ZoomBlurFader = "$ZoomBlurFader);

			ColorModifier(ZoomBlurFader).Material = ActiveItem.ZoomBlurOverlay;
			ColorModifier(ZoomBlurFader).Color.A = ZoomAlpha * 255;

			// Draw the texture, starting at the top left corner of screen
			Canvas.SetPos(0, 0); // top-left
			// Note: have to hardcode size of material to 512x512 because there's no
			// way to get the size of a Material (only Textures)
			Canvas.DrawTile(
				ZoomBlurFader,	    // material
				Canvas.ClipX,		// extend the drawing to the bottom-right corner of screen
				Canvas.ClipY,		// extend the drawing to the bottom-right corner of screen
				0,					// Start with the top-left corner of the texture
				0,					// Start with the top-left corner of the texture
				512,				// Extend to the bottom-right corner of the 512x512 texture
				512);				// Extend to the bottom-right corner of the 512x512 texture
		}
   }

   //RenderDebugInfo(Canvas);
}

simulated function RenderDebugInfo(Canvas Canvas)
{
    local float YP;

    YP = 40;

    Canvas.SetDrawColor(255, 255, 255, 255);

    Canvas.SetPos(10, YP);
    Canvas.DrawText("GivenFlashbangs: " $ SwatPlayer(Pawn).GivenFlashbangs);
    YP += 16;
    Canvas.SetPos(10, YP);
    Canvas.DrawText("GivenFlashbangs AvailableCount: " $ SwatPlayer(Pawn).GivenFlashbangs.GetAvailableCount());
}

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	ZoomBlurFader=Material'HUD.ZoomBlurFader'
    PlayerReplicationInfoClass=Class'SwatGame.SwatPlayerReplicationInfo'
    DebugShouldRecoil=true
    bIsPlayer=true
    SpectateSpeed=+200.0
    BeingCuffedTimeout=10
    ThisPlayerIsTheVIP=false
    SniperAlertTime=4
    EquipmentSlotForQualify=SLOT_Invalid
    FlashbangRetinaImageTextureWidth=800
    FlashbangRetinaImageTextureHeight=600

    ForceObserverTime=5.0

    CommandTime=1.0
    ComplianceTime=1.5
}
