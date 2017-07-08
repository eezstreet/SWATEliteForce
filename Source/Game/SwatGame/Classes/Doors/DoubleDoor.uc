class DoubleDoor extends SwatDoor
	native
    placeable;

var() StaticMesh OneOfDoubleDoorsSM "The static mesh representation of one of the double doors for placement in UnrealEd, and collision";

// the door models for either hinge
var DoorModel LeftHingeDoorModel;
var DoorModel RightHingeDoorModel;

const kDoubleDoorWidth = 156.0; // must be twice the single door width. unfortunately unrealscript won't let me reference kSingleDoorWidth

// Door Models are created in BeginPlay because the Awareness system needs to connect based on visibility
//  Having the Awareness system connect after the door models are created prevents connections being made through closed doorways
//  Darren plans on creating a better solution to this problem when he revisits Awareness
simulated function BeginPlay()
{
    Super.BeginPlay();

	// link the double door animations to the double door
    LoadAnimationSet("SwatDoubleDoorAnimations.SwatDoubleDoor");

    if ( Level.NetMode != NM_Client )
    {
        // door models - spawn each door and attach to hinge
        assert(LeftHingeDoorModel == None);
        LeftHingeDoorModel = Spawn(class'DoorModel', self);
        assert(LeftHingeDoorModel != None);
        LeftHingeDoorModel.SetStaticMesh(OneOfDoubleDoorsSM);
        LeftHingeDoorModel.Door = self;
        AttachToBone(LeftHingeDoorModel, 'DoorHingeL');

        assert(RightHingeDoorModel == None);
        RightHingeDoorModel = Spawn(class'DoorModel', self);
        assert(RightHingeDoorModel != None);
        RightHingeDoorModel.SetStaticMesh(OneOfDoubleDoorsSM);
        RightHingeDoorModel.Door = self;
        AttachToBone(RightHingeDoorModel, 'DoorHingeR');
    }
}

simulated function PostBroken()
{
    LeftHingeDoorModel.SetStaticMesh(BrokenStaticMesh);
    RightHingeDoorModel.SetStaticMesh(BrokenStaticMesh);
}

simulated function array<Actor> GetDoorModels()
{
	local array<Actor> DoorModels;
	DoorModels[0] = LeftHingeDoorModel;
	DoorModels[1] = RightHingeDoorModel;
	return DoorModels;
}

//play effects when blasted or breached

simulated state BeingBlasted
{
    simulated function PlayBlastedEffects()
    {
        LeftHingeDoorModel.TriggerEffectEvent('Blasted');
        RightHingeDoorModel.TriggerEffectEvent('Blasted');
    }
}

simulated function PlayBreachedEffects()
{
    LeftHingeDoorModel.TriggerEffectEvent('Breached');
    RightHingeDoorModel.TriggerEffectEvent('Breached');
}

simulated function float GetDoorwayWidth()
{
    return kDoubleDoorWidth;
}

simulated function Vector GetPushAwayDirection(SwatRagdollPawn thePawn)
{
    local Vector            LeftHingeToPawn2D;   // non-normalize vector from left door hinge to pawn, in 2D plane
    local Vector            HingeToKnob2D;        // normalized direction from doorhinge to doorknob, when door is closed, in 2D plane
    local Vector            HingeLocation2D;      // position of the hinge in the 2D plane
    local Vector            DesiredPushLocation2D;      // corner we want to push the pawn towards
    local Vector            CenterLeftSide2D;  // where door edge is when door is open 45 degrees to the left
    local Vector            CenterRightSide2D; // where door edge is when door is open 45 degrees to the right
    local Vector            PawnLocation2D;
    local float             DistFromDoorwayPlane;
    local float             FudgeFactor;
    
    
    HingeToKnob2D = Vector(Rotation);
    HingeToKnob2D.Z = 0;
    HingeToKnob2D = Normal(HingeToKnob2D);

    // Door location is center of doorway, so hinge location is offset by half
    // doorway width 
    HingeLocation2D = Location - (HingeToKnob2D * (GetDoorwayWidth() * 0.5));
    HingeLocation2D.Z = 0;

    PawnLocation2D  = thePawn.Location;
    PawnLocation2D.Z = 0;

    LeftHingeToPawn2D = PawnLocation2D - HingeLocation2D; 


    // If the pawn is behind the open door model (more than 90 degrees away from 
    // the HingeToKnob vector in either direction), then the door will never close
    // or open into him. However, we push the pawn directly away from the model
    // so he doesn't get his limbs caught in it (especially in MP games).
    if ( VSize2D(HingeToKnob2D * ((thePawn.Location - Location) dot HingeToKnob2D)) > GetDoorwayWidth() * 0.5  )
    {
        // push away from door model
        return Normal(HingeToKnob2D * ((thePawn.Location - Location) dot HingeToKnob2D));
    }

    CenterLeftSide2D  = Location + ( Normal( HingeToKnob2D Cross Vect(0,0,1)  ) * GetDoorwayWidth() * 0.5);
    CenterRightSide2D = Location + ( Normal( HingeToKnob2D Cross Vect(0,0,-1) ) * GetDoorwayWidth() * 0.5);

    //Level.GetLocalPlayerController().myHUD.AddDebugLine(Location, CenterLeftSide2D, class'Engine.Canvas'.Static.MakeColor(0,255,0), 0.01);
    //Level.GetLocalPlayerController().myHUD.AddDebugLine(Location, CenterRightSide2D, class'Engine.Canvas'.Static.MakeColor(0,0,255), 0.01);

    // If pawn is within FudgeFactor units on either side from the plane of the
    // doorway, and he's on the side the door is open to, then we push him 
    // to the side the door is not open to
    DistFromDoorwayPlane = VSize2D( LeftHingeToPawn2D - (HingeToKnob2D * (LeftHingeToPawn2D dot HingeToKnob2D)) );
    FudgeFactor = GetDoorwayWidth() * 0.4;
    if (PointIsOnSideThatDoorIsOpenTo(thePawn.Location) && DistFromDoorwayPlane <= FudgeFactor)
    {
        if (IsOpenLeft() || IsOpeningLeft())
            DesiredPushLocation2D = CenterRightSide2D;
        else
            DesiredPushLocation2D = CenterLeftSide2D;
    }
    else
    {
        // Pawn is either far from doorway plane or not on the side that the door is
        // open to, so push him towards the direction the door is open to
        if (PointIsToMyLeft(thePawn.Location))
            DesiredPushLocation2D = CenterLeftSide2D;
        else
            DesiredPushLocation2D = CenterRightSide2D;
    }

    return Normal(DesiredPushLocation2D - Location); // away from door plane
}
defaultproperties
{
	// collision radius of 120 fits around both doors when they are open either way
    CollisionRadius=120.0

    Mesh=SkeletalMesh'SWATDoubleDoorAnimations.SwatDoubleDoor'
	StaticMesh=StaticMesh'Doors_sm.FusedDoubleDoor'
	OneOfDoubleDoorsSM=StaticMesh'Doors_sm.TestDoorKarma78Wide'

    DoorBufferVolumeCollisionMesh=StaticMesh'Doors_sm.door_phys_doubleref'
}
