class Equipment extends Actor
implements IHaveWeight
    config(SwatEquipment)
    abstract
    native;

//TMC note: no attach socket(s) here! That goes in subclasses.

function OnGivenToOwner();

// Must be overridden in subclasses
static function string GetFriendlyName(){ return ""; }
static function string GetShortName() { return ""; }
static function String GetDescription(){ return ""; }
static function Material GetGUIImage() { return None; }
simulated function float GetWeight() { return 0.0; }
simulated function float GetBulk() { return 0.0; }
static function bool IsUsableByPlayer(){ return false; }

defaultproperties
{
    RemoteRole=ROLE_None

    // Warning: subclasses (e.g., HandHeldEquipment) *might* change bOwnerNoSee dynamically changed every frame
    bOwnerNoSee=true

    // To speed up rendering, don't let pawn shadows be cast on equipment
    bAcceptsShadowProjectors=true

    // To speed up rendering, regular equipment doesn't accept projectors
    bAcceptsProjectors=true
}
