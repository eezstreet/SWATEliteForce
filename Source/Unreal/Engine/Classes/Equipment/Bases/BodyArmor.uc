class BodyArmor extends ProtectiveEquipment;

var(ArmorShredding) public config bool MayBeShredded "If true, this armor may be shredded.";
var(ArmorShredding) public config float MinMomentumToPenetrate "Minimum MtP that this armor can be reduced to.";
var(ArmorShredding) public config float MaxMomentumToPenetrate "Maximum MtP that this armor has. (The starting amount)";
var(ArmorShredding) public config float FirstBulletMtPReduction "The amount of MtP drained by the first bullet.";
var(ArmorShredding) public config float MultiplyPerBullet "How much to multiply the MtP drainage per bullet. For example, if the FirstBulletMtPReduction is 100 and this value is 0.5, the second will be 50, the third will be 25, ...";
var(ArmorShredding) public config float MinBulletMtpReduction "The minimum amount that a bullet must drain MtP by.";
var(GUI) public localized config string ArmorRating "The rating level, as shown in the GUI (ie, 'Type II')";
var(GUI) public localized config string ExtraProtection "Extra protection effects, as shown in the GUI (ie, 'Protects against Flashbangs')";
var private float CurrentMomentumToPenetrate;
var private float CurrentBulletMtP;

////////////////////////////////////////////////////////////////////////////////
//
// IHaveWeight implementation
var() public config float Weight;
var() public config float Bulk;

simulated function float GetWeight() {
  return Weight;
}

simulated function float GetBulk() {
  return Bulk;
}

////////////////////////////////////////////////////////////////////////////////
//
// ProtectiveEquipment overrides
static function String GetMtPString()
{
  if(default.MayBeShredded) {
    return String(default.MaxMomentumToPenetrate);
  } else {
    return String(default.MomentumToPenetrate);
  }
}

static function String GetProtectionRating()
{
  return default.ArmorRating;
}

static function String GetSpecialProtection()
{
  return default.ExtraProtection;
}

////////////////////////////////////////////////////////////////////////////////
//
// Equipment implementation
function OnGivenToOwner() {
  Super.OnGivenToOwner();

  if(MayBeShredded) {
    CurrentMomentumToPenetrate = MaxMomentumToPenetrate;
    CurrentBulletMtP = FirstBulletMtPReduction;
  }
}

////////////////////////////////////////////////////////////////////////////////
//
// Armor Shredding mechanic
simulated function float GetMtP() {
  if(!MayBeShredded) {
    return MomentumToPenetrate;
  } else {
    return CurrentMomentumToPenetrate;
  }
}

simulated function OnProtectedRegionHit() {
  CurrentMomentumToPenetrate -= CurrentBulletMtP;
  CurrentBulletMtP *= MultiplyPerBullet;

  if(CurrentBulletMtP < MinBulletMtpReduction) {
    CurrentBulletMtP = MinBulletMtpReduction;
  }

  if(CurrentMomentumToPenetrate < MinMomentumToPenetrate) {
    CurrentMomentumToPenetrate = MinMomentumToPenetrate;
  }
  log("[SHREDDING] Armor "$self$" now has "$CurrentMomentumToPenetrate$" MtP");
}

function bool IsArmorShreddable() {
  return MayBeShredded;
}

simulated function float GetArmorHealthPercent() {
  return (CurrentMomentumToPenetrate - MinMomentumToPenetrate) / (MaxMomentumToPenetrate - MinMomentumToPenetrate);
}

////////////////////////////////////////////////////////////////////////////////
//
// Replication info

Replication
{
  reliable if (bNetOwner)
    CurrentMomentumToPenetrate, CurrentBulletMtP;
}
