class GrenadeLauncherBase extends RoundBasedWeapon;

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
		SwatGrenadeProjectile(Grenade).bWasFired = true;

    Grenade.Velocity = ShotVector * MuzzleVelocity;
}
