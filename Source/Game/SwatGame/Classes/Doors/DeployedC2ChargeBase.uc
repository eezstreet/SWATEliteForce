class DeployedC2ChargeBase extends RWOSupport.DeployedTacticalAid
    Implements IAmUsedByToolkit, ICanBeDisabled, SwatAICommon.IDeployedC2Charge, IDisableableByAI
    config(SwatEquipment);

var(C2Charge) StaticMesh PreviewStaticMesh;

//in seconds, the time required to qualify to remove a C2Charge with a Toolkit
var config float QualifyTimeForToolkit;

var config float Damage;
//damage is applied to Pawns within a cone.  this is the angle at the cone's vertex.
var config float DamageAngle;
var config float DamageRadius;

// distance that we will stun any actors that implement IReactToC2Detonation
var config float StunAngle;     //the full angle in degrees
var config float StunRadius;
var config float StunDuration;

var config bool DebugBlast;

var private SwatDoor AssociatedDoor;
var private SwatPawn DeployedBy;
var private bool CurrentlyDeployed;

var Rotator BackwardVectorOffset;       //this is the direction, relative to the facing direction of a DeployedC2Charge, in which the charge affects pawns.  in other words, a DeployedC2Charge should affect pawns in the direction of Rotation + BackwardVectorOffset.
var array<Pawn> Victims;

replication
{
    reliable if (Role == Role_Authority)
        AssociatedDoor;
}

function SetAssociatedDoor(SwatDoor inAssociatedDoor)
{
    AssociatedDoor = inAssociatedDoor;
}

simulated function ISwatDoor GetDoorDeployedOn()
{
    if (IsDeployed())
    {
        return AssociatedDoor;
    }

    return None;
}

simulated function OnDeployed(SwatPawn inDeployedBy)
{
    SetCollision(true, false, false);
    Show();
    Deployedby = inDeployedBy;
    CurrentlyDeployed = true;
}

simulated function OnDetonated()
{
    mplog( self$"---DeployedC2ChargeBase::OnDetonated()." );

    assertWithDescription(AssociatedDoor != None,
        "[tcohen] DeployedC2ChargeBase::OnDetonated() AssociatedDoor=None");

    if ( Level.NetMode != NM_Client )
        assertWithDescription(DeployedBy != None,
            "[tcohen] DeployedC2ChargeBase::OnDetonated() DeployedBy=None");

    TriggerEffectEvent('Detonated', AssociatedDoor, AssociatedDoor.GetCurrentMaterial(0));
    SwatGameInfo(Level.Game).GameEvents.C2Detonated.Triggered(DeployedBy, self);

    ICanUseC2Charge(DeployedBy).SetDeployedC2Charge(None);

    if ( Level.NetMode != NM_Client )
    {
        AssociatedDoor.Breached(self);

        AffectVictims();

        Hide();
    }

    CurrentlyDeployed = false;
}

function AffectVictims()
{
    local IReactToC2Detonation Victim;
    local Actor VictimActor;
    local rotator AffectDirection;
    local vector OriginForTrace;
    local vector Momentum;
    local float DamageMomentumMagnitude;

    //a DeployedC2Charge affects Pawns in the "backward" direction from their forward-facing vector
	AffectDirection = Rotation + BackwardVectorOffset;

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
    if (DebugBlast)
    {
        Level.GetLocalPlayerController().myHUD.AddDebugCone(
            Location, vector(AffectDirection),
            StunRadius, StunAngle / 2,                          //half angle in degrees
            class'Engine.Canvas'.Static.MakeColor(0,50,255),
            60);                                                 //lifespan
        Level.GetLocalPlayerController().myHUD.AddDebugCone(
            Location, vector(AffectDirection),
            DamageRadius, DamageAngle / 2,                      //half angle in degrees
            class'Engine.Canvas'.Static.MakeColor(255, 255, 50),
            60);                                                 //lifespan
    }
#endif

    // pre-calculate magnitude of damage impact momentum
    // damage = momentum * conversion factor...
    //   so, momentum = damage / conversion factor
    DamageMomentumMagnitude *= Damage / Level.GetRepo().MomentumToDamageConversionFactor;

    foreach RadiusActors(class'IReactToC2Detonation', Victim, FMax(StunRadius, DamageRadius))
    {
        VictimActor = Actor(Victim);

        if  (
                VSize(VictimActor.Location - Location) < StunRadius
            &&  PointWithinInfiniteCone(
                    Location,
                    Vector(AffectDirection),
                    VictimActor.Location,
                    StunAngle * DEGREES_TO_RADIANS)
            &&  (Abs(VictimActor.Location.Z - Location.Z) < 150)
            )
        {
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
            if (DebugBlast)
                Level.GetLocalPlayerController().myHUD.AddDebugLine(
                        Location,
                        VictimActor.Location,
                        class'Engine.Canvas'.Static.MakeColor(100,0,200),
                        60
                        );
#endif

			Victim.ReactToC2Detonation(self, StunRadius, StunDuration);
        }

        if  (
                VSize(VictimActor.Location - Location) < DamageRadius
            &&  PointWithinInfiniteCone(
                    Location,
                    Vector(AffectDirection),
                    VictimActor.Location,
                    DamageAngle * DEGREES_TO_RADIANS)
            )
        {
            OriginForTrace = Location + vector(AffectDirection) * 10;

            if (FastTrace(VictimActor.Location, OriginForTrace))
            {
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
                if (DebugBlast)
                    Level.GetLocalPlayerController().myHUD.AddDebugLine(
                            OriginForTrace,
                            VictimActor.Location,
                            class'Engine.Canvas'.Static.MakeColor(255,0,0),
                            60
                            );
#endif

                // Calculate damage momentum
                Momentum = DamageMomentumMagnitude * Normal( VictimActor.Location - OriginForTrace);

                VictimActor.TakeDamage(
                        Damage,
                        DeployedBy,
                        VictimActor.Location,
                        Momentum,
                        class'ConcussiveDamageType');
            }
            else
            {
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
                if (DebugBlast)
                    Level.GetLocalPlayerController().myHUD.AddDebugLine(
                            OriginForTrace,
                            VictimActor.Location,
                            class'Engine.Canvas'.Static.MakeColor(0,255,0),
                            60
                            );
#endif
            }
        }
    }
}

//IAmUsedByToolkit implementation

simulated function bool CanBeUsedByToolkitNow()
{
    return true;
}

// Called when qualifying begins.
function OnUsingByToolkitBegan( Pawn User );

// Called when qualifying completes successfully.
function OnUsedByToolkit(Pawn User)
{
    CurrentlyDeployed = false;
    GotoState('Removed');
}

// Called when qualifying is interrupted.
function OnUsingByToolkitInterrupted( Pawn User );


//ICanBeDisabled implementation
simulated function bool IsActive()
{
    return CurrentlyDeployed;
}

//IDisableableByAI implementation
simulated function bool IsDisableableNow()
{
  return IsActive();
}

state Removed
{
    ignores CanBeUsedByToolkitNow;   //once its removed, it is no longer active

Begin:

    ICanUseC2Charge(DeployedBy).SetDeployedC2Charge(None);

    Hide();
}

//return the time to qualify to use this with a Toolkit
simulated function float GetQualifyTimeForToolkit()
{
    return QualifyTimeForToolkit;
}

defaultproperties
{
    BackwardVectorOffset=(Yaw=16384)
    DebugBlast=false

    CollisionHeight=5
    CollisionRadius=6

    bAlwaysRelevant=true
}
