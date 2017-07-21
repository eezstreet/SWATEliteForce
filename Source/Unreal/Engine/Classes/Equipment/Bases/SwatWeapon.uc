class SwatWeapon extends FiredWeapon
    config(SwatEquipment);

/*
 * Describes which "equip type" a weapon is a part of.
 * This is pretty self-explanatory.
 */
enum WeaponEquipType
{
  WeaponEquip_PrimaryOnly,
  WeaponEquip_SecondaryOnly,
  WeaponEquip_Either
};

/*
 * Describes which "equip class" a weapon is a part of.
 * This determines the category of weapon for the GUI, nothing more.
 * If a class has no valid weapons for the slot, the category won't appear.
 */
enum WeaponEquipClass
{
  WeaponClass_AssaultRifle,             // Assault Rifles (M4, M16, AKM, etc.)
  WeaponClass_MarksmanRifle,            // Marksman Rifles (scoped rifles)
  WeaponClass_SubmachineGun,            // Submachine Guns (MP5, G36C, Uzi, etc.)
  WeaponClass_Shotgun,                  // Shotguns (M4, Nova, M870, BSG)
  WeaponClass_LightMachineGun,          // Light Machine Guns (M249 SAW)
  WeaponClass_MachinePistol,            // Machine Pistols; SMGs that don't have a stock (MP5K, TEC-9)
  WeaponClass_Pistol,                   // Pistols (Desert Eagle, M1911, Glock, ... but not tasers!)
  WeaponClass_LessLethal,               // Less-lethal shotguns, tasers, and pepperball
  WeaponClass_GrenadeLauncher,          // Grenade Launchers (ARWEN 37, HK69)
  WeaponClass_Uncategorized             // Not categorized! Find one!
};

/*
 * Determines what animation set the weapon should use while equipped.
 */
enum WeaponAimAnimationType
{
  WeaponAnimAim_Handgun,
  WeaponAnimAim_SubmachineGun,
  WeaponAnimAim_MachineGun,
  WeaponAnimAim_Shotgun,
  WeaponAnimAim_Grenade,
  WeaponAnimAim_TacticalAid,
  WeaponAnimAim_TacticalAidUse,
  WeaponAnimAim_PepperSpray,
  WeaponAnimAim_M4,
  WeaponAnimAim_UMP,
  WeaponAnimAim_P90,
  WeaponAnimAim_Optiwand,
  WeaponAnimAim_Paintball,
  WeaponAnimAim_Cuffed
};

enum WeaponLowReadyAnimationType
{
  WeaponAnimLowReady_Handgun,
  WeaponAnimLowReady_SubmachineGun,
  WeaponAnimLowReady_MachineGun,
  WeaponAnimLowReady_Shotgun,
  WeaponAnimLowReady_Grenade,
  WeaponAnimLowReady_TacticalAid,
  WeaponAnimLowReady_PepperSpray,
  WeaponAnimLowReady_M4,
  WeaponAnimLowReady_UMP,
  WeaponAnimLowReady_P90,
  WeaponAnimLowReady_Optiwand,
  WeaponAnimLowReady_Paintball
};

/*
 * Determines what animations the AI-controlled officers should use when idling
 */

enum EIdleWeaponStatus
{
	IdleWeaponDoesNotMatter,
  IdleWithSAW,
  IdleWithMachineGun,
	IdleWithG36,
	IdleWithSubMachineGun,
	IdleWithUMP,
  IdleWithHandgun,
	IdleWithShotgun,
	IdleWithPaintballGun,
	IdleWithGrenade,
  IdleWithP90,
	IdleWithAnyWeapon,
  IdleWithoutWeapon
};

/*
 * Determines what animations the AI-controlled officers should use when ordering compliance
 */

enum EComplianceWeaponAnimation
{
  Compliance_Machinegun,
  Compliance_Shotgun,
  Compliance_SubmachineGun,
  Compliance_CSBallLauncher,
  Compliance_Handgun
};

var(Firing) config int MagazineSize;
var(Firing) protected config float Choke "Mostly used for shotguns - specifies how spread apart bullets should be - applied after AimError";
var(Firing) config WeaponAimAnimationType AimAnimation;
var(Firing) config WeaponLowReadyAnimationType LowReadyAnimation;
var(Firing) config array<EIdleWeaponStatus> IdleWeaponCategory;
var(Firing) config EComplianceWeaponAnimation ComplianceAnimation;
var(Firing) protected config bool ShowCrosshairInIronsights "Whether to show the crosshair in ironsights";

// Manufacturer Information
var(AdvancedDescription) protected localized config string Manufacturer         "The Manufacturer in the Advanced Information panel (localized)";
var(AdvancedDescription) protected localized config string CountryOfOrigin      "The Country of Origin in the Advanced Information panel (localized)";
var(AdvancedDescription) protected localized config string ProductionStart      "The Production Start in the Advanced Information panel (localized)";
// Cartridge Information
var(AdvancedDescription) protected localized config string Caliber              "The Caliber in the Advanced Information panel (localized)";
var(AdvancedDescription) protected localized config string MagazineSizeString   "The Magazine Size in the Advanced Information panel - this needs to be defined separately since real magazine size is determined by ammo. Logical, right?";
var(AdvancedDescription) protected localized config string TotalAmmoString      "The Total Ammo in the Advanced Information panel - human friendly localized string";
// Action Information
var(AdvancedDescription) protected localized config string FireModes            "Human-readable firing mode string for Advanced Information panel (localized)";
// Muzzle velocity
var(AdvancedDescription) protected localized config string RateOfFire           "Human-readable RoF string for Advanced Information panel (localized)";

var(Categorization) public config WeaponEquipClass WeaponCategory            "Which category this weapon belongs to in the GUI.";
var(Categorization) public config WeaponEquipType AllowedSlots               "Which slots this weapon is allowed to be equipped in";

// New Damage Information
var(Damage) protected config float Vc0         "Muzzle Velocity of the weapon";
var(Damage) protected config float Vc1      "Diference between muzzle velocity and velocity at 50m ((Muzzle Velocity/Velocity at 50m)*-1)";
var(Damage) protected config float Vc2      "Last Velocity factor ((Velocity at 50m-(Muzzle Velocity+(Vc1*50m)))/(50m^2))";
var(Damage) protected config float Dc1      "Proportion between energy at 50m and muzzle velocity (Energy at 50m/(Muzzle Velocity*3.28084))";
var(Damage) protected config float Dc2      "Last damage factor ((Dc0-(Dc1*Velocity at 50m))/(Velocity at 50m^2))";
var(Damage) protected config bool bUsesBullets;

// Weight/bulk
var() public config float Weight;
var() public config float Bulk;

var config vector DefaultLocationOffset;
var config Rotator DefaultRotationOffset;
var config vector IronSightLocationOffset;
var config vector PlayerViewOffset;
var config Rotator IronSightRotationOffset;
var config Rotator PlayerViewRotation;
var config float ZoomedAimErrorModifier;
var config float ViewInertia;
var config float MaxInertiaOffset;

//a bit of a hack since we can't add vars to Hands.uc - K.F.
var float IronSightAnimationProgress;	//denotes position of weapon, in linear range where 0 = held at hip and 1 = fully aiming down sight
var array<vector> AnimationSplinePoints;

var bool bPenetratesDoors;

simulated function float GetWeight() {
  return Weight;
}

simulated function float GetBulk() {
  return Bulk;
}

simulated function float GetChoke()
{
  return Choke;
}

simulated function float GetVc0()
{
  return default.MuzzleVelocity / 50.4725;
}

simulated function float GetVc1()
{
  return Vc1;
}

simulated function float GetVc2()
{
  return Vc2;
}

simulated function float GetDc1()
{
  return Dc1;
}

simulated function float GetDc2()
{
  return Dc2;
}

simulated function bool ShouldHideCrosshairsInIronsights()
{
  return !ShowCrosshairInIronsights;
}

simulated function UpdateAmmoDisplay()
{
  Ammo.UpdateHUD();
}

static function string GetManufacturer()
{
    return "Manufacturer: "$default.Manufacturer;
}

static function string GetCaliber()
{
  return "Caliber: "$default.Caliber;
}

static function string GetCountryOfOrigin()
{
  return "Country of Origin: "$default.CountryOfOrigin;
}

static function string GetMagSize()
{
  if(default.MagazineSize != 0) {
    return "Magazine Size: "$string(default.MagazineSize);
  }
  return "Magazine Size: "$default.MagazineSizeString;
}

static function string GetProductionStart()
{
  return "Started Production: "$default.ProductionStart;
}

static function string GetFireModes()
{
  return "Fire Modes: "$default.FireModes;
}

static function string GetMuzzleVelocityString()
{
  // AK-47 has muzzle velocity (ingame) of 47,404 units and this is confirmed accurate
  // In reality it fires at 715 m/s (2,350 ft/s)
  // Therefore by multiplying by ~0.015 you can get meters and 0.05 for feet
  local int metersPerSecond, feetPerSecond;
  local string metersPerSecondStr, feetPerSecondStr;
  metersPerSecond = default.MuzzleVelocity / 50.4725;
  feetPerSecond = default.MuzzleVelocity / 15.385;
  metersPerSecondStr = string(metersPerSecond);
  feetPerSecondStr = string(feetPerSecond);

  return "Muzzle Velocity: "$feetPerSecondStr$" ft/s ("$metersPerSecondStr$" m/s)";
}

static function string GetRateOfFire()
{
  return "Rate of Fire: "$default.RateOfFire;
}

static function string GetTotalAmmoString()
{
  return "Maximum Ammo: "$default.TotalAmmoString;
}
simulated function BallisticFire(vector StartTrace, vector EndTrace)
{
	local vector HitLocation, HitNormal, ExitLocation, ExitNormal;
	local actor Victim;
    local Material HitMaterial, ExitMaterial; //material on object that was hit
    local float Momentum;
    local float Distance;
    local float LostVelocity;
    local float Velocity;
    local float KillEnergy;
    local int BulletType;
    local ESkeletalRegion HitRegion;

    Momentum = MuzzleVelocity * Ammo.Mass;
    BulletType = Ammo.GetBulletType();
    Distance = (VSize(HitLocation - StartTrace)) / 50.4725;
    Velocity = ((GetVc0()) + ((GetVc1()) * Distance)+((GetVc2()) * (Distance * Distance)));	
    KillEnergy = ((GetDc1()) * Velocity)+((GetDc2()) * (Velocity * Velocity));

    Ammo.BallisticsLog("BallisticFire(): Weapon "$name
        $", shot by "$Owner.name
        $", has MuzzleVelocity="$MuzzleVelocity
        $", Ammo "$Ammo.name
        $", Class "$BulletType
        $" has Mass="$Ammo.Mass
        $".  Initial Momentum is "$Momentum
        $".  Velocity is "$Velocity
        $".  Kill Energy is "$KillEnergy
        $".  Target is at "$Distance
        $"m.");

    foreach TraceActors(
        class'Actor',
        Victim,
        HitLocation,
        HitNormal,
        HitMaterial,
        EndTrace,
        StartTrace,
        /*optional extent*/,
        true, //bSkeletalBoxTest
        HitRegion,
        true,   //bGetMaterial
        true,   //bFindExitLocation
        ExitLocation,
        ExitNormal,
        ExitMaterial )
    {
//        Ammo.BallisticsLog("IMPACT: Momentum before drag: "$Momentum);
//        Momentum -= Ammo.GetDrag() * VSize(HitLocation - StartTrace);
//        Ammo.BallisticsLog("IMPACT: Momentum after drag: "$Momentum);

        if(Momentum < 0.0) {
          Ammo.BallisticsLog("Momentum went < 0. Not impacting with anything (LOST BULLET)");
          break;
        }

        //handle each ballistic impact until the bullet runs out of momentum and does not penetrate
        if (Ammo.CanRicochet(Victim, HitLocation, HitNormal, Normal(HitLocation - StartTrace), HitMaterial, Momentum, 0)) {
          // Do a ricochet
          DoBulletRicochet(Victim, HitLocation, HitNormal, Normal(HitLocation - StartTrace), HitMaterial, Momentum, KillEnergy, BulletType, 0);
          break;
        }
        else if (!HandleBallisticImpact(Victim, HitLocation, HitNormal, Normal(HitLocation - StartTrace), HitMaterial, HitRegion, Momentum, KillEnergy, BulletType, ExitLocation, ExitNormal, ExitMaterial))
            break;
    }
}

simulated function bool HandleBallisticImpact(
    Actor Victim,
    vector HitLocation,
    vector HitNormal,
    vector NormalizedBulletDirection,
    Material HitMaterial,
    ESkeletalRegion HitRegion,
    out float Momentum,
    out float KillEnergy,
    out int BulletType,
    vector ExitLocation,
    vector ExitNormal,
    Material ExitMaterial
    )
{
    local float MomentumToPenetrateVictim;
    local float MomentumLostToVictim;
    local vector MomentumVector;
    local bool PenetratesVictim;
    local int Damage;
    local float KillChance;
	local float RandomChance;
	local float LostVelocity;
    local SkeletalRegionInformation SkeletalRegionInformation;
    local ProtectiveEquipment Protection;
    local int ArmorLevel;
    local int BulletLevel;
    local float WoundChance;
    local float DamageModifier, ExternalDamageModifier;
    local float LimbInjuryAimErrorPenalty;
    local IHaveSkeletalRegions SkelVictim;
    local Pawn  PawnVictim;
	local PlayerController OwnerPC;
	
	BulletType = Ammo.GetBulletType();	
    ArmorLevel = Protection.GetProtectionType();
    BulletLevel = Ammo.GetPenetrationType();

    // You shouldn't be able to hit hidden actors that block zero-extent
    // traces (i.e., projectors, blocking volumes). However, the 'Victim'
    // when you hit BSP is LevelInfo, which is hidden, so we have to
    // handle that as a special case.
    if ((Victim.bHidden || Victim.DrawType == DT_None) && !(Victim.IsA('LevelInfo')))
    {
        Ammo.BallisticsLog("BallisticFire: Skipping bHidden=true Victim "$Victim.Name$" of class "$Victim.class.name);
        return true;    //penetrates, no damage or momentum lost
    }

    if (Victim.IsA('SwatDoor') || Victim.Owner.IsA('SwatDoor'))	//Handle this case on its own, because we dont wanna trigger the skeletal hit, we do that in the shotgun code
    {															//We also still wanna draw the decals
		return HandleDoorImpact(Victim, HitLocation, HitNormal, HitMaterial, ExitLocation, ExitNormal, ExitMaterial);
	}
	
	// officers don't hit other officers, or the player (unless we're attacking them)
	if (Owner.IsA('SwatOfficer') &&
		(Victim.IsA('SwatOfficer') || (Victim.IsA('SwatPlayer') && !Pawn(Owner).IsAttackingPlayer())))
	{
    Ammo.BallisticsLog("BallisticFire: Skipping Victim "$Victim.Name$" of class "$Victim.class.name$" because officers shouldn't hit other friendly officers/players");
		return false;   //friendly fire... blocked, no effects
	}

    // Some dynamic actors are not rendered due to the player's
    // detail settings being too low. In this case they should not block
    // bullets, to keep the visual experience consistent.
	if( (Victim.bHighDetail && Level.DetailMode == DM_Low)
         || (Victim.bSuperHighDetail && Level.DetailMode != DM_SuperHigh))
    {
        Ammo.BallisticsLog("BallisticFire: Skipping Victim "$Victim.Name$" of class "$Victim.class.name$
                " because Level.DetailMode="$GetEnum(EDetailMode, Level.DetailMode)$
                " and Victim.bHighDetail="$Victim.bHighDetail$
                " and Victim.bSuperHighDetail="$Victim.bSuperHighDetail);
        return true;    //penetrates, no damage or momentum lost
    }

    //play effects at the point of impact
    Ammo.SetLocation(HitLocation);
    Ammo.SetRotation(rotator(HitNormal));

    // Normal TraceActors() collection of material doesn't work quite right for
    // skeletal meshes, so we call this helper function to get the material manually.
    if (Victim.DrawType == DT_Mesh)
    {
        HitMaterial = Victim.GetCurrentMaterial(0); // get skin at first index
        ExitMaterial = HitMaterial;
		
        //if the Victim has skeletal regions, do some more work
        if (HitRegion != REGION_None && Victim.IsA('IHaveSkeletalRegions'))
        {
            //if the Victim is protected at the impacted region then handle an impact with ProtectiveEquipment

            if (Victim.IsA('ICanUseProtectiveEquipment'))
            {
                SkeletalRegionInformation = ICanUseProtectiveEquipment(Victim).GetSkeletalRegionInformation(HitRegion);
                Protection = ICanUseProtectiveEquipment(Victim).GetSkeletalRegionProtection(HitRegion);

                if (Protection != None)
                {
                    Ammo.TriggerEffectEvent('BulletHit', Protection, HitMaterial);
                    if (!HandleProtectiveEquipmentBallisticImpact(
                                Victim,
                                Protection,
                                HitRegion,
                                HitLocation,
                                HitNormal,
                                NormalizedBulletDirection,
                                Momentum,
                                KillEnergy,
                                BulletType,
								ArmorLevel,
								BulletLevel))
                        return false;   //blocked by ProtectiveEquipment
                }
            }
        }
    }

    if (HitMaterial == None) // weird situation, should trigger FX but not block the bullet (or should it?)
    {
        Ammo.BallisticsLog("[WARNING!!] BallisticFire: Trace hit Victim "$Victim$" of class "$Victim.class.name$", HitMaterial is None, treating as if no momentum required to penetrate.");
        MomentumLostToVictim = 0;
    }
    else
    if (Victim.class.name == 'LevelInfo' || Ammo.RoundsNeverPenetrate)
    {
        MomentumToPenetrateVictim = Momentum;
        MomentumLostToVictim = Momentum;
    }
    else
    {
        MomentumToPenetrateVictim = Victim.GetMomentumToPenetrate(HitLocation, HitNormal, HitMaterial);
        MomentumLostToVictim = FMin(Momentum, MomentumToPenetrateVictim);
    }

    //the bullet will penetrate the victim unles it loses all of its momentum to the victim
    PenetratesVictim = (MomentumLostToVictim < Momentum);

    //calculate damage imparted to victim
    Damage = MomentumLostToVictim * Level.GetRepo().MomentumToDamageConversionFactor;

    //calculate momentum vector imparted to victim
    MomentumVector = NormalizedBulletDirection * MomentumLostToVictim;
    if (PenetratesVictim)
        MomentumVector *= Level.getRepo().MomentumImpartedOnPenetrationFraction;

    //consider adding internal damage
    if (!PenetratesVictim)
        Damage += Ammo.InternalDamage;

    //apply any external damage modifiers (maintained by the Repo)
    ExternalDamageModifier = Level.GetRepo().GetExternalDamageModifier( Owner, Victim );
    Damage = int( float(Damage) * ExternalDamageModifier );

	// damage pawns
    PawnVictim = Pawn(Victim);
    if (Damage <= 0 && SkeletalRegionInformation != None && PawnVictim != None)    
	{
		Damage = 0;
    }
    if(SkeletalRegionInformation != None && PawnVictim != None && bUsesBullets)
    {
		
		// dbeswick: stats
		OwnerPC = PlayerController(Pawn(Owner).Controller);
		if (OwnerPC != None)
		{
			OwnerPC.Stats.Hit(class.Name, PlayerController(PawnVictim.Controller));
		}
		
        // Give chances based on the part hit
        if (HitRegion == REGION_Head)
        WoundChance = 1;
		
        if (HitRegion == REGION_Torso)
			{
			switch(BulletType) 
				{
				case 1:
					WoundChance = 175;
					break;
				case 2:
					WoundChance = 150;
					break;
				case 3:
					WoundChance = 125;
					break;
				case 4:
					WoundChance = 100;
					break;
				case 5:
				case 6:
				case 7:
					WoundChance = 100;
					break;
				default:
					WoundChance = 100;
				}
			}
			
        if ((HitRegion == REGION_LeftArm || HitRegion == REGION_RightArm))
        WoundChance = 950;
        if ((HitRegion == REGION_LeftLeg || HitRegion == REGION_RightLeg))
        WoundChance = 500;
		
		//Reset damage First
		Damage = 0;	
		
		log( "Initiating damage system" );
		do
		{	
			KillChance = 1 - (WoundChance / KillEnergy);
			RandomChance = 1.0 - FRand();
			log( "The KillEnergy is " $ KillEnergy );
			log( "The KillChance is " $ KillChance );
			log( "The RandomChance is " $ RandomChance );
			if (KillChance <= 0.10)    
			{
					KillChance = 0.10;
			}
			if (RandomChance < KillChance)    
			{
					Damage += 15;
					log( "Victim is wounded. Adding 15 damage points. Actual Damage points are " $ Damage );
			}			
			else    
			{
					Damage += 5;
					log( "Victim is not wounded. Adding 5 damage point. Actual Damage points are " $ Damage );
			}
			KillEnergy = KillEnergy - WoundChance;
		}		 
			until( KillEnergy <= 0 || RandomChance > KillChance);
			log( "Stopping, RandomChance is higher than kill chance");	
			log( "Final damage is " $ Damage );		
    }
    if( Damage > 0 && SkeletalRegionInformation != None && PawnVictim != None)
    {
		// dbeswick: stats
		OwnerPC = PlayerController(Pawn(Owner).Controller);
		if (OwnerPC != None)
		{
			OwnerPC.Stats.Hit(class.Name, PlayerController(PawnVictim.Controller));
		}
	if(!bUsesBullets)
		{
		DamageModifier = RandRange(SkeletalRegionInformation.DamageModifier.Min, SkeletalRegionInformation.DamageModifier.Max);

        // Give the weapon the chance to override arm specific damage...
        if ( OverrideArmDamageModifier != 0 && (HitRegion == REGION_LeftArm || HitRegion == REGION_RightArm)  )
            DamageModifier = OverrideArmDamageModifier;
        Damage *= DamageModifier;
		}

        LimbInjuryAimErrorPenalty = RandRange(SkeletalRegionInformation.AimErrorPenalty.Min, SkeletalRegionInformation.AimErrorPenalty.Max);
        PawnVictim.AccumulatedLimbInjury += LimbInjuryAimErrorPenalty;
    }

#if IG_EFFECTS
    //don't play hit effects on the sky
    if (HitMaterial == None || HitMaterial.MaterialVisualType != MVT_Sky)
    {
        if (Damage <= 0)
            Ammo.AddContextForNextEffectEvent('NoDamage');
        Ammo.TriggerEffectEvent('BulletHit', Victim, HitMaterial);
    }
#endif // IG_EFFECTS

    Ammo.BallisticsLog("  ->  Remaining Momentum is "$Momentum$". Bullet hit Victim "$Victim.name);

    if (HitMaterial != None)
        Ammo.BallisticsLog("  ... HitMaterial = "$HitMaterial);
    else
        Ammo.BallisticsLog("  ... HitMaterial = None");

    Ammo.BallisticsLog("  ... MomentumToPenetrateVictim is "$MomentumToPenetrateVictim$", so the bullet will lose "$MomentumLostToVictim$" momentum to the Victim.");

    if ( HitRegion != REGION_None && Victim.IsA( 'IHaveSkeletalRegions' ) )
    {
        Ammo.BallisticsLog("  ... Victim has SkeletalRegions.  "$GetEnum(ESkeletalRegion, HitRegion)$" was hit.");
        if (Protection != None)
            Ammo.BallisticsLog("  ... (Region is protected by "$Protection.class.name$".)");
        if ( OverrideArmDamageModifier != 0 && (HitRegion == REGION_LeftArm || HitRegion == REGION_RightArm) )
        {
            Ammo.BallisticsLog("  ... DamageModifier from the skeletal region was overriden for this arm hit, the OverrideArmDamageModifier is: "
                $OverrideArmDamageModifier);
        }
        else
        {
	            Ammo.BallisticsLog("  ... DamageModifier from the skeletal region is on the Range (Min="$SkeletalRegionInformation.DamageModifier.Min
                $", Max="$SkeletalRegionInformation.DamageModifier.Max
                $"), Selected "$DamageModifier
                $".");
        }
        Ammo.BallisticsLog("  ... ExternalDamageModifier = "$ExternalDamageModifier
            $".");
        Ammo.BallisticsLog("  ... AimErrorPenalty in on Range (Min="$SkeletalRegionInformation.AimErrorPenalty.Min
            $", Max="$SkeletalRegionInformation.AimErrorPenalty.Max
            $"), Selected "$LimbInjuryAimErrorPenalty
            $".");

        if (PenetratesVictim)
            Ammo.BallisticsLog("  ... Victim was penetrated:          Damage = MomentumLostToVictim * MomentumToDamageConversionFactor * DamageModifier * ExternalDamageModifier = "$MomentumLostToVictim
                $" * "$Level.GetRepo().MomentumToDamageConversionFactor
                $" * "$DamageModifier
                $" * "$ExternalDamageModifier
                $" = "$Damage);
        else
            Ammo.BallisticsLog("  ... Bullet was buried in Victim:    Damage = ((MomentumLostToVictim * MomentumToDamageConversionFactor) + InternalDamage) * DamageModifier * ExternalDamageModifier = (("$MomentumLostToVictim
                $" * "$Level.GetRepo().MomentumToDamageConversionFactor
                $") + "$Ammo.InternalDamage
                $") * "$DamageModifier
                $" * "$ExternalDamageModifier
                $" = "$Damage);
    }
    else
    {
        if (PenetratesVictim)
            Ammo.BallisticsLog("  ... Victim was penetrated:          Damage = MomentumLostToVictim * MomentumToDamageConversionFactor = "$MomentumLostToVictim
                $" * "$Level.GetRepo().MomentumToDamageConversionFactor
                $" = "$Damage);
        else
            Ammo.BallisticsLog("  ... Bullet was buried in Victim:    Damage = (MomentumLostToVictim * MomentumToDamageConversionFactor) + InternalDamage = ("$MomentumLostToVictim
                $" * "$Level.GetRepo().MomentumToDamageConversionFactor
                $") + "$Ammo.InternalDamage
                $" = "$Damage);
    }

    // If it's something with skeletal regions, do notification
    // We check this using a separate variable to avoid accessed nones
    // every time bsp or a static mesh is hit
    SkelVictim = IHaveSkeletalRegions(Victim);
    if (SkelVictim != None)
        SkelVictim.OnSkeletalRegionHit(HitRegion, HitLocation, HitNormal, Damage, GetDamageType(), Owner);

    DealDamage(Victim, Damage, Pawn(Owner), HitLocation, MomentumVector, GetDamageType());

    Ammo.BallisticsLog("  ... Bullet will impart to victim the momentum it lost to the victim:  "$VSize(MomentumVector)$" in direction "$Normal(MomentumVector));

    Victim.TakeHitImpulse(HitLocation, MomentumVector, GetDamageType());

    //the bullet has lost momentum to its victim
    Momentum -= MomentumLostToVictim;


#if IG_EFFECTS
    if (PenetratesVictim)
    {
        Ammo.SetLocation( ExitLocation );
        Ammo.SetRotation( rotator(ExitNormal) );

        Ammo.TriggerEffectEvent('BulletExited', Victim, ExitMaterial);
    }

    if ( ShouldSpawnBloodForVictim( PawnVictim, Damage ) )
        SpawnBloodEffects( Ammo, ExitLocation, Damage, NormalizedBulletDirection );
#endif // IG_EFFECTS
    return PenetratesVictim;
}

//returns true iff the bullet penetrates the ProtectiveEquipment
simulated function bool HandleProtectiveEquipmentBallisticImpact(
    Actor Victim,
    ProtectiveEquipment Protection,
    ESkeletalRegion HitRegion,
    vector HitLocation,
    vector HitNormal,
    vector NormalizedBulletDirection,
    out float Momentum,
    out float KillEnergy,
    out int BulletType,
    int ArmorLevel,
    int BulletLevel
	)
{
    local bool PenetratesProtection;
    local vector MomentumVector;
    local int Damage;
	local float LostVelocity;
    local float KillChance;
	local float RandomChance;
    local float WoundChance;
    local float MomentumLostToProtection;
    local Object.Range DamageModifierRange;
    local float DamageModifier, ExternalDamageModifier;
	
    ArmorLevel = Protection.GetProtectionType();
    BulletLevel = Ammo.GetPenetrationType();

    //the bullet will penetrate the protection unles it loses all of its momentum to the protection
	//Now it will penetrate if the bullet is designed to penetrate
	//   PenetratesProtection = (Protection.GetMtP() < Momentum);
   PenetratesProtection = (BulletLevel >= ArmorLevel);

    //determine DamageModifierRange
    if (PenetratesProtection)
        DamageModifierRange = Protection.PenetratedDamageFactor;
    else
        DamageModifierRange = Protection.BlockedDamageFactor;

    //calculate damage imparted to victim
	
    MomentumLostToProtection = FMin(Momentum, Protection.GetMtP());		
    Damage = MomentumLostToProtection * Level.GetRepo().MomentumToDamageConversionFactor;  
	
	if(Damage > 0 && bUsesBullets)
		{
		if (HitRegion == REGION_Head)
			{
			if (BulletLevel > ArmorLevel)
				WoundChance = 1;
			if (BulletLevel == ArmorLevel)
				WoundChance = 100;
			else
				WoundChance = 400;
			}
		if (HitRegion == REGION_Torso)
			{
			if (BulletLevel > ArmorLevel)
				WoundChance = 100;
			if (BulletLevel == ArmorLevel)
				WoundChance = 400;
			else
				WoundChance = 1750;
			}
		//Reset damage First
		Damage = 0;	
			
		log( "Initiating damage system" );
		do
		{
			KillChance = 1 - (WoundChance / KillEnergy);
			RandomChance = 1.0 - FRand();
			log( "The KillEnergy is " $ KillEnergy );
			log( "The KillChance is " $ KillChance );
			log( "The RandomChance is " $ RandomChance );
			if (KillChance <= 0.10)    
			{
					KillChance = 0.10;
			}
			if (RandomChance < KillChance)    
			{
					Damage += 10;
					log( "Victim is wounded. Adding 10 damage points. Actual Damage points are " $ Damage );
			}			
			else    
			{
					Damage += 5;
					log( "Victim is not wounded. Adding 5 damage point. Actual Damage points are " $ Damage );
			}
			KillEnergy = KillEnergy - WoundChance;
		}		 
			until( KillEnergy <= 0 || RandomChance > KillChance);
			log( "Stopping, RandomChance is higher than kill chance");	
			log( "Final damage is " $ Damage );					
	}

	if(!bUsesBullets)
		{
			DamageModifier = RandRange(DamageModifierRange.Min, DamageModifierRange.Max);
			Damage *= DamageModifier;				
		}

    //apply any external damage modifiers (maintained by the Repo)
    ExternalDamageModifier = Level.GetRepo().GetExternalDamageModifier( Owner, Victim );
    Damage = int( float(Damage) * ExternalDamageModifier );

    //calculate momentum vector imparted to victim
    MomentumVector = NormalizedBulletDirection * Protection.GetMtP();
    if (PenetratesProtection)
        MomentumVector *= Level.getRepo().MomentumImpartedOnPenetrationFraction;

    Ammo.BallisticsLog("  ->  Remaining Momentum is "$Momentum$".");
    Ammo.BallisticsLog("  ->  Remaining KillEnergy is "$KillEnergy$".");
    Ammo.BallisticsLog("  ... Bullet hit "$Protection.class.name$" ProtectiveEquipment on Victim "$Victim.name);
    Ammo.BallisticsLog("  ... Protection.MomentumToPenetrate is "$Protection.GetMtP()$".");
    Ammo.BallisticsLog("  ... Protection.ArmorLevel is "$ArmorLevel$".");
    Ammo.BallisticsLog("  ... Ammo.BulletLevel is "$BulletLevel$".");

    if (PenetratesProtection)
        Ammo.BallisticsLog("  ... The ProtectiveEquipment was penetrated.  Using PenetratedDamageFactor.");
    else
        Ammo.BallisticsLog("  ... Bullet was buried in the ProtectiveEquipment  Using BlockedDamageFactor.");

    Ammo.BallisticsLog("  ... DamageModifier is on the Range (Min="$DamageModifierRange.Min$", Max="$DamageModifierRange.Max$"), selected "$DamageModifier$".");
    Ammo.BallisticsLog("  ... ExternalDamageModifier = "$ExternalDamageModifier$".");

    Ammo.BallisticsLog("  ... Damage = MomentumLostToProtection * MomentumToDamageConversionFactor * DamageModifier * ExternalDamageModifier = "$MomentumLostToProtection
        $" * "$Level.GetRepo().MomentumToDamageConversionFactor
        $" * "$DamageModifier
        $" * "$ExternalDamageModifier
        $" = "$Damage);

    IHaveSkeletalRegions(Victim).OnSkeletalRegionHit(HitRegion, HitLocation, HitNormal, Damage, GetDamageType(), Owner);

    DealDamage(Victim, Damage, Pawn(Owner), HitLocation, MomentumVector, GetDamageType());

    //the bullet has lost momentum to its target
    Momentum -= Protection.GetMtP();

    if(Ammo.CanShredArmor()) {
      Protection.OnProtectedRegionHit();
    }

    return PenetratesProtection;
}

 
simulated function bool HandleDoorImpact(
    Actor Victim,
    vector HitLocation,
    vector HitNormal,
    Material HitMaterial,
    vector ExitLocation,
    vector ExitNormal,
    Material ExitMaterial
    )
{
	Ammo.SetLocation(HitLocation);
	Ammo.SetRotation(rotator(HitNormal));
	Ammo.TriggerEffectEvent('BulletHit', None, HitMaterial);

	Ammo.SetLocation( ExitLocation );
    Ammo.SetRotation( rotator(ExitNormal) );
    Ammo.TriggerEffectEvent('BulletExited', Victim, ExitMaterial);
	return bPenetratesDoors;
}

static function WeaponEquipClass GetEquipClass()
{
  return default.WeaponCategory;
}

static function WeaponEquipType GetEquipType()
{
  return default.AllowedSlots;
}

function WeaponAimAnimationType GetAimAnimation()
{
  return AimAnimation;
}

function WeaponLowReadyAnimationType GetLowReadyAnimation()
{
  return LowReadyAnimation;
}

function bool ValidIdleCategory(EIdleWeaponStatus DesiredStatus)
{
  local int i;

  for(i = 0; i < IdleWeaponCategory.Length; i++)
  {
    if(IdleWeaponCategory[i] == DesiredStatus)
    {
      return true;
    }
  }
  return false; // This isn't a valid idle category for this weapon
}

simulated function vector GetDefaultLocationOffset()
{
    return DefaultLocationOffset;
}

simulated function Rotator GetDefaultRotationOffset()
{
    return DefaultRotationOffset;
}

simulated function vector GetIronsightsLocationOffset()
{
    return IronSightLocationOffset;
}

simulated function Rotator GetIronsightsRotationOffset()
{
    return IronSightRotationOffset;
}

simulated function float GetViewInertia()
{
	return ViewInertia;
}

simulated function float GetMaxInertiaOffset()
{
	return MaxInertiaOffset;
}

simulated function float GetIronSightAnimationProgress()
{
	return IronSightAnimationProgress;
}

simulated function SetIronSightAnimationProgress(float value)
{
	if (value < 0) value = 0;
	if (value > 1) value = 1;
	IronSightAnimationProgress = value;
}

simulated function array<vector> GetAnimationSplinePoints()
{
	return AnimationSplinePoints;
}
simulated function AddAnimationSplinePoint(vector value)
{
	AnimationSplinePoints.Insert(AnimationSplinePoints.Length, 1);
	AnimationSplinePoints[AnimationSplinePoints.Length - 1] = value;
	if (AnimationSplinePoints.Length > 4)
	{
		AnimationSplinePoints.Remove(0, 1);
	}
}

simulated function float GetBaseAimError()
{
	local float BaseAimError;
	local Pawn OwnerPawn;
	local PlayerController OwnerController;

	BaseAimError = super.GetBaseAimError();

	OwnerPawn = Pawn(Owner);

	if (OwnerPawn!= None)
	{
		OwnerController = PlayerController(OwnerPawn.Controller);

		if (OwnerController != None && OwnerController.WantsZoom)
		{
			return BaseAimError * ZoomedAimErrorModifier;
		}
	}

	return BaseAimError;
}

simulated function UpdateAimError(float dTime)
{
    local float AimErrorRecoveryRate;
    local float TargetAimError;
	local Pawn OwnerPawn;
	local PlayerController OwnerController;

    //target aim error is state-based error plus event-based penalties
    TargetAimError = GetBaseAimError() + PendingAimErrorPenalty;
	
	OwnerPawn = Pawn(Owner);
	
	if (OwnerPawn!= None)
	{
		OwnerController = PlayerController(OwnerPawn.Controller);
		
		if (OwnerController != None && OwnerController.WantsZoom)
		{		
			if (AimError > TargetAimError)
			{
				//determine recovery rate, which depends on how bad our accuracy is now
				if (AimError > AimErrorBreakingPoint)
					AimErrorRecoveryRate = LargeAimErrorRecoveryRate / ZoomedAimErrorModifier;
				else
					AimErrorRecoveryRate = SmallAimErrorRecoveryRate / ZoomedAimErrorModifier;

				//recover accuracy over time
				AimError = FMax(TargetAimError, AimError - dTime * AimErrorRecoveryRate);
			}
			else 	
			{
				//current aim error should be at least target aim error
				AimError = FMax(TargetAimError, AimError);
			}
		}
		else
		{		
			if (AimError > TargetAimError)
			{
				//determine recovery rate, which depends on how bad our accuracy is now
				if (AimError > AimErrorBreakingPoint)
					AimErrorRecoveryRate = LargeAimErrorRecoveryRate;
				else
					AimErrorRecoveryRate = SmallAimErrorRecoveryRate;

				//recover accuracy over time
				AimError = FMax(TargetAimError, AimError - dTime * AimErrorRecoveryRate);
			}
			else 	
			{
				//current aim error should be at least target aim error
				AimError = FMax(TargetAimError, AimError);
			}
		}
	}
//    log("[AIM] Updated AimError="$AimError);

    //clear event-based penalties which are applied once
    PendingAimErrorPenalty = 0;
}

// Sticky selection: if this item is equipped, then we switch to a grenade, then use a grenade, it switches to this item
simulated function bool HasStickySelection()
{
  return true;
}

simulated function EquippedHook()
{
  local Pawn OwnerPawn;
  local PlayerController OwnerController;

  Super.EquippedHook();

  OwnerPawn = Pawn(Owner);
  if(OwnerPawn != None && HasStickySelection())
  {
    OwnerController = PlayerController(OwnerPawn.Controller);
    if(OwnerController != None)
    {
      if(GetPocket() == Pocket.Pocket_SecondaryWeapon)
      {
        OwnerController.bSecondaryWeaponLast = true;
      }
      else
      {
        OwnerController.bSecondaryWeaponLast = false;
      }
    }
  }

}

//simulated function UnEquippedHook();  //TMC do we want to blank the HUD's ammo count?

defaultproperties
{
  Manufacturer="Unknown"
  Caliber="Unknown"
  CountryOfOrigin="Unknown"
  MagazineSize=0
  ProductionStart="Unknown"
  FireModes="Unknown"
  MagazineSizeString="Unknown"
  RateOfFireString="Not Applicable"
  TotalAmmoString="Unknown"
  Choke = 0.0
  Slot=Slot_Invalid
  bPenetratesDoors=true
  ZoomedAimErrorModifier = 0.75
  ComplianceAnimation=Compliance_Handgun
}
