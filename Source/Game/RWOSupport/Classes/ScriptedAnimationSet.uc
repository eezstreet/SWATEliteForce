class ScriptedAnimationSet extends Core.Object
    hidecategories(Object)
    editinlinenew
    native;

struct native ScriptedAnimation
{
    var() int Chance;
    var() name Animation;
};

var() export editinline deepcopy array<ScriptedAnimation> ScriptedAnimations;
var() Range LoopCount;

var int TotalChance;


//lazy initialization
//TMC I was doing this in Construct(), but these are new'ed in the Editor, so Construct() wansn't being called
simulated function Initialize()
{
    local int i;

    if (ScriptedAnimations.length == 0) return;
    
    //calculate the sum of chances of the ScriptedAnimations
    for (i=0; i<ScriptedAnimations.length; ++i)
        TotalChance += ScriptedAnimations[i].Chance;

    assertWithDescription(LoopCount.Min <= LoopCount.Max,
        "[tcohen] "$name
        $" owned by "$Outer
        $" specifies a LoopCount with Max < Min.");
}

simulated function name SelectAnimation()
{
    local int RandChance;
    local int AccumulatedChance;
    local int i;

    if (ScriptedAnimations.length == 0) return '';

    if (TotalChance == 0) Initialize();
    assertWithDescription(TotalChance > 0,
        "[tcohen] "$name
        $", a ScriptedAnimationSet of ReactiveAnimatedMesh '"$Outer$"',"
        $" has a TotalChance of zero.  Please add at least one non-zero Chance to it.");

    RandChance = Rand(TotalChance);

    //find the chosen option
    for (i=0; i<ScriptedAnimations.length; ++i)
    {
        AccumulatedChance += ScriptedAnimations[i].Chance;
        
        if (AccumulatedChance >= RandChance)
            return ScriptedAnimations[i].Animation;
    }

    assert(false);  //we should have chosen something (even if it was a 'None')
}

defaultproperties
{
    LoopCount=(Min=1,Max=1)
}
