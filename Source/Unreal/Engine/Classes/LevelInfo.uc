//=============================================================================
// LevelInfo contains information about the current level. There should
// be one per level and it should be actor 0. UnrealEd creates each level's
// LevelInfo automatically so you should never have to place one
// manually.
//
// The ZoneInfo properties in the LevelInfo are used to define
// the properties of all zones which don't themselves have ZoneInfo.
//=============================================================================
class LevelInfo extends ZoneInfo
    dependsOn(Repo)
	native
	nativereplication;

#if IG_SWAT //dkaplan: some additional info we want to use in SWAT
import enum EMPMode from Repo;
#endif

//-----------------------------------------------------------------------------
// Level time.

// Time passage.
var() float TimeDilation;          // Normally 1 - scales real time passage.

// Current time.
var           float	TimeSeconds;   // Time in seconds since level began play.
var transient int   Year;          // Year.
var transient int   Month;         // Month.
var transient int   Day;           // Day of month.
var transient int   DayOfWeek;     // Day of week.
var transient int   Hour;          // Hour.
var transient int   Minute;        // Minute.
var transient int   Second;        // Second.
var transient int   Millisecond;   // Millisecond.
var			  float	PauseDelay;		// time at which to start pause

//-----------------------------------------------------------------------------
// Level Summary Info

var(LevelSummary) localized String 	Title;
var(LevelSummary)           String 	Author;
#if IG_SWAT //dkaplan we use different level summary info
var(LevelSummary)         Material Screenshot "Screenshot of the level to be displayed on the server setup menu";
var(LevelSummary) Localized string Description "Description of the level to be displayed on the server setup menu";
var(LevelSummary) array<EMPMode>   SupportedModes "Game modes supported by this map";
var(LevelSummary)			int		IdealPlayerCountMin		"Recommended minimum number of players for this level.";
var(LevelSummary)			int		IdealPlayerCountMax		"Recommended maximum number of players for this level.";
#else
var(LevelSummary)			int 	RecommendedNumPlayers;
#endif

var() config enum EPhysicsDetailLevel
{
	PDL_Low,
	PDL_Medium,
	PDL_High
} PhysicsDetailLevel;


// Karma - jag
var(Karma) float KarmaTimeScale;		// Karma physics timestep scaling.
var(Karma) float RagdollTimeScale;		// Ragdoll physics timestep scaling. This is applied on top of KarmaTimeScale.
var(Karma) int   MaxRagdolls;			// Maximum number of simultaneous rag-dolls.
var(Karma) float KarmaGravScale;		// Allows you to make ragdolls use lower friction than normal.
var(Karma) bool  bKStaticFriction;		// Better rag-doll/ground friction model, but more CPU.

var()	   bool bKNoInit;				// Start _NO_ Karma for this level. Only really for the Entry level.
// jag

var(Havok)    bool bHavokDisabled;          //  Disable Havok for this level.
var(Havok)    float HavokStepTimeQuantum;   // Usually 0.016f (1/60) of a sec)
var(Havok)    string HavokMoppCodeFilename; // The optional filename to load the static (prebuilt) Mopp code from.
var(Havok)    int HavokBroadPhaseDimension; // Something like 50,000 or so. Must encompase the whole world from the orign

#if IG_SWAT // ckline: allow designers to try different solvers
var(Havok) enum EHavokSolverType
{
    HAVOKSOLVER_4ITERS_SOFT,
    HAVOKSOLVER_4ITERS_MEDIUM,
    HAVOKSOLVER_4ITERS_HARD,
} HavokSolverType "This controls how Havok resolves physical interactions and constraints. The 'harder' the solver, the greater the percentage of error it will try to resolve in one iteration.\n\nSo if you have a 'Hard' solver these values will be quite high and the constraints might seem quite abrupt in how they solve, they could also handle unstable situations more aggresively. On the downside, where a medium constraint might relax in an unstable situation, a hard constraint could continually fight to fix itself, possibly causing jitter. You must also set bUseCustomSolver to true.";
var(Havok)	bool bUseCustomSolver;
#endif

var config float	DecalStayScale;		// 0 to 50 - affects decal stay time

var() localized string LevelEnterText;  // Message to tell players when they enter.
var()           string LocalizedPkg;    // Package to look in for localizations.
var             PlayerReplicationInfo Pauser;          // If paused, name of person pausing the game.
var		LevelSummary Summary;
var           string VisibleGroups;			// List of the group names which were checked when the level was last saved
var transient string SelectedGroups;		// A list of selected groups in the group browser (only used in editor)
//-----------------------------------------------------------------------------
// Flags affecting the level.

var(LevelSummary) bool HideFromMenus;
var() bool           bLonePlayer;     // No multiplayer coordination, i.e. for entranceways.
var bool             bBegunPlay;      // Whether gameplay has begun.
var bool             bPlayersOnly;    // Only update players.
var const EDetailMode	DetailMode;      // Client detail mode.
var bool			 bDropDetail;	  // frame rate is below DesiredFrameRate, so drop high detail actors
var bool			 bAggressiveLOD;  // frame rate is well below DesiredFrameRate, so make LOD more aggressive
var bool             bStartup;        // Starting gameplay.
var config bool		 bLowSoundDetail;
var	bool			 bPathsRebuilt;	  // True if path network is valid
var bool			 bHasPathNodes;
var globalconfig bool bCapFramerate;		// frame rate capped in net play if true (else limit number of servermove updates)
var	bool			bLevelChange;

//-----------------------------------------------------------------------------
// Renderer Management.
var config bool bNeverPrecache;

//-----------------------------------------------------------------------------
// Legend - used for saving the viewport camera positions
var() vector  CameraLocationDynamic;
var() vector  CameraLocationTop;
var() vector  CameraLocationFront;
var() vector  CameraLocationSide;
var() rotator CameraRotationDynamic;

//-----------------------------------------------------------------------------
// Audio properties.

var(Audio) string	Song;			// Filename of the streaming song.
var(Audio) float	PlayerDoppler;	// Player doppler shift, 0=none, 1=full.
var(Audio) float	MusicVolumeOverride;

//-----------------------------------------------------------------------------
// Miscellaneous information.

var() float Brightness;
#if !IG_SWAT //dkaplan: we use the LevelSummary's screenshot instead
var() texture Screenshot;
#endif
var texture DefaultTexture;
var texture WireframeTexture;
var texture WhiteSquareTexture;
var texture LargeVertex;
var int HubStackLevel;
var transient enum ELevelAction
{
	LEVACT_None,
	LEVACT_Loading,
	LEVACT_Saving,
	LEVACT_Connecting,
	LEVACT_Precaching
} LevelAction;

var transient GameReplicationInfo GRI;

//-----------------------------------------------------------------------------
// Networking.

var enum ENetMode
{
	NM_Standalone,        // Standalone game.
	NM_DedicatedServer,   // Dedicated server, no local client.
	NM_ListenServer,      // Listen server.
	NM_Client             // Client only, no local server.
} NetMode;
var string ComputerName;  // Machine's name according to the OS.
var string EngineVersion; // Engine version.
var string MinNetVersion; // Min engine version that is net compatible.
#if IG_SHARED // karl:
var string BuildVersion; // Engine version.
var string ModName; //dkaplan: name of the current mod
#endif

#if IG_SWAT // relevancy stats for Stat Net (crombie)
struct native RelevancyInfo
{
	var Pawn  RelevantPawnViewer;
	var Actor RelevantActor;
	var bool  bIsRelevant;
	var float RelevantUpdateTime;
};

var array<RelevancyInfo> RelevancyInformation;
#endif

//-----------------------------------------------------------------------------
// Gameplay rules

var() string DefaultGameType;
var() string PreCacheGame;
var GameInfo Game;
var float DefaultGravity;

//-----------------------------------------------------------------------------
// Navigation point and Pawn lists (chained using nextNavigationPoint and nextPawn).

var const NavigationPoint NavigationPointList;
var const Controller ControllerList;
var private PlayerController LocalPlayerController;		// player who is client here

#if IG_SHARED
var const Pawn PawnList;
#endif

#if IG_SWAT
var const array<AwarenessPoint> AwarenessPointList;
#endif

//-----------------------------------------------------------------------------
// Server related.

var string NextURL;
var bool bNextItems;
var float NextSwitchCountdown;

//-----------------------------------------------------------------------------
// Global object recycling pool.

var transient ObjectPool	ObjectPool;

//-----------------------------------------------------------------------------
// Additional resources to precache (e.g. Playerskins).

var transient array<material>		PrecacheMaterials;
var transient array<staticmesh>		PrecacheStaticMeshes;
#if IG_SHARED	// rowan: precache skeletal meshes
var transient array<mesh>		PrecacheMeshes;
#endif

#if IG_EFFECTS
var config enum EPlatform
{
	PC,
	PS2,
	XBOX
} Platform;

var IGEffectsSystemBase  EffectsSystem;

var private array<Actor> InterestedActorsGameStarted;		//these are the Actors who are interested in game started, ie. currently registered for notification
#endif

#if IG_SCRIPTING // david:
var MessageDispatcher messageDispatcher;
#endif

#if IG_SHARED	// marc: class to hang global AI data from
var Tyrion_Setup	AI_Setup;
#endif

#if IG_SHARED || IG_EFFECTS // tcohen: effects needs this to support Actor.bTriggerEffectEventsBeforeGameStarts
var private bool bGameStarted;  // use HasGameStarted() to access
#endif

//-----------------------------------------------------------------------------
// AI Repository variables (SWAT-specific)

var config string               AIRepositoryClassName;
var AIRepository                AIRepo;

//-----------------------------------------------------------------------------
// Enemy/Hostage Conversing variables (SWAT-specific)

#if IG_SWAT
// if true, enemies will talk to hostages when they are unaware or suspicious
// if false, enemies will talk to hostages only when they are suspicious
var() bool						EnemiesAlwaysTalkToHostages;
#endif

//-----------------------------------------------------------------------------
// Spawning system variables

#if IG_SWAT
//true iff this map is being played in COOP mode on the server
// Note that if this ever is true on clients, some assumptions that have been made will not be valid! [crombie]
var bool IsCOOPServer;
var bool IsPlayingCOOP;

var actor CurrentServerSettings;
var actor PendingServerSettings;

var bool TickSpecialEnabled;

var() editinline ISpawningManager SpawningManager;
var config bool AnalyzeBallistics;
var() bool IsTraining "Indicates whether or not this is a Training mission. If true, you will have unlimited ammo and tactical aids";
var bool DebugFlag;									// a generic flag value used for debugging purposes
var() bool NoEnemyHostageConversations "Specifies that enemies and hostages should not play conversations";
#endif //IG_SWAT

//-----------------------------------------------------------------------------
// Replication variables

var float MoveRepSize;

// these two properties are valid only during replication
var const PlayerController ReplicationViewer;	// during replication, set to the playercontroller to
												// which actors are currently being replicated
var const Actor  ReplicationViewTarget;				// during replication, set to the viewtarget to
												// which actors are currently being replicated

//-----------------------------------------------------------------------------
// speed hack detection
#if IG_SPEED_HACK_PROTECTION
var globalconfig float MaxTimeMargin;
var globalconfig float TimeMarginSlack;
var globalconfig float MinTimeMargin;
#endif

#if IG_ADCLIENT_INTEGRATION // dbeswick: Massive AdClient integration
var(Massive)	string	MassiveZoneName			"Name of the Massive zone for this level.";
#endif

//-----------------------------------------------------------------------------
// Functions.

#if IG_SHARED // Ryan: Allow access to the GameSpy manager
final native function GameSpyManager GetGameSpyManager();
#endif // IG

//#ifdef UNREAL_HAVOK

// Update the collidabilty between two layers (A and B). See the HavokRigidBody.uc for details on
// layers. If you are doing a few of these updates at once, only updateWorldInfo as true on the last one.
// updateWorldInfo needs to be set for at least one before the next step, BUT it is slow to do.
native final function HavokSetCollisionLayerEnabled(int layerA, int layerB, bool enabled, bool updateWorldInfo);

// If you use collision layers, and want to use the system layers in those, you can use this
// func to find the next free (unused) system layer (32K of them) and once you call this it will be deemed to be used.
// Be careful as any object can use which ever layer they like so if you don't use this func
// for all of them they may overlap if handcoded ones are not very high (this auto starts at 1)
// Will return -1 if none left.
native final function HavokGetNextFreeSystemLayer(out int systemLayer);

//endif

#if IG_MOJO // rowan:
native final function PlayMojoCutscene(name cutsceneName);
native function bool EscapeCutscene();
#endif // IG

native simulated function DetailChange(EDetailMode NewDetailMode);

// MCJ: this function is named poorly. It does NOT tell you whether this
// LevelInfo's level is the entry level. What is DOES is tell you if the
// game's current level is the entry level.
//
// I suppose a better name for this method would be AmIInTheEntryLevel().
native simulated function bool IsEntry();

#if IG_SWAT // ckline
// This method returns true of the Level in which this LevelInfo is placed is
// the Entry level (i.e., GEntry).
native simulated function bool IsTheEntryLevel();
#endif

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	DecalStayScale = FClamp(DecalStayScale,0,50);
}


#if IG_EFFECTS
simulated function CreateEffectsSystem()
{
	local class<IGEffectsSystemBase> EffectsSystemClass;

	EffectsSystemClass = class'IGEffectsSystemBase'.static.GetEffectsSystemClass();
	EffectsSystem = new(self, "EffectsSystem", 0) EffectsSystemClass;
    assertWithDescription(EffectsSystem != None,
        "The EffectsSystem could not be created.  (LevelInfo tried to create a new instance of class "$EffectsSystemClass$")");
}

simulated function InitializeEffectsSystem()
{
	local float time;
	time = AppSeconds();
	EffectsSystem.Init(self);
	time = AppSeconds() - time;

	log( "LevelInfo::InitializeEffectsSystem() called. Initialised in "$time$" seconds.");
}
#endif

function PlayerReplicationInfo ReplicationInfoFromPlayerID(int PlayerID)
{
	local Controller C;
	local PlayerReplicationInfo PRI;

	for(C = ControllerList; C != None; C = C.NextController)
	{
		PRI = C.PlayerReplicationInfo;
		if(PRI != None && PRI.PlayerID == PlayerID)
		{
			return PRI;
		}
	}

	return None;
}

private function CreateAIRepository()
{
    local class<AIRepository> AIRepositoryClass;

	if (Level.GetEngine().EnableDevTools)
		log( "dkaplan: CreateAIRepository() ... Level.IsCOOPServer = "$Level.IsCOOPServer$", NetMode = "$GetEnum(ENetMode, NetMode) );

    // if we are not a networked game (NM_Standalone), then spawn the AIRepository
    if (NetMode == NM_Standalone
#if IG_SWAT //dkaplan, also create an AIRepo for COOP
        || Level.IsCOOPServer
#endif
       )
    {
        AIRepositoryClass = class<AIRepository>(DynamicLoadObject(AIRepositoryClassName,class'Class'));
        assert(AIRepositoryClass != None);

        AIRepo = Spawn(AIRepositoryClass, self);
        assert(AIRepo != None);
    }
}

#if IG_SWAT //dkaplan&mjames - Repo/Engine accessors
native function Engine GetEngine();
simulated function Repo GetRepo()
{
    local Engine GameEngine;
    GameEngine = GetEngine();
    assert( GameEngine != None );
    return GameEngine.GetRepo();
//    return class'Engine'.static.GetRepo();
}

function bool UsingCustomScenario()
{
    return Game.UsingCustomScenario();
}
#endif

simulated function class<GameInfo> GetGameClass()
{
	local class<GameInfo> G;

	if(Level.Game != None)
		return Level.Game.Class;

	if (GRI != None && GRI.GameClass != "")
		G = class<GameInfo>(DynamicLoadObject(GRI.GameClass,class'Class'));
	if(G != None)
		return G;

	if ( DefaultGameType != "" )
		G = class<GameInfo>(DynamicLoadObject(DefaultGameType,class'Class'));

	return G;
}

simulated event FillRenderPrecacheArrays()
{
	local Actor A;
	local class<GameInfo> G;

	if ( NetMode == NM_DedicatedServer )
		return;
	if ( Level.Game == None )
	{
		if ( (GRI != None) && (GRI.GameClass != "") )
			G = class<GameInfo>(DynamicLoadObject(GRI.GameClass,class'Class'));
		if ( (G == None) && (DefaultGameType != "") )
			G = class<GameInfo>(DynamicLoadObject(DefaultGameType,class'Class'));
		if ( G == None )
			G = class<GameInfo>(DynamicLoadObject(PreCacheGame,class'Class'));
		if ( G != None )
			G.Static.PreCacheGameRenderData(self);
	}
	ForEach AllActors(class'Actor',A)
	{
		A.UpdatePrecacheRenderData();
	}
}

#if IG_SHARED	// rowan:
simulated event AddPrecacheMesh(Mesh mesh)
{
	local int i, Index;

	if ( NetMode == NM_DedicatedServer )
		return;
    if (mesh == None)
        return;

	// keep unique items in array
	// hmmm, need non unique items, so we can create mesh pool instances
	for (i=0; i<PrecacheMeshes.length; i++)
	{
		if (PrecacheMeshes[i] == mesh)
			return;
	}

//	LOG("PRECACHING MESH "$mesh.Name);

    Index = Level.PrecacheMeshes.Length;
	PrecacheMeshes.Insert(Index, 1);
	PrecacheMeshes[Index] = mesh;
}
#endif

simulated event AddPrecacheMaterial(Material mat)
{
    local int i, Index;

	if ( NetMode == NM_DedicatedServer )
		return;
    if (mat == None)
        return;

#if IG_SHARED	// rowan: keep unique entries in array
	for (i=0; i<PrecacheMaterials.length; i++)
	{
		if (PrecacheMaterials[i] == mat)
			return;
	}
#endif

//	LOG("PRECACHING MATERIAL "$mat.Name);

    Index = Level.PrecacheMaterials.Length;
    PrecacheMaterials.Insert(Index, 1);
	PrecacheMaterials[Index] = mat;
}

simulated event AddPrecacheStaticMesh(StaticMesh stat)
{
    local int i, Index;

	if ( NetMode == NM_DedicatedServer )
		return;
    if (stat == None)
        return;

#if IG_SHARED	// rowan: keep unique entries in array
	for (i=0; i<PrecacheStaticMeshes.length; i++)
	{
		if (PrecacheStaticMeshes[i] == stat)
			return;
	}
#endif

//	LOG("PRECACHING STATICMESH "$stat.Name);

    Index = Level.PrecacheStaticMeshes.Length;
    PrecacheStaticMeshes.Insert(Index, 1);
	PrecacheStaticMeshes[Index] = stat;
}

//
// Return the URL of this level on the local machine.
//
native simulated function string GetLocalURL();

//
// Demo build flag
//
native simulated final function bool IsDemoBuild();  // True if this is a demo build.


//
// Return the URL of this level, which may possibly
// exist on a remote machine.
//
native simulated function string GetAddressURL();

//
// Jump the server to a new level.
//
event ServerTravel( string URL, bool bItems )
{
	if( NextURL=="" )
	{
		bLevelChange = true;
		bNextItems          = bItems;
		NextURL             = URL;
		if( Game!=None )
			Game.ProcessServerTravel( URL, bItems );
		else
			NextSwitchCountdown = 0;
	}
}

//
// ensure the DefaultPhysicsVolume class is loaded.
//
function ThisIsNeverExecuted()
{
	local DefaultPhysicsVolume P;
	P = None;
}

/* Reset()
reset actor to initial state - used when restarting level without reloading.
*/
function Reset()
{
	// perform garbage collection of objects (not done during gameplay)
	ConsoleCommand("OBJ GARBAGE");
	Super.Reset();
}

//-----------------------------------------------------------------------------
// Network replication.

replication
{
#if IG_SWAT
	reliable if( Role==ROLE_Authority )
		CurrentServerSettings, PendingServerSettings;
#endif

#if IG_ADCLIENT_INTEGRATION
	reliable if ( Role==ROLE_Authority )
		MassiveZoneName;
#endif

	reliable if( bNetDirty && Role==ROLE_Authority )
		Pauser, TimeDilation, DefaultGravity;

	reliable if( bNetInitial && Role==ROLE_Authority )
		RagdollTimeScale, KarmaTimeScale, KarmaGravScale;
}


#if IG_EFFECTS
//register for notification that game has started... will get OnGameStarted() call.
simulated function InternalRegisterNotifyGameStarted(Actor registeree)
{
	local int i;

	for (i=0; i<InterestedActorsGameStarted.length; i++)
		if (InterestedActorsGameStarted[i] == registeree)
			AssertWithDescription(false, registeree$" is re-registering for NotifyGameStarted");

	InterestedActorsGameStarted[InterestedActorsGameStarted.length] = registeree;
}

//called by Tick() on the first frame of the game
simulated function NotifyGameStarted()
{
	local int i;

	if (Level.GetEngine().EnableDevTools)
	log( "LevelInfo::NotifyGameStarted() called on Level '"$Outer.Name$"' that has Label '"$Label$"'");

    if (Outer.Name != 'Entry')
    {
#if IG_EFFECTS // Carlos: Moved this from PostBeginPlay so Flushing of queued events happens after the game has started
        Level.InitializeEffectsSystem();

#if !IG_THIS_IS_SHIPPING_VERSION
        // Warn if, in any official maps, the levelinfo doesn't
        // have a reasonable name based on the map. Official maps
        // are the ones starting with MP- or SP-
        if (Outer.Name != Label &&
            (Left(Outer.Name, 3) == "SP-" || Left(Outer.Name, 3) == "MP-"))
        {
            assertWithDescription(
                false,
                "WARNING: Label for level does not match map name (MapName='"$Outer.Name$" LevelInfo.Label='"$Label$"').\nDesigners should set LevelInfo's label to something based on the map name.");
        }
#endif

        EffectsSystem.AddPersistentContext(name("Level_"$Label));
        Log("Added persistent context "$name("Level_"$Label)$" to EffectsSystem");
#endif

	    //notify interested Actors
	    for (i=0; i<InterestedActorsGameStarted.length; i++)
		{
			if (Level.GetEngine().EnableDevTools)
				mplog( "LevelInfo Calling OnGameStarted on: "$InterestedActorsGameStarted[i] );

		    InterestedActorsGameStarted[i].OnGameStarted();
		}

#if IG_SPEECH_RECOGNITION
		if (GetEngine().SpeechManager != None)
			GetEngine().SpeechManager.Init();
#endif
    }
}

//add a string tag to the current frame about a potentially slow code operation
simulated function GuardSlow(String GuardString) { assert(false); }
#endif

#if IG_SHARED // ckline: notifications upon Pawn death and Actor destruction

// NOTE: When an object that has previously registered via any of the following
// RegisterNotifyXXXX() methods is itself destroyed, it will automatically be
// UnRegistered for all subsequent notifications. Therefore, while possible,
// it is not necessary for an object to UnRegisterXXX() itself upon destruction.

// WARNING: These methods only guaranteed send notification during normal
// gameplay. During level transitions all listeners will be un-registered
// and no further notifications will be sent to any listeners (unless
// they re-register themselves when the next level begins).
//
// For these reasons, objects should not rely on these notifications for
// cleanup during level transitions.

// Register for notification whenever Died() is called on a Pawn, or
// PawnDied() is called on the pawn's Controller (whichever happens first).
// See comments in IInterestedPawnDied.uc for additional details.
//
// Note: If ObjectToNotify is itself a pawn, it *will* receive notification of its
// own death.
native final function RegisterNotifyPawnDied(IInterestedPawnDied ObjectToNotify);
native final function UnRegisterNotifyPawnDied(IInterestedPawnDied RegisteredObject);

// Register for notification whenever a Engine.Actor for which bStatic=false
// is destroyed during gameplay. Static actors will not generate notifications
// when they are destroyed.
//
// See comments in IInterestedActorDestroyed.uc for additional details.
//
// WARNING: Even if ObjectToNotify is itself an Actor, it will NOT be
// notified of its own destruction. If it wishes to handle its own
// destruction, it should override Pawn.Destroyed().
native final function RegisterNotifyActorDestroyed(IInterestedActorDestroyed ObjectToNotify);
native final function UnRegisterNotifyActorDestroyed(IInterestedActorDestroyed RegisteredObject);

#endif // IG_SHARED


//
//	PreBeginPlay
//

simulated event PreBeginPlay()
{
#if IG_SWAT
    local class<Actor> ServerSettingsClass;

	if (Level.GetEngine().EnableDevTools)
		log( self$"::PreBeginPlay() ..... " );

    if( SupportedModes.Length > 0 )
        IsPlayingCOOP = ( SupportedModes[0] == EMPMode.MPM_COOP );

	AssertWithDescription( !IsPlayingCOOP || SupportedModes.Length == 1, "CO-OP was specified as a supported mode; no other modes may be specified for this map!" );

    IsCOOPServer = IsPlayingCOOP && ( NetMode == NM_ListenServer || NetMode == NM_DedicatedServer );

    if( NetMode != NM_Client )
    {
        ServerSettingsClass = class<Actor>(DynamicLoadObject("SwatGame.ServerSettings",class'Class'));
        assert(ServerSettingsClass != None);

        CurrentServerSettings = Spawn(ServerSettingsClass, self);
        PendingServerSettings = Spawn(ServerSettingsClass, self);
    }
#endif

	// Create the object pool.
	ObjectPool = new(none) class'ObjectPool';

#if IG_SCRIPTING // david:
	MessageDispatcher = new class'MessageDispatcher';
#endif

#if IG_SHARED	// marc: class to hang global AI data from
	AI_Setup = spawn( class<Tyrion_Setup>( DynamicLoadObject( "Tyrion.Setup", class'Class') ));
#endif

#if IG_SHARED || IG_EFFECTS // tcohen: effects needs this to support Actor.bTriggerEffectEventsBeforeGameStarts
    RegisterNotifyGameStarted();
#endif

#if IG_EFFECTS
	CreateEffectsSystem();
#endif

#if IG_SWAT
	// Create the AI Repository, if we're not in the entry level
	if (! IsTheEntryLevel())
	{
		CreateAIRepository();
	}

	// set the level info on the repo (dedicated server work -- commented out [crombie])
//	GetRepo().SetLevel(self);
#endif

#if IG_SWAT // Carlos: Make sure and call super so that LinkToSkyZone is called
    Super.PreBeginPlay();
#endif

}

#if IG_SHARED || IG_EFFECTS // tcohen: effects needs this to support Actor.bTriggerEffectEventsBeforeGameStarts
simulated function OnGameStarted()
{
    bGameStarted = true;
}

simulated function bool HasGameStarted()
{
    return bGameStarted;
}
#endif // IG_SHARED || IG_EFFECTS

#if IG_AUTOTEST
simulated event AT_Begin();

simulated event AT_Exec(vector Location);

simulated event AT_Tick(float Delta);
#endif

// ckline NOTE: moved GetLocalPlayerController() native for performance reasons
// crombie NOTE: doesn't need to be an event anymore because I made ALevelInfo::GetLocalPlayerController() -- which this function calls natively
simulated native function PlayerController GetLocalPlayerController();

#if IG_SWAT //dkaplan: GameReplicationInfo accessor
simulated function GameReplicationInfo GetGameReplicationInfo()
	{
    if( NetMode == NM_Client )
		{
        return GetLocalPlayerController().GameReplicationInfo;
		}
    else
    {
        return Game.GameReplicationInfo;
	}
}
#endif

defaultproperties
{
	PreCacheGame="Engine.GameInfo"
    RemoteRole=ROLE_DumbProxy
	 bAlwaysRelevant=true
     TimeDilation=+00001.000000
	 Brightness=1
     bHiddenEd=True
	 DefaultTexture=DefaultTexture
	 WireframeTexture=Texture'Engine_res.WireframeTexture'
	 WhiteSquareTexture=WhiteSquareTexture
	 LargeVertex=Texture'Engine_res.LargeVertex'
	 HubStackLevel=0
	 DetailMode=DM_SuperHigh
	 PlayerDoppler=0
	 bWorldGeometry=true
	 VisibleGroups="None"
         KarmaTimeScale=0.9
         RagdollTimeScale=1
         MaxRagdolls=16
         bKStaticFriction=true
         KarmaGravScale=1
	 PhysicsDetailLevel=PDL_High
    DefaultGravity=-1500.0
	bCapFramerate=true

	HavokBroadPhaseDimension=524288 // WORLD_MAX. Reduce this if you can. Check in the VDB to see Broad Phase size.

     Title="Untitled"
    MoveRepSize=+64.0
    MusicVolumeOverride=-1
    AIRepositoryClassName="Engine.AIRepository"

//#if IG_SHARED // ckline: set DecalStayScale default to 1, old default of 0 means no ProjectedDecals show up!
    DecalStayScale=1.0
//#endif
//#if IG_SWAT // dbeswick: made hard solver default
    HavokSolverType=HAVOKSOLVER_4ITERS_MEDIUM
	bUseCustomSolver=false

    TickSpecialEnabled=true
//#endif

//#if IG_SPEED_HACK_PROTECTION
    MaxTimeMargin=+1.0
    TimeMarginSlack=+1.35
    MinTimeMargin=-1.0
//#endif
}
