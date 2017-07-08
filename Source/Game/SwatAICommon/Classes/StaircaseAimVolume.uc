///////////////////////////////////////////////////////////////////////////////

class StaircaseAimVolume extends Engine.Volume
    placeable;

///////////////////////////////////////////////////////////////////////////////

var() private array<String> StaircaseAimPointNames;
var   private array<StaircaseAimPoint> StaircaseAimPoints;

///////////////////////////////////////////////////////////////////////////////

event PostBeginPlay()
{
    local StaircaseAimPoint staircaseAimPoint;
    local int i;

    super.PostBeginPlay();

    // Find each staircase aim point
    foreach AllActors(class 'StaircaseAimPoint', staircaseAimPoint)
    {
        // If this point is in the designer-specified list of names, keep it.
        for (i = 0; i < StaircaseAimPointNames.length; i++)
        {
            if (StaircaseAimPointNames[i] ~= String(staircaseAimPoint.Name))
            {
                StaircaseAimPoints[StaircaseAimPoints.length] = staircaseAimPoint;
                break;
            }
        }
    }
}

///////////////////////////////////////

event Touch(Actor other)
{
    local ISwatAI swatAI;

    Super.Touch(other);

    swatAI = ISwatAI(other);
    if (swatAI != None)
    {
        swatAI.OnTouchedStaircaseAimVolume(self);
    }
}

///////////////////////////////////////

event Untouch(Actor other)
{
    local ISwatAI swatAI;

    Super.Untouch(other);

    swatAI = ISwatAI(other);
    if (swatAI != None)
    {
        swatAI.OnUntouchedStaircaseAimVolume(self);
    }
}

///////////////////////////////////////

function int GetNumStaircaseAimPoints()
{
    return StaircaseAimPoints.length;
}

///////////////////////////////////////

function StaircaseAimPoint GetStaircaseAimPointAtIndex(int index)
{
    assert(index >= 0 && index < StaircaseAimPoints.length);
    return StaircaseAimPoints[index];
}

///////////////////////////////////////////////////////////////////////////////\

defaultproperties
{
    bOccludedByGeometryInEditor=true
}
