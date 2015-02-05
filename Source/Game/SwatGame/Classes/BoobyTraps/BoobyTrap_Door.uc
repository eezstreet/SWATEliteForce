class BoobyTrap_Door extends BoobyTrap;

// Base class of booby traps that are attached to doors


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
}
