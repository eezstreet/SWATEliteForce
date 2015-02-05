// Havok actor that imparts forces on the underlying body (s) when shot etc
// It also initializes the Actor fields to reasonable defaults for a 
// rigid body constructed from a StaticMesh.

class HavokActor extends Actor
	native
#if IG_SWAT
    config(SwatGame)
#endif
	placeable;

cpptext
{
#ifdef UNREAL_HAVOK
	virtual void Spawned();
#endif
}

var (Havok)	bool bAcceptsShotImpulse "If true, an impulse will be imparted to this object when it takes damage";
var config float MomentumToHavokImpulseConversionFactor;

#if IG_SWAT
// ckline -- Commented out ImpactInterval for now, since no existing classes 
// use it! Probably will need to do something slightly different for Havok, since
// it supports callbacks (with time delays constraints) natively in the API
//
//var(Havok)      protected float	ImpactInterval "Minimum amount of time (in seconds) that must pass after a collision Effect Event is triggered before a subsequent event will be triggered";

#if IG_SWAT // ckline
var(Ballistics) protected float OverrideMomentumToPenetrate "If this is > -1, then OverrideMomentumToPenetrate is used instead of its Material's MomentumToPenetrate when calculating impact ballistics.";
var(Ballistics) config protected float MaxImpulseToMassRatio "If this object receives a ballistic impact, the magnitude of the applied impulse will be capped such that Magnitude(Impulse)/hkMassOfThisObject) is less than this value";
#endif

simulated function float GetMomentumToPenetrate(vector HitLocation, vector HitNormal, Material MaterialHit)
{
    if (OverrideMomentumToPenetrate <= -1)
        return MaterialHit.MomentumToPenetrate;
    else
        return OverrideMomentumToPenetrate;
}
#endif
 
simulated event TakeHitImpulse(vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
	local vector impulseDir;
    local float impulseMag;
    local HavokRigidBody rb;

    if( bAcceptsShotImpulse )
	{
		
#if IG_SWAT // ckline
		impulseDir = Normal(momentum);
        impulseMag = VSize(momentum);
		
        if(impulseMag < 0.001)
			return;
        
        impulseMag *= MomentumToHavokImpulseConversionFactor;

        rb = HavokRigidBody(HavokData);

        if (Level.AnalyzeBallistics)
        {
            // change in linear velocity from the impulse should be around momentum/mass
            log("[BALLISTICS] The HavokActor (HavokIsActive="$HavokIsActive()$") named "$name$" took a shot from a gun:");
            log("   Momentum magnitude = "$VSize(Momentum)$", direction = "$Normal(Momentum));
            log("   MomentumToHavokImpulseConversionFactor = "$MomentumToHavokImpulseConversionFactor);
            log("   Converted impulse mag = "$VSize(Momentum)$" * "$MomentumToHavokImpulseConversionFactor$" = "$impulseMag);
            if (rb != None)
            {
                log("     Mass of actor ="$rb.hkMass);
                log("     Impulse/Mass  ="$(impulseMag/rb.hkMass));
                log("     MaxImpulseToMassRatio  ="$MaxImpulseToMassRatio);
            }
        }

		impulseMag = ClampImpulse(impulseMag);
        if (Level.AnalyzeBallistics)
        {
            log("     After clamping to "$MaxImpulseToMassRatio);
            log("       -> Impulse mag  = "$impulseMag);
            log("       -> Impulse/Mass = "$(impulseMag/rb.hkMass));
        }

        if (Level.AnalyzeBallistics)
        {
            log("   Velocity of actor prior to impulse:  Linear = "$VSize(HavokGetLinearVelocity())$", Angular = "$VSize(HavokGetAngularVelocity()));
        }
        HavokImpartImpulse(impulseMag * impulseDir, hitlocation);
#else
		if(VSize(momentum) < 0.001)
			return;
        HavokImpartImpulse(Normal(momentum) * damageType.default.hkHitImpulseScale, hitlocation);
#endif


#if IG_SWAT // ckline
        if (Level.AnalyzeBallistics)
            log("   Velocity of actor after the impulse: Linear = "$VSize(HavokGetLinearVelocity())$", Angular = "$VSize(HavokGetAngularVelocity()));
#endif
    }
}

// dbeswick: impulse to mass ratio clamping
#if IG_SWAT 
simulated function float ClampImpulse( float impulseMag )
{
    local HavokRigidBody rb;
    rb = HavokRigidBody(HavokData);

	if ( rb != None && ( (impulseMag/rb.hkMass) > MaxImpulseToMassRatio) )
    {
        // clamp impulseMag so that impulseMag/rb.hkMass = MaxImpulseToMassRatio
        impulseMag = MaxImpulseToMassRatio * rb.hkMass;
	}

	return impulseMag;
}
#endif

simulated function Trigger( actor Other, pawn EventInstigator )
{
	HavokActivate();
}

defaultproperties
{
//#if IG_SWAT
    OverrideMomentumToPenetrate=-1
    MomentumToHavokImpulseConversionFactor=1
    bStasis=true
//#endif

	Texture=Texture'Engine_res.Havok.S_HkActor'
	bAcceptsShotImpulse=true
	DrawType=DT_StaticMesh
	Physics=PHYS_Havok
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
	bBlockHavok=True
	bAcceptsProjectors=True
    CollisionHeight=+000001.000000
	CollisionRadius=+000001.000000
	bNoDelete=true
    RemoteRole=ROLE_None
//#if IG_SWAT 
    MaxImpulseToMassRatio=100000
    bAlwaysRelevant=true
//#endif
}

