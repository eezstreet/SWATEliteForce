//=============================================================================
// PhysicsVolume:  a bounding volume which affects actor physics
// Each Actor is affected at any time by one PhysicsVolume
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class PhysicsVolume extends Volume
	native
	nativereplication;

var()		bool		bPainCausing;	 // Zone causes pain.
var()		vector		ZoneVelocity;
var()		vector		Gravity;
var()		float		GroundFriction;
var()		float		TerminalVelocity;
var()		float		DamagePerSec;
var() class<DamageType>	DamageType;
var()		int			Priority;	// determines which PhysicsVolume takes precedence if they overlap
var() sound  EntrySound;	//only if waterzone
var() sound  ExitSound;		// only if waterzone
var() class<actor> EntryActor;	// e.g. a splash (only if water zone)
var() class<actor> ExitActor;	// e.g. a splash (only if water zone)
var() float  FluidFriction;
var() vector ViewFlash, ViewFog;

var()		bool	bDestructive; // Destroys most actors which enter it.
var()		bool	bNoInventory;
var()		bool	bMoveProjectiles;// this velocity zone should impart velocity to projectiles and effects
var()		bool	bBounceVelocity;	// this velocity zone should bounce actors that land in it
var()		bool	bNeutralZone; // Players can't take damage in this zone.
var			bool	bWaterVolume;
var	Info PainTimer;

// Distance Fog
var(VolumeFog) bool   bDistanceFog;	// There is distance fog in this physicsvolume.
var(VolumeFog) color DistanceFogColor;
var(VolumeFog) float DistanceFogStart;
var(VolumeFog) float DistanceFogEnd;

// Karma
var(Karma)	   float KExtraLinearDamping; // Extra damping applied to Karma actors in this volume.
var(Karma)	   float KExtraAngularDamping;
var(Karma)	   float KBuoyancy;			  // How buoyant Karma things are in this volume (if bWaterVolume true). Multiplied by Actors KarmaParams->KBuoyancy.

var PhysicsVolume NextPhysicsVolume;

replication
{
	// Things the server should send to the client.
	reliable if( bNetDirty && (Role==ROLE_Authority) )
		Gravity;
}

/* Called when an actor in this PhysicsVolume changes its physics mode
*/
event PhysicsChangedFor(Actor Other);

event ActorEnteredVolume(Actor Other);
event ActorLeavingVolume(Actor Other);

event PawnEnteredVolume(Pawn Other)
{
	if ( Other.IsPlayerPawn() )
		TriggerEvent(Event,self, Other);
}

event PawnLeavingVolume(Pawn Other)
{
	if ( Other.IsPlayerPawn() )
		UntriggerEvent(Event,self, Other);
}

/*
TimerPop
damage touched actors if pain causing.
since PhysicsVolume is static, this function is actually called by a volumetimer
*/
function TimerPop(VolumeTimer T)
{
	local actor A;
	local bool bFound;

	if ( T == PainTimer )
	{
		if ( !bPainCausing )
		{
			PainTimer.Destroy();
			return;
		}
		ForEach TouchingActors(class'Actor', A)
			if ( A.bCanBeDamaged && !A.bStatic )
			{
			CausePainTo(A);
				bFound = true;
			}
			
		if ( !bFound )
			PainTimer.Destroy();
	}
}

function Trigger( actor Other, pawn EventInstigator )
{
	// turn zone damage on and off
	if (DamagePerSec != 0)
	{
		bPainCausing = !bPainCausing;
		if ( bPainCausing && (PainTimer == None) )
			PainTimer = spawn(class'VolumeTimer', self);
	}
}

event touch(Actor Other)
{
	local Pawn P;
	local bool bFoundPawn;
	
	Super.Touch(Other);
	if ( Other == None )
		return;
	if ( bNoInventory && Other.IsA('Inventory') && (Other.Owner == None) )
	{
		Other.LifeSpan = 1.5;
		return;
	}
	if ( bMoveProjectiles && (ZoneVelocity != vect(0,0,0)) )
	{
		if ( Other.Physics == PHYS_Projectile )
			Other.Velocity += ZoneVelocity;
		else if ( Other.IsA('Effects') && (Other.Physics == PHYS_None) )
		{
			Other.SetPhysics(PHYS_Projectile);
			Other.Velocity += ZoneVelocity;
		}
	}
	if ( bPainCausing )
	{
		if ( Other.bDestroyInPainVolume )
		{
			Other.Destroy();
			return;
		}
		if ( Other.bCanBeDamaged && !Other.bStatic )
		{
		CausePainTo(Other);
			if ( PainTimer == None )
				PainTimer = Spawn(class'VolumeTimer', self);
			else if ( Pawn(Other) != None )
			{
				ForEach TouchingActors(class'Pawn', P)
					if ( (P != Other) && P.bCanBeDamaged )
					{
						bFoundPawn = true;
						break;
					}
				if ( !bFoundPawn )
					PainTimer.SetTimer(1.0,true);
			}
		}
	}
	if ( bWaterVolume && Other.CanSplash() )
		PlayEntrySplash(Other);
}

function PlayEntrySplash(Actor Other)
{
	local float SplashSize;
	local actor splash;

	splashSize = FClamp(0.00003 * Other.Mass * (250 - 0.5 * FMax(-600,Other.Velocity.Z)), 0.1, 1.0 );
	if( EntrySound != None )
	{
#if IG_EFFECTS
		PlaySound(EntrySound, splashSize);
#else
		PlaySound(EntrySound, SLOT_Interact, splashSize);
#endif
		if ( Other.Instigator != None )
			MakeNoise(SplashSize);
	}
	if( EntryActor != None )
	{
		splash = Spawn(EntryActor); 
		if ( splash != None )
			splash.SetDrawScale(splashSize);
	}
}

event untouch(Actor Other)
{
	if ( bWaterVolume && Other.CanSplash() )
		PlayExitSplash(Other);
}

function PlayExitSplash(Actor Other)
{
	local float SplashSize;
	local actor splash;

	splashSize = FClamp(0.003 * Other.Mass, 0.1, 1.0 );
	if( ExitSound != None )
#if IG_EFFECTS
        PlaySound(ExitSound, splashSize);
#else
		PlaySound(ExitSound, SLOT_Interact, splashSize);
#endif
	if( ExitActor != None )
	{
		splash = Spawn(ExitActor); 
		if ( splash != None )
			splash.SetDrawScale(splashSize);
	}
}

function CausePainTo(Actor Other)
{
	local float depth;
	local Pawn P;

	// FIXMEZONE figure out depth of actor, and base pain on that!!!
	depth = 1;
	P = Pawn(Other);

	if ( DamagePerSec > 0 )
	{
		if ( Region.Zone.bSoftKillZ && (Other.Physics != PHYS_Walking) )
			return;
		Other.TakeDamage(int(DamagePerSec * depth), None, Location, vect(0,0,0), DamageType); 
		if ( (P != None) && (P.Controller != None) )
			P.Controller.PawnIsInPain(self);
	}	
	else
	{
		if ( (P != None) && (P.Health < P.Default.Health) )
		P.Health = Min(P.Default.Health, P.Health - depth * DamagePerSec);
	}
}

defaultproperties
{
    Gravity=(X=0.000000,Y=0.000000,Z=-1500.000000)
	FluidFriction=+0.3
    TerminalVelocity=+02500.000000
	bAlwaysRelevant=true
	bOnlyDirtyReplication=true
    GroundFriction=+00008.000000
	KBuoyancy=1.0
	NetUpdateFrequency=5
	bSkipActorPropertyReplication=true
}