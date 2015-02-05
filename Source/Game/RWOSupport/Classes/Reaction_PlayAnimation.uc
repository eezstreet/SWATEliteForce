class Reaction_PlayAnimation extends Reaction;

var (Reaction) enum EPlayAnimationMode
{
    Play_Normal,
    Play_Looping,       //loop the specified animation
    Play_TweenTo,       //tween to the specified animation
    Play_Stop,          //stop animating
    Play_FreezeAt       //calls Actor::FreezeAnimAt()... does whatever that does
} Mode;

var (Reaction) name Animation;
var (Reaction) float Rate;
var (Reaction) float TweenTime;
var (Reaction) int Channel;

protected simulated function Execute(Actor Owner, Actor Other)
{
    AssertWithDescription(Owner.DrawType == DT_Mesh,
    	"[tcohen] "$name$": can't play an animation on "$Owner$" because it is not DrawType=DT_Mesh");

    switch (Mode)
    {
    case Play_Normal:
        Owner.PlayAnim(Animation, Rate, TweenTime, Channel);
        break;

    case Play_Looping:
        Owner.LoopAnim(Animation, Rate, TweenTime, Channel);
        break;

    case Play_TweenTo:
        Owner.TweenAnim(Animation, TweenTime, Channel);
        break;

    case Play_Stop:
        Owner.StopAnimating();
        break;

    case Play_FreezeAt:
        Owner.FreezeAnimAt(TweenTime, Channel);
        break;

    default:
        assert(false);  //unexpected EPlayAnimationMode
    }
}

defaultproperties
{
    Rate=1.0
}
