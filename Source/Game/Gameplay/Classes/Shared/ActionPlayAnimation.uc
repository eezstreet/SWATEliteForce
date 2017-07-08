class ActionPlayAnimation extends Scripting.Action;

var() name TargetLabel "Who to play the animation on.";
var() name Animation "Which animation to play on the Target.";
var() float AnimationRate "The speed at which to play Animation.  1.0 is normal speed, and 0.5 is half-speed.";
var() float TweenTime "The time for the Target to Tween (interpolate animation) before starting the Animation.";
var() float Channel "The animation channel on which Target should play Animation.";

// execute
latent function Variable execute()
{
    local Actor Target;

    Target = parentScript.findByLabel(class'Actor', TargetLabel);

    assertWithDescription(Target != None,
        "[tcohen] The Script named "$parentScript.name
        $" tried to execute an ActionPlayAnimation on a Target defined by having the Label '"$TargetLabel
        $"', but no such target was found.");

    assertWithDescription(Target.DrawType==DT_Mesh,
        "[tcohen] The Script named "$parentScript.name
        $" tried to execute an ActionPlayAnimation on a Target defined by having the Label '"$TargetLabel
        $"'.\nThe target was found (named "$Target.name$"), but it is not DrawType DT_Mesh, so it can't play animations.");

    Target.PlayAnim(Animation, AnimationRate, TweenTime, Channel);

	return None;
}


defaultproperties
{
	returnType			= None
	actionDisplayName	= "Play an Animation on a Mesh"
	actionHelp			= "Causes a Target Actor of DrawType DT_Mesh to play a specified Animation."
	category			= "Script"

    AnimationRate       = 1.0
}
