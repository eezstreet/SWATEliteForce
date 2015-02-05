class Hands extends Actor     
    implements ICanHoldEquipment, ICanThrowWeapons
    native
    config(SwatGame);

//TMC from Inventory.uc
var config vector PlayerViewOffset; //offset from view center

var protected config array<string> AnimationGroups;

var config float MinimumLongThrowSpeed;         //if a ThrownWeapon is thrown at a speed less than this, then the 'short' animations are played, otherwise, 'long' animations are used

var config name ThrowShortAnimation;
var config name ThrowLongAnimation;

var config name PreThrowAnimation;      //a pull-pin-and-raise-grenade animation
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
    local Pawn PawnOwner;
    local vector NewLocation;
    local rotator NewRotation;
    local HandheldEquipmentModel EquippedFirstPersonModel;
    local HandheldEquipment EquippedItem;
    
    PawnOwner = Pawn(Owner);
    if (PawnOwner == None)
    {
        AssertWithDescription(false,"[tcohen] Hands.UpdateHandsForRendering() was called, but its Owner wasn't a Pawn.");
    }

    NewRotation = PawnOwner.GetViewRotation();

    NewLocation = 
        PawnOwner.Location + 
        PawnOwner.CalcDrawOffset() + 
        PawnOwner.ViewLocationOffset(NewRotation);

    // Implement "showhands" command in SwatCheatManager.
    // Native code sets bHidden on hands/gun every tick, so we hide
    // the hands in native code. But we need to hide/show the first person
    // model each tick here.
    EquippedItem = PawnOwner.GetActiveItem();
    if (EquippedItem != None)
    {
        EquippedFirstPersonModel = EquippedItem.FirstPersonModel;
        if (EquippedFirstPersonModel != None)
        {
            EquippedFirstPersonModel.bOwnerNoSee = !PawnOwner.bRenderHands;        
        }
    }

    bOwnerNoSee = !PawnOwner.bRenderHands;

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

    //only use a tween time once each time it is set
    SavedTweenTime = NextIdleTweenTime;
    SetNextIdleTweenTime(0.0);

    theActiveItem = GetActiveItem();
    if ( theActiveItem == None )
        return;

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
    return PreThrowAnimation;
}

simulated function name GetThrowAnimation(float ThrowSpeed)
{
    if (ThrowSpeed < MinimumLongThrowSpeed)
        return ThrowShortAnimation;
    else
        return ThrowLongAnimation;
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
