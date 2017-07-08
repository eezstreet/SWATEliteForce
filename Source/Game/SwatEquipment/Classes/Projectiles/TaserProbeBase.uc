class TaserProbeBase extends Engine.Actor;
// was: class TaserProbeBase extends RWOSupport.ReactiveStaticMesh;

var config int   BounceCount;
var config float BounceDampening;

//
// Engine Events
//

// Set up the initial state of the probe to be positioned by the Taser class
simulated function ResetState() 
{
	BounceCount = Default.BounceCount;
	SetPhysics(PHYS_None);
    SetCollision(false, false, false);
    bCollideWorld=false;
	bBounce=false;
}

// Set up the 'physics' state of the probe to fall and bounce off stuff
simulated function StartPhysics() 
{
	BounceCount = Default.BounceCount;
	SetPhysics(PHYS_Falling);
    SetCollision(true, false, false);
    bCollideWorld=true;
    bBounce=true;
}
										  
simulated event HitWall(vector normal, actor wall)
{
	local vector mirror;

	//log("HitWall: " $ Velocity @ normal @ (Velocity Dot normal));
	if ((Velocity Dot normal) > 0) {
		return;
	}

    if (BounceCount > 0)
	{
		mirror = MirrorVectorByNormal(Velocity, normal);

		Velocity = mirror * BounceDampening;	

        TriggerEffectEvent('Bounced');

        BounceCount--;
	}
    else
    {
        TriggerEffectEvent('Bounced');
        //Disable('HitWall');
        //Disable('Touch');
		SetPhysics(PHYS_None);
    }
}

simulated singular function Touch(Actor Other)
{
    if (Other.bHidden || Other.DrawType == DT_None ||  TaserProbeBase(Other) != None) // || Other.IsA('SwatDoor')) 
        return;

    HitWall(Location - Other.Location, Other);
}

//tcohen: when a probe is optimized out, it should no longer collide
simulated function OnOptimizedOut()
{
    Super.OnOptimizedOut();
    ResetState();
}

// was:     RemoteRole=ROLE_SimulatedProxy

defaultproperties
{
    DrawType=DT_StaticMesh
    CollisionRadius=5
    CollisionHeight=5
    Physics=PHYS_None
    bCollideActors=true
    bCollideWorld=true
    bBounce=true
    bStatic=false
    RemoteRole=ROLE_None
    bAlwaysRelevant=true
	BounceCount=5
	BounceDampening=.5
}
