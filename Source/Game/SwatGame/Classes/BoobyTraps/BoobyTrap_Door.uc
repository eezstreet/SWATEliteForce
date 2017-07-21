class BoobyTrap_Door extends BoobyTrap;

// Base class of booby traps that are attached to doors
var() config bool C2DisablesThis "If true, C2 disables the trap instead of triggering it";

function OnBoobyTrapInitialize()
{
    BoobyTrapDoor.AttachToBone(Self, AttachSocket);
    log(Self$" has attached to the door! ... staticmesh: "$StaticMesh);
    log("BoobyTrap attached to door: "$BoobyTrapDoor);
}

defaultproperties
{
    staticmesh=StaticMesh'arms_sm.arms_bathsink'
    DrawScale=0.5
    AttachSocket=C2ChargeLeft
    bHidden=false
    QualifyTime=1.0
    bCollideActors=true
    bCollideWorld=true
    bBlockActors=true

    // Force bombs to always update their collision box from their bone boxes;
    // otherwise bombs sometimes don't get added to the octree properly when
    // replicated to clients, causing traces (like for disabling bombs) to
    // miss the bomb when they shouldn't.
    bUseCollisionBoneBoundingBox=true
}
