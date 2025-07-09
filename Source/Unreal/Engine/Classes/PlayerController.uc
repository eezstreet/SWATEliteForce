//=============================================================================
// PlayerController
//
// PlayerControllers are used by human players to control pawns.
//
// This is a built-in Unreal class and it shouldn't be modified.
// for the change in Possess().
//=============================================================================
class PlayerController extends Controller
	config(user)
	native
    nativereplication;

// Player info.
var const player Player;

// player input control
var globalconfig	bool 	bLookUpStairs;	// look up/down stairs (player)
var globalconfig	bool	bSnapToLevel;	// Snap to level eyeheight when not mouselooking
var globalconfig	bool	bAlwaysMouseLook;
var globalconfig	bool	bKeyboardLook;	// no snapping when true
var bool					bCenterView;

// Player control flags
var bool		bBehindView;    // Outside-the-player view.
var bool		bFrozen;		// set when game ends or player dies to temporarily prevent player from restarting (until cleared by timer)
var bool		bPressedJump;
var	bool		bDoubleJump;
var bool		bUpdatePosition;
var bool		bIsTyping;
var bool		bFixedCamera;	// used to fix camera in position (to view animations)
var bool		bJumpStatus;	// used in net games
var	bool		bUpdating;

#if !IG_SWAT    //tcohen: weapon zoom
var bool		bZooming;
#endif

var globalconfig bool bAlwaysLevel;
var bool		bSetTurnRot;
var bool		bCheatFlying;	// instantly stop in flying mode
var bool		bFreeCamera;	// free camera when in behindview mode (for checking out player models and animations)
var	bool		bZeroRoll;
var	bool		bCameraPositionLocked;
var	bool		bViewBot;
var bool		UseFixedVisibility;
var bool	bBlockCloseCamera;
var bool	bValidBehindCamera;
var bool	bForcePrecache;
var bool	bClientDemo;
var const bool bAllActorsRelevant;	// used by UTTV.  DO NOT SET THIS TRUE - it has a huge impact on network performance
var bool	bShortConnectTimeOut;	// when true, reduces connect timeout to 15 seconds
var bool	bPendingDestroy;		// when true, playercontroller is being destroyed

var globalconfig bool bNoVoiceMessages;
var globalconfig bool bNoVoiceTaunts;
var globalconfig bool bNoAutoTaunts;
var globalconfig bool bAutoTaunt;
var public bool bSecondaryWeaponLast;
var globalconfig bool bDynamicNetSpeed;

var(VoiceChat)               bool           bVoiceChatEnabled;	    // Whether voice chat is enabled on this client
var(VoiceChat)  globalconfig bool           bEnableInitialChatRoom; // Enables speaking on DefaultActiveChannel upon joining server

var globalconfig byte AnnouncerLevel;  // 0=none, 1=no possession announcements, 2=all
var globalconfig byte AnnouncerVolume; // 1 to 4
var globalconfig float AimingHelp;
var globalconfig float MaxResponseTime;		// how long server will wait for client move update before setting position
var float WaitDelay;			// Delay time until can restart

var input float
	aBaseX, aBaseY, aBaseZ,	aMouseX, aMouseY,
	aForward, aTurn, aStrafe, aUp, aLookUp;

var input byte
	bStrafe, bSnapLevel, bLook, bFreeLook, bTurn180, bTurnToNearest, bXAxis, bYAxis;

var EDoubleClickDir DoubleClickDir;		// direction of movement key double click (for special moves)

// Camera info.
var int ShowFlags;
#if IG_R // rowan: Extended show flags for new rendering stuff
var int ExShowFlags;
#endif
var int Misc1,Misc2;

var int RendMap;
var float        OrthoZoom;     // Orthogonal/map view zoom factor.
var const actor ViewTarget;
var const Controller RealViewTarget;
var PlayerController DemoViewer;
var float CameraDist;		// multiplier for behindview camera dist
var vector OldCameraLoc;		// used in behindview calculations
var rotator OldCameraRot;
var transient array<CameraEffect> CameraEffects;	// A stack of camera effects.

#if IG_SWAT		//tcohen: weapon zoom
var globalconfig float BaseFOV;
var float ZoomedFOV;
var config private float ZoomTime;
var config private float ZoomBezierPt1X;
var config private float ZoomBezierPt1Y;
var config private float ZoomBezierPt2X;
var config private float ZoomBezierPt2Y;
//the current zoom alpha.  0 is no zoom, 1 is full zoom.  updated natively.
var float ZoomAlpha;
var bool WantsZoom;
#else
var globalconfig float DesiredFOV;
var globalconfig float DefaultFOV;
var float		ZoomLevel;
#endif

// Fixed visibility.
var vector	FixedLocation;
var rotator	FixedRotation;
var matrix	RenderWorldToCamera;

// Screen flashes
var vector FlashScale, FlashFog;
var float ConstantGlowScale;
var vector ConstantGlowFog;
#if IG_SHARED // dbeswick: support for cinematic fade action
var bool bManualFogUpdate;
#endif

// Distance fog fading.
var color	LastDistanceFogColor;
var float	LastDistanceFogStart;
var float	LastDistanceFogEnd;
var float	CurrentDistanceFogEnd;
var float	TimeSinceLastFogChange;
var int		LastZone;

// Remote Pawn ViewTargets
#if IG_SWAT
var vector      TargetViewLocation;
#else
var float		TargetEyeHeight;
#endif
var rotator		TargetViewRotation;
var rotator     BlendedTargetViewRotation;

var HUD	myHUD;	// heads up display info

var float LastPlaySound;
var float LastPlaySpeech;

// Music info.
var string				Song;
var EMusicTransition	Transition;

// Move buffering for network games.  Clients save their un-acknowledged moves in order to replay them
// when they get position updates from the server.
var SavedMove SavedMoves;	// buffered moves pending position updates
var SavedMove FreeMoves;	// freed moves, available for buffering
var SavedMove PendingMove;
var float CurrentTimeStamp,LastUpdateTime,ServerTimeStamp,TimeMargin, ClientUpdateTime;
var globalconfig float MaxTimeMargin;

// Progess Indicator - used by the engine to provide status messages (HUD is responsible for displaying these).
var string	ProgressMessage[4];
var color	ProgressColor[4];
var float	ProgressTimeOut;

// Localized strings
var localized string QuickSaveString;
var localized string NoPauseMessage;
var localized string OwnCamera;

// ReplicationInfo
var VoiceChatReplicationInfo VoiceReplicationInfo;
var GameReplicationInfo GameReplicationInfo;

// Stats Logging
var globalconfig string StatsUsername;
var globalconfig string StatsPassword;

var class<LocalMessage> LocalMessageClass;

// view shaking (affects roll, and offsets camera position)
var float	MaxShakeRoll; // max magnitude to roll camera
var vector	MaxShakeOffset; // max magnitude to offset camera position
var float	ShakeRollRate;	// rate to change roll
var vector	ShakeOffsetRate;
var vector	ShakeOffset; //current magnitude to offset camera from shake
var float	ShakeRollTime; // how long to roll.  if value is < 1.0, then MaxShakeOffset gets damped by this, else if > 1 then its the number of times to repeat undamped
var vector	ShakeOffsetTime;

#if IG_MOJO // rowan: Cinematic camera shake for mojo
var vector	CinematicShakeOffset;
var rotator	CinematicShakeRotate;
#endif

var Pawn		TurnTarget;
var config int	EnemyTurnSpeed;
var int			GroundPitch;
var rotator		TurnRot180;

var vector OldFloor;		// used by PlayerSpider mode - floor for which old rotation was based;

// Components ( inner classes )
var private transient CheatManager    CheatManager;   // Object within playercontroller that manages "cheat" commands
var class<CheatManager>		CheatClass;		// class of my CheatManager
var private transient PlayerInput	PlayerInput;	// Object within playercontroller that manages player input.
var config class<PlayerInput>       InputClass;     // class of my PlayerInput
var const vector FailedPathStart;

// Demo recording view rotation
var int DemoViewPitch;
var int DemoViewYaw;

#if IG_SHARED
var bool bAlreadyNotifiedLevelOfGameStarted;
#endif

var Security PlayerSecurity;	// Used for Cheat Protection
var float ForcePrecacheTime;

var float LastPingUpdate;
var float ExactPing;
var float OldPing;
var float SpectateSpeed;
var globalconfig float DynamicPingThreshold;
var float NextSpeedChange;
var int ClientCap;

//var(ForceFeedback) globalconfig bool bEnablePickupForceFeedback;
var(ForceFeedback) globalconfig bool bEnableWeaponForceFeedback;
var(ForceFeedback) globalconfig bool bEnableDamageForceFeedback;
var(ForceFeedback) globalconfig bool bEnableGUIForceFeedback;
var(ForceFeedback) bool bForceFeedbackSupported;  // true if a device is detected

var globalconfig float FOVBias;

#if IG_SWAT //tcohen: maintain the last delta time
var float LastDeltaTime;

// Carlos: Moved this here so I can make actors relevant to the ActiveViewport when one is active
// if an ActiveViewport is set, then input will be diverted to it.
var IControllableViewport   ActiveViewport;
// When a client is viewing through a viewport (regardless of whether or not it has been activated), the server needs to have knowledge
// of it so it can update its relevancy checks...
var IControllableViewport   ServerItemViewport;
var IControllableViewport   ServerOfficerViewport;
var bool  bIsObserving;
#endif

#if IG_SPEED_HACK_PROTECTION
var bool bWasSpeedHack;
var bool bIsSpaceFighter;	// hack for spacefighter joystick controls
var float LastSpeedHackLog;
#endif

#if !IG_THIS_IS_SHIPPING_VERSION // speed hack testing [crombie]
var bool bDebugSpeedhack;
#endif


#if IG_SWAT //dkaplan made input bytes toggled through exec functions
var bool bIgnoreNextRunRelease;
var bool bIgnoreNextCrouchRelease;
#endif

#if IG_SWAT // ckline: can do extra flush after precaching to fix corruption after alt-tabbing back into fullscreen on some cards
var config private float PostFullscreenManualFlushDelay; // how long to wait before manually flushing
var private Timer ManualFlushTimer;  // Timer used to trigger a manual "FLUSH" console command after alt-tabbing back in from taskbar to fullscreen
#endif

#if IG_SWAT // dbeswick: stats
var StatsInterface Stats;
#endif

replication
{
	// Things the server should send to the client.
	reliable if( bNetDirty && bNetOwner && Role==ROLE_Authority )
        GameReplicationInfo, VoiceReplicationInfo;
	unreliable if ( bNetOwner && Role==ROLE_Authority && (ViewTarget != Pawn) && (Pawn(ViewTarget) != None) )
#if IG_SWAT
        TargetViewLocation,
#else
        TargetEyeHeight,
#endif
		TargetViewRotation;    //TMC 11-11-2003, TargetItemViewOffset;
	reliable if( bDemoRecording && Role==ROLE_Authority )
		DemoViewPitch, DemoViewYaw;

	// Functions server can call.
	reliable if( Role==ROLE_Authority )
		ClientSetHUD,ClientReliablePlaySound, //FOV, StartZoom,     //IG_SWAT    //tcohen: weapon zoom
		//ToggleZoom, StopZoom, EndZoom,    //IG_SWAT   //tcohen: weapon zoom
        ClientSetMusic, ClientRestart,
		ClientAdjustGlow,
		ClientSetBehindView, ClientSetFixedCamera, ClearProgressMessages,
        SetProgressMessage, SetProgressTime,
		GivePawn, ClientGotoState,
		ClientChangeVoiceChatter,
		ClientLeaveVoiceChat,
		ClientValidate,
        ClientSetViewTarget, ClientCapBandwidth,
		ClientOpenMenu, ClientCloseMenu,
		ClientNotifyArmorTakeDamage,
		ConsoleMessage;

	reliable if ( (Role == ROLE_Authority) && (!bDemoRecording || (bClientDemoRecording && bClientDemoNetFunc)) )
		ClientMessage, TeamMessage, ReceiveLocalizedMessage;
	unreliable if( Role==ROLE_Authority && !bDemoRecording )
        ClientPlaySound,PlayAnnouncement;
	reliable if( Role==ROLE_Authority && !bDemoRecording )
        ClientStopForceFeedback, ClientTravel;
	unreliable if( Role==ROLE_Authority )
        //SetFOVAngle,  //IG_SWAT   //tcohen: weapon zoom
        ClientShake, ClientFlash,
		ClientAdjustPosition, ShortClientAdjustPosition, VeryShortClientAdjustPosition, LongClientAdjustPosition;
	unreliable if( (!bDemoRecording || bClientDemoRecording && bClientDemoNetFunc) && Role==ROLE_Authority )
		ClientHearSound;
    reliable if( bClientDemoRecording && ROLE==ROLE_Authority )
		DemoClientSetHUD;

    /*reliable if ( Role < ROLE_Authority )
        ActiveViewport;*/

	// Functions client can call.
	unreliable if( Role<ROLE_Authority )
        ServerUpdatePing, ShortServerMove, ServerMove, Say, TeamSay,
        //TMC removed ServerSetHandedness,
        ServerViewNextPlayer, ServerViewSelf,ServerUse, ServerDrive;
	reliable if( Role<ROLE_Authority )
        Speech, Pause, SetPause,Mutate,
		//TMC removed PrevItem, ActivateItem,
        ServerReStartGame, AskForPawn,
		ChangeName, ChangeTeam, Suicide,
        //TMC removed ServerThrowWeapon,
        BehindView, Typing,
		ServerChangeVoiceChatter,
		ServerGetVoiceChatters,
		ServerValidationResponse, ServerVerifyViewTarget, ServerSpectateSpeed, ServerSetClientDemo;
#if IG_UDN_UTRACE_DEBUGGING // ckline: UDN UTrace code
 	reliable if( Role<ROLE_Authority )
		ServerUTrace;
#endif
#if IG_SWAT // Carlos: added rpc's to broadcast effect events; dkaplan: and triggers... moved to GameReplicationInfo
    reliable if( Role==ROLE_Authority )
        ClientBroadcastUnTriggerEffectEvent, ClientBroadcastEffectEvent, ClientBroadcastSoundEffectSpecification, ClientBroadcastTrigger,
        ClientDoAIReload, ClientAIBeginFiringWeapon, ClientAIEndFiringWeapon, ClientWeaponFellOutOfWorld,
        ClientDroppedWeaponAtRest, ClientAIDroppedWeapon;
#endif
	// Voice-chat replicated functions
	reliable if (Role < ROLE_Authority)
		/*ServerSetChatPassword, ServerJoinVoiceChannel, ServerLeaveVoiceChannel, ServerSpeak,*/
		ServerChangeVoiceChatMode/*, ServerChatRestriction, ServerRequestBanInfo, ServerGetWeaponStats*/;

#if IG_RWO //dkaplan added rwo broadcasts
    reliable if( Role==ROLE_Authority )
        ClientBroadcastReactToDamaged, ClientBroadcastReactToBumped, ClientBroadcastReactToUsed, ClientBroadcastReactToTriggered;
#endif
}

native final function SetNetSpeed(int NewSpeed);
native final function string GetPlayerNetworkAddress();
native final function string GetServerNetworkAddress();
native function string ConsoleCommand( string Command );
native final function LevelInfo GetEntryLevel();
native(544) final function ResetKeyboard();
native final function SetViewTarget(Actor NewViewTarget);
native event ClientTravel( string URL, ETravelType TravelType, bool bItems );
native(546) final function UpdateURL(string NewOption, string NewValue, bool bSaveDefault);
native final function string GetDefaultURL(string Option);
// Execute a console command in the context of this player, then forward to Actor.ConsoleCommand.
native function CopyToClipboard( string Text );
native function string PasteFromClipboard();

#if IG_SWAT // Carlos: Receive notification for focus events from the viewport
event WindowFocusLost();
event WindowFocusRegained();
#endif

#if IG_SPEED_HACK_PROTECTION
native final function bool CheckSpeedHack(float DeltaTime);

function ResetTimeMargin()
{
    TimeMargin = -0.1;
	MaxTimeMargin = Level.MaxTimeMargin;
}
#endif

// Validation.
private native event ClientValidate(string C);
private native event ServerValidationResponse(string R);

/* FindStairRotation()
returns an integer to use as a pitch to orient player view along current ground (flat, up, or down)
*/
native(524) final function int FindStairRotation(float DeltaTime);

native event INT ClientHearSound (
	actor Actor,
#if !IG_EFFECTS
	int Id,
#endif
	sound S,
	vector SoundLocation,
	vector Parameters,
#if IG_EFFECTS
    float InnerRadius,
    int Flags,
    FLOAT FadeInTime,
#endif
	bool Attenuate
);

#if IG_SHARED
event PreBeginPlay()
{
    Super.PreBeginPlay();

    //MCJ @ IGB
    // The following line forces LevelInfo to set its LocalPlayer variable
    // now. Native code uses it without calling the accessor, so we have to force
    // it to be set here before the native code uses it.
    Level.GetLocalPlayerController();
	assert( (Level.NetMode == NM_DedicatedServer) || (Level.GetLocalPlayerController() != None ) );
}
#endif

event PostBeginPlay()
{
	Super.PostBeginPlay();
	SpawnDefaultHUD();
	if (Level.LevelEnterText != "" )
		ClientMessage(Level.LevelEnterText);

#if IG_SWAT		//tcohen: weapon zoom
	SetZoom(false, true);   //unzoom instantly
#else
	DesiredFOV = DefaultFOV;
#endif
	SetViewTarget(self);  // MUST have a view target!

	if ( Level.NetMode == NM_Standalone )
		AddCheats();

#if !IG_SHARED	// rowan: this was essentially an epic hack.. we handle this better now by explicitly precaching actors on the client
	//bForcePrecache = (Role < ROLE_Authority);
 //   ForcePrecacheTime = Level.TimeSeconds + 2;
#endif

#if IG_SHARED // dbeswick: support for cinematic fade action
	bManualFogUpdate = false;
#endif
}

#if IG_RWO //dkaplan: added rwo broacasts
simulated function ClientBroadcastReactToDamaged( String UniqueIdentifier,
                                                int Damage,
                                                Pawn EventInstigator,
                                                vector HitLocation,
                                                vector Momentum,
                                                class<DamageType> DamageType)
{
    local  Actor SourceActor;

        SourceActor = FindByUniqueID( None, UniqueIdentifier );

        if( SourceActor == None )
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "Warning!  ClientBroadcastReactToDamaged called with a non-relevant source actor!" );
            return;
        }

    if (Level.GetEngine().EnableDevTools)
        mplog( "Client: "$Self$", ReactToDamaged on source actor: "$SourceActor );
    SourceActor.ReactToDamaged( Damage, EventInstigator, HitLocation, Momentum, DamageType );
}

simulated function ClientBroadcastReactToBumped(String UniqueIdentifier,
                                                Actor Other )
{
    local  Actor SourceActor;

        SourceActor = FindByUniqueID( None, UniqueIdentifier );

        if( SourceActor == None )
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "Warning!  ClientBroadcastReactToBumped called with a non-relevant source actor!" );
            return;
        }

    if (Level.GetEngine().EnableDevTools)
        mplog( "Client: "$Self$", ReactToBumped on source actor: "$SourceActor );
    SourceActor.ReactToBumped( Other );
}

simulated function ClientBroadcastReactToUsed( String UniqueIdentifier,
                                                Actor Other )
{
    local  Actor SourceActor;

        SourceActor = FindByUniqueID( None, UniqueIdentifier );

        if( SourceActor == None )
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "Warning!  ClientBroadcastReactToUsed called with a non-relevant source actor!" );
            return;
        }

    if (Level.GetEngine().EnableDevTools)
        mplog( "Client: "$Self$", ReactToUsed on source actor: "$SourceActor );
    SourceActor.ReactToUsed( Other );
}

simulated function ClientBroadcastReactToTriggered( String UniqueIdentifier,
                                                Actor Other )
{
    local  Actor SourceActor;

        SourceActor = FindByUniqueID( None, UniqueIdentifier );

        if( SourceActor == None )
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "Warning!  ClientBroadcastReactToTriggered called with a non-relevant source actor!" );
            return;
        }

    if (Level.GetEngine().EnableDevTools)
        mplog( "Client: "$Self$", ReactToTriggered on source actor: "$SourceActor );
    SourceActor.ReactToTriggered( Other );
}

#endif
#if IG_SWAT
simulated function ClientBroadcastSoundEffectSpecification( name EffectSpecification,
                                                            Actor Source,
                                                            Actor Target,
                                                            int SpecificSoundRef,
                                                            optional Material Material,
                                                            optional Vector overrideWorldLocation,
                                                            optional Rotator overrideWorldRotation,
                                                            optional IEffectObserver Observer )
{
    TriggerSoundEffectSpecification( EffectSpecification, Source, Target, SpecificSoundRef, Material, overrideWorldLocation, overrideWorldRotation, Observer);
}

simulated function TriggerSoundEffectSpecification( name EffectSpecification,
                                                    Actor Source,
                                                    Actor Target,
                                                    int SpecificSoundRef,
                                                    optional Material Material,
                                                    optional Vector overrideWorldLocation,
                                                    optional Rotator overrideWorldRotation,
                                                    optional IEffectObserver Observer );

// RPC on the client that triggers the given effect event on the given source actor.
// If the SourceActor is not relevant and cannont be referenced by uniqueID, the call is ignored.
simulated function ClientBroadcastEffectEvent(  Actor SourceActor,
                                                String UniqueIdentifier,
                                                string EffectEvent,
                                                optional Actor Other,
                                                optional Material TargetMaterial,
                                                optional Vector HitLocation,
                                                optional Rotator HitNormal,
                                                optional bool PlayOnOther,
                                                optional bool QueryOnly,
                                                optional IEffectObserver Observer,
                                                optional String ReferenceTag )
{
    if( SourceActor == None )
    {
        SourceActor = FindByUniqueID( None, UniqueIdentifier );

        if( SourceActor == None )
        {
            mplog( "Warning!  ClientBroadcastEffectEvent called with a non-relevant source actor!" );
            return;
        }
    }

    mplog( "Client: "$Self$", playing effect event: "$EffectEvent$" on source actor: "$SourceActor );
    SourceActor.TriggerEffectEvent( name(EffectEvent), other, TargetMaterial, HitLocation, HitNormal, PlayOnOther, QueryOnly, Observer, name(ReferenceTag) );
}

// RPC on the client that UNtriggers the given effect event on the given source actor.
// If the SourceActor is not relevant and cannont be referenced by uniqueID, the call is ignored.
simulated function ClientBroadcastUnTriggerEffectEvent(  Actor SourceActor,
                                                String UniqueIdentifier,
                                                string EffectEvent,
                                                optional String ReferenceTag )
{
    if( SourceActor == None )
    {
        SourceActor = FindByUniqueID( None, UniqueIdentifier );

        if( SourceActor == None )
        {
            mplog( "Warning!  ClientBroadcastUnTriggerEffectEvent called with a non-relevant source actor!" );
            return;
        }
    }

    mplog( "Client: "$Self$", stopping effect event: "$EffectEvent$" on source actor: "$SourceActor );
    SourceActor.UnTriggerEffectEvent( name(EffectEvent), name(ReferenceTag) );
}
#endif // IG_SWAT

#if IG_SWAT //dkaplan: broadcast Triggers
// RPC on the client that triggers on the given source actor.
// If the SourceActor is not relevant and cannont be referenced by uniqueID, the call is ignored.
simulated function ClientBroadcastTrigger(  Actor SourceActor,
                                            String UniqueIdentifier,
                                            Actor Other,
                                            Pawn EventInstigator )
{
    if( SourceActor == None )
    {
        SourceActor = FindByUniqueID( None, UniqueIdentifier );

        if( SourceActor == None )
        {
            mplog( "Warning!  ClientBroadcastTrigger called with a non-relevant source actor!" );
            return;
        }
    }

    mplog( "Client: "$Self$", Triggering source actor: "$SourceActor );
    SourceActor.Trigger( Other, EventInstigator );
}

// Override in derived class.
simulated function ClientDoAIReload( Pawn theAIPawn );
simulated function ClientAIBeginFiringWeapon( Pawn theAIPawn, int CurrentFireMode );
simulated function ClientAIEndFiringWeapon( Pawn theAIPawn );
simulated function ClientWeaponFellOutOfWorld( string WeaponModelUniqueID );
simulated function ClientDroppedWeaponAtRest( string WeaponModelUniqueID, float Location_X, float Location_Y, float Location_Z, rotator Rotation );
simulated function ClientAIDroppedWeapon( string WeaponModelUniqueID, vector Location, rotator Rotation, vector ThrowDirectionImpulse, class<HandheldEquipmentModel> WeaponModelClass );

#endif // IG_SWAT

exec function History()
{
	Console(Player.InteractionMaster.Console).ToggleLog();
}

exec function SetSpectateSpeed(Float F)
{
	SpectateSpeed = F;
	ServerSpectateSpeed(F);
}

function ServerSpectateSpeed(Float F)
{
	SpectateSpeed = F;
}

function ServerGivePawn()
{
	GivePawn(Pawn);
}

function ClientCapBandwidth(int Cap)
{
	ClientCap = Cap;
	if ( (Player != None) && (Player.CurrentNetSpeed > Cap) )
		SetNetSpeed(Cap);
}

function PendingStasis()
{
	bStasis = true;
	Pawn = None;
	GotoState('Scripting');
}

function AddCheats()
{
    if (!Level.GetEngine().EnableDevTools)
        return;

    // Assuming that this never gets called for NM_Client
	if ( CheatManager == None && (Level.NetMode == NM_Standalone) )
		CheatManager = new(self) CheatClass;
}

#if !IG_SWAT	// ckline: don't need support pickups
function HandlePickup(Pickup pick)
{
	ReceiveLocalizedMessage(pick.MessageClass,,,,pick.class);
}
#endif

event ClientSetViewTarget( Actor a )
{
    //mplog( self$"---PlayerController::ClientSetViewTarget(). Actor="$a );
	if ( A == None )
		ServerVerifyViewTarget();
    SetViewTarget( a );
}

function ServerVerifyViewTarget()
{
    //mplog( self$"---PlayerController::ServerVerifyViewTarget()." );
    //mplog( "...ViewTarget="$ViewTarget );
	if ( ViewTarget == self )
    {
        //mplog( "...ViewTarget == self, returning" );
		return;
    }

	ClientSetViewTarget(ViewTarget);
}

/* SpawnDefaultHUD()
Spawn a HUD (make sure that PlayerController always has valid HUD, even if \
ClientSetHUD() hasn't been called\
*/
function SpawnDefaultHUD()
{
	myHUD = spawn(class'HUD',self);
}

/* Reset()
reset actor to initial state - used when restarting level without reloading.
*/
function Reset()
{
    PawnDied(Pawn);
	Super.Reset();
	SetViewTarget(self);
	bBehindView = false;
	WaitDelay = Level.TimeSeconds + 2;
    FixFOV();
    if ( !PlayerReplicationInfo.bOnlySpectator )
		GotoState('PlayerWaiting');
}

function CleanOutSavedMoves()
{
    local SavedMove Next;

	// clean out saved moves
	while ( SavedMoves != None )
	{
		Next = SavedMoves.NextMove;
		SavedMoves.Destroy();
		SavedMoves = Next;
	}
	if ( PendingMove != None )
	{
		PendingMove.Destroy();
		PendingMove = None;
	}
}

/* InitInputSystem()
Spawn the appropriate class of PlayerInput
Only called for playercontrollers that belong to local players
*/
event InitInputSystem()
{
	PlayerInput = new(self) InputClass;
}

/* ClientGotoState()
server uses this to force client into NewState
*/
function ClientGotoState(name NewState, name NewLabel)
{
	GotoState(NewState,NewLabel);
}

function AskForPawn()
{
    //mplog( self$"---PlayerController::AskForPawn()." );

	if ( IsInState('GameEnded') )
		ClientGotoState('GameEnded', 'Begin');
	else if ( Pawn != None )
		GivePawn(Pawn);
	else
	{
        //mplog( "...calling ServerRestartPlayer()." );
		bFrozen = false;
		ServerRestartPlayer();
	}
}

function GivePawn(Pawn NewPawn)
{
    //mplog( self$"---PlayerController::GivePawn()." );

	if ( NewPawn == None )
    {
        //mplog( "...NewPawn == None, returning." );
		return;
    }
    //mplog( "...setting pawn="$NewPawn );
	Pawn = NewPawn;
	NewPawn.Controller = self;
	ClientRestart();
}

/* GetFacingDirection()
returns direction faced relative to movement dir
0 = forward
16384 = right
32768 = back
49152 = left
*/
function int GetFacingDirection()
{
	local vector X,Y,Z, Dir;

	GetAxes(Pawn.Rotation, X,Y,Z);
	Dir = Normal(Pawn.Acceleration);
	if ( Y Dot Dir > 0 )
		return ( 49152 + 16384 * (X Dot Dir) );
	else
		return ( 16384 - 16384 * (X Dot Dir) );
}

// Possess a pawn
function Possess(Pawn aPawn)
{
    if ( PlayerReplicationInfo.bOnlySpectator )
		return;

#if IG_SPEED_HACK_PROTECTION
	ResetTimeMargin();
#endif

	SetRotation(aPawn.Rotation);
	aPawn.PossessedBy(self);
	Pawn = aPawn;
	Pawn.bStasis = false;
    CleanOutSavedMoves();  // don't replay moves previous to possession
	PlayerReplicationInfo.bIsFemale = Pawn.bIsFemale;
	Restart();
}

// unpossessed a pawn (not because pawn was killed)
function UnPossess()
{
	if ( Pawn != None )
	{
		SetLocation(Pawn.Location);
		Pawn.RemoteRole = ROLE_SimulatedProxy;
		Pawn.UnPossessed();
		CleanOutSavedMoves();  // don't replay moves previous to unpossession
		if ( Viewtarget == Pawn )
			SetViewTarget(self);
	}
	Pawn = None;
	GotoState('Spectating');
}

function ViewNextBot()
{
	if ( CheatManager != None )
		CheatManager.ViewBot();
}

// unpossessed a pawn (because pawn was killed)
function PawnDied(Pawn P)
{
	if ( P != Pawn )
		return;
#if IG_SWAT
    SetZoom(false, true);   //unzoom instantly
#else
	EndZoom();
#endif
	if ( Pawn != None )
		Pawn.RemoteRole = ROLE_SimulatedProxy;
	if ( ViewTarget == Pawn )
		bBehindView = true;

    Super.PawnDied(P);
}

function ClientSetHUD(class<HUD> newHUDType, class<Scoreboard> newScoringType)
{
	local HUD NewHUD;

	if ( (myHUD == None) || ((newHUDType != None) && (newHUDType != myHUD.Class)) )
	{
		NewHUD = spawn(newHUDType, self);
		if ( NewHUD != None )
		{
			if ( myHUD != None )
				myHUD.Destroy();
			myHUD = NewHUD;
		}
	}
	if ( (myHUD != None) && (newScoringType != None) )
		MyHUD.SpawnScoreBoard(newScoringType);
}

// jdf ---
// Server ignores this call, client plays effect
simulated function ClientPlayForceFeedback( String EffectName )
{
    if (bForceFeedbackSupported && Viewport(Player) != None)
        PlayFeedbackEffect( EffectName );
}

simulated function StopForceFeedback( optional String EffectName )
{
    if (bForceFeedbackSupported && Viewport(Player) != None)
    {
		if (EffectName != "")
			StopFeedbackEffect( EffectName );
		else
			StopFeedbackEffect();
	}
}

function ClientStopForceFeedback( optional String EffectName )
{
    if (bForceFeedbackSupported && Viewport(Player) != None)
    {
		if (EffectName != "")
			StopFeedbackEffect( EffectName );
		else
			StopFeedbackEffect();
	}
}
// --- jdf

final function float UpdateFlashComponent(float Current, float Step, float goal)
{
	if ( goal > current )
		return FMin(Current + Step, goal);
	else
		return FMax(Current - Step, goal);
}

function ViewFlash(float DeltaTime)
{
    local vector goalFog;
    local float goalscale, delta, Step;

#if IG_SHARED // dbeswick: support for cinematic fade action
	if (bManualFogUpdate)
		return;
#endif

    delta = FMin(0.1, DeltaTime);
    goalScale = 1; // + ConstantGlowScale;
    goalFog = vect(0,0,0); // ConstantGlowFog;

    if ( Pawn != None )
    {
        goalScale += Pawn.HeadVolume.ViewFlash.X;
        goalFog += Pawn.HeadVolume.ViewFog;
    }
	Step = 0.6 * delta;
	FlashScale.X = UpdateFlashComponent(FlashScale.X,step,goalScale);
    FlashScale = FlashScale.X * vect(1,1,1);

	FlashFog.X = UpdateFlashComponent(FlashFog.X,step,goalFog.X);
	FlashFog.Y = UpdateFlashComponent(FlashFog.Y,step,goalFog.Y);
	FlashFog.Z = UpdateFlashComponent(FlashFog.Z,step,goalFog.Z);
}

simulated event ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	Message.Static.ClientReceive( Self, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
	if ( Message.default.bIsConsoleMessage && (Player != None) && (Player.Console != None) )
		Player.Console.Message(Message.Static.GetString(Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject),0 );
}

event ClientMessage( coerce string S, optional Name Type )
{
	if (Type == '')
		Type = 'Event';

	TeamMessage(PlayerReplicationInfo, S, Type);
}

event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional string Location  )
{
	if ( myHUD != None )
	myHUD.Message( PRI, S, Type );

    if ( ((Type == 'Say') || (Type == 'TeamSay')) && (PRI != None) )
		S = PRI.PlayerName$" ("$Location$"): "$S;

    Player.Console.Message( S, 0 );
}

function ConsoleMessage(string S) {
	Player.InteractionMaster.Console.Message(S, 0);
}

simulated function PlayBeepSound();

simulated function PlayAnnouncement(sound ASound, byte AnnouncementLevel, optional bool bForce)
{
	local float Atten;

	if ( AnnouncementLevel > AnnouncerLevel )
		return;
	if ( !bForce && (Level.TimeSeconds - LastPlaySound < 1) )
		return;
	LastPlaySound = Level.TimeSeconds;	// so voice messages won't overlap
	LastPlaySpeech = Level.TimeSeconds;	// don't want chatter to overlap announcements

	Atten = FClamp(0.1 + float(AnnouncerVolume)*0.225,0.2,1.0);
#if IG_EFFECTS
    ClientPlaySound(ASound,true,Atten);
#else
	ClientPlaySound(ASound,true,Atten,SLOT_Talk);
#endif
}

function bool AllowVoiceMessage(name MessageType)
{
	if ( Level.NetMode == NM_Standalone )
		return true;

	if ( Level.TimeSeconds - OldMessageTime < 3 )
	{
		if ( (MessageType == 'TAUNT') || (MessageType == 'AUTOTAUNT') )
			return false;
		if ( Level.TimeSeconds - OldMessageTime < 1 )
			return false;
	}
	if ( Level.TimeSeconds - OldMessageTime < 6 )
		OldMessageTime = Level.TimeSeconds + 3;
	else
		OldMessageTime = Level.TimeSeconds;
	return true;
}

//Play a sound client side (so only client will hear it
simulated function ClientPlaySound(sound ASound, optional bool bVolumeControl, optional float inAtten
#if !IG_EFFECTS
                                   , optional ESoundSlot slot
#endif
                                   )
{
    local float atten;

    atten = 0.9;
    if( bVolumeControl )
        atten = FClamp(inAtten,0,1);

	if ( ViewTarget != None )
#if IG_EFFECTS
		ViewTarget.PlaySound(ASound, atten,,,,,,,false);
#else
		ViewTarget.PlaySound(ASound, slot, atten,,,,false);
#endif
}

simulated function ClientReliablePlaySound(sound ASound, optional bool bVolumeControl )
{
	ClientPlaySound(ASound, bVolumeControl);
}

#if UGLY_RENDER_CORRUPTION_WORKAROUND // ckline: can do extra flush after precaching to fix corruption after alt-tabbing back into fullscreen on some cards
simulated function FlushAllViewports()
{
    if (Level.GetEngine().EnableDevTools)
        log("Flushing all viewports manually");

    ConsoleCommand("FLUSH");

    if (Level.GetEngine().EnableDevTools)
        log("Finished flushing all viewports manually at "$Level.TimeSeconds);

    ManualFlushTimer.Destroy();
    ManualFlushTimer = None;
}
#endif

#if IG_SHARED // carlos: move first actor tick until after precaching
simulated event OnFinishedPrecaching(bool doExtraFlush)
{
    FlushInput();

#if UGLY_RENDER_CORRUPTION_WORKAROUND // ckline: can do extra flush after precaching to fix corruption after alt-tabbing back into fullscreen on some cards
    if (doExtraFlush && PostFullscreenManualFlushDelay > 0)
    {
        // HACK: Set a timer to manually call "flush" console command after a short
        // pause. This fixes the texture corruption on some cards that occurs
        // after alt-tabbing back into full screen mode after alt-tabbing out
        // of it.
        ManualFlushTimer = new class'Timer';

        if (Level.GetEngine().EnableDevTools)
            log("Starting timer at time "$Level.TimeSeconds$" to flush all viewports manually in "$PostFullscreenManualFlushDelay$" seconds.");

        ManualFlushTimer.TimerDelegate = FlushAllViewports;
        ManualFlushTimer.StartTimer( PostFullscreenManualFlushDelay, false );
    }
#endif
}

native function FlushInput();

#endif

#if IG_SWAT //dkaplan: hook for handling connection failures
simulated event OnConnectionFailed();
#endif

simulated event Destroyed()
{
	local SavedMove Next;
#if !IG_SWAT // ckline: removed vehicles
    local KVehicle DrivenVehicle;
    local SVehicle DrivenSVehicle;
    local HavokVehicle DrivenHVehicle;
	local Pawn Driver;
#endif
#if IG_SWAT
    local Pawn OldPawn;
#endif

	// cheatmanager, adminmanager, and playerinput cleaned up in C++ PostScriptDestroyed()

    StopFeedbackEffect();

	if ( Pawn != None )
	{
#if !IG_SWAT // ckline: removed vehicles
		// If its a vehicle, just destroy the driver, otherwise do the normal.
		DrivenVehicle = KVehicle(Pawn);
		if(DrivenVehicle != None)
		{
			Driver = DrivenVehicle.Driver;
			DrivenVehicle.KDriverLeave(true); // Force the driver out of the car
			Driver.Destroy();
		}
		else
		{
			DrivenHVehicle = HavokVehicle(Pawn);
			if(DrivenHVehicle != None)
			{
				Driver = DrivenHVehicle.Driver;
				DrivenHVehicle.DriverLeave(true); // Force the driver out of the car
				Driver.Destroy();
			}
			else
			{
				DrivenSVehicle = SVehicle(Pawn);
				if(DrivenSVehicle != None)
				{
					Driver = DrivenSVehicle.Driver;
					DrivenSVehicle.KDriverLeave(true); // Force the driver out of the car
					Driver.Destroy();
				}
				else
				{
#endif // !IG_SWAT
                    // For swat, we don't want to put pawn and playercontroller in
                    // a dead state when Destroyed. This way, the server does not
                    // think someone has died on a disconnect and won't trigger
                    // the team's reinforcement timer. [darren]
#if IG_SWAT
                    OldPawn = Pawn;
                    Unpossess();
                    OldPawn.Health = 0;
                    OldPawn.Died( self, class'Suicided', OldPawn.Location,vect(0,0,0));
#else
					Pawn.Health = 0;
					Pawn.Died( self, class'Suicided', Pawn.Location );
#endif
#if !IG_SWAT // ckline: removed vehicles
				}
			}
		}
#endif
	}
	myHud.Destroy();

	while ( FreeMoves != None )
	{
		Next = FreeMoves.NextMove;
		FreeMoves.Destroy();
		FreeMoves = Next;
	}
	while ( SavedMoves != None )
	{
		Next = SavedMoves.NextMove;
		SavedMoves.Destroy();
		SavedMoves = Next;
	}

    if( PlayerSecurity != None )
    {
        PlayerSecurity.Destroy();
        PlayerSecurity = None;
    }

    Super.Destroyed();
}

function ClientSetMusic( string NewSong, EMusicTransition NewTransition )
{
	StopAllMusic( 0.0 );
	PlayMusic( NewSong, 3.0 );
	Song        = NewSong;
	Transition  = NewTransition;
}

// ------------------------------------------------------------------------
// Zooming/FOV change functions

#if IG_SWAT     //tcohen: weapon zoom

exec function ToggleZoom()
{
    if ( Pawn == None || class'Pawn'.static.CheckDead(Pawn) )
        return;

    SetZoom(!WantsZoom);
}

exec function SetZoom(bool Zoom, optional bool Instantly)
{
    WantsZoom = Zoom;

    if (Instantly)
    {
        if (Zoom)
            ZoomAlpha = 1.0;
        else
            ZoomAlpha = 0.0;
    }
}

exec function FOV(float F)
{
	local float fFOV;

	if( (F >= 70.0) )
	{
		fFOV = FClamp(F, 70, 120);
		BaseFOV = fFOV;
	}
}

exec function FPFOV(float F)
{
	local float fFOV;

	if( (F >= 70.0) )
	{
		fFOV = FClamp(F, 70, 120);
		class'FOVSettings'.default.FPFOV = fFOV;
	}
}

exec function SetFOVBias(float F)
{
	local float fFOV;

	FOVBias = F;
}

exec function SetFOVTemporary(float F)
{
	if(F >= 70.0)
	{
		BaseFOV = FClamp(F, 70, 120);
	}
}

exec function SaveFOVSettings()
{
	SaveConfig();
}

function FixFOV();  //defunct for SWAT
#else   //!IG_SWAT

function ToggleZoom()
{
	if ( DefaultFOV != DesiredFOV )
		EndZoom();
	else
		StartZoom();
}

function StartZoom()
{
	ZoomLevel = 0.0;
	bZooming = true;
}

function StopZoom()
{
	bZooming = false;
}

function EndZoom()
{
	bZooming = false;
	DesiredFOV = DefaultFOV;
}

function FixFOV()
{
	FOVAngle = Default.DefaultFOV;
	DesiredFOV = Default.DefaultFOV;
	DefaultFOV = Default.DefaultFOV;
}

function SetFOV(float NewFOV)
{
	DesiredFOV = NewFOV;
	FOVAngle = NewFOV;
}

function ResetFOV()
{
	DesiredFOV = DefaultFOV;
	FOVAngle = DefaultFOV;
}

exec function FOV(float F)
{
	if( (F >= 80.0) || (Level.Netmode==NM_Standalone) )
	{
		DefaultFOV = FClamp(F, 1, 170);
		DesiredFOV = DefaultFOV;
		RecalculateZoomedFov();
		SaveConfig();
	}
}

#endif  //IG_SWAT   //tcohen: weapon zoom

function RecalculateZoomedFov();

exec function Mutate(string MutateString)
{
	if( Level.NetMode == NM_Client )
		return;
	Level.Game.BaseMutator.Mutate(MutateString, Self);
}

exec function SetSensitivity(float F)
{
	PlayerInput.UpdateSensitivity(F);
}

exec function SetMouseSmoothing( int Mode )
{
    PlayerInput.UpdateSmoothing( Mode );
}

exec function SetMouseAccel(float F)
{
	PlayerInput.UpdateAccel(F);
}

exec function Melee()
{
	InternalMelee();
}

exec function MeleeDedicated()
{
	InternalMelee(true);
}

exec function GiveItemDedicated()
{
	InternalMelee(, , true);
}

exec function CheckLockDedicated()
{
	InternalMelee(, true);
}

exec function Reload()
{
    InternalReload();
}

simulated function InternalMelee(optional bool UseMeleeOnly, optional bool UseCheckLockOnly, optional bool UseGiveItemOnly);

// Overridden for Swat players in SwatGamePlayerController.
simulated private function InternalReload()
{
    local HandheldEquipment ActiveItem;
    local FiredWeapon Weapon;

    ActiveItem = Pawn.GetActiveItem();

    //TMC this assert is invalid because between unequipping and equipping, the ActiveItem is supposed to be None
    //
    //AssertWithDescription(ActiveItem != None,
    //    "[tcohen] Reload() was called on the PlayerController.  But either the Pawn is None, the Pawn has no ActiveItem, or the Pawn's ActiveItem is not a HandheldEquipment.");

    Weapon = FiredWeapon(ActiveItem);

    if (Weapon == None) return; //can only reload a FiredWeapon

    if (!Weapon.IsIdle()) return; //can only do one thing at a time

    if (!Weapon.Ammo.CanReload() ) return;

    Weapon.Reload();
}


// ------------------------------------------------------------------------
// Messaging functions

// Send a message to all players.
exec function Say( string Msg )
{
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

	Level.Game.Broadcast(self, Msg, 'Say');
}

exec function TeamSay( string Msg )
{
	if( !GameReplicationInfo.bTeamGame )
	{
		Say( Msg );
		return;
	}

    Level.Game.BroadcastTeam( self, Level.Game.ParseMessageString( Level.Game.BaseMutator , self, Msg ) , 'TeamSay');
}

function CoopQMMMessage( string Msg )
{
	Level.Game.Broadcast(self, Msg, 'CoopQMM');
}

// ------------------------------------------------------------------------

function bool IsDead()
{
	return false;
}

//TMC removed Epic's Weapon or Inventory code here - function ShoGun()

event PreClientTravel()
{
    log("PreClientTravel");
    ClientStopForceFeedback();  // jdf
}

function ClientSetFixedCamera(bool B)
{
	bFixedCamera = B;
}

function ClientSetBehindView(bool B)
{
	bBehindView = B;
}

function ClientVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
	local VoicePack V;

	if ( (Sender == None) || (Sender.voicetype == None) || (Player.Console == None) )
		return;

	V = Spawn(Sender.voicetype, self);
	if ( V != None )
		V.ClientInitialize(Sender, Recipient, messagetype, messageID);
}

/* ForceDeathUpdate()
Make sure ClientAdjustPosition immediately informs client of pawn's death
*/
function ForceDeathUpdate()
{
	LastUpdateTime = Level.TimeSeconds - 10;
}

/* ShortServerMove()
compressed version of server move for bandwidth saving
*/
function ShortServerMove
(
	float TimeStamp,
	vector ClientLoc,
	bool NewbRun,
	bool NewbDuck,
	bool NewbJumpStatus,
#if IG_SWAT
    bool NewbLeanLeft,
    bool NewbLeanRight,
#endif
	byte ClientRoll,
	int View
)
{
    ServerMove(TimeStamp,vect(0,0,0),ClientLoc,NewbRun,NewbDuck,NewbJumpStatus,false,
#if IG_SWAT
        NewbLeanLeft, NewbLeanRight,
#endif
        DCLICK_None,ClientRoll,View);
}

/* ServerMove()
- replicated function sent by client to server - contains client movement and firing info
Passes acceleration in components so it doesn't get rounded.
*/
function ServerMove
(
	float TimeStamp,
	vector InAccel,
	vector ClientLoc,
	bool NewbRun,
	bool NewbDuck,
	bool NewbJumpStatus,
    bool NewbDoubleJump,
#if IG_SWAT
    bool NewbLeanLeft,
    bool NewbLeanRight,
#endif
	eDoubleClickDir DoubleClickMove,
	byte ClientRoll,
	int View,
	optional byte OldTimeDelta,
	optional int OldAccel
)
{
	local float DeltaTime, clientErr, OldTimeStamp;
	local rotator DeltaRot, Rot, ViewRot;
	local vector Accel, LocDiff, ClientVel, ClientFloor;
	local int maxPitch, ViewPitch, ViewYaw;
    local bool NewbPressedJump, OldbRun, OldbDoubleJump;
	local eDoubleClickDir OldDoubleClickMove;
	local actor ClientBase;
	local ePhysics ClientPhysics;


	// If this move is outdated, discard it.
	if ( CurrentTimeStamp >= TimeStamp )
		return;

	bShortConnectTimeOut = true;

	// if OldTimeDelta corresponds to a lost packet, process it first
	if (  OldTimeDelta != 0 )
	{
		OldTimeStamp = TimeStamp - float(OldTimeDelta)/500 - 0.001;
		if ( CurrentTimeStamp < OldTimeStamp - 0.001 )
		{
			// split out components of lost move (approx)
			Accel.X = OldAccel >>> 23;
			if ( Accel.X > 127 )
				Accel.X = -1 * (Accel.X - 128);
			Accel.Y = (OldAccel >>> 15) & 255;
			if ( Accel.Y > 127 )
				Accel.Y = -1 * (Accel.Y - 128);
			Accel.Z = (OldAccel >>> 7) & 255;
			if ( Accel.Z > 127 )
				Accel.Z = -1 * (Accel.Z - 128);
			Accel *= 20;

			OldbRun = ( (OldAccel & 64) != 0 );
            OldbDoubleJump = ( (OldAccel & 32) != 0 );
			NewbPressedJump = ( (OldAccel & 16) != 0 );
			if ( NewbPressedJump )
				bJumpStatus = NewbJumpStatus;
			switch (OldAccel & 7)
			{
				case 0:
					OldDoubleClickMove = DCLICK_None;
					break;
				case 1:
					OldDoubleClickMove = DCLICK_Left;
					break;
				case 2:
					OldDoubleClickMove = DCLICK_Right;
					break;
				case 3:
					OldDoubleClickMove = DCLICK_Forward;
					break;
				case 4:
					OldDoubleClickMove = DCLICK_Back;
					break;
			}
			//log("Recovered move from "$OldTimeStamp$" acceleration "$Accel$" from "$OldAccel);
            OldTimeStamp = FMin(OldTimeStamp, CurrentTimeStamp + MaxResponseTime);
            MoveAutonomous(OldTimeStamp - CurrentTimeStamp, OldbRun, (bDuck == 1), NewbPressedJump, OldbDoubleJump,
#if IG_SWAT
                (bLeanLeft == 1), (bLeanRight == 1),
#endif
                OldDoubleClickMove, Accel, rot(0,0,0));
			CurrentTimeStamp = OldTimeStamp;
		}
	}

	// View components
	ViewPitch = View/32768;
	ViewYaw = 2 * (View - 32768 * ViewPitch);
	ViewPitch *= 2;
	// Make acceleration.
	Accel = InAccel/10;

	NewbPressedJump = (bJumpStatus != NewbJumpStatus);
	bJumpStatus = NewbJumpStatus;

	// Save move parameters.
    DeltaTime = FMin(MaxResponseTime,TimeStamp - CurrentTimeStamp);

#if IG_SPEED_HACK_PROTECTION
	if ( Pawn == None )
	{
		bWasSpeedHack = false;
		ResetTimeMargin();
	}
	else if ( !CheckSpeedHack(DeltaTime) )
	{
		if ( !bWasSpeedHack )
		{
			if ( Level.TimeSeconds - LastSpeedHackLog > 20 )
			{
				log("Possible speed hack by "$PlayerReplicationInfo.PlayerName);
				LastSpeedHackLog = Level.TimeSeconds;
			}
			ClientMessage( "Speed Hack Detected!",'CriticalEvent' );
		}
		else
			bWasSpeedHack = true;
		DeltaTime = 0;
		Pawn.Velocity = vect(0,0,0);
	}
	else
		bWasSpeedHack = false;
#endif

	if ( ServerTimeStamp > 0 )
	{
		// allow 1% error
        TimeMargin = FMax(0,TimeMargin + DeltaTime - 1.01 * (Level.TimeSeconds - ServerTimeStamp));
		if ( TimeMargin > MaxTimeMargin )
		{
			// player is too far ahead
			TimeMargin -= DeltaTime;
			if ( TimeMargin < 0.5 )
				MaxTimeMargin = Default.MaxTimeMargin;
			else
				MaxTimeMargin = 0.5;
			DeltaTime = 0;
		}
	}

	CurrentTimeStamp = TimeStamp;
	ServerTimeStamp = Level.TimeSeconds;
	ViewRot.Pitch = ViewPitch;
	ViewRot.Yaw = ViewYaw;
	ViewRot.Roll = 0;
	SetRotation(ViewRot);

	if ( Pawn != None )
	{
		Rot.Roll = 256 * ClientRoll;
		Rot.Yaw = ViewYaw;
		if ( (Pawn.Physics == PHYS_Swimming) || (Pawn.Physics == PHYS_Flying) )
			maxPitch = 2;
		else
            maxPitch = 0;
		If ( (ViewPitch > maxPitch * RotationRate.Pitch) && (ViewPitch < 65536 - maxPitch * RotationRate.Pitch) )
		{
			If (ViewPitch < 32768)
				Rot.Pitch = maxPitch * RotationRate.Pitch;
			else
				Rot.Pitch = 65536 - maxPitch * RotationRate.Pitch;
		}
		else
			Rot.Pitch = ViewPitch;
		DeltaRot = (Rotation - Rot);
		Pawn.SetRotation(Rot);
	}

    // Perform actual movement
	if ( (Level.Pauser == None) && (DeltaTime > 0) )
        MoveAutonomous(DeltaTime, NewbRun, NewbDuck, NewbPressedJump, NewbDoubleJump,
#if IG_SWAT
            NewbLeanLeft, NewbLeanRight,
#endif
            DoubleClickMove, Accel, DeltaRot);

	// Accumulate movement error.
	if ( Level.TimeSeconds - LastUpdateTime > 0.3 )
		ClientErr = 10000;
	else if ( Level.TimeSeconds - LastUpdateTime > 180.0/Player.CurrentNetSpeed )
	{
		if ( Pawn == None )
			LocDiff = Location - ClientLoc;
		else
			LocDiff = Pawn.Location - ClientLoc;
		ClientErr = LocDiff Dot LocDiff;
	}

	// If client has accumulated a noticeable positional error, correct him.
	if ( ClientErr > 3 )
	{
		if ( Pawn == None )
		{
			ClientPhysics = Physics;
			ClientLoc = Location;
			ClientVel = Velocity;
		}
		else
		{
			ClientPhysics = Pawn.Physics;
			ClientVel = Pawn.Velocity;
			ClientBase = Pawn.Base;
			if ( Mover(Pawn.Base) != None )
				ClientLoc = Pawn.Location - Pawn.Base.Location;
			else
				ClientLoc = Pawn.Location;
			ClientFloor = Pawn.Floor;
		}
		//	log(Level.TimeSeconds$" Client Error at "$TimeStamp$" is "$ClientErr$" with acceleration "$Accel$" LocDiff "$LocDiff$" Physics "$Pawn.Physics);
		LastUpdateTime = Level.TimeSeconds;

		if ( (Pawn == None) || (Pawn.Physics != PHYS_Spider) )
		{
			if ( ClientVel == vect(0,0,0) )
			{
					ShortClientAdjustPosition
					(
						TimeStamp,
						GetStateName(),
						ClientPhysics,
						ClientLoc.X,
						ClientLoc.Y,
						ClientLoc.Z,
						ClientBase
					);
			}
			else
				ClientAdjustPosition
				(
					TimeStamp,
					GetStateName(),
					ClientPhysics,
					ClientLoc.X,
					ClientLoc.Y,
					ClientLoc.Z,
					ClientVel.X,
					ClientVel.Y,
					ClientVel.Z,
					ClientBase
				);
		}
		else
			LongClientAdjustPosition
			(
				TimeStamp,
				GetStateName(),
				ClientPhysics,
				ClientLoc.X,
				ClientLoc.Y,
				ClientLoc.Z,
				ClientVel.X,
				ClientVel.Y,
				ClientVel.Z,
				ClientBase,
				ClientFloor.X,
				ClientFloor.Y,
				ClientFloor.Z
			);
	}
	//log("Server moved stamp "$TimeStamp$" location "$Pawn.Location$" Acceleration "$Pawn.Acceleration$" Velocity "$Pawn.Velocity);
}

// Only executed on server
function ServerDrive(float InForward, float InStrafe, float InUp, bool InJump)
{
	ProcessDrive(InForward, InStrafe, InUp, InJump);
}

function ProcessDrive(float InForward, float InStrafe, float InUp, bool InJump)
{
	Log("ProcessDrive Not Valid Outside State PlayerDriving");
}

function ProcessMove ( float DeltaTime, vector newAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
{
	if ( Pawn != None )
		Pawn.Acceleration = newAccel;
}

final function MoveAutonomous
(
	float DeltaTime,
	bool NewbRun,
	bool NewbDuck,
	bool NewbPressedJump,
    bool NewbDoubleJump,
#if IG_SWAT
    bool NewbLeanLeft,
    bool NewbLeanRight,
#endif
	eDoubleClickDir DoubleClickMove,
	vector newAccel,
	rotator DeltaRot
)
{
	if ( NewbRun )
		bRun = 1;
	else
		bRun = 0;

	if ( NewbDuck )
		bDuck = 1;
	else
		bDuck = 0;
#if IG_SWAT
	if ( NewbLeanLeft )
		bLeanLeft = 1;
	else
		bLeanLeft = 0;

	if ( NewbLeanRight )
		bLeanRight = 1;
	else
		bLeanRight = 0;
#endif

	bPressedJump = NewbPressedJump;
    bDoubleJump = NewbDoubleJump;
	HandleWalking();
	ProcessMove(DeltaTime, newAccel, DoubleClickMove, DeltaRot);
	if ( Pawn != None )
		Pawn.AutonomousPhysics(DeltaTime);
	else
		AutonomousPhysics(DeltaTime);
    bDoubleJump = false;
	//log("Role "$Role$" moveauto time "$100 * DeltaTime$" ("$Level.TimeDilation$")");
}

/* VeryShortClientAdjustPosition
bandwidth saving version, when velocity is zeroed, and pawn is walking
*/
function VeryShortClientAdjustPosition
(
	float TimeStamp,
	float NewLocX,
	float NewLocY,
	float NewLocZ,
	Actor NewBase
)
{
	local vector Floor;

	if ( Pawn != None )
		Floor = Pawn.Floor;
	LongClientAdjustPosition(TimeStamp,'PlayerWalking',PHYS_Walking,NewLocX,NewLocY,NewLocZ,0,0,0,NewBase,Floor.X,Floor.Y,Floor.Z);
}

/* ShortClientAdjustPosition
bandwidth saving version, when velocity is zeroed
*/
function ShortClientAdjustPosition
(
	float TimeStamp,
	name newState,
	EPhysics newPhysics,
	float NewLocX,
	float NewLocY,
	float NewLocZ,
	Actor NewBase
)
{
	local vector Floor;

	if ( Pawn != None )
		Floor = Pawn.Floor;
	LongClientAdjustPosition(TimeStamp,newState,newPhysics,NewLocX,NewLocY,NewLocZ,0,0,0,NewBase,Floor.X,Floor.Y,Floor.Z);
}

/* ClientAdjustPosition
- pass newloc and newvel in components so they don't get rounded
*/
function ClientAdjustPosition
(
	float TimeStamp,
	name newState,
	EPhysics newPhysics,
	float NewLocX,
	float NewLocY,
	float NewLocZ,
	float NewVelX,
	float NewVelY,
	float NewVelZ,
	Actor NewBase
)
{
	local vector Floor;

	if ( Pawn != None )
		Floor = Pawn.Floor;
	LongClientAdjustPosition(TimeStamp,newState,newPhysics,NewLocX,NewLocY,NewLocZ,NewVelX,NewVelY,NewVelZ,NewBase,Floor.X,Floor.Y,Floor.Z);
}

/* LongClientAdjustPosition
long version, when care about pawn's floor normal
*/
function LongClientAdjustPosition
(
	float TimeStamp,
	name newState,
	EPhysics newPhysics,
	float NewLocX,
	float NewLocY,
	float NewLocZ,
	float NewVelX,
	float NewVelY,
	float NewVelZ,
	Actor NewBase,
	float NewFloorX,
	float NewFloorY,
	float NewFloorZ
)
{
    local vector NewLocation, NewVelocity, NewFloor;
	local Actor MoveActor;
    local SavedMove CurrentMove;

	// update ping
	if ( (PlayerReplicationInfo != None) && !bDemoOwner )
	{
		if ( ExactPing < 0.006 )
			ExactPing = Level.TimeSeconds - TimeStamp;
		else
			ExactPing = 0.99 * ExactPing + 0.008 * (Level.TimeSeconds - TimeStamp); // placebo effect
		PlayerReplicationInfo.Ping = 1000 * ExactPing;

		if ( Level.TimeSeconds - LastPingUpdate > 4 )
		{
			if ( bDynamicNetSpeed && (OldPing > DynamicPingThreshold * 0.001) && (ExactPing > DynamicPingThreshold * 0.001) )
			{
				if ( Player.CurrentNetSpeed > 5000 )
					SetNetSpeed(5000);
				else if ( Level.MoveRepSize < 80 )
					Level.MoveRepSize += 8;
				else if ( Player.CurrentNetSpeed > 4000 )
					SetNetSpeed(4000);
				OldPing = 0;
			}
			else
				OldPing = ExactPing;
			LastPingUpdate = Level.TimeSeconds;
			ServerUpdatePing(1000 * ExactPing);
		}
	}
	if ( Pawn != None )
	{
		if ( Pawn.bTearOff )
		{
			Pawn = None;
			if ( !IsInState('GameEnded') && !IsInState('Dead')
#if IG_SWAT //dkaplan we also dont want to transition to DEAD if we are already in observer cam
			      && !IsInState('ObserveTeam')
#endif
			    )
			{
    			GotoState('Dead');
            }
			return;
		}
		MoveActor = Pawn;
        if ( (ViewTarget != Pawn)
			&& ((ViewTarget == self) || ((Pawn(ViewTarget) != None) && (Pawn(ViewTarget).Health <= 0))) )
		{
			bBehindView = false;
			SetViewTarget(Pawn);
		}
	}
	else
    {
		MoveActor = self;
 	   	if( GetStateName() != newstate )
		{
		    if ( NewState == 'GameEnded' )
			    GotoState(NewState);
			else if ( IsInState('Dead') )
			{
		    	if ( (NewState != 'PlayerWalking') && (NewState != 'PlayerSwimming') )
		        {
				    GotoState(NewState);
		        }
		        return;
			}
			else if ( NewState == 'Dead'
#if IG_SWAT //darren we dont want to transition to DEAD if we are already in observer cam
			      && !IsInState('ObserveTeam')
#endif
                    )
				GotoState(NewState);
		}
	}
    if ( CurrentTimeStamp >= TimeStamp )
		return;
	CurrentTimeStamp = TimeStamp;

	NewLocation.X = NewLocX;
	NewLocation.Y = NewLocY;
	NewLocation.Z = NewLocZ;
    NewVelocity.X = NewVelX;
    NewVelocity.Y = NewVelY;
    NewVelocity.Z = NewVelZ;

	// skip update if no error
    CurrentMove = SavedMoves;
    while ( CurrentMove != None )
    {
        if ( CurrentMove.TimeStamp <= CurrentTimeStamp )
        {
            SavedMoves = CurrentMove.NextMove;
            CurrentMove.NextMove = FreeMoves;
            FreeMoves = CurrentMove;
			if ( CurrentMove.TimeStamp == CurrentTimeStamp )
			{
				FreeMoves.Clear();
				if ( (VSize(CurrentMove.SavedLocation - NewLocation) < 3)
					&& (VSize(CurrentMove.SavedVelocity - NewVelocity) < 3)
					&& (GetStateName() == NewState)
					&& ((MoveActor.Physics != PHYS_Flying) || !IsInState('PlayerWalking')) )
				{
					return;
				}
				CurrentMove = None;
			}
			else
			{
				FreeMoves.Clear();
				CurrentMove = SavedMoves;
			}
        }
        else
			CurrentMove = None;
    }

	NewFloor.X = NewFloorX;
	NewFloor.Y = NewFloorY;
	NewFloor.Z = NewFloorZ;
	MoveActor.SetBase(NewBase, NewFloor);
	if ( Mover(NewBase) != None )
		NewLocation += NewBase.Location;

	if ( !bDemoOwner )
	{
	    //log("Client "$Role$" adjust "$self$" stamp "$TimeStamp$" location "$MoveActor.Location);
	    MoveActor.bCanTeleport = false;
        if ( !MoveActor.SetLocation(NewLocation) && (Pawn(MoveActor) != None)
		    && (MoveActor.CollisionHeight > Pawn(MoveActor).CrouchHeight)
		    && !Pawn(MoveActor).bIsCrouched
		    && (newPhysics == PHYS_Walking)
		    && (MoveActor.Physics != PHYS_Karma) && (MoveActor.Physics != PHYS_KarmaRagDoll)
		    && (MoveActor.Physics != PHYS_Havok) && (MoveActor.Physics != PHYS_HavokSkeletal) )
	    {
		    MoveActor.SetPhysics(newPhysics);
#if !IG_SWAT
            // This crouch was getting tripped in multiplayer when you'd try
            // to rush through a door that was opening. It appears that our
            // client tries to move the pawn to the location sent by the
            // server, but there are is a delicate timing issue where on the
            // client, the sent location collides with the still-opening door.
            // So, for some reason this engine code attempts to crouch the
            // pawn and try again. I don't believe we ever want this crouch
            // to happen in SWAT. [darren]
		    Pawn(MoveActor).ForceCrouch();
#endif
	    MoveActor.SetLocation(NewLocation);
	    }
	    MoveActor.bCanTeleport = true;
	}
	// Hack. Don't let network change physics mode of karma stuff on the client.
	if( MoveActor.Physics != PHYS_Karma && MoveActor.Physics != PHYS_KarmaRagDoll &&
		MoveActor.Physics != PHYS_Havok && MoveActor.Physics != PHYS_HavokSkeletal &&
		newPhysics != PHYS_Karma && newPhysics != PHYS_KarmaRagDoll &&
		newPhysics != PHYS_Havok && newPhysics != PHYS_HavokSkeletal)
	{
		MoveActor.SetPhysics(newPhysics);
	}

    MoveActor.Velocity = NewVelocity;

	if( GetStateName() != newstate
#if IG_SWAT //darren we dont want to transition to DEAD if we are already in observer cam
		&& newstate != 'Dead' || !IsInState('ObserveTeam')
#endif
      )
    {
		GotoState(newstate);
    }

	bUpdatePosition = true;
}

function ServerUpdatePing(int NewPing)
{
	PlayerReplicationInfo.Ping = NewPing;
	PlayerReplicationInfo.bReceivedPing = true;
}

function ClientUpdatePosition()
{
	local SavedMove CurrentMove;
	local int realbRun, realbDuck;
#if IG_SWAT
    local int realbLeanLeft;
    local int realbLeanRight;
#endif
	local bool bRealJump;

	// Dont do any network position updates on things running PHYS_Karma
	if( Pawn != None && (Pawn.Physics == PHYS_Karma || Pawn.Physics == PHYS_KarmaRagDoll ||
		Pawn.Physics == PHYS_Havok || Pawn.Physics == PHYS_HavokSkeletal ))
		return;

	bUpdatePosition = false;
	realbRun= bRun;
	realbDuck = bDuck;
#if IG_SWAT
    realbLeanLeft = bLeanLeft;
    realbLeanRight = bLeanRight;
#endif
	bRealJump = bPressedJump;
	CurrentMove = SavedMoves;
	bUpdating = true;
	while ( CurrentMove != None )
	{
		if ( CurrentMove.TimeStamp <= CurrentTimeStamp )
		{
			SavedMoves = CurrentMove.NextMove;
			CurrentMove.NextMove = FreeMoves;
			FreeMoves = CurrentMove;
			FreeMoves.Clear();
			CurrentMove = SavedMoves;
		}
		else
		{
            MoveAutonomous(CurrentMove.Delta, CurrentMove.bRun, CurrentMove.bDuck, CurrentMove.bPressedJump, CurrentMove.bDoubleJump,
#if IG_SWAT
                CurrentMove.bLeanLeft, CurrentMove.bLeanRight,
#endif
                CurrentMove.DoubleClickMove, CurrentMove.Acceleration, rot(0,0,0));
			CurrentMove = CurrentMove.NextMove;
		}
	}
    if ( PendingMove != None )
        MoveAutonomous(PendingMove.Delta, PendingMove.bRun, PendingMove.bDuck, PendingMove.bPressedJump, PendingMove.bDoubleJump,
#if IG_SWAT
            PendingMove.bLeanLeft, PendingMove.bLeanRight,
#endif
            PendingMove.DoubleClickMove, PendingMove.Acceleration, rot(0,0,0));

	//log("Client updated position to "$Pawn.Location);
	bUpdating = false;
	bDuck = realbDuck;
	bRun = realbRun;
	bPressedJump = bRealJump;
#if IG_SWAT
    bLeanLeft = realbLeanLeft;
    bLeanRight = realbLeanRight;
#endif
}

final function SavedMove GetFreeMove()
{
	local SavedMove s, first;
	local int i;

	if ( FreeMoves == None )
	{
        // don't allow more than 100 saved moves
		For ( s=SavedMoves; s!=None; s=s.NextMove )
		{
			i++;
            if ( i > 100 )
			{
				first = SavedMoves;
				SavedMoves = SavedMoves.NextMove;
				first.Clear();
				first.NextMove = None;
				// clear out all the moves
				While ( SavedMoves != None )
				{
					s = SavedMoves;
					SavedMoves = SavedMoves.NextMove;
					s.Clear();
					s.NextMove = FreeMoves;
					FreeMoves = s;
				}
				return first;
			}
		}
		return Spawn(class'SavedMove');
	}
	else
	{
		s = FreeMoves;
		FreeMoves = FreeMoves.NextMove;
		s.NextMove = None;
		return s;
	}
}

function int CompressAccel(int C)
{
	if ( C >= 0 )
		C = Min(C, 127);
	else
		C = Min(abs(C), 127) + 128;
	return C;
}

/*
========================================================================
Here's how player movement prediction, replication and correction works in network games:

Every tick, the PlayerTick() function is called.  It calls the PlayerMove() function (which is implemented
in various states).  PlayerMove() figures out the acceleration and rotation, and then calls ProcessMove()
(for single player or listen servers), or ReplicateMove() (if its a network client).

ReplicateMove() saves the move (in the PendingMove list), calls ProcessMove(), and then replicates the move
to the server by calling the replicated function ServerMove() - passing the movement parameters, the client's
resultant position, and a timestamp.

ServerMove() is executed on the server.  It decodes the movement parameters and causes the appropriate movement
to occur.  It then looks at the resulting position and if enough time has passed since the last response, or the
position error is significant enough, the server calls ClientAdjustPosition(), a replicated function.

ClientAdjustPosition() is executed on the client.  The client sets its position to the servers version of position,
and sets the bUpdatePosition flag to true.

When PlayerTick() is called on the client again, if bUpdatePosition is true, the client will call
ClientUpdatePosition() before calling PlayerMove().  ClientUpdatePosition() replays all the moves in the pending
move list which occured after the timestamp of the move the server was adjusting.
*/

//
// Replicate this client's desired movement to the server.
//
function ReplicateMove
(
	float DeltaTime,
	vector NewAccel,
	eDoubleClickDir DoubleClickMove,
	rotator DeltaRot
)
{
	local SavedMove NewMove, OldMove, LastMove;
	local byte ClientRoll;
	local float OldTimeDelta, NetMoveDelta;
	local int OldAccel;
	local vector BuildAccel, AccelNorm, MoveLoc;

	// find the most recent move, and the most recent interesting move
	if ( SavedMoves != None )
	{
        LastMove = SavedMoves;
		AccelNorm = Normal(NewAccel);
        while ( LastMove.NextMove != None )
		{
			// find most recent interesting move to send redundantly
            if ( LastMove.bPressedJump || LastMove.bDoubleJump || ((LastMove.DoubleClickMove != DCLICK_NONE) && (LastMove.DoubleClickMove < 5))
                || ((LastMove.Acceleration != NewAccel) && ((normal(LastMove.Acceleration) Dot AccelNorm) < 0.95)) )
                OldMove = LastMove;
            LastMove = LastMove.NextMove;
		}
        if ( LastMove.bPressedJump || LastMove.bDoubleJump || ((LastMove.DoubleClickMove != DCLICK_NONE) && (LastMove.DoubleClickMove < 5))
            || ((LastMove.Acceleration != NewAccel) && ((normal(LastMove.Acceleration) Dot AccelNorm) < 0.95)) )
            OldMove = LastMove;
	}
    // Get a SavedMove actor to store the movement in.
    if ( PendingMove != None )
        PendingMove.SetMoveFor(Level.TimeSeconds, self, DeltaTime, NewAccel, DoubleClickMove);

	NewMove = GetFreeMove();
	if ( NewMove == None )
		return;

#if !IG_THIS_IS_SHIPPING_VERSION // testing speed hack [crombie]
	if (bDebugSpeedhack)
 		NewMove.SetMoveFor(Level.TimeSeconds * 2.0, self, DeltaTime, NewAccel, DoubleClickMove);
 	else
 		NewMove.SetMoveFor(Level.TimeSeconds, self, DeltaTime, NewAccel, DoubleClickMove);
#else
	NewMove.SetMoveFor(Level.TimeSeconds, self, DeltaTime, NewAccel, DoubleClickMove);
#endif

	// Simulate the movement locally.
    bDoubleJump = false;
	ProcessMove(NewMove.Delta, NewMove.Acceleration, NewMove.DoubleClickMove, DeltaRot);

	if ( Pawn != None )
		Pawn.AutonomousPhysics(NewMove.Delta);
	else
		AutonomousPhysics(DeltaTime);

	if ( PendingMove == None )
		PendingMove = NewMove;
	else
	{
		NewMove.NextMove = FreeMoves;
		FreeMoves = NewMove;
		FreeMoves.Clear();
		NewMove = PendingMove;
	}
    NewMove.PostUpdate(self);
    NetMoveDelta = FMax(80.0/Player.CurrentNetSpeed, 0.015);

    // Decide whether to hold off on move
    // send if double click move, jump, or fire unless really too soon, or if newmove.delta big enough
    if ( !Level.bCapFramerate && !PendingMove.bPressedJump && !PendingMove.bDoubleJump
		&& ((PendingMove.DoubleClickMove == DCLICK_None) || (PendingMove.DoubleClickMove == DCLICK_Active))
		&& ((PendingMove.Acceleration == NewAccel) || ((Normal(NewAccel) Dot Normal(PendingMove.Acceleration)) > 0.95))
		&& (PendingMove.Delta < NetMoveDelta - ClientUpdateTime) )
	{
		return;
	}
	else
	{
		ClientUpdateTime = PendingMove.Delta - NetMoveDelta;
		if ( SavedMoves == None )
			SavedMoves = PendingMove;
		else
			LastMove.NextMove = PendingMove;
		PendingMove = None;
	}

	// check if need to redundantly send previous move
	if ( OldMove != None )
	{
		// old move important to replicate redundantly
		OldTimeDelta = FMin(255, (Level.TimeSeconds - OldMove.TimeStamp) * 500);
		BuildAccel = 0.05 * OldMove.Acceleration + vect(0.5, 0.5, 0.5);
		OldAccel = (CompressAccel(BuildAccel.X) << 23)
					+ (CompressAccel(BuildAccel.Y) << 15)
					+ (CompressAccel(BuildAccel.Z) << 7);
		if ( OldMove.bRun )
			OldAccel += 64;
        if ( OldMove.bDoubleJump )
			OldAccel += 32;
		if ( OldMove.bPressedJump )
			OldAccel += 16;
		OldAccel += OldMove.DoubleClickMove;
	}

	// Send to the server
	ClientRoll = (Rotation.Roll >> 8) & 255;
	if ( NewMove.bPressedJump )
		bJumpStatus = !bJumpStatus;

	if ( Pawn == None )
		MoveLoc = Location;
	else
		MoveLoc = Pawn.Location;

	if ( (NewMove.Acceleration == vect(0,0,0)) && (NewMove.DoubleClickMove == DCLICK_None) && !NewMove.bDoubleJump )
		ShortServerMove
		(
			NewMove.TimeStamp,
			MoveLoc,
			NewMove.bRun,
			NewMove.bDuck,
			bJumpStatus,
#if IG_SWAT
            NewMove.bLeanLeft,
            NewMove.bLeanRight,
#endif
			ClientRoll,
			(32767 & (Rotation.Pitch/2)) * 32768 + (32767 & (Rotation.Yaw/2))
		);
	else
		ServerMove
		(
			NewMove.TimeStamp,
			NewMove.Acceleration * 10,
			MoveLoc,
			NewMove.bRun,
			NewMove.bDuck,
			bJumpStatus,
            NewMove.bDoubleJump,
#if IG_SWAT
            NewMove.bLeanLeft,
            NewMove.bLeanRight,
#endif
			NewMove.DoubleClickMove,
			ClientRoll,
			(32767 & (Rotation.Pitch/2)) * 32768 + (32767 & (Rotation.Yaw/2)),
			OldTimeDelta,
			OldAccel
		);
}

function HandleWalking()
{
	if ( Pawn != None )
		Pawn.SetWalking( (bRun != 0) && !Region.Zone.IsA('WarpZoneInfo') );
}

function ServerRestartGame()
{
}

function SetFOVAngle(float newFOV)
{
	FOVAngle = newFOV;
}

function ClientFlash( float scale, vector fog )
{
    FlashScale = scale * vect(1,1,1);
    flashfog = 0.001 * fog;
}

function ClientAdjustGlow( float scale, vector fog )
{
	ConstantGlowScale += scale;
	ConstantGlowFog += 0.001 * fog;
}

/* ClientShake()
Function called on client to shake view.
Only ShakeView() should call ClientShake()
*/
private function ClientShake(vector ShakeRoll, vector OffsetMag, vector ShakeRate, float OffsetTime)
{
	if ( (MaxShakeRoll < ShakeRoll.X) || (ShakeRollTime < 0.01 * ShakeRoll.Y) )
{
		MaxShakeRoll = ShakeRoll.X;
		ShakeRollTime = 0.01 * ShakeRoll.Y;
		ShakeRollRate = 0.01 * ShakeRoll.Z;
}
	if ( VSize(OffsetMag) > VSize(MaxShakeOffset) )
	{
		ShakeOffsetTime = OffsetTime * vect(1,1,1);
		MaxShakeOffset = OffsetMag;
		ShakeOffsetRate = ShakeRate;
	}
	}

/* ShakeView()
Call this function to shake the player's view
shaketime = how long to roll view
RollMag = how far to roll view as it shakes
OffsetMag = max view offset
RollRate = how fast to roll view
OffsetRate = how fast to offset view
OffsetTime = how long to offset view (number of shakes)
*/
function ShakeView( float shaketime, float RollMag, vector OffsetMag, float RollRate, vector OffsetRate, float OffsetTime)
{
	local vector ShakeRoll;

	ShakeRoll.X = RollMag;
	ShakeRoll.Y = 100 * shaketime;
	ShakeRoll.Z = 100 * rollrate;
	ClientShake(ShakeRoll, OffsetMag, OffsetRate, OffsetTime);
}

function damageAttitudeTo(pawn Other, float Damage)
{
	if ( (Other != None) && (Other != Pawn) && (Damage > 0) )
		Enemy = Other;
}

function Typing( bool bTyping )
{
	bIsTyping = bTyping;
 	Pawn.bIsTyping = bIsTyping;
	if ( bTyping && (Pawn != None) && !Pawn.bTearOff )
		Pawn.ChangeAnimation();

}

//*************************************************************************************
// Normal gameplay execs
// Type the name of the exec function at the console to execute it

exec function Jump( optional float F )
{
	if ( Level.Pauser == PlayerReplicationInfo )
		SetPause(False);
	else
		bPressedJump = true;
}

// Send a voice message of a certain type to a certain player.
exec function Speech( name Type, int Index, string Callsign )
{
	if(PlayerReplicationInfo.VoiceType != None)
		PlayerReplicationInfo.VoiceType.static.PlayerSpeech( Type, Index, Callsign, Self );
}

exec function RestartLevel()
{
	if( Level.Netmode==NM_Standalone )
		ClientTravel( "?restart", TRAVEL_Relative, false );
}

exec function LocalTravel( string URL )
{
	if( Level.Netmode==NM_Standalone )
		ClientTravel( URL, TRAVEL_Relative, true );
}

// ------------------------------------------------------------------------
// Loading and saving

/* QuickSave()
Save game to slot 9
*/
exec function QuickSave()
{
	if ( (Pawn.Health > 0)
		&& (Level.NetMode == NM_Standalone) )
	{
		ClientMessage(QuickSaveString);
		ConsoleCommand("SaveGame 9");
	}
}

/* QuickLoad()
Load game from slot 9
*/
exec function QuickLoad()
{
	if ( Level.NetMode == NM_Standalone )
		ClientTravel( "?load=9", TRAVEL_Absolute, false);
}

/* SetPause()
 Try to pause game; returns success indicator.
 Replicated to server in network games.
 */
function bool SetPause( BOOL bPause )
{
    if ( Level.NetMode == NM_Standalone )
    {
        bFire = 0;
        bAltFire = 0;
	    return Level.Game.SetPause(bPause, self);
    }
    else
        return false;
}

/* Pause()
Command to try to pause the game.
*/
exec function Pause()
{
	// Pause if not already
	if(Level.Pauser == None)
		SetPause(true);
	else
		SetPause(false);
}

exec function ExecSetPause( bool bPause )
{
    SetPause( bPause );
}

exec function ShowMenu()
{
	// Pause if not already
	if(Level.Pauser == None)
		SetPause(true);

	StopForceFeedback();  // jdf - no way to pause feedback
}

//TMC removed Epic's Weapon or Inventory code here - functions ActivateInventoryItem(), ThrowWeapon(), ThrowWeapon(), ServerThrowWeapon(), PrevWeapon(), NextWeapon(), SwitchWeapon()

exec function Fire()
{
    local HandheldEquipment ActiveItem;

    ActiveItem = Pawn.GetActiveItem();
    if ( ActiveItem == None )
{
        log( "[tcohen] Fire() was called on the PlayerController.  But either the Pawn is None, the Pawn has no ActiveItem, or the Pawn's ActiveItem is not a HandheldEquipment." );
		return;
}
    //AssertWithDescription(ActiveItem != None,
    //    "[tcohen] Fire() was called on the PlayerController.  But either the Pawn is None, the Pawn has no ActiveItem, or the Pawn's ActiveItem is not a HandheldEquipment.");

    if (!ActiveItem.IsIdle() || !ActiveItem.IsAvailable())
        return; //can only do one thing at a time

    ActiveItem.OnPlayerUse();
}

simulated function Throw(); // overridden in SwatGamePlayerController.

// The player wants to use something in the level.
exec function Use()
	{
    local HandheldEquipment ActiveItem;

    ActiveItem = Pawn.GetActiveItem();

    AssertWithDescription(ActiveItem != None,
            "[tcohen] Use() was called on the PlayerController.  But either the Pawn is None, the Pawn has no ActiveItem, or the Pawn's ActiveItem is not a HandheldEquipment.");

    if (!ActiveItem.IsIdle()) return; //can only do one thing at a time

    ActiveItem.Use();
}

function ServerUse()
{
	local Actor A;

	if ( Level.Pauser == PlayerReplicationInfo )
	{
		SetPause(false);
		return;
	}

	if (Pawn==None)
		return;

	// Send the 'DoUse' event to each actor player is touching.
	ForEach Pawn.TouchingActors(class'Actor', A)
	{
		A.UsedBy(Pawn);
	}
}

exec function Suicide()
{
	if ( (Pawn != None) && (Level.TimeSeconds - Pawn.LastStartTime > 1) )
    Pawn.KilledBy( Pawn );
}

exec function Name( coerce string S )
{
	SetName(S);
}

exec function Assert()
{
    assert(false);
}

exec function SetName( coerce string S)
{
	ChangeName(S);
	UpdateURL("Name", S, true);
	SaveConfig();
}

function ChangeName( coerce string S )
{
    if ( Len(S) > 20 )
        S = left(S,20);
	ReplaceText(S, " ", "_");
    Level.Game.ChangeName( self, S, true );
}

exec function SwitchTeam()
{
	if ( (PlayerReplicationInfo.Team == None) || (PlayerReplicationInfo.Team.TeamIndex == 1) )
		ChangeTeam(0);
	else
		ChangeTeam(1);
}

exec function ChangeTeam( int N )
{
	local TeamInfo OldTeam;

	OldTeam = PlayerReplicationInfo.Team;
    Level.Game.ChangeTeam(self, N, true);
	if ( Level.Game.bTeamGame && (PlayerReplicationInfo.Team != OldTeam) )
    {
		if ( Pawn != None )
		    Pawn.Died( None, class'DamageType', Pawn.Location
#if IG_SWAT
                      ,vect(0,0,0) // hit momentum
#endif
            );
    }
}


exec function SwitchLevel( string URL )
{
    log( "In PlayerController::SwitchLevel. URL="$URL );
	if( Level.NetMode==NM_Standalone || Level.netMode==NM_ListenServer )
		Level.ServerTravel( URL, false );
}

exec function ClearProgressMessages()
{
	local int i;

	for (i=0; i<ArrayCount(ProgressMessage); i++)
	{
		ProgressMessage[i] = "";
		ProgressColor[i] = class'Canvas'.Static.MakeColor(255,255,255);
	}
}

exec event SetProgressMessage( int Index, string S, color C )
{
	if ( Index < ArrayCount(ProgressMessage) )
	{
		ProgressMessage[Index] = S;
		ProgressColor[Index] = C;
	}
}

exec event SetProgressTime( float T )
{
	ProgressTimeOut = T + Level.TimeSeconds;
}

function Restart()
{
	Super.Restart();

#if IG_SPEED_HACK_PROTECTION
	ResetTimeMargin();
#endif

	ServerTimeStamp = 0;
	TimeMargin = 0;
	EnterStartState();
	SetViewTarget(Pawn);
	bBehindView = Pawn.PointOfView();
	ClientRestart();
}

function EnterStartState()
{
	local name NewState;

	if ( Pawn.PhysicsVolume.bWaterVolume )
	{
		NewState = Pawn.WaterMovementState;
	}
	else
		NewState = Pawn.LandMovementState;

	if ( IsInState(NewState) )
		BeginState();
	else
		GotoState(NewState);
}

function ClientRestart()
{
    mplog( self$"---PlayerController::ClientRestart()." );

	if ( (Pawn != None) && Pawn.bTearOff )
	{
        //mplog( "...Pawn was bTearOff" );
		Pawn.Controller = None;
		Pawn = None;
	}
	if ( Pawn == None )
	{
		GotoState('WaitingForPawn');
		return;
	}

    //mplog( "...Pawn was not None, doing the restart." );
	Pawn.ClientRestart();
	SetViewTarget(Pawn);
	bBehindView = Pawn.PointOfView();
    CleanOutSavedMoves();

    // Reset all player movement flags while we're respawning.
    bDuck = 0;
    bRun = 0;
#if IG_SWAT
    bLeanLeft = 0;
    bLeanRight = 0;
    bIgnoreNextRunRelease = true;
    bIgnoreNextCrouchRelease = true;
#endif

	EnterStartState();
}

exec function BehindView( Bool B )
{
	if ( (Level.NetMode == NM_Standalone) || Level.Game.bAllowBehindView || PlayerReplicationInfo.bOnlySpectator || PlayerReplicationInfo.bAdmin || IsA('Admin') )
	{
	    bBehindView = B;
	    ClientSetBehindView(bBehindView);
    }
}

exec function ToggleBehindView()
{
// dbeswick: integrated 20/6/05
#if IG_SWAT // prevent cheating in net games
    if (Level.NetMode != NM_Standalone)
        return;
#endif
	ServerToggleBehindview();
}

function ServerToggleBehindView()
{
	bBehindView = !bBehindView;
	ClientSetBehindView(bBehindView);
}

//=============================================================================
// functions.

//TMC removed Epic's Weapon or Inventory code here - function ChangedWeapon()

event TravelPostAccept()
{
	if ( Pawn.Health <= 0 )
		Pawn.Health = Pawn.Default.Health;
}

event PlayerTick( float DeltaTime )
{
	LastDeltaTime = DeltaTime;


#if !IG_SHARED	// rowan: this is essentially a hack.. we handle this better now by explicitly precaching actors on the client
	//if ( bForcePrecache && (Level.TimeSeconds > ForcePrecacheTime) )
	//{
	//	bForcePrecache = false;
	//	Level.FillRenderPrecacheArrays();
	//}
#endif
	PlayerInput.PlayerInput(DeltaTime);
	if ( bUpdatePosition )
		ClientUpdatePosition();
	PlayerMove(DeltaTime);

#if IG_SHARED
	if ( Level.NetMode == NM_Client )
	{
		// IGB: mcj--I'm adding this here. It has to happen on the network clients,
		// but LevelInfo doesn't get ticked, and GameInfo doesn't exist.
		if ( !bAlreadyNotifiedLevelOfGameStarted )
		{
            mplog( "Notifying gamestarted" );
			bAlreadyNotifiedLevelOfGameStarted = true;
			Level.NotifyGameStarted();
		}
	}
#endif
}

function PlayerMove(float DeltaTime);

#if !IG_SWAT    //tcohen: weapon zoom
//
/* AdjustAim()
Calls this version for player aiming help.
Aimerror not used in this version.
Only adjusts aiming at pawns
*/
simulated function rotator AdjustAim(Ammunition FiredAmmunition, vector projStart, int aimerror)
{
	local vector FireDir, AimSpot, HitNormal, HitLocation, OldAim, AimOffset;
	local actor BestTarget;
	local float bestAim, bestDist, projspeed;
	local actor HitActor;
	local bool bNoZAdjust, bLeading;
	local rotator AimRot;

	FireDir = vector(Rotation);
	if ( FiredAmmunition.bInstantHit )
		HitActor = Trace(HitLocation, HitNormal, projStart + 10000 * FireDir, projStart, true);
	else
		HitActor = Trace(HitLocation, HitNormal, projStart + 4000 * FireDir, projStart, true);
	if ( (HitActor != None) && HitActor.bProjTarget )
	{
        //TMC removed
		//FiredAmmunition.WarnTarget(Target,Pawn,FireDir);
		BestTarget = HitActor;
		bNoZAdjust = true;
		OldAim = HitLocation;
		BestDist = VSize(BestTarget.Location - Pawn.Location);
	}
	else
	{
		// adjust aim based on FOV
		bestAim = 0.95;
		if ( AimingHelp == 1 )
		{
			bestAim = 0.93;
			if ( FiredAmmunition.bInstantHit )
				bestAim = 0.97;
			if ( FOVAngle < DefaultFOV - 8 )
				bestAim = 0.99;
		}
		else
		{
			if ( FiredAmmunition.bInstantHit )
				bestAim = 0.98;
			if ( FOVAngle != DefaultFOV )
				bestAim = 0.995;
		}
        //TMC removed Epic's Weapon or Inventory code here - pick & warn target
		OldAim = projStart + FireDir * bestDist;
	}
    if ( (AimingHelp == 0) || (Level.NetMode != NM_Standalone) )
	{
		if (bBehindView)
			return Pawn.Rotation;
		else
			return Rotation;
	}

	// aim at target - help with leading also
	if ( !FiredAmmunition.bInstantHit )
	{
		projspeed = FiredAmmunition.ProjectileClass.default.speed;
		BestDist = vsize(BestTarget.Location + BestTarget.Velocity * FMin(2, 0.02 + BestDist/projSpeed) - projStart);
		bLeading = true;
		FireDir = BestTarget.Location + BestTarget.Velocity * FMin(2, 0.02 + BestDist/projSpeed) - projStart;
		AimSpot = projStart + bestDist * Normal(FireDir);
        //TMC removed Epic's Weapon or Inventory code here - splash damage
	}
	else
	{
		FireDir = BestTarget.Location - projStart;
		AimSpot = projStart + bestDist * Normal(FireDir);
	}
	AimOffset = AimSpot - OldAim;

	// adjust Z of shooter if necessary
	if ( bNoZAdjust || (bLeading && (Abs(AimOffset.Z) < BestTarget.CollisionHeight)) )
		AimSpot.Z = OldAim.Z;
	else if ( AimOffset.Z < 0 )
		AimSpot.Z = BestTarget.Location.Z + 0.4 * BestTarget.CollisionHeight;
	else
		AimSpot.Z = BestTarget.Location.Z - 0.7 * BestTarget.CollisionHeight;

	if ( !bLeading )
	{
		// if not leading, add slight random error ( significant at long distances )
		if ( !bNoZAdjust )
		{
			AimRot = rotator(AimSpot - projStart);
			if ( FOVAngle < DefaultFOV - 8 )
				AimRot.Yaw = AimRot.Yaw + 200 - Rand(400);
			else
				AimRot.Yaw = AimRot.Yaw + 375 - Rand(750);
			return AimRot;
		}
	}
	else if ( !FastTrace(projStart + 0.9 * bestDist * Normal(FireDir), projStart) )
	{
		FireDir = BestTarget.Location - projStart;
		AimSpot = projStart + bestDist * Normal(FireDir);
	}

	return rotator(AimSpot - projStart);
}
#endif

function bool NotifyLanded(vector HitNormal)
{
	return bUpdating;
}

//=============================================================================
// Player Control

// Player view.
// Compute the rendering viewpoint for the player.
//

function AdjustView(float DeltaTime )
{
#if !IG_SWAT    //tcohen: weapon zoom
	// teleporters affect your FOV, so adjust it back down
	if ( FOVAngle != DesiredFOV )
	{
		if ( FOVAngle > DesiredFOV )
			FOVAngle = FOVAngle - FMax(7, 0.9 * DeltaTime * (FOVAngle - DesiredFOV));
		else
			FOVAngle = FOVAngle - FMin(-7, 0.9 * DeltaTime * (FOVAngle - DesiredFOV));
		if ( Abs(FOVAngle - DesiredFOV) <= 10 )
			FOVAngle = DesiredFOV;
	}

	// adjust FOV for weapon zooming
	if ( bZooming )
	{
		ZoomLevel += DeltaTime * 1.0;
		if (ZoomLevel > 0.9)
			ZoomLevel = 0.9;
		DesiredFOV = FClamp(90.0 - (ZoomLevel * 88.0), 1, 170);
	}
#endif
}

function CalcBehindView(out vector CameraLocation, out rotator CameraRotation, float Dist)
{
	local vector View,HitLocation,HitNormal;
    local float ViewDist,RealDist;

	CameraRotation = Rotation;
	if ( bBlockCloseCamera )
		CameraLocation.Z += 12;

	View = vect(1,0,0) >> CameraRotation;

    // add view radius offset to camera location and move viewpoint up from origin (amb)
    RealDist = Dist;

    if( Trace( HitLocation, HitNormal, CameraLocation - Dist * vector(CameraRotation), CameraLocation,false,vect(10,10,10) ) != None )
		ViewDist = FMin( (CameraLocation - HitLocation) Dot View, Dist );
	else
		ViewDist = Dist;

    if ( !bBlockCloseCamera || !bValidBehindCamera || (ViewDist > 10 + FMax(ViewTarget.CollisionRadius, ViewTarget.CollisionHeight)) )
	{
		//Log("Update Cam ");
		bValidBehindCamera = true;
		OldCameraLoc = CameraLocation - ViewDist * View;
		OldCameraRot = CameraRotation;
	}
	else
	{
		//Log("Dont Update Cam "$bBlockCloseCamera@bValidBehindCamera@ViewDist);
		SetRotation(OldCameraRot);
	}

    CameraLocation = OldCameraLoc;
    CameraRotation = OldCameraRot;
}

function CalcFirstPersonView( out vector CameraLocation, out rotator CameraRotation )
{
	// First-person view.
#if IG_SWAT //tcohen: support for StingGrenade view modification
	CameraRotation = Rotation + Pawn.ViewRotationOffset();
	CameraLocation = CameraLocation + Pawn.EyePosition() + Pawn.ViewLocationOffset(CameraRotation);
#else
	CameraRotation = Rotation;
	CameraLocation = CameraLocation + Pawn.EyePosition() + ShakeOffset;
#endif
}

#if IG_SWAT  //tcohen: changed Add/RemoveCameraEffect()

//  Assuming that only Add/RemoveCameraEffect() are used to manipulate the CameraEffects list,
//    UniqueClass - If true, then CameraEffects will never contain two CameraEffects the same class.
//    UniqueObject - If true, then CameraEffects will never contain the same CameraEffect more than once.
//  In the case of a conflict (adding something that can't be immediately added because of UniqueClass or UniqueObject),
//    RemoveConflicting - If true, remove the existing conflicting CameraEffect.  if false, don't add the NewEffect.
//
//  Note that UniqueClass implies UniqueObject, so if UniqueClass is true, then UniqueObject is ignored.

event AddCameraEffect(CameraEffect NewEffect, bool UniqueClass, bool UniqueObject, bool RemoveConflicting)
{
    local int i;

    if (UniqueClass)
    {
        //check if there's already a CameraEffect with the same class as NewEffect
        for (i=0; i<CameraEffects.Length; ++i)
        {
            while (CameraEffects[i].class == NewEffect.class)
            {
                if (!RemoveConflicting) return; //found a conflict, and we're not supposed to remove it

                CameraEffects[i].OnRemoved();
                CameraEffects.Remove(i, 1);

                if (i >= CameraEffects.Length) break;
            }
        }
    }
    else
    if (UniqueObject)
    {
        //check if NewEffect is already in the list
        for (i=0; i<CameraEffects.Length; ++i)
        {
            while (CameraEffects[i] == NewEffect)
            {
                if (!RemoveConflicting) return; //found a conflict, and we're not supposed to remove it

                CameraEffects[i].OnRemoved();
                CameraEffects.Remove(i, 1);

                if (i >= CameraEffects.Length) break;
}
        }
    }

	CameraEffects[CameraEffects.Length] = NewEffect;
    NewEffect.OnAdded();
}

//if ByClass is true, then all instances of ExEffect.class are removed
event RemoveCameraEffect(CameraEffect ExEffect, optional bool ByClass)
{
	local int i;

	for (i=0; i<CameraEffects.Length; ++i)
    {
        while   (
                    !ByClass && CameraEffects[i] == ExEffect
                ||  ByClass && CameraEffects[i].class == ExEffect.class
                )
        {
            CameraEffects[i].OnRemoved();
			CameraEffects.Remove(i, 1);

            if (i >= CameraEffects.Length) break;
		}
}
}

function RemoveAllCameraEffects()
{
	local int i;

	for (i=0; i<CameraEffects.Length; ++i)
        CameraEffects[i].OnRemoved();

    CameraEffects.Remove(0, CameraEffects.Length);
}

#else   //!IG_SWAT

event AddCameraEffect(CameraEffect NewEffect,optional bool RemoveExisting)
{
	if(RemoveExisting)
		RemoveCameraEffect(NewEffect);

	CameraEffects.Length = CameraEffects.Length + 1;
	CameraEffects[CameraEffects.Length - 1] = NewEffect;
}

event RemoveCameraEffect(CameraEffect ExEffect)
{
	local int	EffectIndex;

	for(EffectIndex = 0;EffectIndex < CameraEffects.Length;EffectIndex++)
		if(CameraEffects[EffectIndex] == ExEffect)
		{
			CameraEffects.Remove(EffectIndex,1);
			return;
		}
}

exec function CreateCameraEffect(class<CameraEffect> EffectClass)
{
	AddCameraEffect(new EffectClass);
}

#endif

simulated function rotator GetViewRotation()
{
	if ( bBehindView && (Pawn != None) )
		return Pawn.Rotation;
	return Rotation;
}

event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
	local Pawn PTarget;

	// If desired, call the pawn's own special callview
	if( Pawn != None && Pawn.bSpecialCalcView )
	{
		// try the 'special' calcview. This may return false if its not applicable, and we do the usual.
		if( Pawn.SpecialCalcView(ViewActor, CameraLocation, CameraRotation) )
			return;
	}

	if ( (ViewTarget == None) || ViewTarget.bDeleteMe )
	{
        if ( bViewBot && (CheatManager != None) )
			CheatManager.ViewBot();
        else if ( (Pawn != None) && !Pawn.bDeleteMe )
			SetViewTarget(Pawn);
        else if ( RealViewTarget != None )
            SetViewTarget(RealViewTarget);
		else
			SetViewTarget(self);
	}

	ViewActor = ViewTarget;
	CameraLocation = ViewTarget.Location;

	if ( ViewTarget == Pawn )
	{
		if( bBehindView ) //up and behind
			CalcBehindView(CameraLocation, CameraRotation, CameraDist * Pawn.Default.CollisionRadius);
		else
			CalcFirstPersonView( CameraLocation, CameraRotation );
		return;
	}
	if ( ViewTarget == self )
	{
		if ( bCameraPositionLocked )
			CameraRotation = CheatManager.LockedRotation;
		else
			CameraRotation = Rotation;
		return;
	}

    if ( ViewTarget.IsA('Projectile') && !bBehindView )
    {
        CameraLocation += (ViewTarget.CollisionHeight) * vect(0,0,1);
        CameraRotation = Rotation;
        return;
    }

	CameraRotation = ViewTarget.Rotation;
	PTarget = Pawn(ViewTarget);
	if ( PTarget != None )
	{
		if ( Level.NetMode == NM_Client )
		{
#if IG_SWAT
            PTarget.SetViewLocation(TargetViewLocation);
#else
			PTarget.EyeHeight = TargetEyeHeight;
#endif
			PTarget.SetViewRotation(TargetViewRotation);
            CameraRotation = BlendedTargetViewRotation;
		}
		else if ( PTarget.IsPlayerPawn() )
			CameraRotation = PTarget.GetViewRotation();
		if ( !bBehindView )
			CameraLocation += PTarget.EyePosition();
	}
	if ( bBehindView )
	{
		CameraLocation = CameraLocation + (ViewTarget.Default.CollisionHeight - ViewTarget.CollisionHeight) * vect(0,0,1);
		CalcBehindView(CameraLocation, CameraRotation, CameraDist * ViewTarget.Default.CollisionRadius);
	}
}

function int BlendRot(float DeltaTime, int BlendC, int NewC)
{
	if ( Abs(BlendC - NewC) > 32767 )
	{
		if ( BlendC > NewC )
			NewC += 65536;
		else
			BlendC += 65536;
	}
	if ( Abs(BlendC - NewC) > 4096 )
		BlendC = NewC;
	else
		BlendC = BlendC + (NewC - BlendC) * FMin(1,24 * DeltaTime);

	return (BlendC & 65535);
}

function CheckShake(out float MaxOffset, out float Offset, out float Rate, out float Time)
{
	if ( abs(Offset) < abs(MaxOffset) )
		return;

	Offset = MaxOffset;
	if ( Time > 1 )
	{
		if ( Time * abs(MaxOffset/Rate) <= 1 )
			MaxOffset = MaxOffset * (1/Time - 1);
		else
			MaxOffset *= -1;
		Time -= 1;
		Rate *= -1;
	}
	else
	{
		MaxOffset = 0;
		Offset = 0;
		Rate = 0;
	}
}

function ViewShake(float DeltaTime)
{
	local Rotator ViewRotation;
	local float FRoll;

	if ( ShakeOffsetRate != vect(0,0,0) )
	{
		// modify shake offset
		ShakeOffset.X += DeltaTime * ShakeOffsetRate.X;
		CheckShake(MaxShakeOffset.X, ShakeOffset.X, ShakeOffsetRate.X, ShakeOffsetTime.X);

		ShakeOffset.Y += DeltaTime * ShakeOffsetRate.Y;
		CheckShake(MaxShakeOffset.Y, ShakeOffset.Y, ShakeOffsetRate.Y, ShakeOffsetTime.Y);

		ShakeOffset.Z += DeltaTime * ShakeOffsetRate.Z;
		CheckShake(MaxShakeOffset.Z, ShakeOffset.Z, ShakeOffsetRate.Z, ShakeOffsetTime.Z);
	}

	ViewRotation = Rotation;

	if ( ShakeRollRate != 0 )
	{
		ViewRotation.Roll = ((ViewRotation.Roll & 65535) + ShakeRollRate * DeltaTime) & 65535;
		if ( ViewRotation.Roll > 32768 )
			ViewRotation.Roll -= 65536;
		FRoll = ViewRotation.Roll;
		CheckShake(MaxShakeRoll, FRoll, ShakeRollRate, ShakeRollTime);
		ViewRotation.Roll = FRoll;
	}
	else if ( bZeroRoll )
		ViewRotation.Roll = 0;
	SetRotation(ViewRotation);
}

function bool TurnTowardNearestEnemy();

function TurnAround()
{
	if ( !bSetTurnRot )
	{
		TurnRot180 = Rotation;
		TurnRot180.Yaw += 32768;
		bSetTurnRot = true;
	}

	DesiredRotation = TurnRot180;
	bRotateToDesired = ( DesiredRotation.Yaw != Rotation.Yaw );
}

function UpdateRotation(float DeltaTime, float maxPitch)
{
	local rotator newRotation, ViewRotation;
#if IG_SWAT
    local int LeftYawLimit;
    local int RightYawLimit;
    local int ViewYawRelativeToLockedYaw;
    local float YawEdgeAlpha;
#endif

	if ( bInterpolating || ((Pawn != None) && Pawn.bInterpolating) )
	{
		ViewShake(deltaTime);
		return;
	}
	ViewRotation = Rotation;
	DesiredRotation = ViewRotation; //save old rotation
	if ( bTurnToNearest != 0 )
		TurnTowardNearestEnemy();
	else if ( bTurn180 != 0 )
		TurnAround();
	else
	{
		TurnTarget = None;
		bRotateToDesired = false;
		bSetTurnRot = false;
		ViewRotation.Yaw += 32.0 * DeltaTime * aTurn;
		ViewRotation.Pitch += 32.0 * DeltaTime * aLookUp;
	}
	ViewRotation.Pitch = ViewRotation.Pitch & 65535;
	If ((ViewRotation.Pitch > 18000) && (ViewRotation.Pitch < 49152))
	{
		If (aLookUp > 0)
			ViewRotation.Pitch = 18000;
		else
			ViewRotation.Pitch = 49152;
	}

#if IG_SWAT
    // If this pawn is leaning, limit his yaw
    if (Pawn != None && Pawn.LeanState != kLeanStateNone)
    {
        ViewYawRelativeToLockedYaw = WrapAngle0To2Pi(ViewRotation.Yaw - Pawn.LeanLockedYaw);

        // Clamp yaw if it is outside our left and right limits.

        YawEdgeAlpha = Pawn.GetYawEdgeAlpha(ViewRotation.Pitch);

        // Right is positive, left is negative.
        Pawn.GetLeanYawRanges(LeftYawLimit, RightYawLimit);
        LeftYawLimit  = WrapAngle0To2Pi(65536 - (LeftYawLimit * YawEdgeAlpha));
        RightYawLimit = WrapAngle0To2Pi(RightYawLimit * YawEdgeAlpha);

        // Do the clamping
        if (ViewYawRelativeToLockedYaw > RightYawLimit && ViewYawRelativeToLockedYaw <= 32768)
        {
            ViewRotation.Yaw = Pawn.LeanLockedYaw + RightYawLimit;
        }
        else if (ViewYawRelativeToLockedYaw < LeftYawLimit && ViewYawRelativeToLockedYaw > 32768)
        {
            ViewRotation.Yaw = Pawn.LeanLockedYaw + LeftYawLimit;
        }
    }
#endif

	SetRotation(ViewRotation);

	ViewShake(deltaTime);
	ViewFlash(deltaTime);

	NewRotation = ViewRotation;
	NewRotation.Roll = Rotation.Roll;

	if ( !bRotateToDesired && (Pawn != None) && (!bFreeCamera || !bBehindView) )
		Pawn.FaceRotation(NewRotation);
}

function ClearDoubleClick()
{
	if (PlayerInput != None)
		PlayerInput.DoubleClickTimer = 0.0;
}

// Player movement.
// Player Standing, walking, running, falling.
state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;

	function bool NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
	{
		if ( NewVolume.bWaterVolume )
			GotoState(Pawn.WaterMovementState);
		return false;
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local vector OldAccel;
		local bool OldCrouch;

		if ( Pawn == None )
			return;
		OldAccel = Pawn.Acceleration;
		Pawn.Acceleration = NewAccel;
		if ( bDoubleJump && (bUpdating || Pawn.CanDoubleJump()) )
			Pawn.DoDoubleJump(bUpdating);
        else if ( bPressedJump )
			Pawn.DoJump(bUpdating);
		if ( Pawn.Physics != PHYS_Falling )
		{
			OldCrouch = Pawn.bWantsToCrouch;
			if (bDuck == 0)
				Pawn.ShouldCrouch(false);
			else if ( Pawn.bCanCrouch )
				Pawn.ShouldCrouch(true);

#if IG_SWAT
            if (bLeanLeft == 0)
                Pawn.ShouldLeanLeft(false);
            else
                Pawn.ShouldLeanLeft(true);
            if (bLeanRight == 0)
                Pawn.ShouldLeanRight(false);
            else
                Pawn.ShouldLeanRight(true);
#endif

		}
	}

	function PlayerMove( float DeltaTime )
	{
		local vector X,Y,Z, NewAccel;
		local eDoubleClickDir DoubleClickMove;
		local rotator OldRotation, ViewRotation;
		local bool	bSaveJump;

		GetAxes(Pawn.Rotation,X,Y,Z);

		// Update acceleration.
		NewAccel = aForward*X + aStrafe*Y;
		NewAccel.Z = 0;
		if ( VSize(NewAccel) < 1.0 )
			NewAccel = vect(0,0,0);
		DoubleClickMove = PlayerInput.CheckForDoubleClickMove(DeltaTime);

		GroundPitch = 0;
		ViewRotation = Rotation;
		if ( Pawn.Physics == PHYS_Walking )
		{
			// tell pawn about any direction changes to give it a chance to play appropriate animation
			//if walking, look up/down stairs - unless player is rotating view
			if ( (bLook == 0)
                && (((Pawn.Acceleration != Vect(0,0,0)) && bSnapToLevel) || !bKeyboardLook) )
			{
				if ( bLookUpStairs || bSnapToLevel )
				{
					GroundPitch = FindStairRotation(deltaTime);
					ViewRotation.Pitch = GroundPitch;
				}
				else if ( bCenterView )
				{
					ViewRotation.Pitch = ViewRotation.Pitch & 65535;
					if (ViewRotation.Pitch > 32768)
						ViewRotation.Pitch -= 65536;
					ViewRotation.Pitch = ViewRotation.Pitch * (1 - 12 * FMin(0.0833, deltaTime));
                    if ( Abs(ViewRotation.Pitch) < 200 )
						ViewRotation.Pitch = 0;
				}
			}
		}
		else
		{
			if ( !bKeyboardLook && (bLook == 0) && bCenterView )
			{
				ViewRotation.Pitch = ViewRotation.Pitch & 65535;
				if (ViewRotation.Pitch > 32768)
					ViewRotation.Pitch -= 65536;
				ViewRotation.Pitch = ViewRotation.Pitch * (1 - 12 * FMin(0.0833, deltaTime));
                if ( Abs(ViewRotation.Pitch) < 200 )
					ViewRotation.Pitch = 0;
			}
		}
		Pawn.CheckBob(DeltaTime, Y);

		// Update rotation.
		SetRotation(ViewRotation);
		OldRotation = Rotation;
		UpdateRotation(DeltaTime, 1);
		bDoubleJump = false;

		if ( bPressedJump && Pawn.CannotJumpNow() )
		{
			bSaveJump = true;
			bPressedJump = false;
		}
		else
			bSaveJump = false;

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
		else
			ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
		bPressedJump = bSaveJump;
	}

	function BeginState()
	{
       	DoubleClickDir = DCLICK_None;
       	bPressedJump = false;
       	GroundPitch = 0;
		if ( Pawn != None )
		{
		if ( Pawn.Mesh == None )
			Pawn.SetMesh();
		Pawn.ShouldCrouch(false);
		if (Pawn.Physics != PHYS_Falling && Pawn.Physics != PHYS_Karma && Pawn.Physics != PHYS_Havok) // FIXME HACK!!!
			Pawn.SetPhysics(PHYS_Walking);
		}
	}

	function EndState()
	{

		GroundPitch = 0;
		if ( Pawn != None && bDuck==0 )
		{
			Pawn.ShouldCrouch(false);
		}
	}

#if IG_SWAT
// We need this label (even if it's empty) for ClientGotoState() to work.
Begin:
#endif
}

// player is climbing ladder
state PlayerClimbing
{
ignores SeePlayer, HearNoise, Bump;

	function bool NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
	{
		if ( NewVolume.bWaterVolume )
			GotoState(Pawn.WaterMovementState);
		else
			GotoState(Pawn.LandMovementState);
		return false;
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local vector OldAccel;

		OldAccel = Pawn.Acceleration;
		Pawn.Acceleration = NewAccel;

		if ( bPressedJump )
		{
			Pawn.DoJump(bUpdating);
			if ( Pawn.Physics == PHYS_Falling )
				GotoState('PlayerWalking');
		}
	}

	function PlayerMove( float DeltaTime )
	{
		local vector X,Y,Z, NewAccel;
		local eDoubleClickDir DoubleClickMove;
		local rotator OldRotation, ViewRotation;
		local bool	bSaveJump;

		GetAxes(Rotation,X,Y,Z);

		// Update acceleration.
#if !IG_SWAT // ckline: we don't support ladders
		if ( Pawn.OnLadder != None )
			NewAccel = aForward*Pawn.OnLadder.ClimbDir;
		else
#endif
			NewAccel = aForward*X + aStrafe*Y;
		if ( VSize(NewAccel) < 1.0 )
			NewAccel = vect(0,0,0);

		ViewRotation = Rotation;

		// Update rotation.
		SetRotation(ViewRotation);
		OldRotation = Rotation;
		UpdateRotation(DeltaTime, 1);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
		else
			ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
		bPressedJump = bSaveJump;
	}

	function BeginState()
	{
		Pawn.ShouldCrouch(false);
		bPressedJump = false;
	}

	function EndState()
	{
		if ( Pawn != None )
			Pawn.ShouldCrouch(false);
	}
}

#if !IG_SWAT // ckline: removed vehicles
// Player movement.
// Player Driving a Karma or Havok vehicle.
state PlayerDriving
{
ignores SeePlayer, HearNoise, Bump;

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{

	}

    exec function Fire()
    {
		local KVehicle DrivenVehicle;

		DrivenVehicle = KVehicle(Pawn);
		if(DrivenVehicle != None)
		{
			DrivenVehicle.VehicleFire(false);
			DrivenVehicle.bVehicleIsFiring = true;
		}
    }

    exec function AltFire(optional float F)
    {
		local KVehicle DrivenVehicle;

		DrivenVehicle = KVehicle(Pawn);
		if(DrivenVehicle != None)
		{
			DrivenVehicle.VehicleFire(true);
			DrivenVehicle.bVehicleIsAltFiring = true;
		}
    }

	// When you hit use inside the SVehicle or HavokVehicle, you get out.
	function ServerUse()
	{
		local SVehicle DrivenSVehicle;
		local HavokVehicle DrivenHVehicle;

		if(Role != ROLE_Authority)
			return;

		DrivenHVehicle = HavokVehicle(Pawn);
		if(DrivenHVehicle != None)
		{
			DrivenHVehicle.bGetOut = true;
		}
		else
		{
			DrivenSVehicle = SVehicle(Pawn);
			if(DrivenSVehicle != None)
			{
				DrivenSVehicle.bGetOut = true;
			}
		}
	}

	// Set the throttle, steering etc. for the vehicle based on the input provided
	function ProcessDrive(float InForward, float InStrafe, float InUp, bool InJump)
	{
		local KVehicle DrivenVehicle;
		local SVehicle DrivenSVehicle;
		local HavokVehicle DrivenHVehicle;

		DrivenVehicle = KVehicle(Pawn);

		if(DrivenVehicle == None)
		{
			// URGH! Need to make superclass of KVehicle and SVehicle
			DrivenSVehicle = SVehicle(Pawn);

			if(DrivenSVehicle == None)
			{
				DrivenHVehicle = HavokVehicle(Pawn);

				// Double URGH! Can't remove the Karma specific stuff in SVehicle, so can't
				// really use it as a base class..

				if(DrivenHVehicle == None)
				{
					log("PlayerDriving.PlayerMove: No Vehicle");
					return;
				}

				if(InForward > 1)
					DrivenHVehicle.Throttle = 1;
				else if(InForward < -1)
					DrivenHVehicle.Throttle = -1;
				else
					DrivenHVehicle.Throttle = 0;

				if(InStrafe < -1)
					DrivenHVehicle.Steering = 1;
				else if(InStrafe > 1)
					DrivenHVehicle.Steering = -1;
				else
					DrivenHVehicle.Steering = 0;

				if(InUp < -1)
					DrivenHVehicle.Rise = -1;
				else if(InUp > 1)
					DrivenHVehicle.Rise = 1;
				else
					DrivenHVehicle.Rise = 0;

				return;
			}

			//log("Drive:"$InForward$" Steer:"$InStrafe);

			if(InForward > 1)
				DrivenSVehicle.Throttle = 1;
			else if(InForward < -1)
				DrivenSVehicle.Throttle = -1;
			else
				DrivenSVehicle.Throttle = 0;

			if(InStrafe < -1)
				DrivenSVehicle.Steering = 1;
			else if(InStrafe > 1)
				DrivenSVehicle.Steering = -1;
			else
				DrivenSVehicle.Steering = 0;

			if(InUp < -1)
				DrivenSVehicle.Rise = -1;
			else if(InUp > 1)
				DrivenSVehicle.Rise = 1;
			else
				DrivenSVehicle.Rise = 0;

			return;
		}

		// // // //

		// check for 'jump' to throw the driver out.
		if(InJump && Role == ROLE_Authority)
		{
			DrivenVehicle.bGetOut = true;
			return;
		}

		//log("Drive:"$InForward$" Steer:"$InStrafe);

		if(InForward > 1)
			DrivenVehicle.Throttle = 1;
		else if(InForward < -1)
			DrivenVehicle.Throttle = -1;
		else
			DrivenVehicle.Throttle = 0;

		if(InStrafe < -1)
			DrivenVehicle.Steering = 1;
		else if(InStrafe > 1)
			DrivenVehicle.Steering = -1;
		else
			DrivenVehicle.Steering = 0;
	}

    function PlayerMove( float DeltaTime )
		{
		local KVehicle DrivenVehicle;

		// Only servers can actually do the driving logic.
		if(Role < ROLE_Authority)
			ServerDrive(aForward, aStrafe, aUp, bPressedJump);
		else
			ProcessDrive(aForward, aStrafe, aUp, bPressedJump);

		// If the vehicle is being controlled here - set replicated variables.
		DrivenVehicle = KVehicle(Pawn);
		if(DrivenVehicle != None)
			{
			if(bFire == 0 && DrivenVehicle.bVehicleIsFiring)
			{
				DrivenVehicle.VehicleCeaseFire(false);
				DrivenVehicle.bVehicleIsFiring = false;
			}

			if(bAltFire == 0 && DrivenVehicle.bVehicleIsAltFiring)
		{
				DrivenVehicle.VehicleCeaseFire(true);
				DrivenVehicle.bVehicleIsAltFiring = false;
			}
		}

        // update 'looking' rotation - no affect on driving
		UpdateRotation(DeltaTime, 2);
	}

	function BeginState()
	{
		CleanOutSavedMoves();
	}

	function EndState()
	{
		CleanOutSavedMoves();
	}
}
#endif // !IG_SWAT

// Player movement.
// Player walking on walls
state PlayerSpidering
{
ignores SeePlayer, HearNoise, Bump;

	event bool NotifyHitWall(vector HitNormal, actor HitActor)
	{
		Pawn.SetPhysics(PHYS_Spider);
		Pawn.SetBase(HitActor, HitNormal);
		return true;
	}

	// if spider mode, update rotation based on floor
	function UpdateRotation(float DeltaTime, float maxPitch)
	{
        local rotator ViewRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, OldX, RealFloor;

		if ( bInterpolating || Pawn.bInterpolating )
		{
			ViewShake(deltaTime);
			return;
		}

		TurnTarget = None;
		bRotateToDesired = false;
		bSetTurnRot = false;

		if ( (Pawn.Base == None) || (Pawn.Floor == vect(0,0,0)) )
			MyFloor = vect(0,0,1);
		else
			MyFloor = Pawn.Floor;

		if ( MyFloor != OldFloor )
		{
			// smoothly change floor
			RealFloor = MyFloor;
			MyFloor = Normal(6*DeltaTime * MyFloor + (1 - 6*DeltaTime) * OldFloor);
			if ( (RealFloor Dot MyFloor) > 0.999 )
				MyFloor = RealFloor;

			// translate view direction
			CrossDir = Normal(RealFloor Cross OldFloor);
			FwdDir = CrossDir Cross MyFloor;
			OldFwdDir = CrossDir Cross OldFloor;
			ViewX = MyFloor * (OldFloor Dot ViewX)
						+ CrossDir * (CrossDir Dot ViewX)
						+ FwdDir * (OldFwdDir Dot ViewX);
			ViewX = Normal(ViewX);

			ViewZ = MyFloor * (OldFloor Dot ViewZ)
						+ CrossDir * (CrossDir Dot ViewZ)
						+ FwdDir * (OldFwdDir Dot ViewZ);
			ViewZ = Normal(ViewZ);
			OldFloor = MyFloor;
			ViewY = Normal(MyFloor Cross ViewX);
		}

		if ( (aTurn != 0) || (aLookUp != 0) )
		{
			// adjust Yaw based on aTurn
			if ( aTurn != 0 )
				ViewX = Normal(ViewX + 2 * ViewY * Sin(0.0005*DeltaTime*aTurn));

			// adjust Pitch based on aLookUp
			if ( aLookUp != 0 )
			{
				OldX = ViewX;
				ViewX = Normal(ViewX + 2 * ViewZ * Sin(0.0005*DeltaTime*aLookUp));
				ViewZ = Normal(ViewX Cross ViewY);

				// bound max pitch
				if ( (ViewZ Dot MyFloor) < 0.707   )
				{
					OldX = Normal(OldX - MyFloor * (MyFloor Dot OldX));
					if ( (ViewX Dot MyFloor) > 0)
						ViewX = Normal(OldX + MyFloor);
					else
						ViewX = Normal(OldX - MyFloor);

					ViewZ = Normal(ViewX Cross ViewY);
				}
			}

			// calculate new Y axis
			ViewY = Normal(MyFloor Cross ViewX);
		}
		ViewRotation =  OrthoRotation(ViewX,ViewY,ViewZ);
		SetRotation(ViewRotation);
		ViewShake(deltaTime);
		ViewFlash(deltaTime);
		Pawn.FaceRotation(ViewRotation);
	}

	function bool NotifyLanded(vector HitNormal)
	{
		Pawn.SetPhysics(PHYS_Spider);
		return bUpdating;
	}

	function bool NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
	{
		if ( NewVolume.bWaterVolume )
			GotoState(Pawn.WaterMovementState);
		return false;
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local vector OldAccel;

		OldAccel = Pawn.Acceleration;
		Pawn.Acceleration = NewAccel;

		if ( bPressedJump )
			Pawn.DoJump(bUpdating);
	}

	function PlayerMove( float DeltaTime )
	{
		local vector NewAccel;
		local eDoubleClickDir DoubleClickMove;
		local rotator OldRotation, ViewRotation;
		local bool	bSaveJump;

		GroundPitch = 0;
		ViewRotation = Rotation;

		if ( !bKeyboardLook && (bLook == 0) && bCenterView )
		{
			// FIXME - center view rotation based on current floor
		}
		Pawn.CheckBob(DeltaTime,vect(0,0,0));

		// Update rotation.
		SetRotation(ViewRotation);
		OldRotation = Rotation;
		UpdateRotation(DeltaTime, 1);

		// Update acceleration.
		NewAccel = aForward*Normal(ViewX - OldFloor * (OldFloor Dot ViewX)) + aStrafe*ViewY;
		if ( VSize(NewAccel) < 1.0 )
			NewAccel = vect(0,0,0);

		if ( bPressedJump && Pawn.CannotJumpNow() )
		{
			bSaveJump = true;
			bPressedJump = false;
		}
		else
			bSaveJump = false;

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
		else
			ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
		bPressedJump = bSaveJump;
	}

	function BeginState()
	{
		if ( Pawn.Mesh == None )
			Pawn.SetMesh();
		OldFloor = vect(0,0,1);
		GetAxes(Rotation,ViewX,ViewY,ViewZ);
		DoubleClickDir = DCLICK_None;
		Pawn.ShouldCrouch(false);
		bPressedJump = false;
		if (Pawn.Physics != PHYS_Falling)
			Pawn.SetPhysics(PHYS_Spider);
		GroundPitch = 0;
		Pawn.bCrawler = true;
		Pawn.SetCollisionSize(Pawn.Default.CollisionHeight,Pawn.Default.CollisionHeight);
	}

	function EndState()
	{
		GroundPitch = 0;
		if ( Pawn != None )
		{
			Pawn.SetCollisionSize(Pawn.Default.CollisionRadius,Pawn.Default.CollisionHeight);
			Pawn.ShouldCrouch(false);
			Pawn.bCrawler = Pawn.Default.bCrawler;
		}
	}
}

// Player movement.
// Player Swimming
state PlayerSwimming
{
ignores SeePlayer, HearNoise, Bump;

	function bool WantsSmoothedView()
	{
		return ( !Pawn.bJustLanded );
	}

	function bool NotifyLanded(vector HitNormal)
	{
		if ( Pawn.PhysicsVolume.bWaterVolume )
			Pawn.SetPhysics(PHYS_Swimming);
		else
			GotoState(Pawn.LandMovementState);
		return bUpdating;
	}

	function bool NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
	{
		local actor HitActor;
		local vector HitLocation, HitNormal, checkpoint;

		if ( !NewVolume.bWaterVolume )
		{
			Pawn.SetPhysics(PHYS_Falling);
            if ( Pawn.Velocity.Z > 0 )
            {
			    if (Pawn.bUpAndOut && Pawn.CheckWaterJump(HitNormal)) //check for waterjump
			    {
				    Pawn.velocity.Z = FMax(Pawn.JumpZ,420) + 2 * Pawn.CollisionRadius; //set here so physics uses this for remainder of tick
				    GotoState(Pawn.LandMovementState);
			    }
			    else if ( (Pawn.Velocity.Z > 160) || !Pawn.TouchingWaterVolume() )
				    GotoState(Pawn.LandMovementState);
			    else //check if in deep water
			    {
				    checkpoint = Pawn.Location;
				    checkpoint.Z -= (Pawn.CollisionHeight + 6.0);
				    HitActor = Trace(HitLocation, HitNormal, checkpoint, Pawn.Location, false);
				    if (HitActor != None)
					    GotoState(Pawn.LandMovementState);
				    else
				    {
					    Enable('Timer');
					    SetTimer(0.7,false);
				    }
			    }
		    }
        }
		else
		{
			Disable('Timer');
			Pawn.SetPhysics(PHYS_Swimming);
		}
		return false;
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		local vector X,Y,Z, OldAccel;

		GetAxes(Rotation,X,Y,Z);
		OldAccel = Pawn.Acceleration;
		Pawn.Acceleration = NewAccel;
		Pawn.bUpAndOut = ((X Dot Pawn.Acceleration) > 0) && ((Pawn.Acceleration.Z > 0) || (Rotation.Pitch > 2048));
		if ( !Pawn.PhysicsVolume.bWaterVolume ) //check for waterjump
			NotifyPhysicsVolumeChange(Pawn.PhysicsVolume);
	}

	function PlayerMove(float DeltaTime)
	{
		local rotator oldRotation;
		local vector X,Y,Z, NewAccel;

		GetAxes(Rotation,X,Y,Z);

		NewAccel = aForward*X + aStrafe*Y + aUp*vect(0,0,1);
		if ( VSize(NewAccel) < 1.0 )
			NewAccel = vect(0,0,0);

		//add bobbing when swimming
		Pawn.CheckBob(DeltaTime, Y);

		// Update rotation.
		oldRotation = Rotation;
		UpdateRotation(DeltaTime, 2);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, NewAccel, DCLICK_None, OldRotation - Rotation);
		else
			ProcessMove(DeltaTime, NewAccel, DCLICK_None, OldRotation - Rotation);
		bPressedJump = false;
	}

	function Timer()
	{
		if ( !Pawn.PhysicsVolume.bWaterVolume && (Role == ROLE_Authority) )
			GotoState(Pawn.LandMovementState);

		Disable('Timer');
	}

	function BeginState()
	{
		Disable('Timer');
		Pawn.SetPhysics(PHYS_Swimming);
	}
}

state PlayerFlying
{
ignores SeePlayer, HearNoise, Bump;

	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;

		GetAxes(Rotation,X,Y,Z);

		Pawn.Acceleration = aForward*X + aStrafe*Y;
		if ( VSize(Pawn.Acceleration) < 1.0 )
			Pawn.Acceleration = vect(0,0,0);
		if ( bCheatFlying && (Pawn.Acceleration == vect(0,0,0)) )
			Pawn.Velocity = vect(0,0,0);
		// Update rotation.
		UpdateRotation(DeltaTime, 2);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
	}

	function BeginState()
	{
		Pawn.SetPhysics(PHYS_Flying);
	}
}

function bool IsSpectating()
{
	return false;
}

state BaseSpectating
{
	function bool IsSpectating()
	{
		return true;
	}

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		Acceleration = NewAccel;
        MoveSmooth(SpectateSpeed * Normal(Acceleration) * DeltaTime);
	}

	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;

		if ( (Pawn(ViewTarget) != None) && (Level.NetMode == NM_Client) )
		{
			if ( Pawn(ViewTarget).bSimulateGravity )
				TargetViewRotation.Roll = 0;
			BlendedTargetViewRotation.Pitch = BlendRot(DeltaTime, BlendedTargetViewRotation.Pitch, TargetViewRotation.Pitch & 65535);
			BlendedTargetViewRotation.Yaw = BlendRot(DeltaTime, BlendedTargetViewRotation.Yaw, TargetViewRotation.Yaw & 65535);
			BlendedTargetViewRotation.Roll = BlendRot(DeltaTime, BlendedTargetViewRotation.Roll, TargetViewRotation.Roll & 65535);
		}
		GetAxes(Rotation,X,Y,Z);

		Acceleration = 0.02 * (aForward*X + aStrafe*Y + aUp*vect(0,0,1));

		UpdateRotation(DeltaTime, 1);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
	}
}

state Scripting
{
	// FIXME - IF HIT FIRE, AND NOT bInterpolating, Leave script
	exec function Fire()
	{
	}

	exec function AltFire( optional float F )
	{
		Fire();
	}
}

function ServerViewNextPlayer()
{
    local Controller C, Pick;
    local bool bFound, bRealSpec, bWasSpec;
	local TeamInfo RealTeam;

    bRealSpec = PlayerReplicationInfo.bOnlySpectator;
    bWasSpec = !bBehindView && (ViewTarget != Pawn) && (ViewTarget != self);
    PlayerReplicationInfo.bOnlySpectator = true;
    RealTeam = PlayerReplicationInfo.Team;

	// view next player
	for ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
        if ( Level.Game.CanSpectate(self,true,C) )
		{
			if ( Pick == None )
                Pick = C;
			if ( bFound )
			{
                Pick = C;
				break;
			}
			else
                bFound = ( (RealViewTarget == C) || (ViewTarget == C) );
		}
	}
    PlayerReplicationInfo.Team = RealTeam;
	SetViewTarget(Pick);
    ClientSetViewTarget(Pick);
    if ( (ViewTarget == self) || bWasSpec )
		bBehindView = false;
	else
		bBehindView = true; //bChaseCam;
    ClientSetBehindView(bBehindView);
    PlayerReplicationInfo.bOnlySpectator = bRealSpec;
}

function ServerViewSelf()
{
	bBehindView = false;
    SetViewTarget(self);
    ClientSetViewTarget(self);
	ClientMessage(OwnCamera, 'DebugMessage');
}

function LoadPlayers()
{
	local int i;

	if ( GameReplicationInfo == None )
		return;

	for ( i=0; i<GameReplicationInfo.PRIArray.Length; i++ )
		GameReplicationInfo.PRIArray[i].UpdatePrecacheRenderData();
}

state Spectating extends BaseSpectating
{
    //TMC removed , SwitchWeapon, ThrowWeapon
	ignores RestartLevel, ClientRestart, Suicide, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange;

	exec function Fire()
	{
		ServerViewNextPlayer();
	}

	// Return to spectator's own camera.
	exec function AltFire( optional float F )
	{
		bBehindView = false;
		ServerViewSelf();
	}

	function BeginState()
	{
		if ( Pawn != None )
		{
			SetLocation(Pawn.Location);
			UnPossess();
		}
		bCollideWorld = true;
	}

	function EndState()
	{
		PlayerReplicationInfo.bIsSpectator = false;
		bCollideWorld = false;
	}
}

auto state PlayerWaiting extends BaseSpectating
{
#if IG_SHARED  //tcohen: hooked TakeDamage(), used by effects system and reactive world objects
//TMC removed , NextWeapon, PrevWeapon, SwitchToBestWeapon;
ignores SeePlayer, HearNoise, NotifyBump, PostTakeDamage, PhysicsVolumeChange;
#else
//TMC removed , NextWeapon, PrevWeapon, SwitchToBestWeapon;
ignores SeePlayer, HearNoise, NotifyBump, TakeDamage, PhysicsVolumeChange;
#endif

	exec function Jump( optional float F )
	{
	}

	exec function Suicide()
	{
	}

	function ChangeTeam( int N )
	{
        Level.Game.ChangeTeam(self, N, true);
	}

    function ServerRestartPlayer()
	{
		if ( Level.TimeSeconds < WaitDelay )
			return;
		if ( Level.NetMode == NM_Client )
			return;
		if ( Level.Game.bWaitingToStartMatch )
			PlayerReplicationInfo.bReadyToPlay = true;
		else
			Level.Game.RestartPlayer(self);
	}

	exec function Fire()
	{
        LoadPlayers();
		ServerReStartPlayer();
	}

	exec function AltFire(optional float F)
	{
        Fire();
	}

	function EndState()
	{
		if ( Pawn != None )
			Pawn.SetMesh();
        if ( PlayerReplicationInfo != None )
			PlayerReplicationInfo.SetWaitingPlayer(false);
		bCollideWorld = false;
	}

	function BeginState()
	{
		if ( PlayerReplicationInfo != None )
			PlayerReplicationInfo.SetWaitingPlayer(true);
		bCollideWorld = true;
	}
}

state WaitingForPawn extends BaseSpectating
{
//TMC removed , SwitchWeapon;
ignores SeePlayer, HearNoise, KilledBy;

	exec function Fire()
	{
        //mplog( self$" calling Fire() in state WaitingForPawn." );
		AskForPawn();
	}

	exec function AltFire( optional float F )
	{
	}

	function LongClientAdjustPosition
	(
		float TimeStamp,
		name newState,
		EPhysics newPhysics,
		float NewLocX,
		float NewLocY,
		float NewLocZ,
		float NewVelX,
		float NewVelY,
		float NewVelZ,
		Actor NewBase,
		float NewFloorX,
		float NewFloorY,
		float NewFloorZ
	)
	{
		if ( newState == 'GameEnded' )
			GotoState(newState);
	}

	function PlayerTick(float DeltaTime)
	{
		Global.PlayerTick(DeltaTime);

		if ( Pawn != None )
		{
            //mplog( self$" in PlayerTick() of state WaitingForPawn. Calling ClientRestart()." );
			Pawn.Controller = self;
            Pawn.bUpdateEyeHeight = true;
			ClientRestart();
		}
        else if ( (TimerRate <= 0.0) || (TimerRate > 1.0) )
		{
			SetTimer(0.2,true);
			AskForPawn();
		}
	}

	function Timer()
	{
		AskForPawn();
	}

	function BeginState()
	{
        //mplog( self$" entering state WaitingForPawn." );
		SetTimer(0.2, true);
        AskForPawn();
	}

	function EndState()
	{
        //mplog( self$" leaving state WaitingForPawn." );
		bBehindView = false;
		SetTimer(0.0, false);
	}
}

state GameEnded
{
#if IG_SHARED  //tcohen: hooked TakeDamage(), used by effects system and reactive world objects
ignores SeePlayer, HearNoise, KilledBy, NotifyBump, HitWall, NotifyHeadVolumeChange, NotifyPhysicsVolumeChange, Falling, PostTakeDamage, Suicide;
#else
ignores SeePlayer, HearNoise, KilledBy, NotifyBump, HitWall, NotifyHeadVolumeChange, NotifyPhysicsVolumeChange, Falling, TakeDamage, Suicide;
#endif

	function ServerReStartPlayer()
	{
	}

	function bool IsSpectating()
	{
		return true;
	}

	function ServerReStartGame()
	{
		Level.Game.RestartGame();
	}

	exec function Fire()
	{
		if ( Role < ROLE_Authority)
			return;
		if ( !bFrozen )
			ServerReStartGame();
		else if ( TimerRate <= 0 )
			SetTimer(1.5, false);
	}

	exec function AltFire( optional float F )
	{
		Fire();
	}

	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;
		local Rotator ViewRotation;

		GetAxes(Rotation,X,Y,Z);
		// Update view rotation.

		if ( !bFixedCamera )
		{
			ViewRotation = Rotation;
			ViewRotation.Yaw += 32.0 * DeltaTime * aTurn;
			ViewRotation.Pitch += 32.0 * DeltaTime * aLookUp;
			ViewRotation.Pitch = ViewRotation.Pitch & 65535;
			If ((ViewRotation.Pitch > 18000) && (ViewRotation.Pitch < 49152))
			{
				If (aLookUp > 0)
					ViewRotation.Pitch = 18000;
				else
					ViewRotation.Pitch = 49152;
			}
			SetRotation(ViewRotation);
		}
		else if ( ViewTarget != None )
			SetRotation(ViewTarget.Rotation);

		ViewShake(DeltaTime);
		ViewFlash(DeltaTime);

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, vect(0,0,0), DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, vect(0,0,0), DCLICK_None, rot(0,0,0));
		bPressedJump = false;
	}

	function ServerMove
	(
		float TimeStamp,
		vector InAccel,
		vector ClientLoc,
		bool NewbRun,
		bool NewbDuck,
		bool NewbJumpStatus,
        bool NewbDoubleJump,
#if IG_SWAT
        bool NewbLeanLeft,
        bool NewbLeanRight,
#endif
		eDoubleClickDir DoubleClickMove,
		byte ClientRoll,
		int View,
		optional byte OldTimeDelta,
		optional int OldAccel
	)
	{
        Global.ServerMove(TimeStamp, InAccel, ClientLoc, NewbRun, NewbDuck, NewbJumpStatus,NewbDoubleJump,
#if IG_SWAT
                            NewbLeanLeft, NewbLeanRight,
#endif
							DoubleClickMove, ClientRoll, (32767 & (Rotation.Pitch/2)) * 32768 + (32767 & (Rotation.Yaw/2)) );

	}

	function Timer()
	{
		bFrozen = false;
	}

	function LongClientAdjustPosition
	(
		float TimeStamp,
		name newState,
		EPhysics newPhysics,
		float NewLocX,
		float NewLocY,
		float NewLocZ,
		float NewVelX,
		float NewVelY,
		float NewVelZ,
		Actor NewBase,
		float NewFloorX,
		float NewFloorY,
		float NewFloorZ
	)
	{
	}

	function BeginState()
	{
		local Pawn P;

#if IG_SWAT
		SetZoom(false, true);	//unzoom instantly
#else
		EndZoom();
        FOVAngle = DesiredFOV;
#endif
		bFire = 0;
		bAltFire = 0;
		bVoiceTalk = 0;
		if ( Pawn != None )
		{
			Pawn.Velocity = vect(0,0,0);
			Pawn.SetPhysics(PHYS_None);
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
			Pawn.AmbientSound = None;
#endif
			Pawn.bSpecialHUD = false;
#if !IG_SWAT // don't replicate the AnimRate in Swat (it's always 1.0)
			Pawn.SimAnim.AnimRate = 0;
#endif
#if !IG_SWAT // we dont want to stop animations after the game has ended because we want to play out any currently running equipment animations
			Pawn.bPhysicsAnimUpdate = false;
			Pawn.StopAnimating();
#endif
            Pawn.SetCollision(true,false,false);
            StopFiring();
 			Pawn.bIgnoreForces = true;
		}
		myHUD.bShowScores = true;
		bFrozen = true;
		if ( !bFixedCamera )
		{
			FindGoodView();
			bBehindView = true;
		}
        SetTimer(5, false);
		ForEach DynamicActors(class'Pawn', P)
		{
			if ( P.Role == ROLE_Authority )
				P.RemoteRole = ROLE_DumbProxy;
			P.SetCollision(true,false,false);
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
			P.AmbientSound = None;
#endif
			P.Velocity = vect(0,0,0);
			P.SetPhysics(PHYS_None);
#if !IG_SWAT // we dont want to stop animations after the game has ended because we want to play out any currently running equipment animations
            P.bPhysicsAnimUpdate = false;
            P.StopAnimating();
#endif
            P.bIgnoreForces = true;
		}
	}

Begin:
}

state Dead
{
//TMC removed , SwitchWeapon, NextWeapon, PrevWeapon;
ignores SeePlayer, HearNoise, KilledBy;

	function bool IsDead()
	{
		return true;
	}

	function ServerReStartPlayer()
	{
		Super.ServerRestartPlayer();
	}

	exec function Fire()
	{
		if ( bFrozen )
		{
			if ( (TimerRate <= 0.0) || (TimerRate > 1.0) )
				bFrozen = false;
			return;
		}
        LoadPlayers();
		ServerReStartPlayer();
	}

	exec function AltFire( optional float F )
	{
			Fire();
	}

	function ServerMove
	(
		float TimeStamp,
		vector Accel,
		vector ClientLoc,
		bool NewbRun,
		bool NewbDuck,
		bool NewbJumpStatus,
        bool NewbDoubleJump,
#if IG_SWAT
        bool NewbLeanLeft,
        bool NewbLeanRight,
#endif
		eDoubleClickDir DoubleClickMove,
		byte ClientRoll,
		int View,
		optional byte OldTimeDelta,
		optional int OldAccel
	)
	{
		Global.ServerMove(
					TimeStamp,
					Accel,
					ClientLoc,
					false,
					false,
					false,
                    false,
#if IG_SWAT
                    false,
                    false,
#endif
					DoubleClickMove,
					ClientRoll,
					View);
	}

	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;
		local rotator ViewRotation;

		if ( !bFrozen )
		{
			if ( bPressedJump )
			{
				Fire();
				bPressedJump = false;
			}
			GetAxes(Rotation,X,Y,Z);
			// Update view rotation.
			ViewRotation = Rotation;
			ViewRotation.Yaw += 32.0 * DeltaTime * aTurn;
			ViewRotation.Pitch += 32.0 * DeltaTime * aLookUp;
			ViewRotation.Pitch = ViewRotation.Pitch & 65535;
			If ((ViewRotation.Pitch > 18000) && (ViewRotation.Pitch < 49152))
			{
				If (aLookUp > 0)
					ViewRotation.Pitch = 18000;
				else
					ViewRotation.Pitch = 49152;
			}
			SetRotation(ViewRotation);
			if ( Role < ROLE_Authority ) // then save this move and replicate it
				ReplicateMove(DeltaTime, vect(0,0,0), DCLICK_None, rot(0,0,0));
		}
        else if ( (TimerRate <= 0.0) || (TimerRate > 1.0) )
			bFrozen = false;

		ViewShake(DeltaTime);
		ViewFlash(DeltaTime);
	}

	function Timer()
	{
		if (!bFrozen)
			return;

		bFrozen = false;
		bPressedJump = false;
	}

	function BeginState()
	{
		if ( (Pawn != None) && (Pawn.Controller == self) )
			Pawn.Controller = None;
#if IG_SWAT
		SetZoom(false, true);	//unzoom instantly
#else
		EndZoom();
		FOVAngle = DesiredFOV;
#endif
		Pawn = None;
		Enemy = None;
		bBehindView = true;
		bFrozen = true;
		bJumpStatus = false;
		bPressedJump = false;
        bBlockCloseCamera = true;
		bValidBehindCamera = false;
		FindGoodView();
        SetTimer(1.0, false);
		StopForceFeedback();
		ClientPlayForceFeedback("Damage");  // jdf
		CleanOutSavedMoves();
	}

	function EndState()
	{
		bBlockCloseCamera = false;
		CleanOutSavedMoves();
		Velocity = vect(0,0,0);
		Acceleration = vect(0,0,0);
        if ( !PlayerReplicationInfo.bOutOfLives )
			bBehindView = false;
		bPressedJump = false;
		myHUD.bShowScores = false;
}
Begin:
    Sleep(3.0);
    myHUD.bShowScores = true;
}

// Finds a good third person viewing angle
function FindGoodView()
{
	local vector cameraLoc;
	local rotator cameraRot, ViewRotation;
	local int tries, besttry;
	local float bestdist, newdist;
	local int startYaw;
	local actor ViewActor;

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

#if IG_SWAT // marc: added so these CommandInterface functions can be called from AICommon
simulated function ClearHeldCommand(Actor Team);
simulated function ClearHeldCommandCaptions(Actor Team);
#endif

//------------------------------------------------------------------------------
// Control options
function ChangeStairLook( bool B )
{
	bLookUpStairs = B;
	if ( bLookUpStairs )
		bAlwaysMouseLook = false;
}

function ChangeAlwaysMouseLook(Bool B)
{
	bAlwaysMouseLook = B;
	if ( bAlwaysMouseLook )
		bLookUpStairs = false;
}

// Replace with good code
event ClientOpenMenu (string MenuClass, optional string MenuName, optional bool bDisconnect,optional string Msg1, optional string Msg2, optional int Msg3)
{
	Player.GUIController.OpenMenu(MenuClass, MenuName, Msg1, Msg2, Msg3);
	if (bDisconnect)
		ConsoleCommand("Disconnect");
}

event ClientCloseMenu(optional bool bCloseAll)
{
	if (bCloseAll)
		Player.GUIController.CloseAll();
	else
		Player.GUIController.CloseMenu();
}

function bool CanRestartPlayer()
{
    return !PlayerReplicationInfo.bOnlySpectator;
}

event ServerChangeVoiceChatter( PlayerController Player, int IpAddr, int Handle, bool Add )
{
	if( (Level.NetMode == NM_DedicatedServer) || (Level.NetMode == NM_ListenServer) )
	{
		Level.Game.ChangeVoiceChatter( Player, IpAddr, Handle, Add );
	}
}

event ServerGetVoiceChatters( PlayerController Player )
{
	local int i;

	if( (Level.NetMode == NM_DedicatedServer) || (Level.NetMode == NM_ListenServer) )
	{
		for( i=0; i<Level.Game.VoiceChatters.Length; i++ )
		{
			if( Player != Level.Game.VoiceChatters[i].Controller )
			{
				Player.ClientChangeVoiceChatter( Level.Game.VoiceChatters[i].IpAddr, Level.Game.VoiceChatters[i].Handle, true );
			}
		}
	}
}

simulated function ClientChangeVoiceChatter( int IpAddr, int Handle, bool Add )
{
	ChangeVoiceChatter( IpAddr, Handle, Add );
}

simulated function ClientLeaveVoiceChat()
{
	LeaveVoiceChat();
}

native final function LeaveVoiceChat();
native final function ChangeVoiceChatter( int IpAddr, int Handle, bool Add );

//--------------------- Demo recording stuff

// Called on the client during client-side demo recording
simulated event StartClientDemoRec()
{
	// Here we replicate functions which the demo never saw.
	DemoClientSetHUD( MyHud.Class, MyHud.ScoreBoard.Class );

	// tell server to replicate more stuff to me
	bClientDemo = true;
	ServerSetClientDemo();
}

function ServerSetClientDemo()
{
	bClientDemo = true;
}

// Called on the playback client during client-side demo playback
simulated function DemoClientSetHUD(class<HUD> newHUDClass, class<Scoreboard> newScoringClass )
{
	if( MyHUD == None )
		ClientSetHUD( newHUDClass, newScoringClass );
}

#if IG_UDN_UTRACE_DEBUGGING // ckline: UDN UTrace code
function ServerUTrace()
{
	if( Level.NetMode != NM_Standalone /*&& AdminManager == None*/ )
		return;

	UTrace();
}
exec function UTrace()
{
	// If they're running with "-log", be sure to turn it off
	ConsoleCommand("HideLog");
	if( Role!=ROLE_Authority ) {
		ServerUTrace();
	}
	SetUTracing( !IsUTracing() );
	log("UTracing changed to "$IsUTracing()$" at "$Level.TimeSeconds);
}
#endif // IG_UDN_UTRACE_DEBUGGING

#if IG_SWAT
//tcohen: stubs for accuracy & recoil
native simulated event float GetLookAroundSpeed(); // MUST be overridden in derived class
function AddRecoil(float RecoilBackTime, float RecoilForeTime, float RecoilMagnitude, optional float AutoFireRecoilMagnitudeIncrement, optional int AutoFireShotIndex);

// Used for getting the PlayerID needed to match back up with RepoItem after
// reconnecting. Override in SwatGamePlayerController.
function int GetSwatPlayerID()
{
    assert( false );
    return 0;
}

//tcohen: stub for idling hands
function bool HandsShouldIdle() { assert(false); return false; }

//tcohen: stub for modifying input
function InputOffset(out float aForward, out float aStrafe);

//tcohen: moved up from SwatGamePlayerController so that RWOs can access
function OnMissionExitDoorUsed()
{
    Player.GUIController.OpenMenu( "SwatGui.SwatMissionAbortMenu", "SwatMissionAbortMenu" );
}

#endif

#if IG_SWAT //dkaplan made input bytes toggled through exec functions

exec function ToggleRunning( bool bRelease )
{
    if( bRelease && bIgnoreNextRunRelease )
        return;

    bIgnoreNextRunRelease = false;

    if( bRun == 0 )
        bRun = 1;
    else
        bRun = 0;
}

exec function ToggleCrouching( bool bRelease )
{
    if( bRelease && bIgnoreNextCrouchRelease )
        return;

    bIgnoreNextCrouchRelease = false;

    if( bDuck == 0 )
        bDuck = 1;
    else
        bDuck = 0;
}

#endif

#if IG_SWAT //dkaplan: console suppression of FNames
exec function Suppress( string NameToSuppress )
{
    SuppressName( name(NameToSuppress) );
}

native function SuppressName( Name NameToSuppress );
#endif

function bool GetIronsightsDisabled()
{
	assert(false); // must be implemented by subclass
	return false;
}

function bool GetViewmodelDisabled()
{
	assert(false); // must be implemented by subclass
	return false;
}

function bool GetCrosshairDisabled()
{
	assert(false);
	return false;
}

function bool GetInertiaDisabled()
{
	assert(false);
	return false;
}

// =====================================================================================================================
// =====================================================================================================================
//  Voice Chat
// Note: Marc VOIP: replicate these function if you comment them in!
// =====================================================================================================================
// =====================================================================================================================
/*
// Join a voice chatroom by name
exec function Join(string ChanName, string ChanPwd)
{
	local int i, idx;
	local VoiceChatRoom VCR;

	if (VoiceReplicationInfo == None || !VoiceReplicationInfo.bEnableVoiceChat )
		return;

	for (i = 0; i < StoredChatPasswords.Length; i++)
	{
		if (ChanName ~= StoredChatPasswords[i].ChatRoomName)
		{
			if ( ChanPwd == "" )
				ChanPwd = StoredChatPasswords[i].ChatRoomPassword;

			else
			{
				StoredChatPasswords[i].ChatRoomPassword = ChanPwd;
				SaveConfig();
			}

			break;
		}
	}

	if ( i == StoredChatPasswords.Length && ChanPwd != "" )
	{
		StoredChatPasswords.Length = i + 1;
		StoredChatPasswords[i].ChatRoomName = ChanName;
		StoredChatPasswords[i].ChatRoomPassword = ChanPwd;
		SaveConfig();
	}

	log("Join "$ChanName@"Password:"$ChanPwd@"PRI:"$PlayerReplicationInfo.PlayerName@"Team:"$PlayerReplicationInfo.Team,'VoiceChat');
	if (PlayerReplicationInfo != None && PlayerReplicationInfo.Team != None)
		idx = PlayerReplicationInfo.Team.TeamIndex;

	VCR = VoiceReplicationInfo.GetChannel(ChanName, idx);
	if (VCR != None)
	{
		if (!VCR.IsMember(PlayerReplicationInfo))
			ServerJoinVoiceChannel(VCR.ChannelIndex, ChanPwd);
	}
	else if ( ChatRoomMessageClass != None )
		ClientMessage(ChatRoomMessageClass.static.AssembleMessage(0,ChanName));
}*/
/*
// Leave a voice chatroom by name
exec function Leave(string ChannelTitle)
{
	local VoiceChatRoom VCR;
	local int idx;

	if (VoiceReplicationInfo == None || !VoiceReplicationInfo.bEnableVoiceChat )
		return;

	if (PlayerReplicationInfo != None && PlayerReplicationInfo.Team != None)
		idx = PlayerReplicationInfo.Team.TeamIndex;

	VCR = VoiceReplicationInfo.GetChannel(ChannelTitle, idx);
	if (VCR == None && ChatRoomMessageClass != None)
	{
		ClientMessage(ChatRoomMessageClass.static.AssembleMessage(0,ChannelTitle));
		return;
	}

	if ( VCR == ActiveRoom )
		ActiveRoom = None;

	ServerLeaveVoiceChannel(VCR.ChannelIndex);
}*/
/*
// Set a voice chatroom to your active channel
exec function Speak(string ChannelTitle)
{
	local int idx;
	local VoiceChatRoom VCR;
	local string ChanPwd;

	if (VoiceReplicationInfo == None || !VoiceReplicationInfo.bEnableVoiceChat )
		return;

	if (PlayerReplicationInfo != None && PlayerReplicationInfo.Team != None)
		idx = PlayerReplicationInfo.Team.TeamIndex;

	// Check that we are a member of this room
	VCR = VoiceReplicationInfo.GetChannel(ChannelTitle, idx);
	if (VCR == None && ChatRoomMessageClass != None)
	{
		ClientMessage(ChatRoomMessageClass.static.AssembleMessage(0,ChannelTitle));
		return;
	}

	if (VCR.ChannelIndex >= 0)
	{
		ChanPwd = FindChannelPassword(ChannelTitle);
		ServerSpeak(VCR.ChannelIndex, ChanPwd);
	}

	else if ( ChatRoomMessageClass != None )
		ClientMessage(ChatRoomMessageClass.static.AssembleMessage(0,ChannelTitle));
}*/
/*
// Set your active channel to the default channel
exec function SpeakDefault()
{
	local string str;

	str = GetDefaultActiveChannel();
	if ( str != "" && (ActiveRoom == None || !(ActiveRoom.GetTitle() ~= str)) )
		Speak(str);
}*/
/*
// Set your active channel to the last active channel
exec function SpeakLast()
{
	if ( LastActiveChannel != "" && (ActiveRoom == None || !(ActiveRoom.GetTitle() ~= LastActiveChannel)) )
		Speak(LastActiveChannel);
}*/
/*
// Change the password for you personal chatroom
exec function SetChatPassword(string NewPassword)
{
	if (ChatPassword != NewPassword)
	{
		ChatPassword = NewPassword;
		SaveConfig();

		ServerSetChatPassword(NewPassword);
	}
}*/

exec function EnableVoiceChat()
{
	//local bool bCurrent;

	//bCurrent = bool(ConsoleCommand("get ini:Engine.Engine.AudioDevice UseVoIP"));
	//ConsoleCommand("set ini:Engine.Engine.AudioDevice UseVoIP"@True);

	if ( VoiceReplicationInfo == None )
		return;

	if ( !VoiceReplicationInfo.bEnableVoiceChat )
	{
///		ChatRoomMessage(15, -1);
		return;
	}

	ChangeVoiceChatMode( True );
	InitializeVoiceChat();

	// Marc VOIP: SOUND_REBOOT causes crash
	// TODO What else needs to be done before a sound reboot?
	///if (bCurrent == False)
	///	ConsoleCommand("SOUND_REBOOT");
}

exec function DisableVoiceChat()
{
	//local bool bCurrent;

	//bCurrent = bool(ConsoleCommand("get ini:Engine.Engine.AudioDevice UseVoIP"));
	//ConsoleCommand("set ini:Engine.Engine.AudioDevice UseVoIP"@False);

	if (VoiceReplicationInfo == None || !VoiceReplicationInfo.bEnableVoiceChat )
		return;

	ChangeVoiceChatMode( False );

	// Marc VOIP: SOUND_REBOOT causes crash
	// TODO What else needs to be done before a sound reboot?
	///if (bCurrent == True)
	///	ConsoleCommand("SOUND_REBOOT");
}

simulated function InitializeVoiceChat()
{
	if ( bVoiceChatEnabled )
	{
///		InitPrivateChatRoom();
///		AutoJoinVoiceChat();
	}
}
/*
function InitPrivateChatRoom()
{
	ServerChangeVoiceChatMode(True);
	if ( ChatPassword != "" )
		ServerSetChatPassword(ChatPassword);
}*/
/*
simulated function string GetDefaultActiveChannel()
{
	local string DefaultChannel;

	if ( DefaultActiveChannel != "" )
		DefaultChannel = DefaultActiveChannel;
	else if ( VoiceReplicationInfo != None )
		DefaultChannel = VoiceReplicationInfo.GetDefaultChannel();

	return DefaultChannel;
}*/

/*simulated function AutoJoinVoiceChat();*/
simulated function ChangeVoiceChatMode( bool bEnable )
{
	if (VoiceReplicationInfo == None)
		return;

	bVoiceChatEnabled = bEnable;

	if (Level.NetMode == NM_Client || Level.NetMode == NM_ListenServer)
		ServerChangeVoiceChatMode( bEnable );
}
/*
simulated function bool ChatBan(int PlayerID, byte Type)
{
	log("ChatBan Role:"$GetEnum(enum'ENetRole', Role)@"ChatManager:"$ChatManager@"PlayerID:"$PlayerID@"Type:"$Type,'ChatManager');
	if ( Level.NetMode == NM_StandAlone || Level.NetMode == NM_DedicatedServer )
		return false;

	if ( ChatManager == None )
		return false;

	if ( ChatManager.SetRestrictionID(PlayerID, Type) )
	{
		ServerChatRestriction(PlayerID, Type);
		return true;
	}

	log(Name@"ChatBan not successful - could not find player with ID:"@PlayerID,'ChatManager');
	return false;
}*/
/*
simulated function SetChannelPassword(string ChannelName, string ChannelPassword)
{
	local int i;

	if ( Level.NetMode == NM_DedicatedServer )
		return;

	for ( i = 0; i < StoredChatPasswords.Length; i++ )
	{
		if ( StoredChatPasswords[i].ChatRoomName ~= ChannelName )
			break;
	}

	if ( i == StoredChatPasswords.Length )
		StoredChatPasswords.Length = i + 1;

	StoredChatPasswords[i].ChatRoomName = ChannelName;
	StoredChatPasswords[i].ChatRoomPassword = ChannelPassword;
	SaveConfig();
}*/
/*
simulated function string FindChannelPassword(string ChannelName)
{
	local int i;

	for ( i = 0; i < StoredChatPasswords.Length; i++ )
		if ( StoredChatPasswords[i].ChatRoomName ~= ChannelName )
			return StoredChatPasswords[i].ChatRoomPassword;

	return "";
}*/
/*
function VoiceChatRoom.EJoinChatResult ServerJoinVoiceChannel(int ChannelIndex, optional string ChannelPassword)
{
	local VoiceChatRoom VCR;
	local VoiceChatRoom.EJoinChatResult Result;

	VCR = VoiceReplicationInfo.GetChannelAt(ChannelIndex);
	if (VoiceReplicationInfo == None || PlayerReplicationInfo == None || VCR == None || !VoiceReplicationInfo.bEnableVoiceChat)
		return JCR_Invalid;

	if ( VoiceReplicationInfo != None )
		Result = VoiceReplicationInfo.JoinChannelAt(ChannelIndex, PlayerReplicationInfo, ChannelPassword);

	// Take the appropriate action depending on the result received from the VoiceReplicationInfo
	switch ( Result )
	{
		case JCR_NeedPassword:  ClientOpenMenu(ChatPasswordMenuClass, false, VCR.GetTitle(), "NEEDPW");     break;
		case JCR_WrongPassword: ClientOpenMenu(ChatPasswordMenuClass, False, VCR.GetTitle(), "WRONGPW");	break;
		case JCR_Success:       Level.Game.ChangeVoiceChannel(PlayerReplicationInfo, ChannelIndex, -1);
		default:
			if ( ChannelIndex>VoiceReplicationInfo.GetPublicChannelCount(true) )
				ChatRoomMessage(Result, ChannelIndex);

	}

	return Result;
}*/
/*
function ServerLeaveVoiceChannel(int ChannelIndex)
{
	local VoiceChatRoom VCR;

	if (VoiceReplicationInfo == None || PlayerReplicationInfo == None)
		return;

	if ( !VoiceReplicationInfo.bEnableVoiceChat )
	{
		ChatRoomMessage(15, -1);
		return;
	}

	VCR = VoiceReplicationInfo.GetChannelAt(ChannelIndex);
	if (VCR != None && VCR.LeaveChannel(PlayerReplicationInfo))
	{
		if (VCR == ActiveRoom)
		{
			ActiveRoom = None;
			if ( PlayerReplicationInfo != None )
				PlayerReplicationInfo.ActiveChannel = -1;

// not necessary as client will do this itself
//			ClientSetActiveRoom(-1);
		}

		Level.Game.ChangeVoiceChannel( PlayerReplicationInfo, -1, ChannelIndex );
		if ( ChannelIndex>VoiceReplicationInfo.GetPublicChannelCount(true) )
			ChatRoomMessage(8, ChannelIndex);
	}
}

function ServerSpeak(int ChannelIndex, optional string ChannelPassword)
{
	local VoiceChatRoom VCR;
	local int Index;

	if (VoiceReplicationInfo == None)
		return;

	VCR = VoiceReplicationInfo.GetChannelAt(ChannelIndex);
	if ( VCR == None )
	{
		if ( VoiceReplicationInfo.bEnableVoiceChat )
			ChatRoomMessage(0, ChannelIndex);

		else ChatRoomMessage(15, ChannelIndex);
		return;
	}

	if ( !VCR.IsMember(PlayerReplicationInfo) )
	{
		if ( ServerJoinVoiceChannel(ChannelIndex, ChannelPassword) != JCR_Success )
			return;
	}

	Index = -1;
	if (ActiveRoom == VCR)
	{
		ChatRoomMessage(10, ChannelIndex);
		log(PlayerReplicationInfo.PlayerName@"no longer speaking on "$VCR.GetTitle(),'VoiceChat');
		ActiveRoom = None;
		ClientSetActiveRoom(-1);
	}
	else
	{
		ActiveRoom = VCR;
		log(PlayerReplicationInfo.PlayerName@"speaking on"@VCR.GetTitle(),'VoiceChat');
		ChatRoomMessage(9, ChannelIndex);
		ClientSetActiveRoom(VCR.ChannelIndex);
		Index = VCR.ChannelIndex;
	}

	if ( PlayerReplicationInfo != None )
		PlayerReplicationinfo.ActiveChannel = Index;
}*/
/*
function ServerSetChatPassword(string NewPassword)
{
	ChatPassword = NewPassword;

	if (PlayerReplicationInfo != None)
		PlayerReplicationInfo.SetChatPassword(NewPassword);
}*/

function ServerChangeVoiceChatMode( bool bEnable )
{
	if (VoiceReplicationInfo == None)
		return;

	bVoiceChatEnabled = bEnable;
	if ( bVoiceChatEnabled )
	{
		if ( VoiceReplicationInfo.bEnableVoiceChat )
			VoiceReplicationInfo.AddVoiceChatter(PlayerReplicationInfo);
///		else ChatRoomMessage(15, -1);
	}
	else VoiceReplicationInfo.RemoveVoiceChatter(PlayerReplicationInfo);
}
/*
simulated function ClientSetActiveRoom(int ChannelIndex)
{
	if ( VoiceReplicationInfo == None || !bVoiceChatEnabled )
		return;

	if ( ActiveRoom != None )
		LastActiveChannel = ActiveRoom.GetTitle();
	else LastActiveChannel = "";

	ActiveRoom = VoiceReplicationInfo.GetChannelAt(ChannelIndex);
}*/

simulated event bool VOIPIsIgnored(int PlayerID);

function ClientNotifyArmorTakeDamage(float NewMTP)
{
	local BodyArmor Armor;

	log("ClientNotifyArmorTakeDamage()");

	if(Pawn == None)
	{
		log("....Pawn was None");
		return;
	}

	Armor = BodyArmor(Pawn.GetSkeletalRegionProtection(REGION_Torso));
	if(Armor == None)
	{
		// How does this even happen?
		log("....Armor was None");
		return;
	}

	Armor.ClientNotifiedOfHit(NewMTP);
}

defaultproperties
{
	 AimingHelp=0.0
     OrthoZoom=+40000.000000
     FlashScale=(X=1.000000,Y=1.000000,Z=1.000000)
	 AnnouncerVolume=4
	 FOVAngle=85.000
//if IG_SWAT	//tcohen: weapon zoom
	 BaseFOV=85.000000
	 ZoomedFOV=85.000000
//else
//   DesiredFOV=85.000000
//	 DefaultFOV=85.000000
//endif
     bAlwaysMouseLook=True
	 OwnCamera="Now viewing from own camera"
     QuickSaveString="Quick Saving"
     NoPauseMessage="Game is not pauseable"
     bTravel=True
     bStasis=False
	 NetPriority=3
    MaxTimeMargin=+0.35
	 LocalMessageClass=class'LocalMessage'
	 bIsPlayer=true
	 bCanOpenDoors=true
	 bCanDoSpecial=true
	 Physics=PHYS_None
	 EnemyTurnSpeed=45000
	 CheatClass=class'Engine.CheatManager'
	 InputClass=class'Engine.PlayerInput'
	 CameraDist=+9.0
	 bZeroRoll=true
    bDynamicNetSpeed=true
    // jdf ---
    bEnableWeaponForceFeedback=True
    //bEnablePickupForceFeedback=True
    bEnableDamageForceFeedback=True
    bEnableGUIForceFeedback=True
    bForceFeedbackSupported=True
    // --- jdf
    ProgressTimeOut=8.0
    MaxResponseTime=0.7
    SpectateSpeed=+600.0
    DynamicPingThreshold=+400.0
    ClientCap=0
//#if IG_SWAT // ckline: can do extra flush after precaching to fix corruption after alt-tabbing back into fullscreen on some cards
   PostFullscreenManualFlushDelay=0
//#endif
//#if IG_SPEED_HACK_PROTECTION
   LastSpeedHackLog=-100.0
//#endif
}
