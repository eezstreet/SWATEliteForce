class SingleDoor extends SwatDoor
	native
    placeable;

var() private bool bNoDoor "If true, the SingleDoor behaves like just a DoorWay with no model at all.  NOTE that it still needs a correct StaticMesh to indicate the doorway geometry!";

var DoorModel DoorModel;

const kSingleDoorWidth = 78.0;

// Door Models are created in BeginPlay because the Awareness system needs to connect based on visibility
//  Having the Awareness system connect after the door models are created prevents connections being made through closed doorways
//  Darren plans on creating a better solution to this problem when he revisits Awareness
simulated function BeginPlay()
{

	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---SingleDoor::BeginPlay()." );
    
    Super.BeginPlay();

	LoadAnimationSet("SwatDoorAnimation.SwatDoorAnimationSet");

    if ( Level.NetMode != NM_Client )
    {
		assert(DoorModel == None);

        //door models - spawn and attach to hinge
        DoorModel = Spawn(class'DoorModel', self);
        assert(DoorModel != None);
        DoorModel.Door = self;
        DoorModel.SetStaticMesh(StaticMesh);
        DoorModel.SetDrawScale3D(DrawScale3D);
        AttachToBone(DoorModel, 'DoorHinge');
    }

    if (bNoDoor)
    {
        if ( DoorModel != None )
        {
            DoorModel.bHidden = true;
            DoorModel.SetCollision(false, false, false);
            DoorModel.HavokSetBlocking(false);
            DoorModel.bBlockZeroExtentTraces = false;
            DoorModel.bBlockNonZeroExtentTraces = false;
        }

        //SwatDoors should be bCollideActors iff they are not bNoDoor, ie. if they appear to have a door
        SetCollision(false);
    }
}

simulated function DoorPosition GetInitialPosition()
{
    if (bNoDoor)
        return DoorPosition_OpenLeft;
    else
        return Super.GetInitialPosition();
}

simulated function bool WasDoorInitiallyLocked() 
{ 
	// we couldn't have been initially locked if we don't have a door
	if (bNoDoor)
		return false;
	else
		return Super.WasDoorInitiallyLocked();
}

simulated function PostBroken()
{
    DoorModel.SetStaticMesh(BrokenStaticMesh);
}

simulated function array<Actor> GetDoorModels()
{
	local array<Actor> DoorModels;
	DoorModels[0] = DoorModel;
	return DoorModels;
}

//play effects when blasted or breached

simulated state BeingBlasted
{
    simulated function PlayBlastedEffects()
    {
        DoorModel.TriggerEffectEvent('Blasted');
    }
}

simulated function PlayBreachedEffects()
{
    DoorModel.TriggerEffectEvent('Breached');
}

simulated function float GetDoorwayWidth()
{
    return kSingleDoorWidth;
}

simulated function Vector GetPushAwayDirection(SwatRagdollPawn thePawn)
{
    local Vector            HingeToKnob2D;        // normalized direction from doorhinge to doorknob, when door is closed, in 2D plane
    local Vector            HingeLocation2D;      // position of the hinge in the 2D plane
    local Vector            DesiredCorner2D;      // corner we want to push the pawn towards
    local Vector            FarCornerLeftSide2D;  // where door edge is when door is open 45 degrees to the left
    local Vector            FarCornerRightSide2D; // where door edge is when door is open 45 degrees to the right
    local float             InnerRadiusScaleFactor; // amount to scale the collision radius by to determine when a pawn is "too close" to door hinge
    
    HingeToKnob2D = Vector(Rotation);
    HingeToKnob2D.Z = 0;
    HingeToKnob2D = Normal(HingeToKnob2D);

    // Door location is center of doorway, so hinge location is offset by half
    // doorway width 
    HingeLocation2D = Location - (HingeToKnob2D * (GetDoorwayWidth() * 0.5));
    //Level.GetLocalPlayerController().myHUD.AddDebugLine(Location, HingeLocation2D, class'Engine.Canvas'.Static.MakeColor(0,255,0), 0.01);
    HingeLocation2D.Z = 0;

    // If the pawn is behind the open door model (more than 90 degrees away from 
    // the HingeToKnob vector in either direction), then the door will never close
    // or open into him. However, we push the pawn directly away from the model
    // so he doesn't get his limbs caught in it (especially in MP games).
    if ( HingeToKnob2D dot (thePawn.Location-HingeLocation2D) < 0 )
    {
        // push opposite the direction of HingeToKnob
        return -HingeToKnob2D;
    }

    // Imagine the door open 45 degrees in some direction. The place where
    // the edge of the door is in this situation is a "sweet spot" for 
    // a ragdoll to be when the door is open to this side, because
    // when the door is moving the ragdoll will minimally intersect the door
    // and will most easily be "sweeped" out of the way by the door. 
    // 
    // Since we can only apply a small force to the ragdoll to push it towards
    // this direction (too strong a force looks bad), we need to pick which
    // of the two "sweet spots" to push the ragdoll towards. This decision is
    // made by guessing which one the body is most likely to reach before
    // coming to rest. 
    //
    // So what we do is this: 
    // If the pawn is within GetDoorwayWidth() * InnerRadiusScaleFactor units of the hinge 
    //  AND 
    // the pawn is on the same side of the doorway that the door is open to, 
    // then we push him towards the sweet spot on the opposite side of the 
    // doorway. In all other cases we push him towards the sweet spot that is 
    // closest to the pawn. 
    //
    // This heuristic helps minimize the pawn being "pinched" by a
    // closing/opening door.
    //
    // NOTE: Unreal is a *left* handed coordinate system, so we need to cross 
    // HingeToKnob2D with +Z to get the vector to the door's left. Argh!
    FarCornerLeftSide2D  = HingeLocation2D + (Normal( HingeToKnob2D + (HingeToKnob2D Cross Vect(0,0,1)) ) * CollisionRadius);
    FarCornerRightSide2D = HingeLocation2D + (Normal( HingeToKnob2D + (HingeToKnob2D Cross Vect(0,0,-1) ) ) * CollisionRadius);
    InnerRadiusScaleFactor = 0.6;


    //Level.GetLocalPlayerController().myHUD.AddDebugLine(Location, FarCornerLeftSide2D, class'Engine.Canvas'.Static.MakeColor(0,255,0));
    //Level.GetLocalPlayerController().myHUD.AddDebugLine(Location, FarCornerRightSide2D, class'Engine.Canvas'.Static.MakeColor(0,0,255));

    //Log("Pawn on side that door "$Name$" is open to: "$PointIsOnSideThatDoorIsOpenTo(Location));

    if (PointIsOnSideThatDoorIsOpenTo(thePawn.Location) &&
        VSize2D(HingeLocation2D - thePawn.Location) < (GetDoorwayWidth() * InnerRadiusScaleFactor))
    {
        // Pawn is close to the hinge and on same side that door is open to, 
        // so push towards far corner on side opposite the side the door is 
        // currently open to.
        if (IsOpenLeft() || IsOpeningLeft())
            DesiredCorner2D = FarCornerRightSide2D;
        else
            DesiredCorner2D = FarCornerLeftSide2D;
    }
    else 
    {
        // Pawn is either far from hinge or not on the side that the door is
        // open to, so push him towards the nearest far corner.
        if (PointIsToMyLeft(thePawn.Location))
            DesiredCorner2D = FarCornerLeftSide2D;
        else
            DesiredCorner2D = FarCornerRightSide2D;
    }

    // Return normalized vector indicating direction to push the ragdoll
    return DesiredCorner2D - HingeLocation2D;
}

defaultproperties
{
    //CollisionRadius must be at least (w^2+(w/2)^2)^(1/2), where w is the width of the door,
    //  so that the door's collision cylinder contains the door model wherever it is.
    CollisionRadius=90.0
    //w=80, w^2=6400, (w/2)^2=1600
    
    Mesh=SkeletalMesh'SWATDoorAnimation.SwatDoor'
    BrokenStaticMesh=StaticMesh'Doors_sm.door_door01_damaged'

    DoorBufferVolumeCollisionMesh=StaticMesh'Doors_sm.door_phys_singleref'
}
