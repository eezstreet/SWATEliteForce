class BoobyTrap_World extends BoobyTrap;

// Base class of booby traps that are spawned in the world
var() class<BoobyTrapDoorAttachment>   DoorAttachmentClass "Specifies the class of door attachment that is spawned and attached to the door that is tied in with this placed boobytrap.";
var private BoobyTrapDoorAttachment    DoorAttachment;

function OnBoobyTrapInitialize()
{
    log("BoobyTrap_World intiialized, door associated is: "$BoobyTrapDoor );
    if ( DoorAttachmentClass != None )
    {
        DoorAttachment = Spawn(DoorAttachmentClass, Self);
        BoobyTrapDoor.AttachToBone(DoorAttachment, AttachSocket);

        log(Self$" has attached to the door! ... staticmesh: "$DoorAttachment.StaticMesh);
        log("BoobyTrap attached to door: "$BoobyTrapDoor);
    }

}

function ReactToUsed(Actor Other)
{
    // Forward used to our doorattachment
    if ( bActive && DoorAttachment != None )
        DoorAttachment.ReactToUsed(Other);

    Super.ReactToUsed(Other);
}

function ReactToTriggered(Actor Other)
{
    // Forward triggered to our doorattacmeht
    if ( bActive && DoorAttachment != None )
        DoorAttachment.ReactToTriggered(Other);

    Super.ReactToTriggered(Other);
    SetCollision(false, false, false);
}

defaultproperties
{
    staticmesh=StaticMesh'arms_sm.arms_bathsink'
    DrawScale=0.5
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
