class BreachingSG extends BreachingShotgun;

function OnGivenToOwner()
{
  // Need to override this, because otherwise we get problems
  Super.OnGivenToOwner();

  Ammo.InitializeAmmo(8);
}

defaultproperties
{
    Slot=SLOT_Breaching
}
