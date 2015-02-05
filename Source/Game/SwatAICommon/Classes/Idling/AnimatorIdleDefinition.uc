///////////////////////////////////////////////////////////////////////////////
class AnimatorIdleDefinition extends IdleDefinition
    perobjectconfig;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// AnimatorIdleDefinition Config Variables
var config name                 AnimationName;
var config float                AnimationTweenTime;
var config int					MinNumberOfTimesToPlay;
var config int					MaxNumberOfTimesToPlay;

///////////////////////////////////////////////////////////////////////////////
//
// Convenience

function int GetRandomNumberOfTimeToPlay()
{
	return RandRange(MinNumberOfTimesToPlay, MaxNumberOfTimesToPlay);
}

defaultproperties
{
    AnimationTweenTime=0.2
	MinNumberOfTimesToPlay=1
	MaxNumberOfTimesToPlay=1
}