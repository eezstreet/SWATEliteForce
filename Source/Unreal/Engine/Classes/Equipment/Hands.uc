class Hands extends Actor
    implements ICanHoldEquipment, ICanThrowWeapons
    native
    config(SwatGame);

//TMC from Inventory.uc
var config vector PlayerViewOffset; //offset from view center

var protected config array<string> AnimationGroups;

// Moved into HandsConfig so this can be freed up for more important things --eez
/*
var config float MinimumLongThrowSpeed;         //if a ThrownWeapon is thrown at a speed less than this, then the 'short' animations are played, otherwise, 'long' animations are used

var config name ThrowShortAnimation;
var config name ThrowLongAnimation;

var config name PreThrowAnimation;      //a pull-pin-and-raise-grenade animation
*/

/*
 * This is a ginormous hack, but basically we need to pack a ton of information into a little space.
 * Hence, this mess!
 * The HandPass array contains a lot of information that we need to animate the viewmodel correctly.
 * See the comment on each one for what they do.
 */
enum HandAnimationPass
{
  HandPass_PreviousLocation,
  HandPass_PreviousAngles,
};

var protected array<vector> HandsPass;
var protected int NotUsed;

var config float PreThrowTweenTime;
var config float PreThrowRootBone;


var private bool bIsLowReady;
var private float NextIdleTweenTime;    //next time we play an idle, play with this tween time.  PLEASE only set with SetNextIdleTweenTime()

simulated function PreBeginPlay()
{
    AssertWithDescription(AnimationGroups.length > 0,
        "[tcohen] The Hands' AnimationGroups list is empty.  Check SwatGame.ini, [Engine.Hands].");

    AssertWithDescription(Mesh != None,
                          "[ckline] The Hands' mesh wasn't correctly loaded(1). Mesh == None." );

    LoadAnimationSets(AnimationGroups);
    SetTweenMode(0, kChannelTweenModeDynamic);

    AssertWithDescription(Mesh != None,
                          "[ckline] The Hands' mesh wasn't correctly loaded(2). Mesh == None." );

    SetCollision(false,false,false);
}

simulated event PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    // Register to be notified when the level is about to render, so we can
    // render the first person model, if necessary.

    // Because our first person hands rely on registerClientMessage() to
    // notify us to render by calling onMessage(), and that only works for
    // things with valid names, the second parameter to
    // registerClientMessage() below must be non-None.
    AssertWithDescription( Level.Label != '',
                           "[mjames] Every level must have its label set. The current level's label is None." );
    registerClientMessage(class'MessagePreRender', Level.label);
}

simulated function onMessage(Message m)
{
    // NOTE: we don't check the class of 'm' because we only register to
    // receive one kind of message (MessagePreRender, done in
    // PostNetBeginPlay())
	UpdateHandsForRendering();
}

simulated function UpdateHandsForRendering()
{
    local Pawn OwnerPawn;
    local PlayerController OwnerController;
    local vector TargetLocation;
    local float AnimationProgress;
	  local float AnimationProgressChange;
    local vector NewLocation;
    local rotator NewRotation;
    local HandheldEquipmentModel EquippedFirstPersonModel;
    local HandheldEquipment EquippedItem;
    local vector Offset;
    local float ViewInertia;
    local float ADSInertia;
  	local vector Change;
  	local float DeltaTime;
    local vector Velocity, Acceleration;

    OwnerPawn = Pawn(Owner);
    OwnerController = PlayerController(OwnerPawn.Controller);
    DeltaTime = OwnerController.LastDeltaTime;
    HandsPass.Length = HandAnimationPass.EnumCount;

    EquippedItem = OwnerPawn.GetActiveItem();
    if (EquippedItem != None)
    {
        EquippedFirstPersonModel = EquippedItem.FirstPersonModel;
        if (EquippedFirstPersonModel != None)
        {
            EquippedFirstPersonModel.bOwnerNoSee = !OwnerPawn.bRenderHands;
        }
    }

  	NewRotation = OwnerPawn.GetViewRotation();

  	//Location of the weapon if it stayed at our hip without any inertia or ADS effects
  	TargetLocation =
  		OwnerPawn.Location +
  		OwnerPawn.CalcDrawOffset() +
  		OwnerPawn.ViewLocationOffset(NewRotation);

  	AnimationProgress = EquippedItem.GetIronSightAnimationProgress();
  	//ViewInertia controls how much weapon sways when we move
  	ViewInertia = EquippedItem.GetViewInertia();
  	//ADSInertia controls how fast we aim down sight
  	ADSInertia = 1 - ((1 - ViewInertia) / 2.5);

  	//if the player is zooming, add the iron sight offset to the new location
  	if (OwnerController != None && OwnerController.WantsZoom) {
  		AnimationProgress = (AnimationProgress * ADSInertia + 1 * (1 - ADSInertia));
  		//NewRotation += EquippedItem.GetIronsightsRotationOffset();
  	} else {
  		AnimationProgress = (AnimationProgress * ADSInertia + 0 * (1 - ADSInertia));
  		//HACK: offset when the player isn't using iron sights, to fix the ******* P90 -K.F.
  		//NewRotation += EquippedItem.GetDefaultRotationOffset();
  		Offset = EquippedItem.GetDefaultLocationOffset();
  	}

  	//scale animation position change based on framerate
  	AnimationProgressChange = AnimationProgress - EquippedItem.GetIronSightAnimationProgress();
  	AnimationProgressChange = AnimationProgressChange * (deltaTime / 0.016667); //scale relative to 60fps
  	AnimationProgress = EquippedItem.GetIronSightAnimationProgress() + AnimationProgressChange;

  	NewRotation = NewRotation
  		+ EquippedItem.GetDefaultRotationOffset() * (1 - AnimationProgress)
  		+ EquippedItem.GetIronsightsRotationOffset() * AnimationProgress;

  	EquippedItem.SetIronSightAnimationProgress(AnimationProgress);
  	//apply progress of iron sight animation
  	Offset += (EquippedItem.GetIronsightsLocationOffset() * AnimationProgress);

  	//this converts local offset to world coordinates
  	Offset = Offset >> NewRotation;
  	TargetLocation = TargetLocation + Offset;

  	//interpolate towards our target location. inertia controls how quickly the weapon
  	//visually responds to our movements
  	NewLocation = (Location * ViewInertia) + (TargetLocation * (1 - ViewInertia));

  	if (ViewInertia > 0) {
      Change = NewLocation - HandsPass[HandAnimationPass.HandPass_PreviousLocation];
      Change *= (deltaTime / 0.016667);
      NewLocation = (Change * 0.3628864620) + HandsPass[HandAnimationPass.HandPass_PreviousLocation];
  	}

    // Cap the maximum distance we can be away from the target location
    Change = NewLocation - TargetLocation;
    if(Change.x > 1.0) Change.x = 1.0;
    else if(Change.x < -1.0) Change.x = -1.0;
    if(Change.y > 1.0) Change.y = 1.0;
    else if(Change.y < -1.0) Change.y = -1.0;
    if(Change.z > 1.0) Change.z = 1.0;
    else if(Change.z < -1.0) Change.z = -1.0;

    NewLocation = TargetLocation + Change;

  	bOwnerNoSee = !OwnerPawn.bRenderHands;

  	// Special-case exception: even if hands/weapon rendering is disabled,
  	// the hands and weapon should be shown when the optiwand is equipped
  	// (otherwise you can't see the optiwand screen)
  	if (bOwnerNoSee && EquippedItem.IsA('Optiwand'))
  	{
  		if (EquippedFirstPersonModel != None)
  		{
  			EquippedFirstPersonModel.bOwnerNoSee = false;
  		}
  		bOwnerNoSee = false;
  	}

    SetLocation(NewLocation);
    SetRotation(NewRotation);
    HandsPass[HandAnimationPass.HandPass_PreviousLocation] = NewLocation;
    HandsPass[HandAnimationPass.HandPass_PreviousAngles] = vector(NewRotation);
}

simulated function OnEquipKeyFrame()
{
//    log( self$" in Hands::OnEquipKeyFrame()" );
    Pawn(Owner).OnEquipKeyFrame();
}

simulated function OnUnequipKeyFrame()
{
//    log( self$" in Hands::OnUnequipKeyFrame()" );
    Pawn(Owner).OnUnequipKeyFrame();
}

simulated function OnUseKeyFrame()
{
//    log( self$" in Hands::OnUseKeyFrame()" );
    Pawn(Owner).OnUseKeyFrame();
}

simulated function OnLightstickKeyFrame()
{
//    log( self$" in Hands::OnUseKeyFrame()" );
    Pawn(Owner).OnLightstickKeyFrame();
}

simulated function OnMeleeKeyFrame()
{
//    log( self$" in Hands::OnMeleeKeyFrame()" );
    Pawn(Owner).OnMeleeKeyFrame();
}

simulated function OnReloadKeyFrame()
{
//    log( self$" in Hands::OnReloadKeyFrame()" );
    Pawn(Owner).OnReloadKeyFrame();
}

//hands idle
event AnimEnd( int Channel )
{
    if (Level.GetLocalPlayerController().HandsShouldIdle())
        IdleHoldingEquipment();
}

//activeItem should be non-None and Idle
simulated function IdleHoldingEquipment()
{
    local int RandChance;
    local int AccumulatedChance;
    local int i;
    local HandheldEquipmentModel Model;
    local HandheldEquipment theActiveItem;
    local float SavedTweenTime;
    local Pawn OwnerPawn;
    local PlayerController OwnerController;

    //only use a tween time once each time it is set
    SavedTweenTime = NextIdleTweenTime;
    SetNextIdleTweenTime(0.0);

    theActiveItem = GetActiveItem();
    if ( theActiveItem == None )
        return;

	//if the player is zooming, don't play the idle animation unless it changes our lowReady state
	OwnerPawn = Pawn(Owner);
	//if SavedTweenTime is 0, this is a generic idle animation, not a lowReady transitioning
	if (SavedTweenTime == 0 && OwnerPawn != None)
	{
		OwnerController = PlayerController(OwnerPawn.Controller);
		if (OwnerController != None && OwnerController.WantsZoom)
		{
			return;
		}
	}

    Model = theActiveItem.GetFirstPersonModel();

    if (bIsLowReady && Model.HolderLowReadyIdleAnimation != '')
    {
        if (Model.HolderDisorientedLowReadyIdleAnimation != '' && ICanBeArrested(Owner).CanBeArrestedNow())
        {
            PlayNewAnim(Model.HolderDisorientedLowReadyIdleAnimation, 0.0, 0.2);
        }
        else
            PlayNewAnim(Model.HolderLowReadyIdleAnimation, 0.0, 0.2);
    }
    else
    {
        if (Model.HolderIdleAnimations.length == 0)
            return;

        RandChance = Rand(Model.IdleChanceSum);

        //find the selected
        for (i=0; i<Model.HolderIdleAnimations.length; ++i)
        {
            AccumulatedChance += Model.HolderIdleAnimations[i].Chance;

            if (AccumulatedChance >= RandChance)
            {
                PlayNewAnim(
                    Model.HolderIdleAnimations[i].Animation,
                    1.0,                   //Rate
                    SavedTweenTime);    //support tween times for quick low-ready transitions
                return;
            }
        }

        assert(false);  //we should have chosen something
    }
}

//plays Sequence on channel 0 if the Hands aren't already playing that animation
function PlayNewAnim(name Sequence, float Rate, float TweenTime)
{
    if (!IsAnimating() || GetAnimName() != Sequence)
        PlayAnim(Sequence, Rate, TweenTime);
}

//called by SwatPlayer::SetLowReady() only when low-ready changes
function SetLowReady(bool bEnable)
{
    if (bIsLowReady == bEnable)
        return;

    bIsLowReady = bEnable;

    if (Level.GetLocalPlayerController().HandsShouldIdle())
    {
        SetNextIdleTweenTime(0.2);  //we're immediately transitioning, so tween
        IdleHoldingEquipment();
    }
}

function SetNextIdleTweenTime(float inNextIdleTweenTime)
{
    NextIdleTweenTime = inNextIdleTweenTime;
}

//
//ICanHoldEquipment implementation
//

simulated function HandheldEquipment GetActiveItem()
{
    return Pawn(Owner).GetActiveItem();
}

simulated function HandheldEquipment GetPendingItem()
{
    return Pawn(Owner).GetPendingItem();
}

simulated function OnNVGogglesDownKeyFrame()
{
}

simulated function OnNVGogglesUpKeyFrame()
{
}

//
//ICanThrowWeapons implementation
//

function GetThrownProjectileParams(out vector outLocation, out rotator outRotation)
{
    assert(false);  //TMC hands shouldn't be asked to specify thrown projectile params... the player pawn does that for the Hands
}

function name GetPawnThrowRootBone()
{
	assert(false); // hands shouldn't be asked for the pawn's throwing animation root bone
	return '';
}

simulated function float GetPawnThrowTweenTime()
{
	assert(false); // hands shouldn't be asked for the pawn's throwing animation tween time
	return 0.0;
}

simulated function name GetPreThrowAnimation()
{
    return class'HandsConfig'.default.PreThrowAnimation;
}

simulated function name GetThrowAnimation(float ThrowSpeed)
{
    if (ThrowSpeed < class'HandsConfig'.default.MinimumLongThrowSpeed)
        return class'HandsConfig'.default.ThrowShortAnimation;
    else
        return class'HandsConfig'.default.ThrowLongAnimation;
}

simulated function SetMaterialForHands( Material NewMaterial )
{
    assert( Level.NetMode != NM_Standalone );
    Skins[0] = NewMaterial;
}

cpptext
{
    // Automatically updates the correct value of bOwnerNoSee based on
    // the current view.
    virtual UBOOL Tick( FLOAT DeltaSeconds, ELevelTick TickType );
    virtual void PreRenderCallback(UBOOL MainScene, FLevelSceneNode* SceneNode, FRenderInterface* RI);
}

defaultproperties
{
    // Note: bHidden is dynamically changed every frame in AHands::Tick
    bHidden=false

    DrawType=DT_Mesh
    Mesh=SkeletalMesh'FP_Hand2.1stPersonHand'

    bOwnerNoSee=false

    // Don't replicate. All hands are local to the machine on which they
    // were created.
    RemoteRole=ROLE_None

    Physics=PHYS_None
    bNeverDrawIfPlayerIsDrawn=true

    MaxLights=5

    // This will actually stop both pre- and post-render callbacks
    // from being called on the first person model
    bNeedPostRenderCallback=true
}
