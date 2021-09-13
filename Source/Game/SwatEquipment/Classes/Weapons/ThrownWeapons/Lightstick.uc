class Lightstick extends Engine.SwatGrenade
	config(SwatEquipment);

var config string BaseThirdPersonThrowAnim;
var bool Used;
var bool ThrowingFast;
var config name BaseThirdPersonThrowAnimNet;
var config name FastPreThrowAnimation;
var config name FastThrowAnimation;

var config class<LightstickProjectile> RedLightstickClass;
var config class<LightstickProjectile> BlueLightstickClass;
var config Material RedLightstickMaterial;
var config Material BlueLightstickMaterial; 

////////////////////////////////////////////////////////////////////
//
// New stuff for HUD --eez

simulated function EquippedHook()
{
	if(!ThrowingFast)
	{
		Super.EquippedHook();
		UpdateHUD();
	}
}

simulated function OnPostEquipped()
{
	if(ThrowingFast)
	{
		SwatPlayer(Owner).GotoState('Throwing');
	}
}

simulated function UsedHook()
{
	if(Used)
	{
		return;
	}
	Used = true;

	Super.UsedHook();
	UpdateHUD();
}

simulated latent protected function PreUsed()
{
	Super.PreUsed();

	if(Owner.IsA('SwatAI') || ThrowingFast)
	{
		Used = false;

		if (ThirdPersonModel != None)
	        ThirdPersonModel.PlayUse(0);

		/*if(!Owner.IsA('SwatPlayer'))
		{
			PreEquip();
		}*/
	}
}

simulated function OnUsingFinishedHook()
{
	if(ThrowingFast || Owner.IsA('SwatAI'))
	{
		if(!Used)
		{
			UsedHook();
		}
		Used = false;

		if(Owner.IsA('SwatPlayer'))
		{
			SwatPlayer(Owner).DoDefaultEquip();
		}

		if(Level.NetMode != NM_Client && Level.NetMode != NM_Standalone)
		{
			ThrowingFast = false;
		}
	}
	else
	{
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
	else if(ThrowingFast)
	{
		return BaseThirdPersonThrowAnimNet;
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

// Lightsticks can change color of third person mesh too.
simulated function OnGivenToOwner()
{
	if(Owner.IsA('OfficerBlueOne') || Owner.IsA('OfficerBlueTwo'))
	{
		ThirdPersonModel.Skins[0] = BlueLightstickMaterial;
	}
	else if(Owner.IsA('OfficerRedOne') || Owner.IsA('OfficerRedTwo'))
	{
		ThirdPersonModel.Skins[0] = RedLightstickMaterial;
	}
	else if(Owner.IsA('NetPlayer'))
	{
		if(NetPlayer(Owner).GetTeamNumber() == 0)
		{
			ThirdPersonModel.Skins[0] = BlueLightstickMaterial;
		}
		else
		{
			ThirdPersonModel.Skins[0] = RedLightstickMaterial;
		}
	}
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

function MutateThrowingSpeed()
{
	if(ThrowingFast)
	{
		SetThrowSpeed(0.0);
	}
}

simulated function FlagForFastUse()
{
	SetThrowSpeed(0.0);
	ThrowingFast = true;
}

function Name GetHandsPreThrowAnimation()
{
	if(ThrowingFast)
	{
		return FastPreThrowAnimation;
	}
	return Super.GetHandsPreThrowAnimation();
}

function name GetHandsThrowAnimation(Hands Hands)
{
	if(ThrowingFast)
	{
		return FastThrowAnimation;
	}
	return Super.GetHandsThrowAnimation(Hands);
}

function bool IsInFastUse()
{
	if(Owner.IsA('SwatAI'))
	{
		return false;
	}

	return ThrowingFast;
}

simulated function EquipmentSlot GetSlotForReequip()
{
	local SwatGame.SwatGamePlayerController LPC;

	if(ThrowingFast)
	{
		LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

		if (Pawn(Owner).Controller != LPC) return Slot_PrimaryWeapon; //the player doesn't own this ammo

		if(LPC.bSecondaryWeaponLast)
			return Slot_SecondaryWeapon;
		return Slot_PrimaryWeapon;
	}

	return super.GetSlotForReequip();
}

simulated function UnequippedHook()
{
	mplog("UnequippedHook()");
	ThrowingFast = false;
	Super.UnequippedHook();
}

Replication
{
	reliable if(Role == Role_Authority)
		ThrowingFast, Used;
}

defaultproperties
{
    Slot=Slot_Lightstick
	ProjectileClass=class'SwatEquipment.LightstickProjectile'
	BaseThirdPersonThrowAnim="LightStickDrop_"
	BaseThirdPersonThrowAnimNet="LightStickDrop_MP"
	FastPreThrowAnimation="GlowPreThrow"
	FastThrowAnimation="GlowThrow"

	RedLightstickClass=class'SwatEquipment.RedLightstickProjectile'
	BlueLightstickClass=class'SwatEquipment.BlueLightstickProjectile'
	RedLightstickMaterial=Material'GearTex_SEF.lightstickred_held'
	BlueLightstickMaterial=Material'GearTex_SEF.lightstickblue_held'
}
