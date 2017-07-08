class DoorModel extends DoorAttachment
    implements Engine.ICanBeUsed
    config(SwatGame)
	transient
	native;

var SwatDoor Door;

// these variables are used when opening the door model procedurally in UnrealEd 
//  to be able to re-test links between pathnodes when doors are open
var private Rotator SavedRotation;
var private vector  SavedLocation;

//This class represents the visual StaticMesh, per-poly-collision of a conseptual Door

replication
{
    reliable if (bNetDirty && (Role == Role_Authority))
        Door;
}

//ICanBeUsed implementation

simulated function bool CanBeUsedNow()
{
    return SwatDoor(Owner).CanInteract();
}

simulated function OnUsed(Pawn Other)
{
    SwatDoor(Owner).Interact(Other);
}

simulated function PostUsed();

cpptext
{
	void ProcedurallyOpenDoorModel(DoorPosition OpenPosition);
	void ProcedurallyCloseDoorModel();
}

defaultproperties
{
    HavokDataClass=class'SwatGame.HavokDoorRigidBody'
    bCollideActors=true
	bBlockActors=true
    bBlockPlayers=true
    bBlockZeroExtentTraces=true
   
    // Door models must be bMovable=true + bStatic=false +
    // bBlockHavok=true + bWorldGeometry=false in order for
    // havok to do keyframed collision on them. 
    // 
    // NOTE: the door won't actually move in the havok world when opened
    // unless HavokReflectNewTransform is called in UnRenderVisibility.cpp 
    // ProcessVisibleActor() during calls to SetAttachmentLocation().
    // But this is currently disabled because keyframed doors will push 
    // ragdolls and other havok objects around, which doesn't look very good.
	//
	// NOTE: if bWorldGeometry is set to false, then AIs see through doors.
	// unfortunately they shouldn't see through doors, so I have to make
	// bWorldGeometry == true
	bWorldGeometry=true
    bBlockHavok=true
    //bMovable=true


//#if IG_CLAMP_DYNAMIC_LIGHTS
	// Limit the dynamic lights on doors to only two in order to reduce
	// popping of the lighting when officers with flashlights are
	// breaching a door.
	 MaxDynamicLights=2
//#endif

    bStasis=true
}
