class LoadOutValidationBase extends Engine.Actor
implements IAmAffectedByWeight
    native
    perObjectConfig
    abstract;

import enum Pocket from Engine.HandheldEquipment;

enum MaterialPocket
{
    MATERIAL_Pants,
    MATERIAL_Face,
    MATERIAL_Name,
    MATERIAL_Vest,
    MATERIAL_HeavyPants,
    MATERIAL_HeavyVest,
	  MATERIAL_NoArmourVest,
};

// the loadout specification
var(DEBUG) config class<Actor> LoadOutSpec[Pocket.EnumCount];
var(DEBUG) config Material MaterialSpec[MaterialPocket.EnumCount];
var(DEBUG) config string CustomSkinSpec;

simulated function int GetPrimaryAmmoCount();
simulated function int GetSecondaryAmmoCount();

simulated function bool IsWeaponPrimary(FiredWeapon in) {
  if(in.class == LoadOutSpec[0]) {
    return true;
  }
  return false;
}

simulated function PrintLoadOutSpecToMPLog()
{
    local int i;

    log( "LoadOut "$self$" contains spec:" );

    for ( i = 0; i < Pocket.EnumCount; i++ )
    {
        log( "...LoadOutSpec["$GetEnum(Pocket,i)$"]="$LoadOutSpec[i] );
    }
    for ( i = 0; i < MaterialPocket.EnumCount; i++ )
    {
        log( "...MaterialSpec["$GetEnum(MaterialPocket,i)$"]="$MaterialSpec[i] );
    }
}


//Impose restrictions on loadoutspec based on other parts of the loadoutspec
//This assumes the input equipment has already been validated based on the game mode
function bool ValidForLoadoutSpec( class<actor> newEquip, Pocket pock )
{
    local class<FiredWeapon> Weap;
    local class OptiwandClass, AmmoBandolierClass, C2Class, PepperSprayClass;
    local int i;

    switch( pock )
    {
        case Pocket_PrimaryAmmo:
            Weap = class<FiredWeapon>( LoadOutSpec[Pocket.Pocket_PrimaryWeapon] );
            if( Weap == None )
            {
                return true;
            }

            for( i = 0; i < Weap.default.PlayerAmmoOption.Length; i++ )
            {
                if( DynamicFindObject(Weap.default.PlayerAmmoOption[i],class'class') == newEquip )
                    return true;
            }

            return false;
            break;
        case Pocket_SecondaryAmmo:
            Weap = class<FiredWeapon>( LoadOutSpec[Pocket.Pocket_SecondaryWeapon] );
            if( Weap == None )
            {
                return true;
            }

            for( i = 0; i < Weap.default.PlayerAmmoOption.Length; i++ )
            {
                if( DynamicFindObject(Weap.default.PlayerAmmoOption[i],class'class') == newEquip )
                    return true;
            }

            return false;
            break;
        case Pocket_EquipOne:
        case Pocket_EquipTwo:
        case Pocket_EquipThree:
        case Pocket_EquipFour:
        case Pocket_EquipFive:
        case Pocket_EquipSix:
            //ensure only 1 optiwand per loadout
            OptiwandClass = class(DynamicLoadObject("SwatEquipment.Optiwand",class'class'));
            if( ClassIsChildOf( newEquip, OptiwandClass ) )
            {
                for( i = Pocket.Pocket_EquipOne; i <= Pocket.Pocket_EquipSix; i++ )
                    if( pock != i && LoadOutSpec[i] != None && ClassIsChildOf( LoadOutSpec[i], OptiwandClass ) )
                        return false;
            }
            break;
    }
    return true;
}


////////////////////////////////////////////////////////////////////////////////
//
// IAmAffectedByWeight implementation

// Absolute bulk/weight - these determine how to scale weight and bulk
/*static var config float MinimumAbsoluteBulk;
static var config float MaximumAbsoluteBulk;
static var config float MinimumAbsoluteWeight;
static var config float MaximumAbsoluteWeight;

static var config float MinimumQualifyModifer;
static var config float MaximumQualifyModifier;
static var config float MinimumMovementModifier;
static var config float MaximumMovementModifier;*/

simulated function float GetMinimumQualifyModifer() {
  return /*MinimumQualifyModifer*/ 0.5;
}

simulated function float GetMaximumQualifyModifer() {
  return /*MaximumQualifyModifier*/ 2.0;
}

simulated function float GetMinimumMovementModifier() {
  return /*MinimumMovementModifier*/ 0.7;
}

simulated function float GetMaximumMovementModifier() {
  return /*MaximumMovementModifier*/ 1.3;
}

simulated function float GetMinimumBulk() {
  return /*MinimumAbsoluteBulk*/ 18.0;
}

simulated function float GetMinimumWeight() {
  return /*MinimumAbsoluteWeight*/ 5.0;
}

// Functions for getting the maximum amount of weight/bulk we can carry
simulated function float GetMaximumWeight() {
  return /*MaximumAbsoluteWeight*/ 35.0;
}

simulated function float GetMaximumBulk() {
  return /*MaximumAbsoluteBulk*/ 100.0;
}

simulated function float GetWeightPercentage() {
  return (GetTotalWeight() - GetMinimumWeight()) / (GetMaximumWeight() - GetMinimumWeight());
}

simulated function float GetBulkPercentage() {
  return (GetTotalBulk() - GetMinimumBulk()) / (GetMaximumBulk() - GetMinimumBulk());
}

function float GetTotalWeight() {
  assertWithDescription(false, "GetTotalWeight() called on LoadOutValidationBase. Don't do this; call it on a LoadOut or DynamicLoadOutSpec instead.");
  return 0.0;
}

function float GetTotalBulk() {
  assertWithDescription(false, "GetTotalBulk() called on LoadOutValidationBase. Don't do this; call it on a LoadOut or DynamicLoadOutSpec instead.");
  return 0.0;
}

function float GetWeightMovementModifier() {
  assertWithDescription(false, "GetWeightMovementModifier() called on LoadOutValidationBase. Don't do this; call it on a LoadOut or DynamicLoadOutSpec instead.");
  return 0.0;
}

function float GetBulkQualifyModifier() {
  assertWithDescription(false, "GetBulkQualifyModifier() called on LoadOutValidationBase. Don't do this; call it on a LoadOut or DynamicLoadOutSpec instead.");
  return 0.0;
}
