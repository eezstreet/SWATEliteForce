//=============================================================================
// Decoration.
//=============================================================================
class Decoration extends Actor
	abstract
	placeable
	native;

// If set, the pyrotechnic or explosion when item is damaged.
var()  class<actor> EffectWhenDestroyed;
var() bool bPushable;
var() bool bDamageable;
var bool bPushSoundPlaying;
var bool bSplash;

var() sound PushSound, EndPushSound;
var const int	 numLandings;		// Used by engine physics.
var() class<inventory> contents;	// spawned when destroyed

var()	int		NumFrags;		// number of fragments to spawn when destroyed
var()	texture	FragSkin;		// skin to use for fragments
var()	class<Fragment> FragType;	// type of fragment to use
var		vector FragMomentum;		// momentum to be imparted to frags when destroyed
var()	int		Health;
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

function Drop(vector newVel);

function Landed(vector HitNormal)
{
	local rotator NewRot;

	if (Velocity.Z<-500) 
		TakeDamage(100,Pawn(Owner),HitNormal,HitNormal*10000,class'Crushed');	
	Velocity = vect(0,0,0);
	NewRot = Rotation;
	NewRot.Pitch = 0;
	NewRot.Roll = 0;
	SetRotation(NewRot);
}

function HitWall (vector HitNormal, actor Wall)
{
	Landed(HitNormal);
}

#if IG_SHARED  //tcohen: hooked TakeDamage(), used by effects system and reactive world objects
function PostTakeDamage( int NDamage, Pawn instigatedBy, Vector hitlocation, 
					Vector momentum, class<DamageType> damageType)
#else
function TakeDamage( int NDamage, Pawn instigatedBy, Vector hitlocation, 
					Vector momentum, class<DamageType> damageType)
#endif
{
	Instigator = InstigatedBy;
	if (!bDamageable || (Health<0) ) 
		Return;
	if ( Instigator != None )
		MakeNoise(1.0);
	Health -= NDamage;
	FragMomentum = Momentum;
	if (Health <0) 	
		Destroy();		
	else 
	{
		SetPhysics(PHYS_Falling);
		Momentum.Z = 1000;
		Velocity=Momentum/Mass;
	}
}

singular function PhysicsVolumeChange( PhysicsVolume NewVolume )
{
	if( NewVolume.bWaterVolume )
	{
		if( bSplash && !PhysicsVolume.bWaterVolume && Mass<=Buoyancy 
			&& ((Abs(Velocity.Z) < 100) || (Mass == 0)) && (FRand() < 0.05) && !PlayerCanSeeMe() )
		{
			bSplash = false;
			SetPhysics(PHYS_None);
		}
	}
	if( PhysicsVolume.bWaterVolume && (Buoyancy > Mass) )
	{
		if( Buoyancy > 1.1 * Mass )
			Buoyancy = 0.95 * Buoyancy; // waterlog
		else if( Buoyancy > 1.03 * Mass )
			Buoyancy = 0.99 * Buoyancy;
	}
}

function Trigger( actor Other, pawn EventInstigator )
{
	Instigator = EventInstigator;
	TakeDamage( 1000, Instigator, Location, Vect(0,0,1)*900, class'Crushed');
}

singular function BaseChange()
{
	if( Velocity.Z < -500 )
		TakeDamage( (1-Velocity.Z/30),Instigator,Location,vect(0,0,0) , class'Crushed');

	if( base == None )
	{ 
		if ( !bInterpolating && bPushable && (Physics == PHYS_None) )
			SetPhysics(PHYS_Falling);
	}
	else if( Pawn(Base) != None )
	{
		Base.TakeDamage( (1-Velocity.Z/400)* mass/Base.Mass,Instigator,Location,0.5 * Velocity , class'Crushed');
		Velocity.Z = 100;
		if (FRand() < 0.5)
			Velocity.X += 70;
		else
			Velocity.Y += 70;
		SetPhysics(PHYS_Falling);
	}
	else if( Decoration(Base)!=None && Velocity.Z<-500 )
	{
		Base.TakeDamage((1 - Mass/Base.Mass * Velocity.Z/30), Instigator, Location, 0.2 * Velocity, class'Crushed');
		Velocity.Z = 100;
		if (FRand() < 0.5)
			Velocity.X += 70;
		else
			Velocity.Y += 70;
		SetPhysics(PHYS_Falling);
	}
	else
		instigator = None;
}

simulated function Destroyed()
{
	local inventory dropped;
	local int i;
	local Fragment s;
	local float BaseSize;

	if ( Role == ROLE_Authority )
	{
		if( (Contents!=None) && !Level.bStartup )
		{
			dropped = Spawn(Contents);
#if !IG_SWAT // ckline: we don't support this
			dropped.DropFrom(Location);
#endif
		}	

		TriggerEvent( Event, Self, None);

		if ( bPushSoundPlaying )
#if IG_EFFECTS
            PlaySound(EndPushSound);
#else
			PlaySound(EndPushSound, SLOT_Misc);
#endif
	}
		
	if ( (Level.NetMode != NM_DedicatedServer ) 
		&& !PhysicsVolume.bDestructive
		&& (NumFrags > 0) && (FragType != None) )
	{
		// spawn fragments
		BaseSize = 0.8 * sqrt(CollisionRadius*CollisionHeight)/NumFrags;
		for ( i=0; i<numfrags; i++ )
		{
			s = Spawn( FragType, Owner,,Location + CollisionRadius * VRand());
			s.CalcVelocity(FragMomentum);
			if ( FragSkin != None )
				s.Skins[0] = FragSkin;
			s.SetDrawScale(BaseSize * (0.5+0.7*FRand()));
		}
	}

	Super.Destroyed();
}

function Timer()
{
#if IG_EFFECTS
	PlaySound(EndPushSound);
#else
	PlaySound(EndPushSound, SLOT_Misc);
#endif
	bPushSoundPlaying=False;
}

#if IG_RWO    //tcohen: reactive world objects
function PostBump( actor Other )
#else
function Bump( actor Other )
#endif
{
	local float speed, OldZ;
	if( bPushable && (Pawn(Other)!=None) && (Other.Mass > 40) )
	{
		oldZ = Velocity.Z;
		speed = VSize(Other.Velocity);
		Velocity = Other.Velocity * FMin(120.0, 20 + speed)/speed;
		if ( Physics == PHYS_None ) 
		{
			Velocity.Z = 25;
			if (!bPushSoundPlaying) 
			{
#if IG_EFFECTS
                PlaySound(PushSound);
#else
				PlaySound(PushSound, SLOT_Misc);
#endif
				bPushSoundPlaying = True;
			}			
		}
		else
			Velocity.Z = oldZ;
		SetPhysics(PHYS_Falling);
		SetTimer(0.3,False);
		Instigator = Pawn(Other);
	}
}

defaultproperties
{
     bStatic=True
     bStasis=True
     Mass=100.000000
     DrawType=DT_Mesh
	 bOrientOnSlope=true
	 bShouldBaseAtStartup=true
	 NetUpdateFrequency=10
}
