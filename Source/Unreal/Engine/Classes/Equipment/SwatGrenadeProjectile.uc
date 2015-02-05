class SwatGrenadeProjectile extends SwatProjectile
    Config(SwatEquipment)
    abstract;

//timers
var protected config float FuseTime;
var protected config float NotifyAIsTime;

var private Timer NotifyAIsTimer;

//bouncing
var protected config float BounceDampening;
var protected config int BounceCount;

//clients interested when this grenade detonates
var array<IInterestedGrenadeThrowing> InterestedGrenadeRegistrants;

var protected float TimeThrown;

//debug
var private vector DebugLastLocation;
var bool bRenderDebugInfo;

var protected bool bShouldSpin; // should the grenade spin?

//direct impact of a grenade fired from the grenade launcher
var private config float DirectImpactDamage;							// Damage done if the projectile directly hits a target when fired from a grenade launcher
var private config float DirectImpactPlayerStingDuration;				// Sting duration if the projectile directly hits a armoured target when fired from a grenade launcher
var private config float DirectImpactHeavilyArmoredPlayerStingDuration;	// Sting duration if the projectile directly hits an heavily armoured target when fired from a grenade launcher
var private config float DirectImpactNonArmoredPlayerStingDuration;		// Sting duration if the projectile directly hits an non-armoured target when fired from a grenade launcher
var private config float DirectImpactAIStingDuration;					// Sting duration if the projectile directly hits an AI target when fired from a grenade launcher
var bool bWasFired;														// True if this projectile was fired from a grenade launcher instead of being thrown

//
// Engine Events
// 

event PostBeginPlay()
{
	Super.PostBeginPlay();

	NotifyAIsTimer = Spawn(class'Timer', self);
	NotifyAIsTimer.timerDelegate = NotifyAIsGrenadeThrown;
	NotifyAIsTimer.startTimer(NotifyAIsTime, false);

    Label = 'Grenade';
    TimeThrown = Level.TimeSeconds;
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games 
    bRenderDebugInfo = class'SwatGrenadeProjectile'.Default.bRenderDebugInfo;
#endif
    NotifyAIsGrenadeThrown();
}

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games 
simulated function DrawTrajectory()
{
    //log(Name$" DrawTrajectory loc="$Location$" lastDebugLoc="$DebugLastLocation);

    if (DebugLastLocation != vect(0,0,0) && Location != DebugLastLocation)
        Level.GetLocalPlayerController().myHUD.AddDebugLine(Location, DebugLastLocation, class'Engine.Canvas'.Static.MakeColor(255,0,0), 5);
    DebugLastLocation = Location;
}
#endif

event Tick(float dTime)
{
    local float Elapsed;
    local Rotator NewRotation;

    //log(Name$" is Ticking at "$Level.TimeSeconds$" debuggingOn="$bRenderDebugInfo);
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games 
    if (bRenderDebugInfo)
    {
        DrawTrajectory();
    }
#endif

    Elapsed = Level.TimeSeconds - TimeThrown;

    if (bShouldSpin)
    {
        NewRotation = Rotation;
        NewRotation.Pitch = Elapsed * -65535 * 2;
        NewRotation.Yaw = -8192 + Elapsed * -60000;

        if (BounceCount == default.BounceCount)
        {
            NewRotation.Roll = 4096;
        }
        else if (BounceCount == 0)
        {
            NewRotation.Roll = 0;
            bShouldSpin = false;
        }
        else
        {
            NewRotation.Roll = -Rotation.Roll / 2;
        }

        SetRotation(NewRotation);
    }
}

event Destroyed()
{
	Super.Destroyed();

	DestroyNotifyAIsTimer();

	// make sure we remove all of our clients interested in grenade detonation
	InterestedGrenadeRegistrants.Remove(0, InterestedGrenadeRegistrants.Length);
}

//
// Notifying AIs
//

private function NotifyAIsGrenadeThrown()
{
	local Pawn Iter;

	for(Iter = Level.pawnList; Iter != None; Iter = Iter.nextPawn)
	{
		if (class'Pawn'.static.checkConscious(Iter) && Iter.IsA('IReactToThrownGrenades'))
		{
			IReactToThrownGrenades(Iter).NotifyGrenadeThrown(self);
		}
	}
}

//
// Registering for Grenade Detonation
//

private function bool IsAnInterestedGrenadeRegistrant(IInterestedGrenadeThrowing Registrant)
{
	local int i;

	for(i=0; i<InterestedGrenadeRegistrants.Length; ++i)
	{
		if (InterestedGrenadeRegistrants[i] == Registrant)
			return true;
	}

	// didn't find it
	return false;
}

function RegisterInterestedGrenadeRegistrant(IInterestedGrenadeThrowing Registrant)
{
	assert(! IsAnInterestedGrenadeRegistrant(Registrant));

	InterestedGrenadeRegistrants[InterestedGrenadeRegistrants.Length] = Registrant;

	Registrant.NotifyRegisteredOnProjectile(self);
}

function UnRegisterInterestedGrenadeRegistrant(IInterestedGrenadeThrowing Registrant)
{
	local int i;

	for(i=0; i<InterestedGrenadeRegistrants.Length; ++i)
	{
		if (InterestedGrenadeRegistrants[i] == Registrant)
		{
			InterestedGrenadeRegistrants.Remove(i, 1);
			break;
		}
	}
}

private function NotifyRegistrantsGrenadeDetonated()
{
	local int i;

	for(i=0; i<InterestedGrenadeRegistrants.Length; ++i)
	{
		InterestedGrenadeRegistrants[i].NotifyGrenadeDetonated(self);
	}
}

//
// Engine Events
//

simulated event HitWall(vector normal, actor wall)
{
	local vector mirror;

    TriggerEffectEvent('Bounced');

    if (BounceCount > 0)
	{
		mirror = MirrorVectorByNormal(Velocity, normal);
		Velocity = mirror * BounceDampening;	
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
    }
}

simulated singular function Touch(Actor Other)
{
    if (Other.bHidden || Other.DrawType == DT_None || Other == Owner || Other.IsA('SwatDoor'))
        return;

	if (bWasFired && BounceCount == default.BounceCount && Other.IsA('IReactToDazingWeapon'))
	{
		// Being hit directly by a fired grenade causes a mild disorientation and deals some damage
		IReactToDazingWeapon(Other).ReactToGLDirectGrenadeHit(Pawn(Owner),
															  DirectImpactDamage, 
															  DirectImpactPlayerStingDuration,
															  DirectImpactHeavilyArmoredPlayerStingDuration,
															  DirectImpactNonArmoredPlayerStingDuration,
															  DirectImpactAIStingDuration);
	}

    HitWall(Location - Other.Location, Other);
}

auto simulated state Live
{
Begin:
    Sleep(FuseTime);

    TriggerEffectEvent(
		'Detonated',    
		,					// use default Other
		,					// use default TargetMaterial
		self.Location,		// location of projectile
		Rotator(vect(0,0,1)) // scorch should always orient downward to avoid weird clipping with the floor
	);
	
	NotifyRegistrantsGrenadeDetonated();

    Detonated();
	DestroyNotifyAIsTimer();
    DoPostDetonation();
}

private simulated function DestroyNotifyAIsTimer()
{
	if (NotifyAIsTimer != None)
	{
		NotifyAIsTimer.timerDelegate = None;
		NotifyAIsTimer.Destroy();
		NotifyAIsTimer = None;
	}
}

simulated function Detonated() { assert(false); }         //subclasses must implement
simulated latent function DoPostDetonation();


defaultproperties
{
    DrawType=DT_StaticMesh
    CollisionRadius=5
    CollisionHeight=5
    bCollideWorld=true
    bShouldSpin=true
}
