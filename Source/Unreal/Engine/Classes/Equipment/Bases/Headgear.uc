// Headgear is used for every helmet class except for Night Vision Goggles.
class Headgear extends ProtectiveEquipment;

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

var(GUI) public localized config string ArmorRating "The rating level, as shown in the GUI (ie, 'Type II')";
var(GUI) public localized config string ExtraProtection "Extra protection effects, as shown in the GUI (ie, 'Protects against Flashbangs')";

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