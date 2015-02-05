class Reaction_TriggerEffectEvent extends Reaction;

var (Reaction) name EffectEvent         "The name of the EffectEvent to trigger or untrigger";
var (Reaction) bool bUnTrigger;
var (Reaction) bool ConsiderStandingOn  "If TRUE, then it will do a trace down from the RWO, use the material found, and trigger the Effect Event at that location.";    //TMC why did we ever want this?!?

//Trigger or UnTrigger the specified effect event.
//If the Owner is on top of something, then pass its material along with the effect event

protected simulated function Execute(Actor Owner, Actor inOther)
{
    local Vector HitLocation, HitNormal, StartTrace, EndTrace, Offset;
    local Actor Other;
    local Material MaterialOwnerIsStandingOn;
    local Rotator HitRotation;

    if (bUntrigger)
    {
        Owner.UnTriggerEffectEvent(EffectEvent);
        return;
    }

    if (ConsiderStandingOn)
    {
        // Do a trace downward from the owner.
        StartTrace = Owner.Location;
        Offset = vect( 0.0, 0.0, -20.0 );
        EndTrace = StartTrace + Offset;

        Other = Owner.Trace( HitLocation, HitNormal, EndTrace, StartTrace, False, vect(0,0,0), MaterialOwnerIsStandingOn );
    }

    if ( Other != None )
    {
        HitRotation = Rotator( HitNormal );
        Owner.TriggerEffectEvent( EffectEvent, None, MaterialOwnerIsStandingOn, HitLocation, HitRotation );
    }
    else
    {
        Owner.TriggerEffectEvent( EffectEvent );
    }
}
