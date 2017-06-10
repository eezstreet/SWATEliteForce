class Lightstick extends Engine.SwatGrenade
	config(SwatEquipment);

var config string BaseThirdPersonThrowAnim;
var bool Used;

////////////////////////////////////////////////////////////////////
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

	log(self$"Lightstick UsedHook");
}

simulated latent protected function PreUsed()
{
	Super.PreUsed();

	if(Owner.IsA('SwatAI'))
	{
		Used = false;

		if (ThirdPersonModel != None)
	        ThirdPersonModel.PlayUse(0);
	}
}

simulated function OnUsingFinishedHook()
{
	if(Owner.IsA('SwatAI'))
	{
		if (!Used)
			UsedHook();

			Used = false;
	}

}

function UpdateHUD()
{
  local SwatGame.SwatGamePlayerController LPC;
  local int ReserveGrenades;

  LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

  if (Pawn(Owner).Controller != LPC) return; //the player doesn't own this ammo

  ReserveGrenades = GetAvailableCount();
  ReserveGrenades--; // We are holding one
  if(ReserveGrenades < 0)
  {
    ReserveGrenades = 0;
  }

  LPC.GetHUDPage().AmmoStatus.SetTacticalAidStatus(ReserveGrenades, self);
  LPC.GetHUDPage().UpdateWeight();
}

function name GetThirdPersonThrowAnimation()
{
	local FiredWeapon FiredWeapon;

	if(Owner.IsA('SwatAI'))
	{
		FiredWeapon = FiredWeapon(SwatPawn(Owner).GetActiveItem());

		if(FiredWeapon != None)
			return name(BaseThirdPersonThrowAnim $ FiredWeapon.LightstickThrowAnimPostfix);
	}

	return Super.GetThirdPersonThrowAnimation();
}

// Lightstick need not be equipped for AIs to use
simulated function bool ValidateUse( optional bool Prevalidate )
{
	if (Owner.IsA('SwatAI'))
		return true;
	else
		return Super.ValidateUse(Prevalidate);
}

defaultproperties
{
    Slot=Slot_Lightstick
	  ProjectileClass=class'SwatEquipment.LightstickProjectile'
		BaseThirdPersonThrowAnim="LightStickDrop_"
}
