class TripleBatonProjectile extends Engine.SwatProjectile
	Config(SwatEquipment);

//projectile splitting
var private config float SplitAngle;
var private bool bSpawnedOnBounce;

//bouncing
var private config float BounceDampening;
var private config int BounceCount;

//damage
var config float Damage;

//karma impulse - Karma impulse should be applied linearly from KarmaImpulse.Max to KarmaImpulse.Min over KarmaImpulseRadius
var config Object.Range KarmaImpulse;
var config float KarmaImpulseRadius;

//Sting
var config float PlayerStingDuration;
var config float HeavilyArmoredPlayerStingDuration;
var config float NonArmoredPlayerStingDuration;
var config float AIStingDuration;

private function SpawnSplitProjectile(vector normal, float angle)
{
	local vector projectileVelocity;
	local TripleBatonProjectile newProjectile;

	// Don't split projectiles on a client
	if (Level.NetMode == NM_Client)
		return;

	// Create a new projectile velocity by rotating the parent projectiles velocity around the normal
	projectileVelocity = QuatRotateVector(QuatFromAxisAndAngle(normal, angle), Velocity);

	newProjectile = Spawn(class, Owner,, Location, Rotator(projectileVelocity), true);

	newProjectile.Velocity = projectileVelocity;
	newProjectile.bSpawnedOnBounce = true;			// Avoid recursive splitting
	newProjectile.BounceCount--;					// Keep the bounce counts consistent
}

//
// Engine Events
//

simulated event Tick(float dTime)
{
	SetRotation(Rotator(Velocity));
}

simulated event HitWall(vector normal, actor wall)
{
    TriggerEffectEvent('Bounced');

	DoBounce(normal);
}

simulated function DoBounce(Vector normal)
{
	local vector mirror;

    if (BounceCount > 0)
	{
		mirror = MirrorVectorByNormal(Velocity, normal);
		Velocity = mirror * BounceDampening;

		// If this projectile wasn't spawn from a bounce and this is the first bounce split the projectile
		if (!bSpawnedOnBounce && BounceCount == default.BounceCount)
		{								 // Convert to radians
			SpawnSplitProjectile(normal, SplitAngle * (Pi / 180));
			SpawnSplitProjectile(normal, -SplitAngle * (Pi / 180));
		}

        BounceCount--;
	}
    else // no more bouncing
    {
        Disable('HitWall');
        Disable('Touch');

        // Trigger special event so that grenade can trigger a different
        // visual effect once it stops bouncing. For example, the CSGas
        // grenade releases a smoke trail after it detonates, but doesn't
        // fill the room with smoke until after it stops bouncing.
        TriggerEffectEvent('StoppedBouncing');

		Lifespan = 3.0;
    }
}

simulated singular function Touch(Actor Other)
{
	local float ActualDamage;

    if (Other.bHidden || Other.DrawType == DT_None || Other == Owner || Other.IsA('SwatDoor') || Other.IsA('TripleBatonProjectile'))
        return;

	// Only apply damage if the projectile hits directly
	if (BounceCount == default.BounceCount)
		ActualDamage = Damage;
	else
		ActualDamage = 0.0;

	if (Other.IsA('IReactToDazingWeapon'))
		IReactToDazingWeapon(Other).ReactToGLTripleBaton(
			Pawn(Owner),
			ActualDamage,
			PlayerStingDuration,
			HeavilyArmoredPlayerStingDuration,
			NonArmoredPlayerStingDuration,
			AIStingDuration);

	if (Pawn(Other) != None)
	{
		TriggerEffectEvent('BatonHit');
		DoBounce(Location - Other.Location);
	}
	else
	{
		HitWall(Location - Other.Location, Other);
	}
}

defaultproperties
{
    DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'swatmeshfx2_sm.ammo_baton'
	DrawScale3D=(X=3.0,Y=3.0,Z=3.0)
    CollisionRadius=5
    CollisionHeight=5
    bCollideWorld=true
 }