class Reaction_DamageRadius extends Reaction;

var (Reaction) float Radius                 "The radius at which damage should be applied";
var (Reaction) float DamagePerInterval      "The amount of damage applied to victims every interval (specified in IntervalTime)";
var (Reaction) float IntervalTime           "The interval of time between each application of damage to victims";
var (Reaction) int Intervals                "The number of times to apply damage";
var (Reaction) enum EDropOffMode
{
    DropOff_None,
    DropOff_Linear,
    DropOff_Exponential
} DropOffMode                               "How damage should be reduced from the center of the RWO to the Radius distance.  'None' means that the full DamagePerInterval is applied throughout the Raidus.  'Linear' means that damage drops-off linearly from the center to the Radius distance, and 'Exponential' means that damage drops-off exponentially from the center to the Radius distance.";
var (Reaction) name DamageAlternateOrigin   "The Tag of an Actor to use as the center of the damage radius instead of the RWO that owns this Reaction.  Leave 'None' to use the RWO that owns this Reaction.";

var Actor DamageInstigator;
var Actor DamageSource;
var Timer DamageTimer;
var int DeltCount;

var float LastExecuteTime;      //prevent infinite recursion: react to damaged by dealing damage, etc.

protected simulated function Execute(Actor Owner, Actor Other)
{
    local float Now;

    //don't execute more than once in an update to prevent infinite recursion
    Now = Owner.Level.TimeSeconds;
    if (LastExecuteTime == Now) return;
    LastExecuteTime = Now;

    if (DamageAlternateOrigin == '')
        DamageSource = Owner;
    else
        //set Source to the first Dynamic Actor with Tag=DamageAlternateOrigin
        foreach Owner.DynamicActors(class'Actor', DamageSource, DamageAlternateOrigin) break;

    DamageInstigator = Other;
    if( DamageInstigator == None )
        DamageInstigator = DamageSource;

    //log(self$"::Execute( "$Owner$", "$Other$" ) ... DamageSource = "$DamageSource$", DamageInstigator = "$DamageInstigator );

    if (DamageSource != None)
        DealDamage();
}

function simulated DealDamage()
{
    local Actor Current;

    foreach DamageSource.VisibleCollidingActors(class'Actor', Current, Radius, DamageSource.Location)
    {
        //don't affect Pawns that are blocked by BSP.
        //we don't trace to anything else because that would be too expensive...
        //  its no big deal if we hurt some object on the other side of a wall, 
        //  we just don't want to do that to Pawns
        if (!Current.IsA('Pawn') || DamageSource.FastTrace(DamageSource.Location, Current.Location))
            DealDamageTo(Current, DamageSource);
    }

    ++DeltCount;

    if (Intervals >= DeltCount)
    { 
        if (IntervalTime <= 0)
        {
            AssertWithDescription(false, "[tcohen] "$DamageSource$"'s "$name$"'s IntervalTime must be greater than zero.");
        }

        if (DamageTimer == None)
        {
            DamageTimer = DamageSource.Spawn(class'Timer');
            DamageTimer.TimerDelegate = DealDamage;
        }

        DamageTimer.StartTimer(IntervalTime, false, true);  //reset any in-progress timer
    }
    else if (DamageTimer != None) 
    { 
        DamageTimer.Destroy(); 
        DamageTimer = None; 
    }
}

private simulated function DealDamageTo(Actor Target, Actor Source)
{
    local vector Direction;
    local float Distance;
    local float Damage;
    local vector Momentum;

    Direction = Target.Location - Source.Location;
    Distance = VSize(Direction);

    switch (DropOffMode)
    {
    case DropOff_None:
        Damage = DamagePerInterval;
        break;

    case DropOff_Linear:
        Damage = DamagePerInterval * (1 - Distance / Radius);
        break;

    case DropOff_Exponential:
        Damage = DamagePerInterval * (1 - Square(Distance / Radius));
        break;

    default:
        AssertWithDescription(false, "[tcohen] "$name$"::DealDamageTo(): unexpected DropOffMode value");
    }

    //damage = momentum * conversion factor...
    //so, momentum = damage / conversion factor
    Momentum = Normal(Direction) * Damage / Target.Level.GetRepo().MomentumToDamageConversionFactor;
    
    Target.TakeDamage(
        Damage, 
        Pawn(DamageInstigator), 
        Target.Location, 
        Momentum, 
        class'DamageRadiusDamageType');
}

defaultproperties
{
    Radius=500
    DamagePerInterval=100
    IntervalTime=1.0
}
