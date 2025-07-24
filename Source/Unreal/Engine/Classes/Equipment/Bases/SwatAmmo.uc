class SwatAmmo extends Ammunition abstract;

import enum EMaterialVisualType from Material;
enum AmmoType
{
  AmmoType_9mmAP,            		 // 9mm round. Armor Piercing. Probably Level_3a
  AmmoType_9mmFMJ,            		 // 9mm round. Full Metal Jacket. Probably Level_2 or Level_2a
  AmmoType_9mmJSP,            		 // 9mm round. Jacketed Soft Point. Probably Level_2a
  AmmoType_9mmJHP,            		 // 9mm round. Jacketed Hollow Point. Probably Level_1
  AmmoType_45AP,            		 // .45 round. Armor Piercing. Probably Level_3a
  AmmoType_45FMJ,            		 // .45 round. Full Metal Jacket. Probably Level_2 or Level_2a
  AmmoType_45JSP,            		 // .45 round. Jacketed Soft Point. Probably Level_2a
  AmmoType_45JHP,            		 // .45 round. Jacketed Hollow Point. Probably Level_1
  AmmoType_357AP,            		 // .357 round. Armor Piercing. Probably Level_3a
  AmmoType_357FMJ,            		 // .357 round. Full Metal Jacket. Probably Level_2
  AmmoType_357JSP,            		 // .357 round. Jacketed Soft Point. Probably Level_2a
  AmmoType_357JHP,            		 // .357 round. Jacketed Hollow Point. Probably Level_2a
  AmmoType_57AP,            		 // 5.7x28 round. Armor Piercing. Probably Level_3
  AmmoType_57FMJ,            		 // 5.7x28 round. Full Metal Jacket. Probably Level_3a
  AmmoType_57JSP,            		 // 5.7x28 round. Jacketed Soft Point. Probably Level_2
  AmmoType_57JHP,            		 // 5.7x28 round. Jacketed Hollow Point. Probably Level_2a
  AmmoType_50AP,            		 // .50 round. Armor Piercing. Probably Level_3
  AmmoType_50FMJ,            		 // .50 round. Full Metal Jacket. Probably Level_3a
  AmmoType_50JSP,            		 // .50 round. Jacketed Soft Point. Probably Level_2
  AmmoType_50JHP,            		 // .50 round. Jacketed Hollow Point. Probably Level_2
  AmmoType_32AP,            		 // .32 round. Armor Piercing. Probably Level_3a
  AmmoType_32FMJ,            		 // .32 round. Full Metal Jacket. Probably Level_2a
  AmmoType_32JSP,            		 // .32 round. Jacketed Soft Point. Probably Level_1
  AmmoType_32JHP,            		 // .32 round. Jacketed Hollow Point. Probably Level_1
  AmmoType_223AP,            		 // .223 round. Armor Piercing. Probably Level_3X
  AmmoType_223FMJ,            		 // .223 round. Full Metal Jacket. Probably Level_3
  AmmoType_223JSP,            		 // .223 round. Jacketed Soft Point. Probably Level_3a
  AmmoType_223JHP,            		 // .223 round. Jacketed Hollow Point. Probably Level_3a
  AmmoType_762AP,            		 // 7.62 Russian round. Armor Piercing. Probably Level_3a
  AmmoType_762FMJ,            		 // 7.62 Russian round. Full Metal Jacket. Probably Level_3a
  AmmoType_762JSP,            		 // 7.62 Russian round. Jacketed Soft Point. Probably Level_3a
  AmmoType_762JHP,            		 // 7.62 Russian round. Jacketed Hollow Point. Probably Level_3a
  AmmoType_308AP,            		 // 7.62 NATO round. Armor Piercing. Probably Level_3
  AmmoType_308FMJ,            		 // 7.62 NATO round. Full Metal Jacket. Probably Level_3a
  AmmoType_308JSP,            		 // 7.62 NATO round. Jacketed Soft Point. Probably Level_3a
  AmmoType_308JHP,            		 // 7.62 NATO round. Jacketed Hollow Point. Probably Level_3a
  AmmoType_545AP,            		 // 5.45 round. Armor Piercing. Probably Level_3
  AmmoType_545FMJ,            		 // 5.45 round. Full Metal Jacket. Probably Level_3a
  AmmoType_545JSP,            		 // 5.45 round. Jacketed Soft Point. Probably Level_3a
  AmmoType_545JHP,            		 // 5.45 round. Jacketed Hollow Point. Probably Level_3a
  AmmoType_ArmorPiercing,            // Increased anti armor effectiveness at the cost of damage against unarmored targets
  AmmoType_FullMetalJacket,          // All-rounded effectiveness, can go through armor, good effectiveness against unarmored
  AmmoType_JacketedSoftPoint,        // Fair effectiveness against unarmored targets, probably won't go through armor
  AmmoType_JacketedHollowPoint,      // Very effective against unarmored targets, ineffective against armor
  AmmoType_Buckshot,                 // Very effective against unarmored targets, very ineffective against armor
  AmmoType_Special                   // We are not a bullet/pellet/slug. Used for LTL stuff.
};

enum PenetrationLevel
{
  Level_0,            // Can't go through any armor
  Level_1,            // Can go through Level I vests and helmets (AKA nothing)
  Level_2a,           // Can go through Level IIa vests and helmets (AKA Still Nothing)
  Level_2,            // Can go through Level II vests and helmets (AKA light armor, most helmets)
  Level_3a,           // Can go through Level IIIa vests and helmet (AKA damaged heavy armor and protec helmet)
  Level_3,            // Can go through Level III vests (AKA suspect heavy armor)
  Level_3X,           // Can go through Level III+ vests (AKA SWAT heavy armor)
  Level_4             // Can go through Level IV vests.......why you should use this is beyond me
};

// Ricochet occurs when a bullet hits a hard surface and bounces off.
// It can only occur within a certain angle, and when the bullet bounces, it loses momentum.
var(Ricochet) config bool CanCauseRicochet "Can this ammo type cause a ricochet?";
var(Ricochet) config array<EMaterialVisualType> RicochetMaterials "What material types can trigger a ricochet";
var(Ricochet) config float RicochetChance "Chance that a bullet will ricochet";
var(Ricochet) config float MinRicochetAngle "Minimum angle that a ricochet can be triggered from";
var(Ricochet) config float MaxRicochetAngle "Maximum angle that a ricochet can be triggered from";
var(Ricochet) config bool RicochetFromBSPOnly "If true, ricochets will occur from BSP only and not static meshes";
var(Ricochet) config int RicochetBounceCount "Maximum times that a bullet can ricochet";
var(Ricochet) config float RicochetMomentum "Momentum is multiplied by this when a ricochet (not a fracture) occurs";
var(Ricochet) config float RicochetMinimumMomentum "Minimum momentum required to trigger a ricochet";

// Advanced ballstics for Elite Force
var(AdvancedBallistics) config AmmoType BulletClass "What ammo type I am?";
var(AdvancedBallistics) config PenetrationLevel ArmorPenetration "What level of armor can I go through?";
var int PenetrationType "Internal measure to know the BulletClass";

var(AdvancedBallistics) config float Drag "The amount of Momentum that is lost with each unit traveled.";
var(AdvancedBallistics) config bool ShredsArmor "True if this ammo type can shred armor, false otherwise";
var(AdvancedBallistics) config float MinimumMomentum "The minimum amount of momentum that this ammo type has, after drag";

// Fracture occurs when a bullet ricochets and splits into multiple pieces.
// These fractured projectiles deviate from the ricochet angle when they collide against each other. This is simulated by giving them some slop.
// Fractured projectiles lose a great deal more momentum than ricochet because the projectiles are much smaller in mass.
/*
var(Ricochet) config bool CanCauseFracture "Can this bullet be subject to fracturing?";
var(Ricochet) config float FractureChance "Chance (percent) that a bullet can fracture (instead of ricochet) upon impact. The roll is performed after ricochet (ricochet roll must succeed before fracture roll is considered)";
var(Ricochet) config int FractureMinProjectiles "Minimum number of fragments produced from a fracture";
var(Ricochet) config int FractureMaxProjectiles "Maximum number of fragments produced from a fracture";
var(Ricochet) config rotator FractureSlopAngleMin "Minimum angle that gets added to fracture bullets";
var(Ricochet) config rotator FractureSlopAngleMax "Maximum angle that gets added to fracture bullets";
var(Ricochet) config float FractureMomentumMin "Momentum is multiplied by a value between this and FractureMomentumLossMax for each fracture bullet";
var(Ricochet) config float FractureMomentumMax "Momentum is multiplied by a value between this and FractureMomentumLossMin for each fracture bullet";
var(Ricochet) config float FractureMinimumMomentum "Minimum momentum required to trigger a fracture";
*/

// Weight and bulk system for Ammunition
// For RoundBasedWeapon, you want WeightPerMagazine and BulkPerMagazine to be zero.
// For MagazineBasedWeapon, you want BulkPerRound to be zero.
var(CustomReloads) public config float WeightPerReloadLoaded "Amount of weight to add per reload";
var(CustomReloads) public config float WeightPerReloadUnloaded "Amount of weight that's in an unloaded reload (ClipBasedAmmo only)";
var(CustomReloads) public config float BulkPerReload "Amount of bulk to add per reload";
var(CustomReloads) public config int MinReloadsToCarry "Minimum number of reloads we should be carrying";
var(CustomReloads) public config int MaxReloadsToCarry "Maximum number of reloads we should be carrying";
var(CustomReloads) public localized config string ReloadsString "String to show in the Loadout panel (originally was 'Reloads:')";

////////////////////////////////////////////////////////////////////////////////
// Helper functions

simulated function bool ShouldRicochet() {
  local float Chance;
  Chance = FRand();
  BallisticsLog("ShouldRicochet(): Chance = "$Chance);
  if(CanCauseRicochet && Chance < RicochetChance) {
    return true;
  }
  return false;
}

simulated function float GetRicochetMomentumModifier() {
  return RicochetMomentum;
}

simulated function float GetDrag() {
  return Drag;
}

simulated function int GetPenetrationLevel() 
 {
   return ArmorPenetration;
 }
  
simulated function int GetPenetrationType() 
{			
 switch(ArmorPenetration) 
 {				
 case Level_0:
 	PenetrationType = 1;
 	break;
 case Level_1:
 	PenetrationType = 2;
 	break;
 case Level_2a:
 	PenetrationType = 3;
 	break;
 case Level_2:
 	PenetrationType = 4;
 	break;
 case Level_3a:
 	PenetrationType = 5;
 	break;
 case Level_3:
 	PenetrationType = 6;
 	break;
 case Level_3X:
 	PenetrationType = 7;
 	break;
 case Level_4:
 	PenetrationType = 8;
 	break;
 default:
 	PenetrationType = 1;
 }

  return PenetrationType;
}
 
simulated function bool CanShredArmor() {
  return ShredsArmor;
}

simulated function float GetMinimumMomentum()
{
  return MinimumMomentum;
}

////////////////////////////////////////////////////////////////////////////////
// Ricochet / Fracture check

simulated function bool CanRicochet(Actor Victim, vector HitLocation, vector HitNormal, vector NormalizedBulletDirection, Material HitMaterial, float Momentum, int BounceNumber)
{
  local EMaterialVisualType vType;
  local bool bCorrectMaterial;
  local float NormalizedMinimum;
  local float NormalizedMaximum;
  local float PitchNormal, YawNormal;
  local int i;

  BallisticsLog("checked if CanRicochet with Victim="$Victim$", HitLocation="$HitLocation$
    ", HitNormal="$HitNormal$
    ", NormalizedBulletDirection="$NormalizedBulletDirection$
    ", HitMaterialType="$HitMaterial.MaterialVisualType);

  if(!ShouldRicochet()) {
    BallisticsLog("Ammo "$self$" can't cause a ricochet or the roll failed.");
    return false;
  }

  if(RicochetFromBSPOnly && !Victim.IsA('LevelInfo') && !Victim.IsA('StaticMeshActor')) {
    BallisticsLog("RicochetFromBSPOnly was checked and not a LevelInfo or StaticMeshActor");
    return false;
  }

  if(Momentum < RicochetMinimumMomentum) {
    BallisticsLog("Does not meet minimum momentum to cause a ricochet");
    return false;
  }

  if(BounceNumber >= RicochetBounceCount) {
    BallisticsLog("RicochetBounceCount met");
    return false;
  }

  // Roll does not matter. We should be looking to see if ONE of the angles is within the range.
  NormalizedMinimum = Abs(MinRicochetAngle / 90.0);
  NormalizedMaximum = Abs(MaxRicochetAngle / 90.0);
  PitchNormal = Abs(NormalizedBulletDirection.x);
  YawNormal = Abs(NormalizedBulletDirection.y);
  if(PitchNormal > NormalizedMaximum || PitchNormal < NormalizedMinimum) {
    if(YawNormal > NormalizedMaximum || YawNormal < NormalizedMinimum) {
      BallisticsLog("Ricochet angle is not correct (PitchNormal: "$PitchNormal$"; YawNormal: "$YawNormal$")");
      return false;
    }
  }

  for(i = 0; i < RicochetMaterials.Length; i++) {
    vType = RicochetMaterials[i];
    if(vType == HitMaterial.MaterialVisualType) {
      bCorrectMaterial = true;
      break;
    }
  }

  if(!bCorrectMaterial) {
    BallisticsLog("Incorrect material to cause a ricochet.");
    return false;
  }

  BallisticsLog("Ricochet succeeded");
  return true;
}

////////////////////////////////////////////////////////////////////////////////
// Default properties

defaultproperties
{
  Drag=0
  
  BulletClass=AmmoType_Special
  CanCauseRicochet=false
  RicochetChance=0.5
  MinRicochetAngle=20
  MaxRicochetAngle=70
  RicochetFromBSPOnly=true
  RicochetBounceCount=3
  RicochetMomentum=0.5
}
