//=============================================================================
// KarmaActor.
// Just a handy class to derive off to make physics objects.
//=============================================================================

class KActor extends Actor
	native
    config(SwatGame)
	placeable;

cpptext
{
	virtual void Spawned();
}

var (Karma)		bool		bKTakeShot;

// Ragdoll impact sounds.
var() array<sound>		ImpactSounds;
var() float				ImpactVolume;

var() class<actor>		ImpactEffect;
var() bool				bOrientImpactEffect;

var() float				ImpactInterval;
var transient float		LastImpactTime;

var config float        MomentumToKarmaImpulseConversionFactor;

#if IG_SWAT
var(Ballistics) float OverrideMomentumToPenetrate "If this is > -1, then OverrideMomentumToPenetrate is used instead of its Material's MomentumToPenetrate when calculating impact ballistics.";

simulated function float GetMomentumToPenetrate(vector HitLocation, vector HitNormal, Material MaterialHit)
{
    if (OverrideMomentumToPenetrate > -1)
        return OverrideMomentumToPenetrate;
    else
        return MaterialHit.MomentumToPenetrate;
}
#endif

// Default behaviour when shot is to apply an impulse and kick the KActor.
#if IG_SHARED    //tcohen: hooked, used by effects system and reactive world objects
function PostTakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, 
						Vector momentum, class<DamageType> damageType)
#else
function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, 
						Vector momentum, class<DamageType> damageType)
#endif
{
	if(bKTakeShot)
	{
		if(VSize(momentum) < 0.001)
		{
			// DEBUG
			//Log("Zero momentum to KActor.TakeDamage");
			// END DEBUG
			return;
		}
	
        if (Level.AnalyzeBallistics)
            log("[BALLISTICS] The KActor named "$name$" took damage with Momentum="$VSize(Momentum)$".  MomentumToKarmaImpulseConversionFactor="$MomentumToKarmaImpulseConversionFactor$".  Adding Karma impulse "$VSize(Momentum * MomentumToKarmaImpulseConversionFactor));

#if WITH_KARMA
        KAddImpulse(Momentum * MomentumToKarmaImpulseConversionFactor, hitlocation);
#endif
    }
}

// Default behaviour when triggered is to wake up the physics.
function Trigger( actor Other, pawn EventInstigator )
{
#if WITH_KARMA
    KWake();
#endif
}

// 
event KImpact(actor other, vector pos, vector impactVel, vector impactNorm)
{
#if IG_EFFECTS
#else
	local int numSounds, soundNum;
#endif

    //TMC TODO if we want to use KarmaImpactedHandlers, then add a call here

	// If its time for another impact.
	if(Level.TimeSeconds > LastImpactTime + ImpactInterval)
	{
#if IG_EFFECTS
        TriggerEffectEvent('KarmaImpacted');
        //TMC TODO trace in the -impactNorm direction to find impactMaterial, and pass that to TriggerEffectEvent
#else
		// If we have some sounds, play a random one.
		numSounds = ImpactSounds.Length;
		if(numSounds > 0)
		{
			soundNum = Rand(numSounds);
			//Log("Play Sound:"$soundNum);
			PlaySound(ImpactSounds[soundNum], SLOT_Ambient, ImpactVolume);
		}
		
		// If we have an effect class (and its relevant), spawn it.
		if( (ImpactEffect != None) && EffectIsRelevant(pos, false) )
		{
			if(bOrientImpactEffect)
				spawn(ImpactEffect, self, , pos, rotator(impactVel));
			else
				spawn(ImpactEffect, self, , pos);
		}
#endif
		
		LastImpactTime = Level.TimeSeconds;
	}
}

defaultproperties
{
    //TMC added OverrideMomentumToPenetrate
    OverrideMomentumToPenetrate=-1

	bKTakeShot=true;
	DrawType=DT_StaticMesh
	//StaticMesh=StaticMesh'MiscPhysicsMeshes.Barrels.Barrel1'
    Physics=PHYS_Karma
	bEdShouldSnap=True
	bStatic=False
	bShadowCast=False
	bCollideActors=True
	bCollideWorld=False
    bProjTarget=True
	bBlockActors=True
	bBlockNonZeroExtentTraces=True
	bBlockZeroExtentTraces=True
	bBlockPlayers=True
	bWorldGeometry=False
	bBlockKarma=True
	bAcceptsProjectors=True
    CollisionHeight=+000001.000000
	CollisionRadius=+000001.000000
	bNoDelete=true
	RemoteRole=ROLE_None
}

