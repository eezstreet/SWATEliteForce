class C2Charge extends SwatGame.EquipmentUsedOnOther
    implements ITacticalAid;

simulated function UsedHook()
{
    local SwatDoor TargetDoor;

    if (FirstPersonModel != None)
        FirstPersonModel.Hide();
    if (ThirdPersonModel != None)
        ThirdPersonModel.Hide();

    TargetDoor = SwatDoor(Other);
    if (TargetDoor.ActorIsToMyLeft(Pawn(Owner)))
    {
        if (TargetDoor.GetDeployedC2ChargeLeft() != None)
            return; //someone else beat us to it... don't confuse the issue
    }
    else    //Owner is on the Door's Right
        if (TargetDoor.GetDeployedC2ChargeRight() != None)
            return; //someone else beat us to it... don't confuse the issue

    IAmUsedByC2Charge(Other).OnUsedByC2Charge(ICanUseC2Charge(Owner));
    UpdateHUD();
}

simulated function int GetDefaultAvailableCount()
{
  if(GetPocket() == Pocket.Pocket_Unused1 || GetPocket() == Pocket.Pocket_Unused2)
    return 0; // FIXME: The engine always sets the unused pockets as having C2.
              // In the past, the game used to cycle between these unused pockets
              // instead of like how SEF does it with storing a hidden quantity field.
              // This would've made things like 3-packs impossible to do.
  return 3; // We get 3 charges per tactical slot
}

simulated function EquippedHook()
{
  Super.EquippedHook();
  UpdateHUD();
}

function UpdateHUD()
{
  local SwatGame.SwatGamePlayerController LPC;
  local int ReserveWedges;

  LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

  if (Pawn(Owner).Controller != LPC) return; //the player doesn't own this ammo

  ReserveWedges = LPC.SwatPlayer.GetTacticalAidAvailableCount(GetSlot());
  ReserveWedges--; // We are holding one
  if(ReserveWedges < 0)
  {
    ReserveWedges = 0;
  }

  LPC.GetHUDPage().AmmoStatus.SetTacticalAidStatus(ReserveWedges, self);
  LPC.GetHUDPage().UpdateWeight();
}

//which slot should be equipped after this item becomes unavailable
simulated function EquipmentSlot GetSlotForReequip()
{
    return Slot_Detonator;
}

// IAmAQualifiedUseEquipment implementation

simulated function float GetQualifyDuration()
{
    return IAmUsedByC2Charge(Other).GetQualifyTimeForC2Charge() * GetQualifyModifier();
}

// IAmUsedOnOther implementation

simulated protected function AssertOtherIsValid()
{
    assertWithDescription(Other.IsA('IAmUsedByC2Charge'),
        "[tcohen] A C2Charge was called to AssertOtherIsValid(), but Other is a "$Other.class.name
        $", which is not an IAmUsedByC2Charge.");
}

defaultproperties
{
    Slot=SLOT_Breaching
    UnavailableAfterUsed=true
}
