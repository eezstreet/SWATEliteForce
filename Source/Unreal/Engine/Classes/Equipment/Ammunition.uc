class Ammunition extends Actor
    implements ICanBeSelectedInTheGUI, IAmmunition
    config(SwatEquipment)
	abstract
    native;

var bool bInstantHit;
var(Ammo) config class<SwatProjectile>	ProjectileClass;

var(Ammo) config localized  String      Description;
var(Ammo) config localized  String      FriendlyName;
var(Ammo) config localized  Material    GUIImage;

var(Ammo) config            int         InternalDamage          "Extra Damage imparted to an actor when a bullet gets buried in the actor.";

var(Ammo) config            int         ImpactMomentum          "Amount by which the bullet's direction is scaled to create the physics impact momentum.";

var(Ammo) config            int         ShotsPerRound           "The number of shots fired each time the weapon is used, eg. pellets for a shotgun";

var(Ammo) config            bool        RoundsNeverPenetrate    "If true, then impact will always cause round to lose all momentum to its victim";

simulated function Initialize(bool bUsingAmmoBandolier);

//returns true iff there is no ammo loaded (ie. weapon cannot currently be fired).  does not check IsEmpty or CanReload
simulated function bool NeedsReload() { assert(false); return false; } //subclasses must implement

//returns true iff there is ammo remaining that is not loaded
simulated function bool CanReload() { assert(false); return false; } //subclasses must implement

//returns true iff there is no ammo loaded and none remaining to load
simulated function bool IsEmpty() { assert(false); return false; } //subclasses must implement

//returns true iff the current number of rounds loaded is equal to the maximum number of rounds that can be loaded
simulated function bool IsFull() { assert(false); return false; } //subclasses must implement

//returns true iff there is exactly one round left before NeedsReload()
simulated function bool IsLastRound() { assert(false); return false; } //subclasses must implement

//returns the number of rounds that can be shot before the clip or magazine is empty and must be reloaded
simulated function int RoundsRemainingBeforeReload() { assert(false); return 0; }   //subclasses must implement

simulated function OnRoundUsed(Pawn User, Equipment Launcher)  //subclasses must implement
{
	local PlayerController PC;

	if (User != None)
		PC = PlayerController(User.Controller);

	if (PC != None)
		PC.Stats.Fired(Launcher.class.name, class.name);
}

simulated function OnReloaded() { assert(false); } //subclasses must implement

simulated function UpdateHUD() { assert(false); } //subclasses must implement

function string GetAmmoCountString();

static function String GetDescription()
{
    return default.Description;
}

static function String GetFriendlyName()
{
    return default.FriendlyName;
}

static function Material GetGUIImage()
{
    return default.GUIImage;
}

static function class<Actor> GetRenderableActorClass()
{
    return default.Class;
}

simulated function int GetClip( int index ) { Assert(false); return 0; } //subclasses must implement
simulated function SetClip(int index, int amount) { Assert(false); } //subclasses must implement
simulated function int GetCurrentClip() { Assert(false); return 0; } //subclasses must implement
simulated function SetCurrentClip(int Clip) { Assert(false); } //subclasses must implement

defaultproperties
{
    DrawType=DT_None
    RemoteRole=ROLE_None
    ShotsPerRound=1
    bStasis=true
}
