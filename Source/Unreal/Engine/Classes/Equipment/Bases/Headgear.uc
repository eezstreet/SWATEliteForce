// Headgear is used for every helmet class except for Night Vision Goggles.
class Headgear extends ProtectiveEquipment;

var(GUI) public localized config string ArmorRating "The rating level, as shown in the GUI (ie, 'Type II')";
var(GUI) public localized config string ExtraProtection "Extra protection effects, as shown in the GUI (ie, 'Protects against Flashbangs')";
var() public config bool PlayerUsable;

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
static function String GetProtectionRating()
{
  return default.ArmorRating;
}

static function String GetSpecialProtection()
{
  return default.ExtraProtection;
}

static function bool IsUsableByPlayer()
{
	return default.PlayerUsable;
}
