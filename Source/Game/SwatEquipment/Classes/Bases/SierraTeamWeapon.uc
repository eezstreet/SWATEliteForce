class SierraTeamWeapon extends ClipBasedWeapon;


function PostBeginPlay()
{
    Super.PostBeginPlay();
}

simulated function ReloadedHook()
{
    Ammo.OnReloaded();
}



simulated function CreateThirdPersonModel(class<HandheldEquipmentModel> SelectedThirdPersonModelClass)
{
}


function OnPreEquipped()
{
    local ICanHoldEquipment Holder;

    Super.OnPreEquipped();

    Holder = ICanHoldEquipment(Owner);
    AssertWithDescription(Holder != None,
        "[tcohen] AnimNotify_Equip was called on "$Owner$" which cannot hold equipment.");

    Holder.OnEquipKeyFrame();
}

function OnGivenToOwner()
{
  // Need to override this, because otherwise we get problems
  Super.OnGivenToOwner();

  Ammo.InitializeAmmo(50);
}

simulated function GetPerfectFireStart(out vector outLocation, out rotator outDirection)
{
    outLocation  = SniperPawn(Owner).GetViewportLocation();
    outDirection  = SniperPawn(Owner).GetViewportDirection();
}

defaultproperties
{
    Slot=Slot_PrimaryWeapon
    bAlwaysRelevant=true
}
