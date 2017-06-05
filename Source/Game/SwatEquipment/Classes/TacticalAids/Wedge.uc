class Wedge extends SwatGame.WedgeItem
    implements ITacticalAid;

////////////////////////////////////////////////////////////////////////////////
//
// New Stuff for HUD --eez

simulated function EquippedHook()
{
  Super.EquippedHook();
  UpdateHUD();
}

simulated function UsedHook()
{
    FirstPersonModel.Hide();
    ThirdPersonModel.Hide();

    IAmUsedByWedge(Other).OnUsedByWedge();
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

// IAmAQualifiedUseEquipment implementation

simulated function float GetQualifyDuration()
{
    return IAmUsedByWedge(Other).GetQualifyTimeForWedge() * GetQualifyModifier();
}

// IAmUsedOnOther implementation

simulated protected function AssertOtherIsValid()
{
    assertWithDescription(Other.IsA('IAmUsedByWedge'),
        "[tcohen] A Wedge was called to AssertOtherIsValid(), but Other is a "$Other.class.name
        $", which is not an IAmUsedByWedge.");
}

defaultproperties
{
    Slot=SLOT_Wedge
    UnavailableAfterUsed=true
}
