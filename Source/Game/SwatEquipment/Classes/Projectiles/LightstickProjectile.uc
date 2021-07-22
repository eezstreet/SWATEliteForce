class LightstickProjectile extends RWOSupport.ReactiveStaticMesh
    config(SwatEquipment);

var config byte GlowHue;
var config byte GlowSaturation;
var config float GlowBrightness;
var config float GlowLifetime;
var config StaticMesh ExpiredMesh;
var config float MPGlowLifetimeMultiplier;

var vector CurrentVelocity;
var vector CurrentAngular;

var protected float ElapsedTime;
var protected vector LightOffset;
var protected DynamicLightEffect Light;

var int FallCount;

replication
{
	reliable if (Role == ROLE_Authority && bNetInitial)
		ElapsedTime, CurrentVelocity, CurrentAngular, GlowLifetime;
}

simulated event FellOutOfWorld(eKillZType KillType)
{
	local Vector NewLocation;
	local Vector NewVelocity;

	log("---LightstickProjectile "$self$" fell out of world. Its owner was "$Owner);
	if(FallCount >= 6)
	{
		// If we've managed to fall out of the world ten times, then you're one lucky duck and deserve to be dead
		if(Owner.IsA('SwatPawn'))
		{
			log("...refunded a lightstick!");
			SwatPawn(Owner).RefundLightstick();
		}
		Super.FellOutOfWorld(KillType);
	}

	// Try giving it a nudge upwards in a random direction depending on the current FallCount and set its havok velocity to 0
	NewLocation = Location;

	if(FallCount == 0)
	{
		NewLocation.Z = Location.Z + 2.0;
	}
	else if(FallCount == 1)
	{
		NewLocation.Z = Location.Z - 2.0;
	}
	else if(FallCount == 2)
	{
		NewLocation.X = Location.X + 2.0;
	}
	else if(FallCount == 3)
	{
		NewLocation.X = Location.X - 2.0;
	}
	else if(FallCount == 4)
	{
		NewLocation.Y = Location.Y + 2.0;
	}
	else if(FallCount == 5)
	{
		NewLocation.Y = Location.Y - 2.0;
	}

	SetLocation(NewLocation);
	SetInitialVelocity(NewVelocity);
	FallCount++;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	// spawn a dynamic light
	Light = Spawn(class'DynamicLightEffect',self);

	Light.LightBrightness = GlowBrightness;
	Light.LightHue = GlowHue;
	Light.LightSaturation = GlowSaturation;
	Light.LightRadius = 5;

	if (Level.NetMode != NM_Standalone && Role == ROLE_Authority && !Level.IsCOOPServer)
		GlowLifetime *= MPGlowLifetimeMultiplier;
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	Light.LifeSpan = GlowLifetime - ElapsedTime;
}

simulated function SetInitialVelocity(vector Velocity)
{
  CurrentVelocity = Velocity;
  HavokSetLinearVelocity(CurrentVelocity);
}

simulated function Destroyed()
{
	if (Light != None)
		Light.Destroy();
}

auto simulated state Glowing
{
	simulated function Tick(float delta)
	{
		local float Alpha;
	    local Vector HitLoc, HitNorm, EndTrace;
		local Actor HitActor;

		if (Role == ROLE_Authority)
		{
			CurrentVelocity = HavokGetLinearVelocity();
			CurrentAngular = HavokGetAngularVelocity();
		}

		if (Light != None && !Light.bDeleteMe)
		{
			// don't put light through roof or floor
			EndTrace = Location + LightOffset;
			EndTrace.Z += 10;

		    HitActor = Trace( HitLoc, HitNorm, EndTrace );
			if (HitActor == None)
				HitLoc = EndTrace;

			// move light relative to projectile
			Light.SetLocation(HitLoc);

			ElapsedTime = GlowLifetime - Light.LifeSpan;
			Alpha = ElapsedTime / GlowLifetime;

			// Make light fade over lifetime
			Light.LightBrightness = GlowBrightness * (1.0 - Alpha * Alpha);
		}
		else
		{
			GotoState('Expired');
		}
	}

	simulated function ApplyHavok()
	{
		if (Role != ROLE_Authority && CurrentVelocity != Vect(0,0,0))
		{
			HavokSetLinearVelocity(CurrentVelocity);
			HavokSetAngularVelocity(CurrentAngular);
		}
	}

Begin:
	ApplyHavok();
}

state Expired
{
	function BeginState()
	{
		if (Level.NetMode == NM_Standalone)
			SetStaticMesh(ExpiredMesh);
	}

	function Tick(float delta)
	{
		if (Level.NetMode != NM_Standalone)
		{
			if (!PlayerCanSeeMe())
				Destroy();
		}
	}
}

defaultproperties
{
    StaticMesh=StaticMesh'SwatGear2_sm.GlowstickThrown'
	ExpiredMesh=StaticMesh'gear_sef.lightstick_depleted'
	Physics=PHYS_Havok
	bNoDelete=false
	bAlwaysRelevant=false
	bUpdateSimulatedPosition=false
    hkActive=true
	hkMass=0.05
	hkFriction=0.1
	hkRestitution=0.3
	hkStabilizedInertia=true
	CollisionHeight=2
	CollisionRadius=2

	GlowBrightness=192
	GlowHue=90
	GlowSaturation=192
	GlowLifetime=3600
	MPGlowLifetimeMultiplier=0.1

	RemoteRole = ROLE_SimulatedProxy
}
