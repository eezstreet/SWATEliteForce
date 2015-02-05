class Reaction_SetTimer extends Reaction;

var (Reaction) float Time;
var (Reaction) bool Loop;

protected simulated function Execute(Actor Owner, Actor Other)
{
    Owner.SetTimer(Time, Loop);
}
