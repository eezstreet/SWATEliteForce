//=============================================================================
// Projectile.
//
// A delayed-hit projectile that moves around for some time after it is created.
//=============================================================================
class Projectile extends Actor
	abstract
	native;

//-----------------------------------------------------------------------------
// Projectile variables.

// Motion information.
var		float   Speed;               // Initial speed of projectile.
var		float   MaxSpeed;            // Limit on speed of projectile (0 means no limit)
var		float	TossZ;
var		Actor	ZeroCollider;
var		bool	bSwitchToZeroCollision; // if collisionextent nonzero, and hit actor with bBlockNonZeroExtents=0, switch to zero extent collision

// Damage attributes.
var   float    Damage; 
var	  float	   DamageRadius;        
var   float	   MomentumTransfer; // Momentum magnitude imparted by impacting projectile.
var   class<DamageType>	   MyDamageType;

// Projectile sound effects
var   sound    SpawnSound;		// Sound made when projectile is spawned.
var   sound	   ImpactSound;		// Sound made when projectile hits something.

// explosion effects
var   class<Projector> ExplosionDecal;
var   float		ExploWallOut;	// distance to move explosions out from wall

//==============
// Encroachment
function bool EncroachingOn( actor Other )
{
	if ( (Other.Brush != None) || (Brush(Other) != None) )
		return true;
		
	return false;
}

//==============
// Touching
simulated singular function Touch(Actor Other)
{
	local actor HitActor;
	local vector HitLocation, HitNormal, VelDir, AdjustedLocation;
	local bool bBeyondOther;
	local float BackDist, DirZ;

	if ( Other == None ) // Other just got destroyed in its touch?
		return;
	if ( Other.bProjTarget || (Other.bBlockActors && Other.bBlockPlayers) )
	{
		if ( Velocity == vect(0,0,0) || Other.IsA('Mover') ) 
		{
			ProcessTouch(Other,Location);
			return;
		}
		
		//get exact hitlocation - trace back along velocity vector
		bBeyondOther = ( (Velocity Dot (Location - Other.Location)) > 0 );
		VelDir = Normal(Velocity);
		DirZ = sqrt(abs(VelDir.Z));
		BackDist = Other.CollisionRadius * (1 - DirZ) + Other.CollisionHeight * DirZ;
		if ( bBeyondOther )
			BackDist += VSize(Location - Other.Location);
		else
			BackDist -= VSize(Location - Other.Location);

	 	HitActor = Trace(HitLocation, HitNormal, Location, Location - 1.1 * BackDist * VelDir, true);
		if (HitActor == Other)
			AdjustedLocation = HitLocation;
		else if ( bBeyondOther )
			AdjustedLocation = Other.Location - Other.CollisionRadius * VelDir;
		else
			AdjustedLocation = Location;
		ProcessTouch(Other, AdjustedLocation);
		if ( (Role < ROLE_Authority) && (Other.Role == ROLE_Authority) )
			ClientSideTouch(Other, AdjustedLocation);
	}
	}

/* ClientSideTouch()
Allows client side actors (with Role==ROLE_Authority on the client, like ragdolls)
to be affected by projectiles
*/
simulated function ClientSideTouch(Actor Other, Vector HitLocation)
{
	Other.TakeDamage(Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
}

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
	if ( Other != Instigator )
		Explode(HitLocation,Normal(HitLocation-Other.Location));
}

simulated function HitWall (vector HitNormal, actor Wall)
{
	if ( Role == ROLE_Authority )
	{
		if ( Mover(Wall) != None )
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);

		MakeNoise(1.0);
	}
	Explode(Location + ExploWallOut * HitNormal, HitNormal);
	if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) )
		Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
}

simulated function BlowUp(vector HitLocation)
{
	HurtRadius(Damage,DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
	if ( Role == ROLE_Authority )
		MakeNoise(1.0);
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	Destroy();
}

simulated final function RandSpin(float spinRate)
{
	DesiredRotation = RotRand();
	RotationRate.Yaw = spinRate * 2 *FRand() - spinRate;
	RotationRate.Pitch = spinRate * 2 *FRand() - spinRate;
	RotationRate.Roll = spinRate * 2 *FRand() - spinRate;	
}

static function vector GetTossVelocity(Pawn P, Rotator R)
{
	local vector V;

	V = Vector(R);
	V *= ((P.Velocity Dot V)*0.4 + Default.Speed);
	V.Z += Default.TossZ;
	return V;
}

defaultproperties
{
	bCanBeDamaged=true
	 bAcceptsProjectors=false
	 bUseCylinderCollision=true
	 DamageRadius=+220.0
     MaxSpeed=+02000.000000
     DrawType=DT_Mesh
     Texture=S_Camera
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications 
//   SoundVolume=0
//#endif
     CollisionRadius=+00000.000000
     CollisionHeight=+00000.000000
     bCollideActors=True
     bCollideWorld=True
	 bNetTemporary=true
	 bGameRelevant=true
	 bReplicateInstigator=true
     Physics=PHYS_Projectile
     LifeSpan=+0014.000000
     NetPriority=+00002.500000
	 MyDamageType=class'DamageType'
	 RemoteRole=ROLE_SimulatedProxy
	 bUnlit=true
	 TossZ=+100.0
     bNetInitialRotation=true
	 bDisturbFluidSurface=true
}
