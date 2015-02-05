class DoorWay extends Engine.Actor
    native;

//This class represents the invisible region within a doorframe for a conseptual door

simulated function PostBeginPlay()
{
    local SwatDoor Door;

    Super.PostBeginPlay();

    Door = SwatDoor(Owner);
    assert(Door != None);
}

simulated event SwatDoor GetDoor()
{
    local SwatDoor SwatDoor;

    SwatDoor = SwatDoor(Owner);
    assert(SwatDoor != None);

    return SwatDoor;
}

simulated function float GetMomentumToPenetrate(vector HitLocation, vector HitNormal, Material MaterialHit)
{
    return 0;
}

defaultproperties
{
    bHidden=true
    bCollideActors=true
    bBlockZeroExtentTraces=true
    DrawType=DT_StaticMesh
    bStasis=true
}
