class LoadOut extends LoadOutValidationBase
    native
    abstract
    perObjectConfig
    dependsOn(SwatEquipmentSpec)
    Config(StaticLoadout);

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;
import enum eEquipmentType from SwatGame.SwatEquipmentSpec;
import enum eNetworkValidity from SwatGame.SwatGUIConfig;
import enum eTeamValidity from SwatGame.SwatGUIConfig;

// The Actual Equipment
var(DEBUG) protected Actor PocketEquipment[Pocket.EnumCount];

// Cached reference to the GuiConfig
var(DEBUG) SwatGUIConfig GC;

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Completely initialize a loadout.  The procedure is as follows:
//
// - Replace any static spec data with valid Dynamic spec data
// - Validate entire loadout.  Replace any invalid equipment with the pocket's defaults
// - Spawn the equipment from the LoadoutSpec
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated function Initialize(DynamicLoadOutSpec DynamicSpec, bool IsSuspect)
{
    GC = SwatRepo(level.GetRepo()).GuiConfig;
    Assert( GC != None );

 	if (Level.GetEngine().EnableDevTools)
	    log(self.Name$" >>> Initialize( "$DynamicSpec$" )");

	mplog(self.Name$" >>> Initialize("$DynamicSpec$")");

//     if( DynamicSpec != None )
//     {
//         log(self.Name$" ... Dynamic Loadout spec:");
//         DynamicSpec.PrintLoadOutSpecToMPLog();
//     }

//     log(self.Name$" ... Static Loadout spec:");
//     PrintLoadOutSpecToMPLog();

    if( DynamicSpec != None )
    {
        MutateLoadOutSpec( DynamicSpec, IsSuspect );
		mplog(self.name$"...MutateLoadOutSpec");
        //log(self.Name$" ... After mutation:");
        //PrintLoadOutSpecToMPLog();
    }

    ValidateLoadOutSpec(IsSuspect, DynamicSpec);
	mplog(self.name$"...ValidateLoadOutSpec");

    //log(self.Name$" ... After validation:");
    //PrintLoadOutSpecToMPLog();

    SpawnEquipmentFromLoadOutSpec(DynamicSpec);
	mplog(self.name$"...SpawnEquipmentFromLoadOutSpec");

    //log(self.Name$" ... Spawned equipment:");
    //PrintLoadOutToMPLog();
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Mutate the static loadout with the given dynamic loadout.
//      Ignore any invalid equipment in the dynamic loadout
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated protected function MutateLoadOutSpec(DynamicLoadOutSpec DynamicSpec, bool IsSuspect)
{
    local int i;

    // The VIP may have no dynamic part, and, in cases like that, no mutation
    // is necessary.
    if ( DynamicSpec == None )
        return;

    for( i = 0; i <= Pocket.Pocket_Toolkit; i++ )
    {
        if( ValidateEquipmentForPocket( Pocket(i), DynamicSpec.LoadOutSpec[i] ) &&
            DynamicSpec.ValidForLoadoutSpec( DynamicSpec.LoadOutSpec[i], Pocket(i) ) )
		{
			LoadOutSpec[i] = DynamicSpec.LoadOutSpec[i];
		}
        else
        {
            warn("Dynamic LoadOut is invalid: Failed to validate equipment class "$DynamicSpec.LoadOutSpec[i]$" specified for pocket "$GetEnum( Pocket, i )$" in DyanicSpec "$DynamicSpec.name );
            AssertWithDescription( false, self.Name$":  Failed to validate equipment class "$DynamicSpec.LoadOutSpec[i]$" specified for pocket "$GetEnum( Pocket, i )$" in DyanicSpec "$DynamicSpec.name);
        }
    }

    for( i = 0; i < MaterialPocket.EnumCount; i++ )
    {
        if( DynamicSpec.MaterialSpec[i] != None )
            MaterialSpec[i] = DynamicSpec.MaterialSpec[i];
    }

	CustomSkinSpec = DynamicSpec.CustomSkinSpec;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Validate the final loadout spec.
//      Replace any invalid equipment in the loadout spec with the defaults for that pocket.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated function bool ValidateLoadOutSpec(bool IsSuspect, DynamicLoadoutSpec DynamicSpec)
{
    local int i;
    local class<SwatAmmo> PrimaryAmmo;
    local class<SwatAmmo> SecondaryAmmo;

    // Check to make sure that we're bringing along the minimum ammo for primary and secondary weapons
    PrimaryAmmo = class<SwatAmmo>(LoadOutSpec[1]);
    SecondaryAmmo = class<SwatAmmo>(LoadOutSpec[3]);

	mplog(self.name$"...ValidateLoadOutSpec...");
    if(DynamicSpec.GetPrimaryAmmoCount() < PrimaryAmmo.default.MinReloadsToCarry) {
      DynamicSpec.SetPrimaryAmmoCount(PrimaryAmmo.default.MinReloadsToCarry);
    }
    if(DynamicSpec.GetSecondaryAmmoCount() < SecondaryAmmo.default.MinReloadsToCarry) {
      DynamicSpec.SetSecondaryAmmoCount(SecondaryAmmo.default.MinReloadsToCarry);
    }

	mplog(self.name$"...ValidateLoadOutSpec::SetPrimary/SecondaryAmmo counts");
    if(GetTotalWeight() > GetMaximumWeight() || GetTotalBulk() > GetMaximumBulk()) {
      // We are overweight. We need to completely respawn our gear from scratch.
      AssertWithDescription(false, "Loadout "$self$" exceeds maximum weight. It's getting reset to the default equipment.");
      for(i = 0; i < Pocket.EnumCount; i++) {
        LoadOutSpec[i] = DLOClassForPocket(Pocket(i), 0);

        //also replace with default for dependent pocket if valid
  			if( GC.AvailableEquipmentPockets[i].DependentPocket != Pocket_Invalid )
  				LoadOutSpec[GC.AvailableEquipmentPockets[i].DependentPocket] = DLOClassForPocket(GC.AvailableEquipmentPockets[i].DependentPocket, 0 );
      }
      return true;
    }
	mplog(self.name$"...ValidateLoadOutSpec: checked max weight");

    for( i = 0; i < Pocket.EnumCount; i++ )
    {
		    if( i == Pocket.Pocket_CustomSkin )
		    {
			     ValidatePocketCustomSkin(IsSuspect);
			     continue;
		    }

        if( !ValidateEquipmentForPocket( Pocket(i), LoadOutSpec[i] ) ||
            !ValidForLoadoutSpec( LoadOutSpec[i], Pocket(i) ) )
        {
            warn("Failed to validate equipment class "$LoadOutSpec[i]$" specified in DynamicLoadout.ini for pocket "$GetEnum( Pocket, i ) );
            AssertWithDescription( false, self.Name$":  Failed to validate equipment class "$LoadOutSpec[i]$" specified in DynamicLoadout.ini for pocket "$GetEnum( Pocket, i ));

            //replace with default for pocket
            LoadOutSpec[i] = DLOClassForPocket( Pocket(i), 0 );
        }
    }

    return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Validate the custom skin pocket. Custom skins are a special case because the skin class may not be
// available on the client. The default skin will be used in that case.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated protected function ValidatePocketCustomSkin(bool IsSuspect)
{
	AssertWithDescription(LoadOutSpec[Pocket.Pocket_CustomSkin] == None, "The custom skin entry in LoadOutSpec must be None, but is currently "$LoadOutSpec[Pocket.Pocket_CustomSkin]$". Setting to None");

	LoadOutSpec[Pocket.Pocket_CustomSkin] = None;
	if(CustomSkinSpec == "")
	{
		CustomSkinSpec = "SwatGame.DefaultCustomSkin";
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Validate a single piece of quipment in a given pocket.
//      Returns true iff the equipment class is valid in the current game mode
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated protected function bool ValidateEquipmentForPocket( Pocket pock, class<Actor> CheckClass )
{
    local int i;
    local class<Actor> EquipClass;
    local int NumEquipment;
    local bool Valid;

    NumEquipment = GC.AvailableEquipmentPockets[pock].EquipmentClassName.Length;

    if( CheckClass == None && NumEquipment == 0)
        return true;

    for( i = 0; i < NumEquipment; i++ )
    {
        EquipClass = DLOClassForPocket( pock, i );

        //did we find it?
        if( CheckClass == EquipClass )
        {
            Valid = CheckValidity( GC.AvailableEquipmentPockets[pock].Validity[i] );
            assertWithDescription(Valid, "This thing called "$CheckClass$" isn't valid");
            break;
        }
    }

    return Valid;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Utility: DLO's a class for the pocket spec of the given pocket at the given index
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated private function class<actor> DLOClassForPocket( Pocket pock, int index )
{
    local string ClassName;
    local class<actor> DLOClass;

    ClassName = GC.AvailableEquipmentPockets[pock].EquipmentClassName[index];

    if( ClassName == "None" || ClassName == "" )
        return None;

    DLOClass = class<Actor>(DynamicLoadObject(ClassName,class'class'));
    AssertWithDescription( DLOClass != None, self.Name$":  Could not DLO invalid equipment class "$ClassName$" specified in the pocket specifications section of SwatEquipment.ini." );

    return DLOClass;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Utility: Check the validity given the current game mode
//      Returns true iff the current game mode matches the input validity
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated protected function bool CheckValidity( eNetworkValidity type )  //may be further subclassed
{

    if(type == NETVALID_All)
        return true;
    if(type == NETVALID_None)
        return false;
    if(type == NETVALID_MPOnly)
        return true;

    return ( ( type == NETVALID_MPOnly ) ==
             ( GC.SwatGameRole == GAMEROLE_MP_Host ||
               GC.SwatGameRole == GAMEROLE_MP_Client ) );
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Spawn the actual equipment from the final loadout spec.
//      Do not spawn any equipment that has already been created or that cannot be spawned
//          (such as POCKET_Invalid, the ammunition pockets).
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated protected function SpawnEquipmentFromLoadOutSpec(DynamicLoadOutSpec DynamicSpec)
{
    local int i;

    for( i = 0; i < Pocket.EnumCount; i++ )
    {
        if( !GC.AvailableEquipmentPockets[i].bSpawnable )
            continue;

        SpawnEquipmentForPocket( Pocket(i), LoadOutSpec[i], DynamicSpec );
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Spawn a piece of equipment in the given pocket from the final loadout spec.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated protected function SpawnEquipmentForPocket( Pocket i, class<actor> EquipmentClass, DynamicLoadOutSpec DynamicSpec )
{
    //mplog( self$"---LoadOut::SpawnEquipmentForPocket(). Pocket="$i$", class="$EquipmentClass );

    if( PocketEquipment[i] != None )
        PocketEquipment[i].Destroy();

    if( EquipmentClass == None )
        return;

    PocketEquipment[i] = Owner.Spawn(EquipmentClass, Owner);

    assertWithDescription(PocketEquipment[i] != None,
        "LoadOut "$name$" failed to spawn PocketEquipment item in pocket "$GetEnum(Pocket,i)$" of class "$EquipmentClass$".");

    //mplog( "...Spawned equipment="$PocketEquipment[i] );

    if( GC.AvailableEquipmentPockets[i].TypeOfEquipment == EQUIP_Weaponry )
    {
        Assert( GC.AvailableEquipmentPockets[i].DependentPocket != Pocket_Invalid );

        switch( i )
        {
            case Pocket_PrimaryWeapon:
                FiredWeapon( PocketEquipment[i] ).SetSlot( EquipmentSlot.Slot_PrimaryWeapon );

				        // INCREDIBLE HACK... but probably necessary?
                FiredWeapon(PocketEquipment[i]).DeathFired = DynamicSpec.GetPrimaryAmmoCount();

                break;
            case Pocket_SecondaryWeapon:
                FiredWeapon( PocketEquipment[i] ).SetSlot( EquipmentSlot.Slot_SecondaryWeapon );

                // INCREDIBLE HACK...but probably necessary?
                FiredWeapon(PocketEquipment[i]).DeathFired = DynamicSpec.GetSecondaryAmmoCount();

                break;
            default:
                Assert( false );
        }

        FiredWeapon( PocketEquipment[i] ).AmmoClass = class<Ammunition>(LoadOutSpec[GC.AvailableEquipmentPockets[i].DependentPocket]);
    }

    // Set the pocket on the newly spawned item
    if( HandheldEquipment( PocketEquipment[i] ) != None )
    {
        HandheldEquipment( PocketEquipment[i] ).SetAvailable(true);
        HandheldEquipment( PocketEquipment[i] ).SetPocket( i );
    }

    // Trigger notification that this equipment has been spawned for this loadout
    if( Equipment( PocketEquipment[i] ) != None )
        Equipment( PocketEquipment[i] ).OnGivenToOwner();
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Add an existing item to the LoadOut - intended for Pickups
//
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated protected function AddExistingItemToPocket( Pocket i, Actor Item )
{
    if( PocketEquipment[i] != None )
        PocketEquipment[i].Destroy();

    assert(Item != None);

    PocketEquipment[i] = Item;

    if( GC.AvailableEquipmentPockets[i].TypeOfEquipment == EQUIP_Weaponry )
    {
        Assert( GC.AvailableEquipmentPockets[i].DependentPocket != Pocket_Invalid );

        switch( i )
        {
            case Pocket_PrimaryWeapon:
                FiredWeapon( PocketEquipment[i] ).SetSlot( EquipmentSlot.Slot_PrimaryWeapon );
                break;
            case Pocket_SecondaryWeapon:
                FiredWeapon( PocketEquipment[i] ).SetSlot( EquipmentSlot.Slot_SecondaryWeapon );
                break;
            default:
                Assert( false );
        }
    }

    // Set the pocket on the newly spawned item
    if( HandheldEquipment( PocketEquipment[i] ) != None )
        HandheldEquipment( PocketEquipment[i] ).SetPocket( i );
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Log Loadout Utility
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated function PrintLoadOutToMPLog()
{
    local int i;

    mplog( "LoadOut "$self$" contains:" );
    log( "LoadOut "$self$" contains:" );

    for ( i = 0; i < Pocket.EnumCount; i++ )
    {
        mplog( "...PocketEquipment["$GetEnum(Pocket,i)$"]="$PocketEquipment[i] );
        log( "...PocketEquipment["$GetEnum(Pocket,i)$"]="$PocketEquipment[i] );
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Accessors
/////////////////////////////////////////////////////////////////////////////////////////////////////

// Returns the first handheld equipment corresponding to the given slot
simulated function HandheldEquipment GetItemAtSlot(EquipmentSlot Slot)
{
    local int i;
    local HandheldEquipment Item;
    local HandheldEquipment Candidate;

    // FIXME BIGTIME
    assert(Owner.IsA('ICanUseC2Charge'));
    if( Slot == SLOT_Breaching && ICanUseC2Charge(Owner).GetDeployedC2Charge() != None )
        return GetItemAtSlot( Slot_Detonator );

    for( i = 0; i < Pocket.EnumCount; i++ )
    {
        Item = HandheldEquipment(PocketEquipment[i]);
        if  (
                Item != None
            &&  Item.GetSlot() == Slot
            &&  Item.IsAvailable()
            )
        {
            Candidate = Item;

            //tcohen, fix 5480: Can never equip second PepperSpray
            //  this is the only case of LoadOut containing more than one instance
            //of any FiredWeapon class.  if one has empty ammo and another does not,
            //then we want to select the one that is not empty, regardless of order.
            if (!Candidate.IsA('FiredWeapon') || !FiredWeapon(Candidate).Ammo.IsEmpty())
                return Item;
            //else, Candidate IsA 'FiredWeapon' && Candidate's Ammo IsEmpty()
                //continue looking for an instance that isn't empty
        }
    }

    if (Level.NetMode != NM_Standalone ) // ckline: this was bogging down SP performance
    {
	 	if (Level.GetEngine().EnableDevTools)
		{
			mplog( self$"---LoadOut::GetItemAtSlot(). Slot="$Slot );
			mplog( "...Returning None because no item was found for that slot." );
			PrintLoadOutToMPLog();
        }
    }

    //if we never found a match, or if we only found an empty FiredWeapon, the return that
    return Candidate;
}

// Returns the contents of the given pocket
simulated function Actor GetItemAtPocket( Pocket ThePocket )
{
    assert(ThePocket != Pocket_Invalid);

    return PocketEquipment[ThePocket];
}

simulated function FiredWeapon GetPrimaryWeapon()
{
    return FiredWeapon(PocketEquipment[Pocket.Pocket_PrimaryWeapon]);
}

simulated function FiredWeapon GetBackupWeapon()
{
    return FiredWeapon(PocketEquipment[Pocket.Pocket_SecondaryWeapon]);
}

simulated function Material GetDefaultPantsMaterial()
{
    if ( HasHeavyArmor() )
        return MaterialSpec[MaterialPocket.MATERIAL_HeavyPants];
    else
        return MaterialSpec[MaterialPocket.MATERIAL_Pants];
}

simulated function Material GetDefaultFaceMaterial()
{
	return MaterialSpec[MaterialPocket.MATERIAL_Face];
}

simulated function Material GetDefaultNameMaterial()
{
	return MaterialSpec[MaterialPocket.MATERIAL_Name];
}

simulated function Material GetDefaultVestMaterial()
{
	if ( HasHeavyArmor() )
        return MaterialSpec[MaterialPocket.MATERIAL_HeavyVest];
    else if ( HasNoArmor() )
		return MaterialSpec[MaterialPocket.MATERIAL_NoArmourVest];
	else
        return MaterialSpec[MaterialPocket.MATERIAL_Vest];
}

simulated function Material GetMaterial( MaterialPocket pock )
{
	local Material Mat;

	Mat = GetCustomMaterial(pock);

	if (Mat != None)
		return Mat;
	else
		return MaterialSpec[pock];
}


simulated function Material GetNameMaterial()
{
    return MaterialSpec[MaterialPocket.MATERIAL_Name];
}

simulated function Material GetFaceMaterial()
{
    return GetMaterial(MaterialPocket.MATERIAL_Face);
}

simulated function Material GetVestMaterial()
{
    if ( HasHeavyArmor() )
        return GetMaterial(MaterialPocket.MATERIAL_HeavyVest);
    else if ( HasNoArmor() )
		return GetMaterial(MaterialPocket.MATERIAL_NoArmourVest);
	else
        return GetMaterial(MaterialPocket.MATERIAL_Vest);
}

simulated function Material GetPantsMaterial()
{
    if ( HasHeavyArmor() )
        return GetMaterial(MaterialPocket.MATERIAL_HeavyPants);
    else
        return GetMaterial(MaterialPocket.MATERIAL_Pants);
}

simulated function Material GetCustomMaterial( MaterialPocket pock )
{
	local class<SwatCustomSkin> SkinClass;

	//if( !GC.bShowCustomSkins || CustomSkinSpec == "" || CustomSkinSpec == "SwatGame.DefaultCustomSkin" )
	//	return None;

	SkinClass = class<SwatCustomSkin>(DynamicLoadObject(CustomSkinSpec, class'Class', true));

	if (SkinClass != None)
	{
		switch (pock)
		{
		case MaterialPocket.MATERIAL_Face:
			return SkinClass.default.FaceMaterial;

		case MaterialPocket.MATERIAL_Vest:
			return SkinClass.default.VestMaterial;

		case MaterialPocket.MATERIAL_HeavyVest:
			return SkinClass.default.HeavyVestMaterial;

		case MaterialPocket.MATERIAL_NoArmourVest:
			return SkinClass.default.NoArmorVestMaterial;

		case MaterialPocket.MATERIAL_Pants:
			return SkinClass.default.PantsMaterial;

		case MaterialPocket.MATERIAL_HeavyPants:
			return SkinClass.default.HeavyPantsMaterial;
		}
	}

	return None;
}

simulated function bool HasHeavyArmor()
{
    if ( PocketEquipment[Pocket.Pocket_BodyArmor] != None )
        return PocketEquipment[Pocket.Pocket_BodyArmor].IsA('HeavyBodyArmor');
    else
        return false; // The VIP has no armor in Pocket_BodyArmor.
}

simulated function bool HasNoArmor()
{
    if ( PocketEquipment[Pocket.Pocket_BodyArmor] != None )
        return PocketEquipment[Pocket.Pocket_BodyArmor].IsA('NoBodyArmor');
    else
        return false; // The VIP has no armor in Pocket_BodyArmor.
}

simulated function bool HasRiotHelmet()
{
	if ( PocketEquipment[Pocket.Pocket_HeadArmor] != None )
		return PocketEquipment[Pocket.Pocket_HeadArmor].IsA('RiotHelmet');
	else
		return false; // The VIP has no head armor
}

simulated function bool HasProArmorHelmet()
{
	if ( PocketEquipment[Pocket.Pocket_HeadArmor] != None )
		return PocketEquipment[Pocket.Pocket_HeadArmor].IsA('EnemyProtecHelmet');
	else
		return false; // The VIP has no head armor
}

// For an EquipmentSlot, determine how many items we have
simulated function int GetTacticalAidAvailableCount(EquipmentSlot Slot)
{
  local int Count, i;
  local HandheldEquipment Equipment;
  local FiredWeapon Weapon;

  for(i = Pocket.Pocket_EquipOne; i <= Pocket.Pocket_EquipSix; i++)
  {
    Equipment = HandheldEquipment(PocketEquipment[i]);
    if(Slot == SLOT_Detonator)
    {
      // Special case for detonator, it adds the counts from C2
      if(Equipment != None && Equipment.IsA('C2Charge'))
      {
        Count += Equipment.GetAvailableCount();
      }
    }
    else if(Equipment != None && Equipment.GetSlot() == Slot && Equipment.IsAvailable())
    {
      if(Equipment.IsA('PepperSpray'))
      {
        // Special case: pepper spray isn't ever made "not available", it's just emptied
        Weapon = FiredWeapon(Equipment);
        if(Weapon.Ammo.IsEmpty())
        {
          continue;
        }
      }
      Count += Equipment.GetAvailableCount();
    }
  }

  return Count;
}

//returns the item, if any, that was replaced
function HandheldEquipment FindItemToReplace(HandheldEquipment PickedUp)
{
    local int i;

    for( i = 0; i < Pocket.EnumCount; i++ )
        if( ValidateEquipmentForPocket( Pocket(i), PickedUp.class ) )
            return HandheldEquipment(PocketEquipment[i]);

    AssertWithDescription(false,
        "[tcohen] LoadOut::FindItemToReplace() The PickedUp class "$PickedUp.class.name
        $" failed to validate for any Pocket.");
}

simulated function OnPickedUp(HandheldEquipment Item)
{
  local SwatWeapon Weapon;

    AddExistingItemToPocket(FindItemToReplace(Item).GetPocket(), Item);

    if(Item.IsA('RoundBasedWeapon')) {
      Weapon = SwatWeapon(Item);
      Weapon.Ammo.InitializeAmmo(25);
    }
    else if(Item.IsA('ClipBasedWeapon')) {
      // We need to make sure the item has 5 magazines to start out with.
      Weapon = SwatWeapon(Item);
      Weapon.Ammo.InitializeAmmo(5);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// Destroyed, Clean up all spawned equipment
/////////////////////////////////////////////////////////////////////////////////////////////////////
simulated event Destroyed()
{
    local int i;

    Super.Destroyed();

    for( i = 0; i < Pocket.EnumCount; i++ )
        if( PocketEquipment[i] != None )
            PocketEquipment[i].Destroy();
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
//
// IHaveWeight implementation
function float GetTotalWeight() {
	local int i;
	local Engine.IHaveWeight PocketItem;
	local Engine.FiredWeapon FiredItem;
	local Engine.HandHeldEquipment HHEItem;
	local Engine.SwatAmmo FiredItemAmmo;
	local float total;
	local float minimum;

	total = 0.0;
	minimum = GetMinimumWeight();

	for(i = 0; i < Pocket.EnumCount; i++) {
	   	if(PocketEquipment[i] == None)
	    {
	    	continue;
	    }

	    PocketItem = Engine.IHaveWeight(PocketEquipment[i]);
	    HHEItem = Engine.HandHeldEquipment(PocketEquipment[i]);
	    if(HHEItem == None)
		{
		    total += PocketItem.GetWeight();
	    }
		else if(HHEItem.IsAvailable())
		{
		    total += PocketItem.GetWeight();
	    }

	    if(i == Pocket.Pocket_PrimaryWeapon || i == Pocket.Pocket_SecondaryWeapon) {
		    // A weapon
		    FiredItem = FiredWeapon(PocketItem);
		    FiredItemAmmo = SwatAmmo(FiredItem.Ammo);
		    total += FiredItemAmmo.GetCurrentAmmoWeight();
	    }
	}

	if(total < minimum)
	{
		total = minimum; // TODO: investigate why this happens
	}

	return total;
}

function float GetTotalBulk() {
	local int i;
	local Engine.IHaveWeight PocketItem;
	local Engine.FiredWeapon FiredItem;
	local Engine.SwatAmmo FiredItemAmmo;
	local float total;
	local float minimum;

	minimum = GetMinimumBulk();
	total = 0.0;

	for(i = 0; i < Pocket.EnumCount; i++)
	{
	   	if(PocketEquipment[i] == None)
	    {
	    	continue;
	    }

	    PocketItem = Engine.IHaveWeight(PocketEquipment[i]);
	    total += PocketItem.GetBulk();

	    if(i == Pocket.Pocket_PrimaryWeapon || i == Pocket.Pocket_SecondaryWeapon)
		{
	    	// Weapon
	    	FiredItem = FiredWeapon(PocketItem);
	    	FiredItemAmmo = SwatAmmo(FiredItem.Ammo);
	    	total += FiredItemAmmo.GetCurrentAmmoBulk();
	    }
	}

	if(total < minimum)
	{
		total = minimum; // TODO: investigate why this happens
	}

	return total;
}

simulated function float GetWeightMovementModifier() {
	local float totalWeight;
    local float maxWeight, minWeight;
    local float minMoveModifier, maxMoveModifier;

    totalWeight = GetTotalWeight();
    maxWeight = GetMaximumWeight();
    minWeight = GetMinimumWeight();
    minMoveModifier = GetMinimumMovementModifier();
    maxMoveModifier = GetMaximumMovementModifier();

    if(totalWeight < minWeight) {
      // There are legitimate reasons that we don't meet the minimum weight - Training mission comes to mind
      totalWeight = minWeight;
    }

    assertWithDescription(totalWeight <= maxWeight,
      "Loadout "$self$" exceeds maximum weight ("$totalWeight$" > "$maxWeight$"). Adjust the value in code.");

    totalWeight -= minWeight;
    maxWeight -= minWeight;

    return ((totalWeight / maxWeight) * (minMoveModifier - maxMoveModifier)) + maxMoveModifier;
}

simulated function float GetBulkQualifyModifier() {
	local float totalBulk;
    local float maxBulk, minBulk;
    local float minQualifyModifier, maxQualifyModifier;

    totalBulk = GetTotalBulk();
    minBulk = GetMinimumBulk();
    maxBulk = GetMaximumBulk();
    minQualifyModifier = GetMinimumQualifyModifer();
    maxQualifyModifier = GetMaximumQualifyModifer();

    if(totalBulk < minBulk) {
  	  // There are legitimate reasons that we don't meet the minimum bulk - Training mission comes to mind
  	  totalBulk = minBulk;
    }

    assertWithDescription(totalBulk <= maxBulk,
  	  "Loadout "$self$" exceeds maximum bulk ("$totalBulk$" > "$maxBulk$"). Adjust the value in code.");

    totalBulk -= minBulk;
    maxBulk -= minBulk;

    return ((totalBulk / maxBulk) * (maxQualifyModifier - minQualifyModifier)) + minQualifyModifier;
}

simulated function float GetBulkSpeedModifier() {
	local float totalBulk;
	local float maxBulk, minBulk;
	local float minSpeedModifier, maxSpeedModifier;

	totalBulk = GetTotalBulk();
	minBulk = GetMinimumBulk();
	maxBulk = GetMaximumBulk();
	minSpeedModifier = GetMinimumSpeedModifier();
	maxSpeedModifier = GetMaximumSpeedModifier();

	if(totalBulk < minBulk) {
		totalBulk = minBulk;
	}

	totalBulk -= minBulk;
	maxBulk -= minBulk;

	return ((1.0 - (totalBulk / maxBulk)) * (maxSpeedModifier - minSpeedModifier)) + minSpeedModifier;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// cpptext
/////////////////////////////////////////////////////////////////////////////////////////////////////
cpptext
{
    UBOOL HasA(FName HandheldEquipmentName);
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// DefProps
/////////////////////////////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Physics=PHYS_None
    bStasis=true
    bHidden=true
	bDisableTick=true
    RemoteRole=ROLE_None
}
