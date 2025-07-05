//=============================================================================
// GameEngine: The game subsystem.
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class GameEngine extends Engine
	native
	noexport
	transient;

// URL structure.
struct URL
{
	var string			Protocol,	// Protocol, i.e. "unreal" or "http".
						Host;		// Optional hostname, i.e. "204.157.115.40" or "unreal.epicgames.com", blank if local.
	var int				Port;		// Optional host port.
	var string			Map;		// Map name, i.e. "SkyCity", default is "Index".
	var array<string>	Op;			// Options.
	var string			Portal;		// Portal to enter through, default is "".
	var int 			Valid;
};

var Level			GLevel,
					GEntry;
var PendingLevel	GPendingLevel;
#if IG_LEVEL_LOAD_ACTOR_CALLBACK
var	private const int LevelLoadingTotalActorCount;
var	private const int LevelLoadingActorCount;
#endif
var URL				LastURL;
var config array<string>	ServerActors,
					ServerPackages;

var array<object> DummyArray;	// Do not modify
var object        DummyObject;  // Do not modify

var bool		  bCheatProtection;

#if IG_SWAT //dkaplan: the initial map has been loaded
var bool InitialMapLoaded;
#endif

#if IG_GUI_LAYOUT //dkaplan, allows us to specify an initial menu class to be used as the hud if the game is opened with a command line (non-entry) map
var config String HUDMenuClass;			    // Menu used for the HUD if the game is started with a map
var config String InitialMenuClass;			// The initial menu that should appear
#else //these menus are unused by the gui system and are rather annoying to boot
var config String MainMenuClass;			// Menu that appears when you first start
var config String InitialMenuClass;			// The initial menu that should appear
var config String ConnectingMenuClass;		// Menu that appears when you are connecting
var config String DisconnectMenuClass;		// Menu that appears when you are disconnected
var config String LoadingClass;				// Loading screen that appears
#endif

#if IG_SHARED // Ryan:
var config String GameSpyManagerClass;
var GameSpyManager GameSpyManager;
#endif // IG

// Automation driver padding
var transient const int AutomationDriver;

#if IG_ADCLIENT_INTEGRATION // dbeswick: Massive AdClient integration
var int MassiveAdClient;
var config float MassiveUpdateDelay;
#else
var int Unused1;
var float Unused2;
#endif

defaultproperties
{
}
