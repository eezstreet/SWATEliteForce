class DynamicLoadOutSpec extends LoadOutValidationBase
    perObjectConfig
    Config(DynamicLoadout);

////////////////////////////////////////////////////////////////////////////////
//
// IHaveWeight implementation
simulated function float GetTotalWeight() {
  local int i;
  local float total;
  local Pocket pock;

  // Variables for all the things
  local class<SwatWeapon> WeaponClass;
  local class<BodyArmor> BodyArmorClass;
  local class<Headgear> HeadgearClass;
  local class<OptiwandBase> OptiwandClass;
  local class<QualifiedTacticalAid> TacticalAidClass;
  local class<SwatGrenade> GrenadeClass;

  local class NightVisionClass; // special case
  local class OptiwandGenericClass;
  local class WeaponGenericClass;
  local class TacticalAidGenericClass;
  local class GrenadeGenericClass;

  for(i = 0; i < Pocket.EnumCount; i++) {
    pock = Pocket(i);
    switch(pock) {
      case Pocket_PrimaryWeapon:
      case Pocket_SecondaryWeapon:
        WeaponClass = class<SwatWeapon>(LoadOutSpec[i]);
        total += WeaponClass.default.Weight;
        break;

      case Pocket_PrimaryAmmo:
      case Pocket_SecondaryAmmo:
        break;

      case Pocket_BodyArmor:
        BodyArmorClass = class<BodyArmor>(LoadOutSpec[i]);
        total += BodyArmorClass.default.Weight;
        break;

      case Pocket_HeadArmor:
        NightVisionClass = class(DynamicLoadObject("SwatEquipment.NVGogglesBase",class'class'));
        if(ClassIsChildOf(LoadOutSpec[i], NightVisionClass)) {
          total += 0.68; // IMPORTANT: Make sure this matches the value in NVGogglesBase.uc !!!
        } else {
          HeadgearClass = class<Headgear>(LoadOutSpec[i]);
          total += HeadgearClass.default.Weight;
        }
        break;

      case Pocket_EquipOne:
      case Pocket_EquipTwo:
      case Pocket_EquipThree:
      case Pocket_EquipFour:
      case Pocket_EquipFive:
        OptiwandGenericClass = class(DynamicLoadObject("Engine.OptiwandBase", class'class'));
        WeaponGenericClass = class(DynamicLoadObject("Engine.SwatWeapon", class'class'));
        TacticalAidGenericClass = class(DynamicLoadObject("Engine.QualifiedTacticalAid", class'class'));
        GrenadeGenericClass = class(DynamicLoadObject("Engine.SwatGrenade", class'class'));

        if(ClassIsChildOf(LoadOutSpec[i], OptiwandGenericClass)) {
          OptiwandClass = class<OptiwandBase>(LoadOutSpec[i]);
          total += OptiwandClass.default.Weight;
        } else if(ClassIsChildOf(LoadOutSpec[i], WeaponGenericClass)) {
          WeaponClass = class<SwatWeapon>(LoadOutSpec[i]);
          total += WeaponClass.default.Weight;
        } else if(ClassIsChildOf(LoadOutSpec[i], TacticalAidGenericClass)) {
          TacticalAidClass = class<QualifiedTacticalAid>(LoadOutSpec[i]);
          total += TacticalAidClass.default.Weight;
        } else if(ClassIsChildOf(LoadOutSpec[i], GrenadeGenericClass)) {
          GrenadeClass = class<SwatGrenade>(LoadOutSpec[i]);
          total += GrenadeClass.default.Weight;
        }
        break;

      case Pocket_Breaching:
        WeaponGenericClass = class(DynamicLoadObject("Engine.SwatWeapon", class'class'));
        TacticalAidGenericClass = class(DynamicLoadObject("Engine.QualifiedTacticalAid", class'class'));

        if(ClassIsChildOf(LoadOutSpec[i], WeaponGenericClass)) {
          WeaponClass = class<SwatWeapon>(LoadOutSpec[i]);
          total += WeaponClass.default.Weight;
        } else if(ClassIsChildOf(LoadOutSpec[i], TacticalAidGenericClass)) {
          TacticalAidClass = class<QualifiedTacticalAid>(LoadOutSpec[i]);
          total += TacticalAidClass.default.Weight;
        }
        break;

      default:
        break;
    }
  }

  return total;
}

simulated function float GetTotalBulk() {
  local int i;
  local float total;
  local Pocket pock;

  // Variables for all the things
  local class<SwatWeapon> WeaponClass;
  local class<BodyArmor> BodyArmorClass;
  local class<Headgear> HeadgearClass;
  local class<OptiwandBase> OptiwandClass;
  local class<QualifiedTacticalAid> TacticalAidClass;
  local class<SwatGrenade> GrenadeClass;

  local class NightVisionClass; // special case
  local class OptiwandGenericClass;
  local class WeaponGenericClass;
  local class TacticalAidGenericClass;
  local class GrenadeGenericClass;

  for(i = 0; i < Pocket.EnumCount; i++) {
    pock = Pocket(i);
    switch(pock) {
      case Pocket_PrimaryWeapon:
      case Pocket_SecondaryWeapon:
        WeaponClass = class<SwatWeapon>(LoadOutSpec[i]);
        total += WeaponClass.default.Bulk;
        break;

      case Pocket_PrimaryAmmo:
      case Pocket_SecondaryAmmo:
        break;

      case Pocket_BodyArmor:
        BodyArmorClass = class<BodyArmor>(LoadOutSpec[i]);
        total += BodyArmorClass.default.Bulk;
        break;

      case Pocket_HeadArmor:
        NightVisionClass = class(DynamicLoadObject("SwatEquipment.NVGogglesBase",class'class'));
        if(ClassIsChildOf(LoadOutSpec[i], NightVisionClass)) {
          total += 0.68; // IMPORTANT: Make sure this matches the value in NVGogglesBase.uc !!!
        } else {
          HeadgearClass = class<Headgear>(LoadOutSpec[i]);
          total += HeadgearClass.default.Bulk;
        }
        break;

      case Pocket_EquipOne:
      case Pocket_EquipTwo:
      case Pocket_EquipThree:
      case Pocket_EquipFour:
      case Pocket_EquipFive:
        OptiwandGenericClass = class(DynamicLoadObject("Engine.OptiwandBase", class'class'));
        WeaponGenericClass = class(DynamicLoadObject("Engine.SwatWeapon", class'class'));
        TacticalAidGenericClass = class(DynamicLoadObject("Engine.QualifiedTacticalAid", class'class'));
        GrenadeGenericClass = class(DynamicLoadObject("Engine.SwatGrenade", class'class'));

        if(ClassIsChildOf(LoadOutSpec[i], OptiwandGenericClass)) {
          OptiwandClass = class<OptiwandBase>(LoadOutSpec[i]);
          total += OptiwandClass.default.Bulk;
        } else if(ClassIsChildOf(LoadOutSpec[i], WeaponGenericClass)) {
          WeaponClass = class<SwatWeapon>(LoadOutSpec[i]);
          total += WeaponClass.default.Bulk;
        } else if(ClassIsChildOf(LoadOutSpec[i], TacticalAidGenericClass)) {
          TacticalAidClass = class<QualifiedTacticalAid>(LoadOutSpec[i]);
          total += TacticalAidClass.default.Bulk;
        } else if(ClassIsChildOf(LoadOutSpec[i], GrenadeGenericClass)) {
          GrenadeClass = class<SwatGrenade>(LoadOutSpec[i]);
          total += GrenadeClass.default.Bulk;
        }
        break;

      case Pocket_Breaching:
        WeaponGenericClass = class(DynamicLoadObject("Engine.SwatWeapon", class'class'));
        TacticalAidGenericClass = class(DynamicLoadObject("Engine.QualifiedTacticalAid", class'class'));

        if(ClassIsChildOf(LoadOutSpec[i], WeaponGenericClass)) {
          WeaponClass = class<SwatWeapon>(LoadOutSpec[i]);
          total += WeaponClass.default.Bulk;
        } else if(ClassIsChildOf(LoadOutSpec[i], TacticalAidGenericClass)) {
          TacticalAidClass = class<QualifiedTacticalAid>(LoadOutSpec[i]);
          total += TacticalAidClass.default.Bulk;
        }
        break;

      default:
        break;
    }
  }

  return total;
}

simulated function float GetWeightMovementModifier() {
  return 0.0; // We don't care about this
}

simulated function float GetBulkQualifyModifier() {
  return 0.0; // We don't care about this
}


defaultproperties
{
    bStasis=true
	bDisableTick=true
    Physics=PHYS_None
    bHidden=true
    RemoteRole=ROLE_None
}
