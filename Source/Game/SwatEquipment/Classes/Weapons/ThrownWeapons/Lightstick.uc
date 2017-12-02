class Lightstick extends Engine.SwatGrenade
	config(SwatEquipment);

var config string BaseThirdPersonThrowAnim;
var bool Used;

var config class<LightstickProjectile> RedLightstickClass;
var config class<LightstickProjectile> BlueLightstickClass;

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

// Lightsticks can mutate their projectile class based on the person who is throwing them --eez
function class<actor> MutateProjectile()
{
	//if(!UseTeamBasedLightsticks) { return ProjectileClass; }

	if(Owner.IsA('OfficerBlueOne') || Owner.IsA('OfficerBlueTwo'))
	{
		// AI uses the blue lightstick --eez
		return BlueLightstickClass;
	}
	else if(Owner.IsA('OfficerRedOne') || Owner.IsA('OfficerRedTwo'))
	{
		// AI uses the red lightstick --eez
		return RedLightstickClass;
	}
	else if(Owner.IsA('NetPlayer'))
	{
		// make it based on team
		if(NetPlayer(Owner).GetTeamNumber() == 0)
		{
			return BlueLightstickClass;
		}
		else
		{
			return RedLightstickClass;
		}
	}
	return ProjectileClass;
}

defaultproperties
{
    Slot=Slot_Lightstick
	ProjectileClass=class'SwatEquipment.LightstickProjectile'
	BaseThirdPersonThrowAnim="LightStickDrop_"

	RedLightstickClass=class'SwatEquipment.RedLightstickProjectile'
	BlueLightstickClass=class'SwatEquipment.BlueLightstickProjectile'
}
