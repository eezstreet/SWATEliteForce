class PepperSprayAmmoBase extends RoundBasedAmmo config(SwatEquipment);

///////////////////////////////////////////////////////////////////////
//
// New pepper spray handling 06/04/2017

simulated function UpdateHUD()
{
  local SwatGame.SwatGamePlayerController LPC;
  local int ReserveCans;

  LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

  ReserveCans = LPC.SwatPlayer.GetTacticalAidAvailableCount(Slot_PepperSpray);
  ReserveCans--; // We are holding one can
  if(ReserveCans < 0)
  {
    ReserveCans = 0;
  }

  if (Pawn(Owner.Owner).Controller != LPC) return; //the player doesn't own this ammo

  LPC.GetHUDPage().AmmoStatus.SetTacticalAidStatus(ReserveCans, self);
  LPC.GetHUDPage().UpdateWeight();
}
