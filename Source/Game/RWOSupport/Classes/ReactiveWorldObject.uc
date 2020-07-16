class ReactiveWorldObject extends Engine.HavokActor
    implements  Engine.IReactToFlashbangGrenade,
                Engine.IReactToStingGrenade,
                Engine.ICanBeUsed
	hidecategories(Force, LightColor, Lighting, Object, Sound)
    native;

// WARNING!! If you add an array of handlers to this class, you must also
// add appropriate cleanup code to AReactiveWorldObject::CleanupDestroyed()
// and AReactiveWorldObject::CheckForErrors()
var (Handlers) editinline deepcopy array<Handler_Damaged> DamagedHandlers;
var (Handlers) editinline deepcopy array<Handler_Bumped> BumpedHandlers;
var (Handlers) editinline deepcopy array<Handler_Used> UsedHandlers;
var (Handlers) editinline deepcopy array<Handler_Triggered> TriggeredHandlers;
var (Handlers) editinline deepcopy array<Handler_GrenadeDetonated> GrenadeDetonatedHandlers;
var (Handlers) editinline deepcopy array<Handler_TimerExpired> TimerExpiredHandlers;

var (Handlers) bool UsableNow;

var (Handlers) bool TriggerableNow;

var (Handlers) bool IgnoreZeroDamage;

var (Handlers) bool ShouldReactToTriggeredOnPostBeginPlayInMP;

var bool IsConseptuallyBroken;  //is this RWO "broken" from a visual/gameplay point of view

// RWOs do not get their Havok properties from a HavokDataClass.
// Instead, they copy their own properties into a new HavokData instance.
// This is a workaround for the problem that when you create
// a new subclass in the class browser any 'class' objects in the parent
// are not subclassed when deepcopied -- which screws up property
// inheritance in subclasses (modifying the child changes the parent)
// --------- properties in HavokRigidBody -------------
var(Havok) bool  bHighDetailOnly    "If true, the object will have physics disabled if the level's physics setting is less than PDL_High, or if running on a dedicated server.";
var(Havok) bool  bClientOnly        "If true, the object's physics will be disabled when running on a server (i.e., it will only be physical on clients)";
var(Havok) float hkMass             "The mass of the object.\r\n\r\nWARNING: If mass is set to 0 then the object will be fixed in place, and the hkKeyframed setting will be ignored!";
var(Havok) bool  hkStabilizedInertia "Set this flag to help stabilize the physics of unstable configurations, such as long thin objects. For normal configurations is should be left at the default value of false.";
var(Havok) float hkFriction         "Controls how sticky the object is. Minimum value is 0 and maximum is 1";
var(Havok) float hkRestitution      "Controls how bouncy the object is. Minimum value is 0 and maximum is 1";
var(Havok) float hkLinearDamping    "Controls how much damping is applied to linear velocity. Values are usually very small, and 0 means 'no damping'";
var(Havok) float hkAngularDamping   "Controls how much damping is applied to angular velocity. Values are usually very small, and 0 means 'no damping'";
var(Havok) bool	 hkActive           "If true, the object will be 'physical' as soon as the level starts (e.g., it will fall to the ground, etc). If false, it will be inactive until it is activated (i.e., it will float in space something collides with it, etc.)";
var(Havok) bool	 hkKeyframed        "Only set this to true for objects that should block other physics objects but whose movement is controlled by Unreal instead of physical forces. For example, this should be true for Movers.\r\n\r\nWARNING: this flag is ignored if hkMass is 0!";
var(Havok) vector hkLinearVel       "The initial linear velocity of the object.\r\n\r\nWARNING: this value must be in Unreal units, not meters/second (1 meter = 50 Unreal distance units).";
var(Havok) vector hkAngularVel      "The initial angular velocity of the object.\r\n\r\nWARNING: this value must be in Unreal units, not radians/second (1 radian = 10430.2192 Unreal angular units).";
var(Havok) float hkForceUprightStrength "Governs how quickly an object bounces back when tilted away from its upright axis. Higher values mean that the object recovers more quickly. Values can range from 0 to 1";
var(Havok) float hkForceUprightDamping  "Governs how quickly the oscillation along the vertical axis settles down. Low values create springy behavior, while high values will reduce any oscillations very quickly with the size of the oscillations getting much smaller each time. Values can range from 0 to 1";
var(Havok) HavokRigidBody.EOrientationConstraint hkForceUpright "Controls which, if any, of the object's rotational axes are constrained while moving.\r\n\r\nWARNING: this parameter is ignored hkKeyframed is true or hkMass is 0.";
// note: don't expose these to editor, because they aren't generally supported yet in our integration (see havok ticket 619-117889)
var int hkCollisionLayer;
var int hkCollisionSystemGroup;
var int	hkCollisionSubpartID;
var int	hkCollisionSubpartIgnoreID;
// --------- properties in HavokSkeletalSystem -------------
var(Havok) bool useIntrusionDrivenUpdates "If false, the Havok representation of this skeleton's bones will be updated every frame to match the on-screen bone location. If true, they will only be updated when another Havok object enters a volume rougly twice the size of this actor's bounding volume. This is a performance optimization; in most cases you should leave it at the default setting.\r\n\r\nNOTE: This is automatically set to true at runtime for keyframed (animated) skeletal meshes.";
var(Havok) name SkeletonPhysicsFile       "File from which to load the Havok ragdoll skeleton (e.g., \"myRagdoll.hke\"). File path is relative to \"ProjectRoot\Content\HavokData\".";
var(Havok) float hkJointFriction          "Friction applied to all ragdoll joints";
// ---------------------------------------------------------

// Should this object destroy itself?
var const private transient bool bShouldDestroySelf;


// Called by other objects when they want to destroy this RWO. It in turn
// tells the RWO to destroy itself on the next tick.
simulated native function DestroyRWO();


simulated event PostBeginPlay()
{
    Super.PostBeginPlay();

    //react to being triggered when spawned
    if( ShouldReactToTriggeredOnPostBeginPlayInMP && Level.NetMode != NM_Standalone )
        ReactToTriggered( None );
}


simulated event Destroyed()
{
    // Activate this actor before it's destroyed. This will cause any other
    // objects in its simulation island to be activated. This is needed
    // in case this object is hkActive=true and hasn't been activated
    // before destroyed.
    HavokActivate();
}

simulated event bool TriggerEffectEvent(
    name EffectEvent,
    optional Actor Other,
    optional Material TargetMaterial,
    optional vector HitLocation,
    optional rotator HitNormal,
    optional bool PlayOnOther,
    optional bool QueryOnly,
    optional IEffectObserver Observer,
    optional name ReferenceTag,
    optional name SkipSubsystemWithThisName)
{
    //don't retrigger 'Alive' on RWOs that are conseptually broken
    if (IsConseptuallyBroken && EffectEvent == 'Alive')
        return false;

    Super.TriggerEffectEvent(
            EffectEvent,
            Other,
            TargetMaterial,
            HitLocation,
            HitNormal,
            PlayOnOther,
            QueryOnly,
            Observer);
}

simulated function ReactToDamaged(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
//log( self$"::ReactToDamaged( "$Damage$", "$EventInstigator$", "$HitLocation$", "$Momentum$", "$DamageType$" )" );

    if (Damage == 0 && IgnoreZeroDamage)
        return;

    class'Handler_Damaged'.Static.Dispatch(DamagedHandlers, self, Damage, EventInstigator, HitLocation, Momentum, DamageType);
}

simulated function ReactToBumped(Actor Other)
{
    class'Handler_Bumped'.Static.Dispatch(BumpedHandlers, self, Other);
}

simulated function ReactToUsed(Actor Other)
{
    class'Handler_Used'.Static.Dispatch(UsedHandlers, self, Other);
}

simulated function ReactToTriggered(Actor Other)
{
    class'Handler_Triggered'.Static.Dispatch(TriggeredHandlers, self, Other);
}

simulated function ReactToTimerExpired()
{
    class'Handler_TimerExpired'.Static.Dispatch(TimerExpiredHandlers, self, None);
}

function simulated bool CanBeUsed()
{
    return UsedHandlers.length > 0;
}

simulated event Trigger(Actor Other, Pawn EventInstigator)
{
    BroadcastReactToTriggered(Other);
}

simulated event Timer()
{
    //the only way for designers to set a timer on an RWO is with a Reaction.
    //therefore, if the timer is expiring, then a reaction happened on this machine.
    //since the Triggered and Used events are broadcast over the network,
    //  this means that the timer is set on all clients, and
    //  there's no need to broadcast the ReactToTimerExipred RWO event.
    ReactToTimerExpired();
}

//IReactToFlashbangGrenade implementation

simulated function ReactToFlashbangGrenade(
        SwatGrenadeProjectile Grenade,
		Pawn  Instigator,
        float Damage,
        float DamageRadius,
        Range KarmaImpulse,
        float KarmaImpulseRadius,
        float StunRadius,
        float PlayerStunDuration,
        float AIStunDuration,
        float MoraleModifier)
{
    ReactToGrenade(Grenade, Instigator, Damage, DamageRadius, KarmaImpulse, KarmaImpulseRadius);
}

//IReactToStingGrenade implementation

simulated function ReactToStingGrenade(
        SwatProjectile Grenade,
		Pawn  Instigator,
        float Damage,
        float DamageRadius,
        Range PhysicsImpulse,
        float PhysicsImpulseRadius,
        float StingRadius,
        float PlayerStingDuration,
        float HeavilyArmoredPlayerStingDuration,
		float NonArmoredPlayerStingDuration,
        float AIStingDuration,
        float MoraleModifier)
{
    ReactToGrenade(Grenade, Instigator, Damage, DamageRadius, PhysicsImpulse, PhysicsImpulseRadius);
}

simulated function ReactToGrenade(
        SwatProjectile Grenade,
		Pawn  Instigator,
        float Damage,
        float DamageRadius,
        Range PhysicsImpulse,
        float PhysicsImpulseRadius)
{
    local vector Direction, GrenadeLocation;
    local float  Distance;
    local float  Magnitude;

	if (Grenade != None)
	{
		GrenadeLocation = Grenade.Location;
		Direction       = Location - Grenade.Location;
		Distance        = VSize(Direction);
		if (Instigator == None)
			Instigator = Pawn(Grenade.Owner);
	}
	else
	{
		// Handle less lethal shotgun, cheat commands, and pathological cases.
		GrenadeLocation = Location;
		Distance        = 0;
		if (Instigator != None)
			Direction = Location - Instigator.Location;
		else
			Direction = Location; // just for completeness, this should never
		                          // be reached in practice, except for during debug testing
	}


    // Damage should be applied constantly over DamageRadius
    if (Distance <= DamageRadius)
    {
        //event Actor::
        //  TakeDamage(int Damage,  Pawn EventInstigator,   vector HitLocation, vector Momentum,    class<DamageType> DamageType    );
		    TakeDamage(Damage,      Instigator,             GrenadeLocation,		vect(0,0,0),    class'Engine.GrenadeDamageType' );
    }

    // Any physics impulse should be applied linearly from PhysicsImpulse.Max to
    // PhysicsImpulse.Min over PhysicsImpulseRadius
    if ((Physics == PHYS_Havok || Physics == PHYS_HavokSkeletal) &&
        Distance <= PhysicsImpulseRadius)
    {
        Magnitude = Lerp(Distance / PhysicsImpulseRadius, PhysicsImpulse.Max, PhysicsImpulse.Min);

        // Impart impulse at havok center of mass (which may be different from the Location)
        HavokImpartCOMImpulse(Normal(Direction) * Magnitude);
    }

    class'Handler_GrenadeDetonated'.Static.Dispatch(GrenadeDetonatedHandlers, self, Grenade);
}

/////////////////////////////////////////////////////
// ICanBeUsed Implementation

simulated function bool CanBeUsedNow()
{
    return UsableNow && UsedHandlers.length > 0;
}

simulated function OnUsed(Pawn Other)
{
    dispatchMessage(new class'MessageUsed'(Other.label, self.label));

    BroadcastReactToUsed(Other);
}

simulated function PostUsed();

/////////////////////////////////////////////////////

// Removes all projectors from this RWO.
native simulated final event RemoveProjectors();

defaultproperties
{
    OverrideMomentumToPenetrate=-1
	// Note: Make nodelete false, so RWOs can be destroyed properly.  We guarantee that they will be left around at startup
    // with ROLE_DumbProxy

    //dkaplan: RWOs no longer replicated
    //bNoDelete=false

	bEdShouldSnap=True
	bStatic=False
	bStaticLighting=False
	bShadowCast=True
	bCollideActors=True
    // ckline: FIXME -- see if we can set bBlockActors to true and get non-playerpawns to push them out of the way
	bBlockActors=False
    // ckline: FIXME -- see if we can set bBlockPlayers to true and get player pawns to push them out of the way
	bBlockPlayers=False
	bBlockKarma=False
	bWorldGeometry=False
	bAcceptsProjectors=True
	bWeaponTestsPassThrough=true

    UsableNow=true
    TriggerableNow=true

	// RWO objects only are havok if we tell them to be
	Physics=PHYS_None

    // Placed ReactiveWorldObjects have little effects on networking or the current game session.
    // Setting RemoteRole to ROLE_DumProxy makes it so very little information about this object is replicated...

    //dkaplan: RWOs no longer replicated
    //RemoteRole=ROLE_DumbProxy
    RemoteRole=ROLE_None

    // Optimization: RWO don't receive player shadows.
    bAcceptsShadowProjectors=true

    // -------------------------------------------------------------------------
    // Must manually keep in sync with HavokRigidBody defaultproperties
    // -------------------------------------------------------------------------
    bHighDetailOnly=false
	bClientOnly=false
    hkMass=1
    hkStabilizedInertia=false
    hkFriction=0.8
    hkRestitution=0.3
    hkLinearDamping=0
	hkAngularDamping=0.05
    hkActive=false
	hkKeyframed=false
	hkForceUpright=HKOC_Free
	hkForceUprightStrength = 0.3
	hkForceUprightDamping = 0.9
    // -------------------------------------------------------------------------
    // Must manually keep in sync with HavokSkeletalSystem defaultproperties
    // -------------------------------------------------------------------------
    // ...Currently all are default value according to their type...
    // -------------------------------------------------------------------------

}
