class ReactiveKarmaActor extends ReactiveWorldObject
    config(SwatGame);

var() float				ImpactInterval;
var transient float		LastImpactTime;

var config float        MomentumToKarmaImpulseConversionFactor;

// Default behaviour when shot is to apply an impulse and kick the KActor.
#if IG_SHARED    //tcohen: hooked, used by effects system and reactive world objects
simulated function PostTakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, 
						Vector momentum, class<DamageType> damageType)
#else
simulated function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, 
						Vector momentum, class<DamageType> damageType)
#endif
{
    if (Physics == Phys_Karma) // to facilitate the transition to Havok
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
    else
    {
        Super.PostTakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType);
    }
}

// Default behaviour when triggered is to wake up the physics.
simulated function Trigger( actor Other, pawn EventInstigator )
{
    if (Physics == Phys_Karma) // to facilitate the transition to Havok
    {
#if WITH_KARMA 
        KWake();
#endif
    }
    else
    {
        Super.Trigger(Other,EventInstigator);
    }
}

// 
simulated event KImpact(actor other, vector pos, vector impactVel, vector impactNorm)
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
#endif
		
		LastImpactTime = Level.TimeSeconds;
	}
}

defaultproperties
{
    //TMC copied from KActor:

	DrawType=DT_StaticMesh
    Physics=PHYS_Karma
	bEdShouldSnap=True
	bStatic=False
	bShadowCast=False
	bCollideActors=True
	bCollideWorld=False
    bProjTarget=True
	bBlockActors=false
	bBlockNonZeroExtentTraces=True
	bBlockZeroExtentTraces=True
	bBlockPlayers=false
	bWorldGeometry=False
	bBlockKarma=True
	bAcceptsProjectors=True
    CollisionHeight=+000001.000000
	CollisionRadius=+000001.000000
    // ReactiveKarmaActors want to be ROLE_None, otherwise they would get periodic location updates (RWO default ROLE_DumbProxy) that would fight with the local physics simulation
    RemoteRole=ROLE_None
    // Being ROLE_None and placed, they have to be bNoDelete to ensure that they don't get destroyed at level startup.
    bNoDelete=true
}
