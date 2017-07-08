// This singleton is meant to provide a place to store information that should
// persist across level changes. A single instance of it is created in
// PostBeginPlay() of LevelInfo if it is the entry level. Because the entry
// level is always present, any class that can get a reference to the entry
// level can get to the Repo.

class Repo extends Core.Object
    native
    transient;

#if IG_SWAT //dkaplan: Moved here so that Level Summary (and other engine classes)
			// can access the swat game modes
// Defines a SWAT multiplayer game mode
enum EMPMode
{
	MPM_BarricadedSuspects,    
	MPM_VIPEscort, 
    MPM_RapidDeployment,
    MPM_COOP,
	MPM_SmashAndGrab,
	MPM_COOPQMM
};

//DKaplan: Repo now stores a cached reference to the level info
var LevelInfo Level;

//dkaplan: Repo now stores a cached reference to the GUIController (assigned during Engine.init)
var BaseGUIController GUIController;

var bool InitAsListenServer;
var bool InitAsDedicatedServer;
var bool InitWithoutIntroMenu;
var string CommandLineMap; // dbeswick:
var string CommandLineGameMode; // dbeswick:
#endif

var String SplashSceneMapName "Name of the map to load behind the GUI";

var config float MPTimeOut "Time (in seconds) to wait before declaring a timeout";

#if IG_SWAT // Carlos: Moved this here from GameInfo so it can be accessed on Multiplayer clients...
//;The fraction of an Actor's MomentumToPenetrate that is imparted as a Karma impulse to an object when a bullet penetrates the Actor.
//;   eg. 0.2 means that 20% of an Actor's MomentumToPenetrate is imparted as a Karma impulse when a bullet penetrates the Actor.
//;Note1: The bullet will always lose 1.0 * MomentumToPenetrate (100% of MomentumToPenetrate) from its momentum.
//;Note2: This value only affects the Karma impulse imparted to the Actor.
//;       _Damage_ to the Actor is always proportional to MomentumToDamageConversionFactor. (see above)
var float MomentumImpartedOnPenetrationFraction;

//;Damage from a bullet is calculated as Momentum * MomentumToDamageConversionFactor 
var float MomentumToDamageConversionFactor;

// Override in SWATRepo. We need this so the GamePlay package can get this
// info out of the server settings.
function bool IsLANOnlyGame();
#endif

function Initialize();

event PreLevelChange(Player thePlayer, String MapName);
event PostLevelChange(Player thePlayer, String MapName);
#if IG_SWAT //dkaplan: Do special gui loading when disconnecting
event OnDisconnected(); //called when a disconnect happens
#endif

event Tick( Float DeltaSeconds ); //called at the end of the tick cycle

#if IG_SWAT //dkaplan: Added here to handle external damage modification,
			// overridden in SwatRepo
function float GetExternalDamageModifier( Actor Damager, Actor Victim )
{
    return 1.0;
}

event PreBeginPlay();
event PostBeginPlay();

event PostGameEngineInit();
#endif

#if IG_CAPTIONS //used for determining if captions should be displayed by the effects system
event bool ShouldShowSubtitles();
#endif

defaultproperties
{
    SplashSceneMapName="swat_splashscene"
    MPTimeOut=120.0
    MomentumImpartedOnPenetrationFraction=0.5
    MomentumToDamageConversionFactor=0.1
}
