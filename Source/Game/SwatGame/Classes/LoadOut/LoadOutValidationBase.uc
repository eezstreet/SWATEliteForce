class LoadOutValidationBase extends Engine.Actor
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
            //ensure only 1 optiwand per loadout
            OptiwandClass = class(DynamicLoadObject("SwatEquipment.Optiwand",class'class'));
            if( ClassIsChildOf( newEquip, OptiwandClass ) )
            {
                for( i = Pocket.Pocket_EquipOne; i <= Pocket.Pocket_EquipFive; i++ )
                    if( pock != i && LoadOutSpec[i] != None && ClassIsChildOf( LoadOutSpec[i], OptiwandClass ) )
                        return false;
            }

            //ensure only 1 pepper spray per loadout
            PepperSprayClass = class(DynamicLoadObject("SwatEquipment.PepperSpray", class'class'));
            if( ClassIsChildOf(newEquip, PepperSprayClass)) {
              for( i = Pocket.Pocket_EquipOne; i <= Pocket.Pocket_EquipFive; i++ )
                  if( pock != i && LoadOutSpec[i] != None && ClassIsChildOf( LoadOutSpec[i], AmmoBandolierClass ) )
                      return false;
            }

			      //ensure only 1 ammo bandolier per loadout
            AmmoBandolierClass = class(DynamicLoadObject("SwatEquipment.AmmoBandolier",class'class'));
            if( ClassIsChildOf( newEquip, AmmoBandolierClass ) )
            {
                for( i = Pocket.Pocket_EquipOne; i <= Pocket.Pocket_EquipFive; i++ )
                    if( pock != i && LoadOutSpec[i] != None && ClassIsChildOf( LoadOutSpec[i], AmmoBandolierClass ) )
                        return false;
            }
            break;
        case Pocket_HiddenC2Charge1:
        case Pocket_HiddenC2Charge2:
            C2Class = class(DynamicLoadObject("SwatEquipment.C2Charge",class'class'));
            // if class is C2, ensure Pocket_Breaching contains a C2
            if( ClassIsChildOf( newEquip, C2Class ) )
            {
                if( LoadOutSpec[Pocket.Pocket_Breaching] == None ||
                    !ClassIsChildOf( LoadOutSpec[Pocket.Pocket_Breaching], C2Class ) )
                    return false;
            }
            else if( newEquip != None ) //if not C2 or None, then this is not valid
                return false;
    }
    return true;
}
