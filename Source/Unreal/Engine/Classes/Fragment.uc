//=============================================================================
// Fragment.
//=============================================================================
class Fragment extends Effects;

var() MESH Fragments[11];
var int numFragmentTypes;
var bool bFirstHit;
var() sound    ImpactSound, AltImpactSound;		
var()	float  SplashTime;

function bool CanSplash()
{
	if ( (Level.TimeSeconds - SplashTime > 0.25)
		&& (Physics == PHYS_Falling)
		&& (Abs(Velocity.Z) > 100) )
	{
		SplashTime = Level.TimeSeconds;
		return true;
	}
	return false;
}


simulated function CalcVelocity(vector Momentum)
{
	local float ExplosionSize;

	ExplosionSize = 0.011 * VSize(Momentum);
	Velocity = 0.0033 * Momentum + 0.7 * VRand()*(ExplosionSize+FRand()*100.0+100.0); 
	Velocity.z += 0.5 * ExplosionSize;
}

simulated function HitWall (vector HitNormal, actor HitWall)
{
	local float speed;

	Velocity = 0.5*(( Velocity dot HitNormal ) * HitNormal * (-2.0) + Velocity);   // Reflect off Wall w/damping
	speed = VSize(Velocity);	
	if (bFirstHit && speed<400) 
	{
		bFirstHit=False;
		bRotatetoDesired=True;
		bFixedRotationDir=False;
		DesiredRotation.Pitch=0;	
		DesiredRotation.Yaw=FRand()*65536;
		DesiredRotation.roll=0;
	}
	RotationRate.Yaw = RotationRate.Yaw*0.75;
	RotationRate.Roll = RotationRate.Roll*0.75;
	RotationRate.Pitch = RotationRate.Pitch*0.75;
	if ( (speed < 60) && (HitNormal.Z > 0.7) )
	{
		SetPhysics(PHYS_none);
		bBounce = false;
		GoToState('Dying');
	}
	else if (speed > 80) 
	{
#if IG_EFFECTS
		if (FRand()<0.5) 
			PlaySound(ImpactSound, ,, 300, 300, 0.85+FRand()*0.3, 0,, true);
		else 
			PlaySound(AltImpactSound, ,, 300, 300, 0.85+FRand()*0.3, 0,, true);
#else
		if (FRand()<0.5) 
			PlaySound(ImpactSound, SLOT_None,,, 300, 0.85+FRand()*0.3,true);
		else 
			PlaySound(AltImpactSound, SLOT_None,,, 300, 0.85+FRand()*0.3,true);
#endif
	}
}

simulated final function RandSpin(float spinRate)
{
	DesiredRotation = RotRand();
	RotationRate.Yaw = spinRate * 2 *FRand() - spinRate;
	RotationRate.Pitch = spinRate * 2 *FRand() - spinRate;
	RotationRate.Roll = spinRate * 2 *FRand() - spinRate;	
}

auto state Flying
{
	simulated function timer()
	{
		GoToState('Dying');
	}

	simulated singular function PhysicsVolumeChange( PhysicsVolume NewVolume )
	{
		if ( NewVolume.bWaterVolume )
		{
			Velocity = 0.2 * Velocity;
			if (bFirstHit) 
			{
				bFirstHit=False;
				bRotatetoDesired=True;
				bFixedRotationDir=False;
				DesiredRotation.Pitch=0;	
				DesiredRotation.Yaw=FRand()*65536;
				DesiredRotation.roll=0;
			}
			
			RotationRate = 0.2 * RotationRate;
			GotoState('Dying');
		}
	}

	simulated function BeginState()
	{
		RandSpin(125000);
		if (abs(RotationRate.Pitch)<10000) 
			RotationRate.Pitch=10000;
		if (abs(RotationRate.Roll)<10000) 
			RotationRate.Roll=10000;			
		LinkMesh(Fragments[int(FRand()*numFragmentTypes)]);
		if ( Level.NetMode == NM_Standalone )
			LifeSpan = 20 + 40 * FRand();
		SetTimer(5.0,True);			
	}
}

state Dying
{
#if IG_SHARED  //tcohen: hooked TakeDamage(), used by effects system and reactive world objects
	function PostTakeDamage( int Dam, Pawn instigatedBy, Vector hitlocation, 
							Vector momentum, class<DamageType> damageType)
#else
	function TakeDamage( int Dam, Pawn instigatedBy, Vector hitlocation, 
							Vector momentum, class<DamageType> damageType)
#endif
	{
		Destroy();
	}

	simulated function timer()
	{
		if ( !PlayerCanSeeMe() ) 
			Destroy();
	}

	simulated function BeginState()
	{
		SetTimer(1 + FRand(),True);
		SetCollision(true, false, false);
	}
}

defaultproperties
{
	 bDestroyInPainVolume=true
     bFirstHit=True
     CollisionRadius=+00018.000000
     CollisionHeight=+00004.000000
     Physics=PHYS_Falling
     bBounce=True
     bFixedRotationDir=True
	 bCollideActors=false
     bCollideWorld=True
     LifeSpan=+00020.000000
     DrawType=DT_Mesh
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications 
//     SoundVolume=0
//#endif
	 RemoteRole=ROLE_None
}

