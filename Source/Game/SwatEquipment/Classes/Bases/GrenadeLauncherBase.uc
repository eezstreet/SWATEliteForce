class GrenadeLauncherBase extends RoundBasedWeapon;

var config float OfficerUseRangeMin;
var config float OfficerUseRangeMax;
var config int OfficerUseMaxShotsWhenStung;
var config int OfficerUseTargetMinHealth;

function BallisticFire(vector StartTrace, vector EndTrace)
{
    local vector ShotVector;
    local SwatProjectile Grenade;
    local vector GrenadeStart;

	// Don't spawn projectiles on a client
	if (Level.NetMode == NM_Client)
		return;

    ShotVector = Normal(EndTrace - StartTrace);

    GrenadeStart = StartTrace + ShotVector * 20.0;     //push grenade away from the camera a bit

	assertWithDescription(Ammo.ProjectileClass != None,
        "[ryan] The HK69GrenadeLauncher's Ammo.ProjectileClass was None for Ammo class " $ Ammo.class $ ".");

    Grenade = Spawn(
        Ammo.ProjectileClass,	//SpawnClass
        Owner,					//SpawnOwner
        ,						//SpawnTag
        GrenadeStart,			//SpawnLocation
        ,						//SpawnRotation
        true);					//bNoCollisionFail

    assert(Grenade != None);

	if (Grenade.IsA('SwatGrenadeProjectile'))
	{
		SwatGrenadeProjectile(Grenade).Launcher = self;
		SwatGrenadeProjectile(Grenade).bWasFired = true;
		RegisterInterestedGrenadeRegistrantWithProjectile(SwatGrenadeProjectile(Grenade));
	}

    Grenade.Velocity = ShotVector * MuzzleVelocity;
}

function EquipmentSlot GetFiredGrenadeEquipmentSlot()
{
	if(Ammo == None)
	{
		return Slot_Invalid;
	}
	// HACK here
	else if(Ammo.IsA('HK69GL_CSGasGrenadeAmmo'))
	{
		return Slot_CSGasGrenade;
	}
	else if(Ammo.IsA('HK69GL_FlashbangGrenadeAmmo'))
	{
		return Slot_Flashbang;
	}
	else if(Ammo.IsA('HK69GL_StingerGrenadeAmmo'))
	{
		return Slot_StingGrenade;
	}
	else
	{
		return Slot_PrimaryWeapon;
	}
}

simulated function bool ShouldOfficerUseAgainst(Pawn OtherActor, int ShotsFired)
{
	local SwatPawn SwatPawn;
	local float Distance;

	SwatPawn = SwatPawn(OtherActor);
	if (SwatPawn == None)
	{
		return false;
	}

	// Do not use this -at all- against hostages
	if (SwatPawn.IsA('SwatHostage'))
	{
		return false;
	}

	// Only allow the use of the triple baton ammo
	if (!Ammo.IsA('HK69GL_TripleBatonAmmo'))
	{
		return false;
	}

	// Don't shoot the target if lower than X health
	if (SwatPawn.Health < OfficerUseTargetMinHealth)
	{
		return false;
	}

	// Don't more than X times if the target is stunned already
	if (SwatPawn.IsStung() && ShotsFired >= OfficerUseMaxShotsWhenStung)
	{
		return false;
	}

	Distance = VSize(Owner.Location - OtherActor.Location);
	if (Distance < OfficerUseRangeMin || Distance > OfficerUseRangeMax)
	{
		// Outside of the range
		return false;
	}
	
	return super.ShouldOfficerUseAgainst(OtherActor, ShotsFired);
}

defaultproperties
{
	bPenetratesDoors=false
	OfficerUseRangeMin=256
	OfficerUseRangeMax=1024
	OfficerUseMaxShotsWhenStung=1
	OfficerUseTargetMinHealth=50
}
