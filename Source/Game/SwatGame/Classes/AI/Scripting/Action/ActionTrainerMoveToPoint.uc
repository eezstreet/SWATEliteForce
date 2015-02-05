///////////////////////////////////////////////////////////////////////////////

class ActionTrainerMoveToPoint extends TrainerScriptActionBase;

///////////////////////////////////////////////////////////////////////////////

var() editcombotype(enumNavigationPoints) Name navigationPointLabel;
var() bool bFaceFinalNavigationPointDirection;

///////////////////////////////////////////////////////////////////////////////

latent function Variable execute()
{
    local SwatTrainer swatTrainer;
	local NavigationPoint navigationPoint;
    local MoveToActorGoal goal;

    swatTrainer = GetSwatTrainer();
    navigationPoint = FindNavigationPoint();

    if (swatTrainer != None && navigationPoint != None)
    {
        goal = new class'MoveToActorGoal'(AI_Resource(swatTrainer.MovementAI), 99, navigationPoint);
        assert(goal != None);
        goal.AddRef();

        // @TODO: Possibly make these designer-tweakable for the action.
        goal.SetShouldWalkEntireMove(true);
        goal.SetWalkThreshold(0.0);
        goal.SetRotateTowardsFirstPoint(false);
        goal.SetRotateTowardsPointsDuringMovement(true);

        // Have trainer animation full-body when walking
        swatTrainer.AnimSetFlag(kAF_Aim, false);

        goal.postGoal(None);
        WaitForGoal(goal);
        goal.unPostGoal(None);

        swatTrainer.AnimSetFlag(kAF_Aim, true);

        if (bFaceFinalNavigationPointDirection)
        {
            // Wait till pawn is done moving
            while (!IsZero(swatTrainer.Velocity))
            {
                Sleep(0);
            }

            // Set the trainer's "aim" (look-at) rotation
    		swatTrainer.AimToRotation(navigationPoint.Rotation);

            while (!swatTrainer.AnimIsBaseAtAim())
            {
                Sleep(0);
            }
        }

        goal.Release();
        goal= None;
    }

    return None;
}

///////////////////////////////////////

function NavigationPoint FindNavigationPoint()
{
    local NavigationPoint navigationPoint;

    for (navigationPoint = parentScript.Level.NavigationPointList;
         navigationPoint != None;
         navigationPoint = navigationPoint.NextNavigationPoint)
    {
        if (navigationPoint.label == navigationPointLabel)
        {
            return navigationPoint;
        }
    }

    return None;
}

///////////////////////////////////////

function enumNavigationPoints(LevelInfo l, out Array<Name> s)
{
	local NavigationPoint navigationPoint;
    foreach l.AllActors(class'NavigationPoint', navigationPoint)
    {
        if (navigationPoint.label != '')
        {
            s[s.length] = navigationPoint.label;
        }
    }
}

///////////////////////////////////////

function editorDisplayString(out string s)
{
    s = "Move Trainer AI to point labeled " $navigationPointLabel;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    returnType        = None
    actionDisplayName = "Trainer - Move To Point"
    actionHelp        = "Moves the Swat Trainer AI to a specified navigation point."
    category          = "AI"
}

///////////////////////////////////////////////////////////////////////////////
