class EventResponse extends Core.Object
    PerObjectConfig
    native
    abstract;

struct native SpecificationStruct
{
    var Name    SpecificationType;
    var class   SpecificationClass;
};

var config Name                 Event;
var config Name                 SourceClassName;
var class<Actor>                SourceClass;
var config Name                 TargetClassName;
var config Name                 StaticMesh;     //if not None, this is used to filter for Actors with this StaticMesh
var config Name                 Tag;            //if not None, this is used to filter for Actors with this Tag
var config array<int>           Chance;
var config array<SpecificationStruct>          Specification;
// dbeswick: integrated 20/6/05
var transient array<EffectSpecification>  SpecificationReference;
var config array<name>          Context;
#if IG_SWAT
var config bool                 AlwaysInQM;     //when playing Quick Missions, ignore level-specific contexts for this EventResponse, ie. instantiate its specifications and potentially match EffectEvents even if a level-specific Context doesn't match the current level's label
#endif

var private bool initDone;
var private int sum;

simulated function Init()
{
    local int i;

    //init should happen only once
    assert(!initDone);
    if (initDone)
        return;

    if (Chance.length + Specification.length == 0)
    {
        warn("The "$class.name$" named '"$name$"' has no Specification.  This will not cause a problem, but it should be corrected.");
        return;     //no specifications... sum is also zero
    }

    if (Chance.length == 0)
        Chance[0] = 1;

    assertWithDescription(Chance.length == Specification.length,
        "EventResponse "$name$": The number of Chance(s) and Specifications(s) should match, but they don't (except if there's just one Specification, in which case, you may omit the Chance).");

    //set sum
    for (i=0; i<Chance.length; i++)
        sum += Chance[i];

    initDone = true;
}

simulated event EffectSpecification GetSpecification()
{
    local int subSum;
    local int point;
    local int i;

    if (!initDone) Init();

    if (Chance.length + Specification.length == 0)
		return None;

    //select a specification using the random weights specified in the response

    point = rand(sum);

    for (i=0; i<Chance.length; i++)
    {
        subSum += Chance[i];
        if (subSum >= point)
            break;
    }
    assert(i<Chance.length);

    if (SpecificationReference[i] == None)
        assertWithDescription(false,
            "[tcohen] The "$class.name
            $" named "$name
            $" was called to GetSpecification(), but the SpecificationReference (at index "$i
            $") is None.  The Event Response's SourceClass ("$SourceClassName
            $") may need to be added to the PreloadActorClass list in EffectsSystem.ini.  "
            $"Effects will not be played on "$SourceClassName$" instances.  "
            $"(This probably means that the SourceClass was dynamically loaded after the Effects System was initialized, and had not been previously loaded.  "
            $"Therefore the Effects System ignored the Event Response and didn't create any Effect Specifications for it.)");

    return SpecificationReference[i];
}
