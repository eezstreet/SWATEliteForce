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
var protected RedDot redDot;

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

    redDot = Spawn(class'RedDot', self);
    redDot.SetDrawScale(0.0018);
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
	local float MaxInertiaOffset;
	local SwatWeapon Weapon;
    local bool showRedDot;

    OwnerPawn = Pawn(Owner);
    OwnerController = PlayerController(OwnerPawn.Controller);
    DeltaTime = OwnerController.LastDeltaTime;
    HandsPass.Length = HandAnimationPass.EnumCount;

	bOwnerNoSee = !OwnerPawn.bRenderHands || OwnerController.GetViewmodelDisabled();

    EquippedItem = OwnerPawn.GetActiveItem();
    if (EquippedItem != None)
    {
        EquippedFirstPersonModel = EquippedItem.FirstPersonModel;
        if (EquippedFirstPersonModel != None)
        {
            EquippedFirstPersonModel.bOwnerNoSee = bOwnerNoSee;
        }
    }

    Weapon = SwatWeapon(EquippedItem);
    if (Weapon != None) {
        showRedDot = weapon.GetUsesRedDotSight();
    } else {
        showRedDot = false;
    }

    NewRotation = OwnerPawn.GetViewRotation();

    // Location of the weapon if it stayed at our hip without any inertia or ADS effects.
    TargetLocation =
    	OwnerPawn.Location +
    	OwnerPawn.CalcDrawOffset() +
    	OwnerPawn.ViewLocationOffset(NewRotation);

    // Range 0 - 1, where 0 is default view (hip fire) and 1 is ADS view.
    AnimationProgress = EquippedItem.GetIronSightAnimationProgress();
    // ViewInertia controls how much weapon sways when we move.
    ViewInertia = EquippedItem.GetViewInertia();
    // MaxInertiaOffset limits how far the weapon can sway from center.
    MaxInertiaOffset = EquippedItem.GetMaxInertiaOffset();
    // ADSInertia controls how fast we aim down sight. We set it by scaling the ViewInertia.
    ADSInertia = (1 - ViewInertia) * 8;

    // Update animation progress, interpolating towards default view or ADS view as applicable.
    if (OwnerController != None && OwnerController.WantsZoom && !OwnerController.GetIronsightsDisabled()) {
    	AnimationProgress = AnimationProgress + ADSInertia * deltaTime;

        //Enable or disable Red Dot reticle as appropriate
        if (showRedDot) {
            // HACK: only show red dot when sight is near center of screen. -Kevin
            if (AnimationProgress > 0.72) {
                if (RedDot.bHidden) RedDot.Show();
            } else {
                showRedDot = false;
            }
        }

    } else {
    	AnimationProgress = AnimationProgress - ADSInertia * deltaTime;
        showRedDot = false;
    }

    if (AnimationProgress > 1.0) AnimationProgress = 1.0;
    if (AnimationProgress < 0) AnimationProgress = 0;
    EquippedItem.SetIronSightAnimationProgress(AnimationProgress);

    // Update Red Dot reticle.
    if (!showRedDot && !RedDot.bHidden)  RedDot.Hide();
    if (!RedDot.bHidden) {
        // Dead-center screen, exactly where crosshair would be.
        RedDot.SetLocation(OwnerPawn.GetAimOrigin() + vector(NewRotation) * 10.0);
    }

    // Update pose based on AnimationProgress.
    NewRotation = NewRotation
    	+ EquippedItem.GetDefaultRotationOffset() * (1 - AnimationProgress)
    	+ EquippedItem.GetIronsightsRotationOffset() * AnimationProgress;

    Offset = (EquippedItem.GetDefaultLocationOffset() * (1 - AnimationProgress)
           + (EquippedItem.GetIronsightsLocationOffset() * AnimationProgress));

    // Look-down-scope animation for marksman (scoped) weapons.
    if (Weapon != None && Weapon.WeaponCategory == WeaponClass_MarksmanRifle && !bOwnerNoSee) {
        EquippedFirstPersonModel.bOwnerNoSee = (AnimationProgress >= 0.99);
            bHidden = (AnimationProgress >= 0.99);
    }

    // This converts local offset to world coordinates.
    Offset = Offset >> NewRotation;
    TargetLocation = TargetLocation + Offset;

    // Interpolate towards our target location. Inertia controls how quickly the weapon
    // visually responds to our movements.
    if(!OwnerController.GetInertiaDisabled())
    {
        NewLocation = (Location * ViewInertia) + (TargetLocation * (1 - ViewInertia));

        // Apply inertia (reducing weapon's movement speed).
        if (ViewInertia > 0) {
            Change = NewLocation - Location;
            // Scale for framerate. We interp halfway back to 1 because this gives more consistent results
            // across different framerates.
            Change *= 0.5 + (deltaTime / 0.016667) * 0.5;
            NewLocation = Location + Change;
        }

        // Smoothing.
        if (ViewInertia > 0) {
            NewLocation = (NewLocation + (TargetLocation - EquippedItem.GetHandsOffsetLastFrame())) / 2.0;
            EquippedItem.SetHandsOffsetLastFrame(TargetLocation - NewLocation);
        }

        // Cap the maximum distance we can be away from the target location.
        Change = NewLocation - TargetLocation;
        if(Change.x > MaxInertiaOffset) Change.x = MaxInertiaOffset;
        else if(Change.x < -MaxInertiaOffset) Change.x = -MaxInertiaOffset;
        if(Change.y > MaxInertiaOffset) Change.y = MaxInertiaOffset;
        else if(Change.y < -MaxInertiaOffset) Change.y = -MaxInertiaOffset;
        if(Change.z > MaxInertiaOffset) Change.z = MaxInertiaOffset;
        else if (Change.z < -MaxInertiaOffset) Change.z = -MaxInertiaOffset;

        // HACK. Disable Red Dot reticle if weapon is displaced enough that the reticle
        // would fall outside the sight. -Kevin
        if (!RedDot.bHidden) {
            if (abs(Change.x) > 0.9 || abs(Change.y) > 0.9 || abs(Change.z) > 0.9) {
                RedDot.Hide();
            }
        }

        NewLocation = TargetLocation + Change;
    }
    else
    {
        NewLocation = TargetLocation;
    }

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
}

function RenderRedDot(Canvas canvas) {
    if (redDot != None && !redDot.bHidden) {
        // Draw the Red Dot in PostRender; this renders it on top of our hands and weapon.
        // Can't figure out a way to render it at the same time as hands so that it is properly
        // depth sorted relative to our weapon. -Kevin
        canvas.DrawActor(redDot, false, true);
    }
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

    if(TheActiveItem.IsA('SwatGrenade') && SwatGrenade(TheActiveItem).IsInFastUse())
      return; // never idle

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
	/*else if(TheActiveItem.IsA('SwatGrenade') && SwatGrenade(TheActiveItem).IsInFastUse())
	{
		PlayNewAnim('GlowIdle', 0.0, 0.2);
	}*/
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

event Destroyed() {
    if (redDot != None) {
        redDot.Destroy();
    }
    super.Destroyed();
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
