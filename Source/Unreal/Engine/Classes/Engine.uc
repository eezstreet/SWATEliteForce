//=============================================================================
// Engine: The base class of the global application object classes.
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class Engine extends Core.Subsystem
	native
	noexport
	transient;

// Drivers.
var(Drivers) config class<AudioSubsystem> AudioDevice;
var(Drivers) config class<Interaction>    Console;				// The default system console
var(Drivers) config class<Interaction>	  DefaultMenu;			// The default system menu 
var(Drivers) config class<Interaction>	  DefaultPlayerMenu;	// The default player menu
var(Drivers) config class<NetDriver>      NetworkDevice;
var(Drivers) config class<Core.Language>  Language;

// Variables.
var primitive Cylinder;
var const client Client;
var const audiosubsystem Audio;
var const renderdevice GRenDev;
#if IG_SPEECH_RECOGNITION
var const SpeechManager SpeechManager;
#endif

#if IG_SWAT //dkaplan & MCJ: added this so we can get to the Repo whenever we want. The Repo is a
// Singleton to be used for data that persists across level changes.
var Repo Repo;
var config string RepoClassName;
#endif

#if IG_SHARED	// rowan: exec hook
var transient const int	GameExecHook;	
#endif


// Stats.
var int bShowFrameRate;
var int bShowRenderStats;
var int bShowHardwareStats;
var int bShowGameStats;
var int bShowNetStats;
var int bShowAnimStats;		 // Show animation statistics.

#if IG_SWAT	// ckline: render new engine stats (simple stats)
var int ShowEngineStats;
#endif

#if IG_SHARED
var int bShowAIStats;
#endif

// ifdef WITH_LIPSINC
var int bShowLIPSincStats;   // Show LIPSinc statistics.
// endif

var int bShowHistograph;
var int bShowXboxMemStats;
var int bShowMatineeStats;	// Show Matinee specific information
var int bShowAudioStats;
var int bShowLightStats;

var int TickCycles, GameCycles, ClientCycles;
var(Settings) config int CacheSizeMegs;

#if IG_SHARED	// ryan: allow perforce support to be enabled/disabled
var(Advanced) config int UsePerforce;
var config int ForceActorCleanup;
#endif // IG

var(Settings) config bool UseSound;
var(Settings) config bool UseStaticMeshBatching;
#if IG_SHARED	// rowan: disable dev tools stuff
var(Settings) config bool EnableDevTools;
#endif
var(Settings) float CurrentTickRate;

var int ActiveControllerId;	// The ID of the active controller
// Color preferences.
var(Colors) config color
	C_WorldBox,
	C_GroundPlane,
	C_GroundHighlight,
	C_BrushWire,
	C_Pivot,
	C_Select,
	C_Current,
	C_AddWire,
	C_SubtractWire,
	C_GreyWire,
	C_BrushVertex,
	C_BrushSnap,
	C_Invalid,
	C_ActorWire,
	C_ActorHiWire,
	C_Black,
	C_White,
	C_Mask,
	C_SemiSolidWire,
	C_NonSolidWire,
	C_WireBackground,
	C_WireGridAxis,
	C_ActorArrow,
	C_ScaleBox,
	C_ScaleBoxHi,
	C_ZoneWire,
	C_Mover,
	C_OrthoBackground,
	C_StaticMesh,
	C_StaticMeshDynamic,
	C_VolumeBrush,
	C_ConstraintLine,
	C_AnimMesh,
	C_TerrainWire;

#if IG_LEVELINFO_SUBCLASS
var config class<LevelInfo> LevelInfoClass;
#endif

#if IG_SWAT //dkaplan & MCJ: creation and accessor for Repo variable declared above
simulated event CreateRepo()
{
    local class<Repo> RepoClass;
log("dkaplan: >>> Engine::CreateRepo... default.RepoClassName = "$default.RepoClassName);
    RepoClass = class<Repo>( DynamicLoadObject( default.RepoClassName, class'Class' ));
    assert( RepoClass != None );

    Repo = new RepoClass;
    assert( Repo != None );

    Repo.Initialize();
}

simulated final function Repo GetRepo()
{
    return Repo;
}
#endif


defaultproperties
{
	CacheSizeMegs=2
	UseSound=True
	EnableDevTools=False
	UsePerforce=0
	UseStaticMeshBatching=True
	C_WorldBox=(R=0,G=0,B=107,A=255)
	C_GroundPlane=(R=0,G=0,B=63,A=255)
	C_GroundHighlight=(R=0,G=0,B=127,A=255)
	C_BrushWire=(R=255,G=63,B=63,A=255)
	C_Pivot=(R=0,G=255,B=0,A=255)
	C_Select=(R=0,G=0,B=127,A=255)
	C_AddWire=(R=127,G=127,B=255,A=255)
	C_SubtractWire=(R=255,G=192,B=63,A=255)
	C_GreyWire=(R=163,G=163,B=163,A=255)
	C_Invalid=(R=163,G=163,B=163,A=255)
	C_ActorWire=(R=127,G=63,B=0,A=255)
	C_ActorHiWire=(R=255,G=127,B=0,A=255)
	C_White=(R=255,G=255,B=255,A=255)
	C_SemiSolidWire=(R=127,G=255,B=0,A=255)
	C_NonSolidWire=(R=63,G=192,B=32,A=255)
	C_WireGridAxis=(R=119,G=119,B=119,A=255)
	C_ActorArrow=(R=163,G=0,B=0,A=255)
	C_ScaleBox=(R=151,G=67,B=11,A=255)
	C_ScaleBoxHi=(R=223,G=149,B=157,A=255)
	C_Mover=(R=255,G=0,B=255,A=255)
	C_OrthoBackground=(R=163,G=163,B=163,A=255)
	C_Current=(R=0,G=0,B=0,A=255)
	C_BrushVertex=(R=0,G=0,B=0,A=255)
	C_BrushSnap=(R=0,G=0,B=0,A=255)
	C_Black=(R=0,G=0,B=0,A=255)
	C_Mask=(R=0,G=0,B=0,A=255)
	C_WireBackground=(R=0,G=0,B=0,A=255)
	C_ZoneWire=(R=0,G=0,B=0,A=255)
	C_StaticMesh=(R=0,G=255,B=255,A=255)
	C_StaticMeshDynamic=(R=127,G=127,B=255,A=255)
	C_VolumeBrush=(R=255,G=196,B=225,A=255)
	C_AnimMesh=(R=221,G=221,B=28,A=255)
	C_ConstraintLine=(R=0,G=255,B=0,A=255)
	C_TerrainWire=(R=255,G=255,B=255,A=255)
}
