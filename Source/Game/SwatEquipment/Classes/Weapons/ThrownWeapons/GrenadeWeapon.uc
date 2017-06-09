class GrenadeWeapon extends Engine.SwatGrenade;

////////////////////////////////////////////////////////////////////////////////
//
// New stuff for HUD --eez

simulated function EquippedHook()
{
  Super.EquippedHook();
  UpdateHUD();
}

simulated function UsedHook()
{
  Super.UsedHook();
  UpdateHUD();
}

function UpdateHUD()
{
  local SwatGame.SwatGamePlayerController LPC;
  local int ReserveGrenades;

  LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

  if (Pawn(Owner).Controller != LPC) return; //the player doesn't own this ammo

  ReserveGrenades = LPC.SwatPlayer.GetTacticalAidAvailableCount(GetSlot());
  ReserveGrenades--; // We are holding one
  if(ReserveGrenades < 0)
  {
    ReserveGrenades = 0;
  }

  LPC.GetHUDPage().AmmoStatus.SetTacticalAidStatus(ReserveGrenades, self);
  LPC.GetHUDPage().UpdateWeight();
}
