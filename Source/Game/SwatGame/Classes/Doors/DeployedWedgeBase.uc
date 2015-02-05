class DeployedWedgeBase extends RWOSupport.DeployedTacticalAid
    Implements IAmUsedByToolkit
    config(SwatEquipment)
    native;

var(Wedge) StaticMesh PreviewStaticMesh;

//in seconds, the time required to qualify to remove a Wedge with a Toolkit
var config float QualifyTimeForToolkit;

var private SwatDoor AssociatedDoor;

replication
{
    reliable if (Role == Role_Authority)
        AssociatedDoor;
}

///////////////////////////

function SetAssociatedDoor(SwatDoor inAssociatedDoor)
{
    AssociatedDoor = inAssociatedDoor;
}

simulated function Door GetDoorDeployedOn()
{
    if (IsDeployed())
    {
        return AssociatedDoor;
    }

    return None;
}

simulated function OnDeployed()
{
    SetCollision(true, false, false);
    Show();
}

simulated function OnRemoved()
{
    SetCollision(false, true, true);
    Hide();
    AssociatedDoor.OnUnwedged();
}

//IAmUsedWithToolkit implementation

// Return true iff this can be operated by a toolkit now
simulated function bool CanBeUsedByToolkitNow()
{
    return true;
}

// Called when qualifying begins.
function OnUsingByToolkitBegan( Pawn User );

// Called when qualifying completes successfully.
function OnUsedByToolkit(Pawn User)
{
    OnRemoved();
}

// Called when qualifying is interrupted.
function OnUsingByToolkitInterrupted( Pawn User );


//return the time to qualify to use this with a Toolkit
simulated function float GetQualifyTimeForToolkit()
{
    return QualifyTimeForToolkit;
}

defaultproperties
{
    CollisionHeight=20
    CollisionRadius=14
    bBlockNonZeroExtentTraces=false

    bAlwaysRelevant=true
}
