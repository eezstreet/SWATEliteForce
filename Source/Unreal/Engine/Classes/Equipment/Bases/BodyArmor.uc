class BodyArmor extends ProtectiveEquipment;

enum ProtectionLevel
{
  Level_0,            // Doesn't stop anything (AKA gas mask, night vision, no armor)
  Level_1,            // Stops .380 ACP FMJ (AKA Nothing)
  Level_2a,           // Stops .45 from pistols (AKA Glock, M1911)
  Level_2,            // Stops 9mm and .45 from SMGs (AKA MP5, UMP)
  Level_3a,           // Stops .357 and remaining pistol calibers (AKA Python, Desert Eagle)
  Level_3,            // Stops rifle calibers up to .308 (AKA 5.56 JHP, 7.62 FMJ)
  Level_3X,           // Stops rifle calibers and armor piercing calibers up to .308 (AKA 5.56 FMJ, 7.62 AP)
  Level_4             // Stops .308 AP (AKA Nothing yet)
};

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
var() public config bool PlayerUsable;

var(ArmorPenetration) config ProtectionLevel ArmorProtection "What level of armor I represent?";
var int ProtectionType "Internal measure to know the BulletClass";


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

simulated function int GetProtectionLevel() 
{
  return ArmorProtection;
}

simulated function int GetProtectionType() 
{			
	switch(ArmorProtection) 
		{				
		case Level_0:
			ProtectionType = 1;
			break;
		case Level_1:
			ProtectionType = 2;
			break;
		case Level_2a:
			ProtectionType = 3;
			break;
		case Level_2:
			ProtectionType = 4;
			break;
		case Level_3a:
			ProtectionType = 5;
			break;
		case Level_3:
			ProtectionType = 6;
			break;
		case Level_3X:
			ProtectionType = 7;
			break;		
		case Level_4:
			ProtectionType = 8;
			break;
		default:
			ProtectionType = 1;
		}
	return ProtectionType;
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
	local Pawn OwnerPawn;
	local PlayerController OwnerController;

	CurrentMomentumToPenetrate -= CurrentBulletMtP;
	CurrentBulletMtP *= MultiplyPerBullet;

	if(CurrentBulletMtP < MinBulletMtpReduction) {
	    CurrentBulletMtP = MinBulletMtpReduction;
  }
  
  if(CurrentMomentumToPenetrate < MaxMomentumToPenetrate/2) {
    ProtectionType -= 2;
	}

	if(CurrentMomentumToPenetrate < MinMomentumToPenetrate) {
	    CurrentMomentumToPenetrate = MinMomentumToPenetrate;
	}
	log("[SHREDDING] Armor "$self$" now has "$CurrentMomentumToPenetrate$" MtP");

	// Tell the client to update their display in multiplayer
	if(Level.NetMode != NM_Standalone)
	{
		OwnerPawn = Pawn(Owner);
		if(OwnerPawn == None)
		{
			return;
		}

		OwnerController = PlayerController(OwnerPawn.Controller);
		if(OwnerController == None)
		{
			return;
		}

		log("Calling ClientNotifyArmorTakeDamage");
		OwnerController.ClientNotifyArmorTakeDamage(CurrentMomentumToPenetrate);
	}
}

function ClientNotifiedOfHit(float NewMTP)
{
	CurrentMomentumToPenetrate = NewMTP;
	log("...CurrentMomentumToPenetrate is "$NewMTP);
}

function bool IsArmorShreddable() {
  return MayBeShredded;
}

simulated function float GetArmorHealthPercent() {
  return (CurrentMomentumToPenetrate - MinMomentumToPenetrate) / (MaxMomentumToPenetrate - MinMomentumToPenetrate);
}

static function bool IsUsableByPlayer()
{
	return default.PlayerUsable;
}

////////////////////////////////////////////////////////////////////////////////
//
// Replication info

Replication
{
  reliable if (Role == ROLE_Authority)
    CurrentMomentumToPenetrate, CurrentBulletMtP;
}
