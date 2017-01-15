class Lightstick extends SwatGrenade
	config(SwatEquipment);

import enum EquipmentSlot from Engine.HandheldEquipment;

var config class<LightstickProjectile> LightstickClass;
var config float ThrowVelocity;
var config float AIThrowVelocity;
var config int Quantity;
var config string BaseThirdPersonThrowAnim;
var config name BaseThirdPersonThrowAnimNet;

var private bool Used;

replication
{
	reliable if (Role == ROLE_Authority)
		Quantity;
}

simulated function CreateModels()
{
	Super.CreateModels();

	// hide third person model
    if (ThirdPersonModel != None)
       ThirdPersonModel.Hide();
}

simulated function UsedHook()
{
    local ICanThrowWeapons Holder;
    local vector InitialLocation;
    local rotator ThrownDirection;
	local LightstickProjectile Projectile;
	local vector Rot;

	if (Used)
		return;

	Used = true;

	// hide third person model
    if (ThirdPersonModel != None)
       ThirdPersonModel.Hide();

	if ( Quantity > 0 && Level.NetMode != NM_Client )
    {
        Holder = ICanThrowWeapons(Owner);
        assertWithDescription(Holder != None,
                              "[tcohen] "$class.name$" was notified OnThrown(), but its Owner ("$Owner
                              $") cannot throw weapons.");

        Holder.GetThrownProjectileParams(InitialLocation, ThrownDirection);

		if (Owner.IsA('NetPlayer'))
		{
			// start location for the grenade is where the weapon's third person model is
			InitialLocation = NetPlayer(Owner).GetActiveItem().GetThirdPersonModel().Location;
		}
		else
		{
			InitialLocation += vector(ThrownDirection) * (Owner.CollisionRadius + 5);
		}

		Projectile = Spawn(
            LightstickClass,
            None,
            ,                   //tag: default
            InitialLocation,
            ,                   //SpawnRotation: default
            true);              //bNoCollisionFail

		Projectile.TriggerEffectEvent('Thrown');

		Rot.X = FRand() * 65535;
		Rot.Y = FRand() * 65535;
		Rot.Z = FRand() * 65535;

		if (Owner.IsA('SwatPlayer'))
		{
			Projectile.CurrentVelocity = Owner.Velocity + vector(ThrownDirection) * ThrowVelocity;
		}
		else
		{
			Projectile.CurrentVelocity = vector(Owner.Rotation) * AIThrowVelocity;
		}

		Projectile.CurrentAngular = Rot;
		Projectile.HavokSetLinearVelocity(Projectile.CurrentVelocity);
		Projectile.HavokSetAngularVelocity(Projectile.CurrentAngular);

		if(Owner.IsA('SwatAI'))
		{
			log("[eezstreet] " $Owner$ " threw a lightstick. Quantity remaining: "$Quantity);
		}
		Quantity--;
    }
}

simulated function OnPostEquipped()
{
    SwatPlayer(Owner).GotoState('Throwing');
}

simulated function UpdateAvailability()
{
    SetAvailable(Quantity > 0);
}

//See HandheldEquipment::OnForgotten() for an explanation of the notion of "Forgotten".
//Lightsticks become "magically" Available again after they have been Forgotten.
simulated function OnForgotten()
{
    SetAvailable(Quantity > 0);
}

function name GetThirdPersonThrowAnimation()
{
	local FiredWeapon FiredWeapon;

	if (Owner.IsA('SwatAI'))
	{
		FiredWeapon = FiredWeapon(SwatPawn(Owner).GetActiveItem());

		if (FiredWeapon != None)
			return name(BaseThirdPersonThrowAnim $ FiredWeapon.LightstickThrowAnimPostfix);
	}
	else
	{
		return BaseThirdPersonThrowAnimNet;
	}

	return '';
}

// Lightstick need not be equipped for AIs to use
simulated function bool ValidateUse( optional bool Prevalidate )
{
	if (Owner.IsA('SwatAI'))
		return true;
	else
		return Super.ValidateUse(Prevalidate);
}

simulated latent protected function PreUsed()
{
	Super.PreUsed();
	Used = false;

	if (ThirdPersonModel != None)
        ThirdPersonModel.PlayUse(0);

	// make sure EquipStatus is set so third person model shows up
	if (!Owner.IsA('SwatPlayer'))
		PreEquip();
}

simulated function OnUsingFinishedHook()
{
	if (!Used)
		UsedHook();

		Used = false;

	if (Owner.IsA('SwatPlayer'))
	{
		SwatPlayer(Owner).DoDefaultEquip();
	}
}

simulated function CheckTickEquipped()
{
}

simulated function bool ShouldDisplayReticle()
{
	return false;
}

defaultproperties
{
    Slot=Slot_Lightstick
    LightstickClass=class'SwatEquipment.LightstickProjectile'
	ThrowVelocity=100
	AIThrowVelocity=25
	Quantity=25
	UnavailableAfterUsed=false
	BaseThirdPersonThrowAnim="LightStickDrop_"
	BaseThirdPersonThrowAnimNet="LightStickDrop_MP"
	HandsPreThrowAnimation="GlowPreThrow"
	HandsThrowAnimation="GlowThrow"

	InstantUnequip = false
}
