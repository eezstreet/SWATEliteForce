///////////////////////////////////////////////////////////////////////////////
// MirrorCornerGoal.uc - MirrorCornerGoal class
// this goal is given to a Officer to mirror a corner

class MirrorCornerGoal extends OfficerCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// copied to our action
var(parameters) Actor TargetMirrorPoint;

///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r )
{
    // don't use this constructor
	assert(false);
}

overloaded function construct( AI_Resource r, Actor inTargetMirrorPoint )
{
    Super.construct(r);

    assert(inTargetMirrorPoint != None);
    TargetMirrorPoint = inTargetMirrorPoint;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority   = 80
    goalName   = "MirrorCorner"
}