class HandheldEquipment extends Equipment
    implements ICanBeSelectedInTheGUI, DamageType
    abstract
    native;

var(Firing) config int Range;   //the effective range of this equipment

var(Viewmodel) config class<HandheldEquipmentModel> FirstPersonModelClass;
var(Viewmodel) config class<HandheldEquipmentModel> ThirdPersonModelClass;

//if specified, these model classes will be used in multiplayer
var(Viewmodel) config class<HandheldEquipmentModel> MPFirstPersonModelClass;
var(Viewmodel) config class<HandheldEquipmentModel> MPThirdPersonModelClass;

var(GUI) config localized   String  Description;
var(GUI) config localized   String  FriendlyName;
var(GUI) config    Material GUIImage;

var bool ShouldLowReady;

var(Zoom) config float ZoomedFOV;				// FOV when zoomed in
var(Zoom) config float ZoomTime;				// time it takes to zoom in
var(Zoom) config Material ZoomBlurOverlay;	// 512x512 Material that is draw as an overlay when the item is zoomed in; set to None for no overlay

var(Viewmodel) config name		LightstickThrowAnimPostfix	"Postfix appended to the third person lightstick throw animation when pawn is using this equipment.";


enum EquipmentSlot
{
  Slot_Invalid,           //0
	Slot_PrimaryWeapon,     //1
	Slot_SecondaryWeapon,   //2
	Slot_Flashbang,         //3
	Slot_CSGasGrenade,      //4
	Slot_StingGrenade,      //5
	Slot_PepperSpray,       //6
	Slot_Breaching,         //7
	Slot_Toolkit,           //8
	Slot_Optiwand,          //9
	Slot_Wedge,             //10 (zero or F10 key)
	Slot_Cuffs,             //11
	Slot_Detonator,         //12 (not accessable to player)
	Slot_IAmCuffed,         //13 (not accessable to player)
	Slot_Lightstick,        //14
	Slot_AmmoBandolier,     //15
	kNumEquipmentSlots,
};

var protected EquipmentSlot Slot;  //this never changes, and is always returned as the class's default

// Do not rearrange the items in this enum; our loadout code depends on this
// ordering.
enum Pocket
{
    Pocket_PrimaryWeapon,          //  0
    Pocket_PrimaryAmmo,            //  1
    Pocket_SecondaryWeapon,        //  2
    Pocket_SecondaryAmmo,          //  3
    Pocket_EquipOne,               //  4
    Pocket_EquipTwo,               //  5
    Pocket_EquipThree,             //  6
    Pocket_EquipFour,              //  7
    Pocket_EquipFive,              //  8
    Pocket_EquipSix,               //  9
    Pocket_BodyArmor,              // 10
    Pocket_HeadArmor,              // 11
    Pocket_Toolkit,                // 12
    Pocket_Detonator,              // 13
    Pocket_Cuffs,                  // 14
    Pocket_IAmCuffed,              // 15
    Pocket_Unused1,                // 16
    Pocket_Unused2,                // 17
    Pocket_SimpleBackPouch,        // 18
    Pocket_SimpleHipPouch,         // 19
    Pocket_SimpleHolster,          // 20
    Pocket_SimplePepperSprayPouch, // 21
    Pocket_SimpleRadioPouch,       // 22
    Pocket_HeadEffectProtection,   // 23
    Pocket_Lightstick,             // 24
	  Pocket_CustomSkin,             // 25
    Pocket_Invalid                 // 26
};

var private Pocket ThePocket;         // assigned when the item is placed into
                                      // the loadout.

var HandheldEquipmentModel FirstPersonModel;    //PROTECTED, PLEASE (protected becomes private across package boundaries)
var HandheldEquipmentModel ThirdPersonModel;    //PROTECTED, PLEASE (protected becomes private across package boundaries)

//var protected ICanHoldEquipment Hands;

//these are used to ensure that operations complete, and are not interrupted prematurely
enum ActionStatus
{
    ActionStatus_Idle,     //default value
    ActionStatus_Started,
    ActionStatus_HitKeyFrame
};
var protected ActionStatus EquippingStatus;
var protected ActionStatus UnequippingStatus;
var protected ActionStatus UsingStatus;
var protected ActionStatus MeleeingStatus;

var(Viewmodel) config float EquipAnimationRate;
var(Viewmodel) config float UnequipAnimationRate;
var(Viewmodel) config float UseAnimationRate;
var(Viewmodel) config float MeleeAnimationRate;
var(Viewmodel) config bool InstantUnequip;

var bool		 bAbleToMelee;
var bool		 MeleeAnimNotifierTriggered;
var(Melee) config float MeleeRange;
var(Melee) config float MeleeDamage;
var(Melee) config float MeleePlayerStingDuration;
var(Melee) config float MeleeHeavilyArmoredPlayerStingDuration;
var(Melee) config float MeleeNonArmoredPlayerStingDuration;
var(Melee) config float MeleeAIStingDuration;

var bool Available;
var bool UnavailableAfterUsed;          //if true, then Available is set to false after used
var bool EquipOtherAfterUsed;           //if true, then a Holder should DoDefaultEquip() after this item is used.
                                        //  Note: if UnavailableAfterUsed is true, then EquipOtherAfterUsed is assumed!
var bool PlayerCanUnequip;              //if false, then a player cannot simply unequip this piece of equipment.  Intended for the IAmCuffed HandheldEquipment.
var(Viewmodel) config bool ShouldHaveFirstPersonModel;     //Most HandheldEquipment requires a valid FirstPersonModelClass.  But some (eg. IAmCuffed) don't... so this allows us to
                                                //  not provide a FirstPersonModel, and at the same time assert that HHEquipment that should have a FirstPersonModel does.
var(Viewmodel) config bool ShouldHaveThirdPersonModel;     //Most HandheldEquipment requires a valid ThirdPersonModelClass.  But some (eg. SniperRifle) don't... so this allows us to
                                                //  not provide a ThirdPersonModel, and at the same time assert that HHEquipment that should have a ThirdPersonModel does.

var HandheldEquipmentPickup Pickup;

var() private config float RagdollDeathImpactMomentumMultiplier;
var private int AvailableCount;             //eg. not Thrown.  We don't remove items from LoadOut so that we have a record of them having been there.

replication
{
  reliable if(Role == ROLE_Authority)
    AvailableCount;
}

function PostBeginPlay()
{
    Super.PostBeginPlay();
}

simulated event PostNetBeginPlay()
{
    //mplog( self$"HandheldEquipment::PostNetBeginPlay(). Owner="$Owner );

    super.PostNetBeginPlay();

    assertWithDescription(Owner != None,
                          "[tcohen] The HandheldEquipment "$name$" is not owned by any Pawn.");

    CreateModels();
}

simulated function CreateModels()
{
    local class<HandheldEquipmentModel> SelectedFirstPersonModelClass;
    local class<HandheldEquipmentModel> SelectedThirdPersonModelClass;

    //if (Level.GetEngine().EnableDevTools)
    //    mplog( self$"---HandheldEquipment::CreateModels()." );

    SelectModelClasses(SelectedFirstPersonModelClass, SelectedThirdPersonModelClass);
    //mplog( "...SelectedFirstPersonModelClass="$SelectedFirstPersonModelClass );
    //mplog( "...SelectedThirdPersonModelClass="$SelectedThirdPersonModelClass );
    //mplog( "...ShouldHaveFirstPersonModel="$ShouldHaveFirstPersonModel );
    //mplog( "...ShouldHaveThirdPersonModel="$ShouldHaveThirdPersonModel );

    //First Person Model

    if (ShouldHaveFirstPersonModel)
        assertWithDescription(SelectedFirstPersonModelClass != None,
            "[tcohen] The class "$class.name
            $" should have a valid FirstPersonModelClass, but it doesn't.  In SwatEquipment.ini, [SwatEquipment."$class.name
            $", please specify a valid FirstPersonModelClass, or set ShouldHaveFirstPersonModel=false.");

    if (ShouldHaveFirstPersonModel && GetHands() != None )
    {
        FirstPersonModel = Spawn(
							SelectedFirstPersonModelClass,
							Pawn(Owner).GetHands(),		//owned by Hands
							/*default tag*/,
							/*default location*/,
							/*default rotation*/,
							true						//no fail
							);
        //mplog( "......FirstPersonModel="$FirstPersonModel );
        assertWithDescription(FirstPersonModel != None,
                              "[tcohen] "$name$" failed to spawn its FirstPersonModel of class "$SelectedFirstPersonModelClass$".");

		FirstPersonModel.SetHandHeldEquipment(self);
        FirstPersonModel.Show();
        FirstPersonModel.OnUnequipKeyFrame();

        if (FirstPersonModel.HolderLowReadyIdleAnimation != '')
            ShouldLowReady = true;  //ShouldLowReady is now data-driven
    }

    //Third Person Model

    if (ShouldHaveThirdPersonModel)
    {
        assertWithDescription(SelectedThirdPersonModelClass != None,
            "[tcohen] The class "$class.name
            $" should have a valid ThirdPersonModelClass, but it doesn't.  In SwatEquipment.ini, [SwatEquipment."$class.name
            $", please specify a valid ThirdPersonModelClass, or set ShouldHaveThirdPersonModel=false.");

        ThirdPersonModel = Spawn(
								SelectedThirdPersonModelClass,
								Owner,					//owned by Pawn
								/*default tag*/,
								/*default location*/,
								/*default rotation*/,
								true					//no fail
								);
        //mplog( "......ThirdPersonModel="$ThirdPersonModel );
        assertWithDescription(ThirdPersonModel != None,
                              "[tcohen] "$name$" failed to spawn its ThirdPersonModel of class "$ThirdPersonModelClass$".");
        ThirdPersonModel.SetHandHeldEquipment(self);
        ThirdPersonModel.Show();
        ThirdPersonModel.OnUnequipKeyFrame();
    }
    else
        assertWithDescription(SelectedThirdPersonModelClass == None,
            "[tcohen] The class "$class.name
            $" should not have a valid ThirdPersonModelClass, but it does.  In SwatEquipment.ini, [SwatEquipment."$class.name
            $", please specify ThirdPersonModelClass=None, or set ShouldHaveThirdPersonModel=true.");
}

simulated function SelectModelClasses(out class<HandheldEquipmentModel> SelectedFirstPersonModelClass, out class<HandheldEquipmentModel> SelectedThirdPersonModelClass)
{
    if (Level.NetMode == NM_Standalone || Level.IsPlayingCOOP || MPFirstPersonModelClass == None)
        SelectedFirstPersonModelClass = FirstPersonModelClass;
    else
        SelectedFirstPersonModelClass = MPFirstPersonModelClass;

    if (Level.NetMode == NM_Standalone || Level.IsPlayingCOOP || MPThirdPersonModelClass == None)
        SelectedThirdPersonModelClass = ThirdPersonModelClass;
    else
        SelectedThirdPersonModelClass = MPThirdPersonModelClass;
}

// Returns true if this weapon is currently being rendered in 1st person view,
// otherwise returns false to indicate 3rd person view
native protected function bool InFirstPersonView();

simulated function Hands GetHands()
{
    return Pawn(Owner).GetHands();
}


simulated function EquipmentSlot GetSlot()
{
    return Slot;
}

//Caution!  There are only special cases where the Slot of an instance should be changed.
simulated function SetSlot( EquipmentSlot NewSlot )
{
    Slot = NewSlot;
}

simulated static function EquipmentSlot GetDefaultSlot()
{
    return default.Slot;
}


simulated function Pocket GetPocket()
{
// dkaplan: this is no longer a valid assertion
//    if (ThePocket == Pocket_Invalid)
//    {
//        AssertWithDescription( false, "[mcj] Weapon has an invalid pocket value." );
//    }
    return ThePocket;
}


simulated function SetPocket( Pocket NewPocket )
{
    AssertWithDescription( ThePocket == Pocket_Invalid,
                           "[mcj] Trying to set an invalid pocket value for "$self );
    ThePocket = NewPocket;
}

simulated native final function HandheldEquipmentModel GetFirstPersonModel();
simulated native final event HandheldEquipmentModel GetThirdPersonModel();

//If a Pawn who owns a HandheldEquipment has Hands, then the Hands and the Pawn
//  should always agree on what they have equipped.
//This utility function checks that, and reports whether or not this Object is equipped.
simulated function bool IsEquipped()
{
    //log( self$": In HandheldEquipment::IsEquipped(). ActiveItem="$Pawn(Owner).GetActiveItem() );
    return Pawn(Owner).GetActiveItem() == self;
}

//Returns true iff this item's UsingStatus is not idle
simulated final function bool IsBeingUsed()
{
	return (UsingStatus != ActionStatus_Idle);
}

//Returns true iff this item's EquippingStatus is not idle
simulated final function bool IsBeingEquipped()
{
	return (EquippingStatus != ActionStatus_Idle);
}

//Returns true iff this item has hit the equip keyframe
simulated final function bool HasPlayedEquip()
{
	return (EquippingStatus == ActionStatus_HitKeyFrame);
}

//Returns true iff this item's UnequippingStatus is not idle
simulated final function bool IsBeingUnequipped()
{
	return (UnequippingStatus != ActionStatus_Idle);
}

//Returns true iff this is not busy performing some action,
//  ie. the progress of every action is ActionStatus_Idle
simulated final function bool IsIdle()
{
    local bool Result;

    //LogIdleInfo();

    // When an object is in the global state, the state name is the same as
    // class.name, rather than being ''.
    //Result =     IsInState( class.name )
    Result =     EquippingStatus     == ActionStatus_Idle
             &&  UnequippingStatus   == ActionStatus_Idle
             &&  UsingStatus         == ActionStatus_Idle
			 &&  MeleeingStatus		 == ActionStatus_Idle
             &&  IsHandheldEquipmentIdleHook();

    return Result;
}
//subclasses should override if they implement any actions
simulated protected function bool IsHandheldEquipmentIdleHook() { return true; }

// useful for debugging
simulated final function LogIdleInfo()
{
	log( "In HandheldEquipment::IsIdle(). IsHandheldEquipmentIdleHook()="$IsHandheldEquipmentIdleHook() );
    log( "   EquippingStatus="$EquippingStatus );
    log( "   UnequippingStatus="$UnequippingStatus );
    log( "   UsingStatus="$UsingStatus );
    log( "   GetStateName()="$GetStateName() );
}

//This is the entrypoint into equipping a HandheldEquipment.
//It will most likely be called by a Controller, a Pawn, or Tyrion, when the Pawn/hands should equip this item.
//The caller should first ensure that it makes sense to equip this,
//  eg. it is not already equipped, and the Pawn is not busy doing something else.

simulated final function Equip()
{
    //make sure this can be equipped now

    ValidateEquip();
    PreEquip();
    GotoState('BeingEquipped');
}

simulated function PreEquip()
{
    //used to send OnEquipKeyFrame() only once to Pawn & Hands,
    //  rather than once for each.
    EquippingStatus = ActionStatus_Started;
}

//This is a latent version of Equip().  See comments there.
simulated final latent function LatentEquip()
{
    //make sure this can be equipped now
    ValidateEquip();
    PreEquip();
    DoEquipping();
}

// This is a latent version of Equip that the AIs use so they
// interrupt any equipment
simulated final latent function LatentWaitForIdleAndEquip()
{
	Pawn(Owner).AIInterruptEquipment();

	if (! IsIdle())
		AIInterrupt();

	LatentEquip();
}

simulated final function AIInstantEquip()
{
	Pawn(Owner).AIInterruptEquipment();

	if (! IsIdle())
		AIInterrupt();

	Equip();
}


//do some error checking to make sure we're ready to be equipped
//  (we've been asked to Equip(), so we had better be ready)
simulated function ValidateEquip()
{
    local HandheldEquipment CurrentItem;

    CurrentItem = Pawn(Owner).GetActiveItem();

    if (CurrentItem != None && !CurrentItem.IsIdle())
        AssertWithDescription(false,
            "[tcohen] The HandheldEquipment "$name
            $" was called to Equip(), but it's owner's ActiveItem "$CurrentItem
            $" is busy doing something else. (EquippingStatus="$CurrentItem.EquippingStatus
            $", UnequippingStatus="$CurrentItem.UnequippingStatus
            $", UsingStatus="$CurrentItem.UsingStatus
            $HandheldEquipmentStatusString()
            $")");
}

//to support the non-latent version of Equip()
simulated state BeingEquipped
{
Begin:
    DoEquipping();
    GotoState('');
}

simulated latent private function DoEquipping()
{
    local HandheldEquipment OwnersActiveItem;
    local HandheldEquipment OwnersPendingItem;

    //log( "...In DoEquipping. Owner="$Owner );
    //log( "...In DoEquipping. Pawn(Owner)="$Pawn(Owner) );
    //log( "...In DoEquipping. Pawn(Owner)="$Pawn(Owner) );
    //log( "...In DoEquipping. Pawn(Owner).GetActiveItem()="$Pawn(Owner).GetActiveItem() );
    //log( "...In DoEquipping. Pawn(Owner).GetPendingItem()="$Pawn(Owner).GetPendingItem() );
    //log( "...In DoEquipping. FirstPersonModel="$FirstPersonModel );
    //log( "...In DoEquipping. ThirdPersonModel="$ThirdPersonModel );

    //could already be equipped by an auto-equip
    if (IsEquipped())
    {
        // If we're returning early here, we need to make sure that
        // EquippingStatus is set back to a neutral value, since we've already
        // set it to ActionStatus_Started in PreEquip() above. Terry says that
        // this should be o.k., and his explanation made sense to me (FLW).  --MCJ
        EquippingStatus = ActionStatus_Idle;
        return;
    }

    Pawn(Owner).SetPendingItem(self);

    OnPreEquipped();

    //if owner currently has something else equipped, then unequip that first
    OwnersActiveItem = Pawn(Owner).GetActiveItem();
    if (OwnersActiveItem != None && OwnersActiveItem != self)
    {
        if (OwnersActiveItem.AvailableCount > 0)
        {
            OwnersActiveItem.Unequip();
            if (Pickup != None)
                Pickup.OnUnequipToEquipFinished();

            //During unequipping, the owners pending item may have changed.
            OwnersPendingItem = Pawn(Owner).GetPendingItem();
            if (OwnersPendingItem != self)
            {
				if (OwnersPendingItem != None)
	                OwnersPendingItem.LatentEquip();
                return;
            }
        }
        else
            //this is the case where an UnavailableAfterUsed item is the old ActiveItem
            OwnersActiveItem.OnForgotten();
    }

    //Play, then finish, animations on pawn, hands, and the models they hold.
    //We need to play both first, then finish both, since finishing happens latently,
    //  and we want them to play simultaneously.

    if (FirstPersonModel != None)
        FirstPersonModel.PlayEquip();
    if (ThirdPersonModel != None)
        ThirdPersonModel.PlayEquip();

    if (FirstPersonModel != None)
        FirstPersonModel.FinishEquip();
    if (ThirdPersonModel != None)
        ThirdPersonModel.FinishEquip();

    //this should now be equipped
    //assertWithDescription(IsEquipped() || class'Pawn'.static.CheckDead( Pawn(Owner) ),
    //        "[tcohen] The HandheldEquipment "$name$" should have been equipped, but wasn't.");

    EquippingStatus = ActionStatus_Idle;
//    log( self$"In HandheldEquipment::DoEquipping. Set EquippingStatus="$EquippingStatus );

    Pawn(Owner).SetPendingItem(none);

    if (GetHands() != None)
        GetHands().IdleHoldingEquipment();

    //in case the server is really slow, the client might actually finish
    //  equipping before the server is done (because FinishAnim() returns
    //  a frame later). So we delay a bit to compensate.
    if  ( Level.NetMode == NM_Client
          && Pawn(Owner).Controller != None
          &&  Pawn(Owner).Controller.GetEquipmentSlotForQualify() != SLOT_Invalid )
    {
        Sleep(0.2);
    }

	OnPostEquipped();

    Pawn(Owner).OnEquippingFinished();
}

simulated function OnPreEquipped();
simulated function OnPostEquipped(); // dbeswick:

//Note that latent DoEquipping() is not yet complete.
//This is called by the Holder (an ICanHoldEquipment) of one
//  of this HandheldEquipment's Models when an AnimNotify
//  notifies it that the animation it is playing hit a
//  key frame.
//This will maintain the current state of the HandheldEquipment,
//  and will forward the notification to both models
//  (the FirstPersonModel and the ThirdPersonModel).
simulated final function OnEquipKeyFrame()
{
    //Only propagate OnEquipKeyFrame() once.
    //Note that both the Pawn & Hands will get OnEquipKeyFrame()
    //  at the same time, whomever's model gets to key-frame first.
    if (EquippingStatus == ActionStatus_Started)
    {
        if (ThirdPersonModel != None)
        {
            ThirdPersonModel.OnEquipKeyFrame();

            if ( Pawn(Owner).HasEquippedFirstItemYet )
                ThirdPersonModel.TriggerEffectEvent('Equipped');
        }

        if (GetHands() != None)
        {
            FirstPersonModel.OnEquipKeyFrame();
            FirstPersonModel.TriggerEffectEvent('Equipped');

            // This will actually cause both pre- and post-render callbacks
            // to be called on the first person model
            FirstPersonModel.bNeedPostRenderCallback = true;
        }

        EquippedHook();

        EquippingStatus = ActionStatus_HitKeyFrame;
//        log( self$"In HandheldEquipment::OnEquipKeyFrame. Set EquippingStatus="$EquippingStatus );
    }
}
simulated function EquippedHook();    //for subclasses

// PLEASE NOTE!
//
// If another item will be Equip()ed, just Equip() that item,
//  don't UnEquip() first!
// Equip() takes care of UnEquip()ing any current ActiveItem.
// In other words, UnEquip() should only be called (outside of the
//  equipment system) if the Pawn intends to have *nothing* equipped.
//
simulated latent final function UnEquip()
{
	if (InstantUnequip)
	{
		UnequippedHook();
	    UnequippingStatus = ActionStatus_Idle;
		FirstPersonModel.OnUnequipKeyFrame();
		ThirdPersonModel.OnUnequipKeyFrame();
		return;
	}

    //should only try to UnEquip the ActiveItem
    AssertWithDescription(IsEquipped(),
        "[tcohen] The HandheldEquipment "$name$" was called to UnEquip().  But it doesn't think its equipped.");

    //used to send OnUnquipKeyFrame() once to Pawn & Hands,
    //  rather than once for each.
    UnequippingStatus = ActionStatus_Started;

    //Play, then finish, animations on pawn, hands, and the models they hold.
    //We need to play both first, then finish both, since finishing happens latently,
    //  and we want them to play simultaneously.

    if (FirstPersonModel != None)
        FirstPersonModel.PlayUnequip();
    if (ThirdPersonModel != None)
        ThirdPersonModel.PlayUnequip();

    if (FirstPersonModel != None)
        FirstPersonModel.FinishUnequip();
    if (ThirdPersonModel != None)
        ThirdPersonModel.FinishUnequip();

    //this should no longer be equipped
    assertWithDescription(!IsEquipped() || class'Pawn'.static.CheckDead( Pawn(Owner) ),
        "[tcohen] The HandheldEquipment "$name$" should have been unequipped, but wasn't.");

    UnequippingStatus = ActionStatus_Idle;

	if (GetHands() != None)
		GetHands().IdleHoldingEquipment();
}

//Note that latent UnEquip() is not yet complete.
//This is called by the Holder (an ICanHoldEquipment) of one
//  of this HandheldEquipment's Models when an AnimNotify
//  notifies it that the animation it is playing hit a
//  key frame.
//This will maintain the current state of the HandheldEquipment,
//  and will forward the notification to both models
//  (the FirstPersonModel and the ThirdPersonModel).
simulated final function OnUnequipKeyFrame()
{
    //Only propagate OnEquipKeyFrame() once.
    //Note that both the Pawn & GetHands() will get OnUnequipKeyFrame()
    //  at the same time, whomever's model gets to key-frame first.
    if (UnequippingStatus == ActionStatus_Started)
    {
        ThirdPersonModel.OnUnequipKeyFrame();
        ThirdPersonModel.TriggerEffectEvent('UnEquipped');

        if (GetHands() != None)
        {
            FirstPersonModel.OnUnequipKeyFrame();
            FirstPersonModel.TriggerEffectEvent('UnEquipped');

            // This will actually stop both pre- and post-render callbacks
            // from being called on the first person model
            FirstPersonModel.bNeedPostRenderCallback = false;
        }

        UnequippedHook();

        UnequippingStatus = ActionStatus_HitKeyFrame;
    }
}
simulated function UnequippedHook();  //for subclasses

// This function is a total hack. It allows an AI to 'unequip' its weapon
// and make it 'unavailable' without going through the normal
// Unequip()/SetAvailable() process (i.e., without playing animations, etc).
// I have encapsulated it in this function so that all the hacky code
// is in one place.
simulated function HACK_QuickUnequipForAIDropWeapon()
{
    // should only be dropping if we have a 3rd person model
    assert(ThirdPersonModel != None);

    // unequip the weapon (by using the hook)
    UnequippedHook();
    ThirdPersonModel.OnUnequipKeyFrame(); // true means 'never hide after unequipping'

    // disable the weapon, it can no longer be used
    log(self$"SetAvailable(false) because HACK_QuickUnequipForAIDropWeapon");
    SetAvailable(false);

    // HandheldEquipmentModels are hidden in OnUnEquipKeyframe if they
    // don't have an UnequippedSocket, AND in SetAvailable(false).
    // So we need to unhide it here.
    ThirdPersonModel.Show();
}

// Called when the perspective from which the player is viewing the
// equipment's owner changes. For example, when the player's pawn dies the
// view is switched from 1st person to 3rd person view of the pawn. This also
// get's called whenever the Controller of the HandheldEquipment's Owner
// changes.
simulated function OnPlayerViewChanged();

//called by the PlayerController when the player instigates Use of this HandheldEquipment
simulated function OnPlayerUse()
{
    if ( !HandleMultiplayerUse() )
        Use();
}

simulated function bool ShouldUseWhileLowReady()
{
    return true;
}

simulated function bool ShouldLowReadyOnOfficers()
{
    return true;
}

simulated function bool ShouldLowReadyOnArrestable()
{
    return true;
}

// Does any multiplayer use()ing and returns true if it was handled successfully, returns false
// otherwise, indicating the normal use process should occur....
simulated function bool HandleMultiplayerUse()
{
    return false;
}

//This is the entrypoint into using a HandheldEquipment.
//It will most likely be called by a Controller, a Pawn, or Tyrion, when the Pawn/hands should use this item.
//The caller should first ensure that it makes sense to use this now.
simulated final function Use()
{
    //make sure this can be used now
    ValidateUse();
    PreUse();
    GotoState('BeingUsed');
}

simulated function PreUse()
{
    //used to send OnUseKeyFrame() only once to Pawn & Hands,
    //  rather than once for each.
    UsingStatus = ActionStatus_Started;
}

//This is a latent version of Use().  See comments there.
simulated final latent function LatentUse()
{
    //make sure this can be used now
    ValidateUse();
	PreUse();
    DoUsing();
}

simulated function bool PrevalidateUse()
{
    Assert( Level.NetMode != NM_Standalone );
    return ValidateUse( true ); // true means prevalidate (i.e. don't assert)
}

//do some error checking to make sure we're ready to be used
//  (we've been asked to Use(), so we had better be ready)
simulated function bool ValidateUse( optional bool Prevalidate )
{
    if ( !Prevalidate )
    {
        AssertWithDescription(IsEquipped(),
                              "[tcohen] The HandheldEquipment "$name
                              $" was called to Use().  But it doesn't think it is equipped.");

        AssertWithDescription(IsIdle(),
                              "[tcohen] The HandheldEquipment "$name
                              $" was called to Use(), but it is busy doing something else. (EquippingStatus="$EquippingStatus
                              $", UnequippingStatus="$UnequippingStatus
                              $", UsingStatus="$UsingStatus
                              $HandheldEquipmentStatusString()
                              $")");
    }

    return IsEquipped() && IsIdle();
}

//to support the non-latent version of Use()
simulated state BeingUsed
{
Begin:
    DoUsing();
    GotoState('');
}

simulated latent final private function DoUsing()
{
    Pawn(Owner).OnUsingBegan();

	PreUsed();

	DoUsingHook();

	OnUsingFinished();
}

simulated latent protected function PreUsed();      //for subclasses
simulated latent protected function DoUsingHook()   //override in subclasses
{
    //Play, then finish, animations on pawn, hands, and the models they hold.
    //We need to play both first, then finish both, since finishing happens latently,
    //  and we want them to play simultaneously.

    if (FirstPersonModel != None)
        FirstPersonModel.PlayUse(0);    //no tween
    if (ThirdPersonModel != None)
        ThirdPersonModel.PlayUse(0);    //no tween

    OnUsingBegan();

    if (FirstPersonModel != None)
        FirstPersonModel.FinishUse();
    if (ThirdPersonModel != None)
        ThirdPersonModel.FinishUse();

    // MCJ: If you put an assertion here in the future, remember that the pawn
    // may have died and the animation finished without sending all its
    // anim_notifies.
}
simulated latent protected function OnUsingBegan();

//Note that latent DoUsing() is not yet complete.
//This is called by the Holder (an ICanHoldEquipment) of one
//  of this HandheldEquipment's Models when an AnimNotify
//  notifies it that the animation it is playing hit a
//  key frame.
//This will maintain the current state of the HandheldEquipment,
//  and will forward the notification to both models
//  (the FirstPersonModel and the ThirdPersonModel).
simulated final function OnUseKeyFrame( optional bool ForceUse )
{
    //Only propagate OnEquipKeyFrame() once.
    //Note that both the Pawn & Hands will get OnUseKeyFrame()
    //  at the same time, whomever's model gets to key-frame first.
    if (UsingStatus == ActionStatus_Started || ForceUse )
    {
        ThirdPersonModel.OnUseKeyFrame();
        ThirdPersonModel.TriggerEffectEvent('Used');

        if (GetHands() != None)
        {
            FirstPersonModel.OnUseKeyFrame();
            FirstPersonModel.TriggerEffectEvent('Used');
        }

        UsedHook();

        if(UnavailableAfterUsed)
          AvailableCount--;

        log(self$"::OnUseKeyFrame. AvailableCount is now "$AvailableCount);

        UpdateAvailability();

        UsingStatus = ActionStatus_HitKeyFrame;
    }
}
simulated function UsedHook();    //for subclasses
//check the conditions when this item should become unavailable,
//  and set unavailable if appropriate.
//this is overridden in Cuffs because they become unavailable
//  even in training
simulated function UpdateAvailability()
{
    if (AvailableCount <= 0 && !Level.IsTraining)
        SetAvailable(false);
    if(AvailableCount < 0)
      AvailableCount = 0; // Don't let this go negative
}

simulated function DecrementAvailableCount()
{
  UpdateAvailability();
}

simulated final protected function OnUsingFinished()
{
	UsingStatus = ActionStatus_Idle;

	if (GetHands() != None)
		GetHands().IdleHoldingEquipment();

    OnUsingFinishedHook();
    Pawn(Owner).OnUsingFinished();
}
simulated function OnUsingFinishedHook();    //for subclasses

//This is the entrypoint into meleeing with a FiredWeapon.
//It will most likely be called by a Controller, or a Pawn, when the Pawn/hands should melee with this weapon.
//AIs don't melee
//The caller should first ensure that it makes sense to melee now,
//  ie. its not busy doing something else
// Executes on both client and server.
simulated final function Melee()
{
	if (Level.GetEngine().EnableDevTools)
        mplog( self$"---HandheldEquipment::Melee()." );

	//make sure this can be used now
	ValidateMelee();
	PreMelee();
	GotoState('Meleeing');
}

simulated function PreMelee()
{
	MeleeingStatus = ActionStatus_Started;
}

simulated function bool PrevalidateMelee()
{
    Assert( Level.NetMode != NM_Standalone );
    return ValidateMelee( true ); // true means prevalidate (i.e. don't assert)
}

//do some error checking to make sure we're ready to melee
//  (we've been asked to Melee(), so we had better be ready)
simulated function bool ValidateMelee( optional bool Prevalidate )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---HandheldEquipment::ValidateMelee()." );

    if ( !Prevalidate )
    {
        if (!IsEquipped())
        {
            AssertWithDescription(false,
                "[tcohen] The HandheldEquipment "$name
                $" was called to Melee().  But it doesn't think it is equipped.");
        }

        if (!IsIdle())
        {
            AssertWithDescription(false,
                "[tcohen] The HandheldEquipment "$name
                $" was called to Melee(), but it is busy doing something else. (EquippingStatus="$EquippingStatus
                $", UnequippingStatus="$UnequippingStatus
                $", UsingStatus="$UsingStatus
				$", MeleeingStatus="$MeleeingStatus
                $")");
        }
    }

    return IsEquipped() && IsIdle();
}

simulated state Meleeing
{
Begin:
	DoMeleeing();
	GotoState('');
}

simulated latent private function DoMeleeing()
{
	if (Level.GetEngine().EnableDevTools)
        mplog( self$"---FiredWeapon::DoMeleeing()." );

    //Play, then finish, animations on pawn, hands, and the models they hold.
    //We need to play both first, then finish both, since finishing happens latently,
    //  and we want them to play simultaneously.

    if (FirstPersonModel != None)
        FirstPersonModel.PlayMelee();
    if (ThirdPersonModel != None)
        ThirdPersonModel.PlayMelee();

    if (FirstPersonModel != None)
        FirstPersonModel.FinishMelee();
    if (ThirdPersonModel != None)
        ThirdPersonModel.FinishMelee();

    MeleeingStatus = ActionStatus_Idle;

	// If the melee attack was not triggered by an anim notifier, then do a melee attack
	if (!MeleeAnimNotifierTriggered)
		TraceMelee();

	MeleeAnimNotifierTriggered = false;

	if (GetHands() != None)
	    GetHands().IdleHoldingEquipment();
}

simulated final function OnMeleeKeyFrame()
{
    //Only propagate OnMeleeKeyFrame() once.
    //Note that both the Pawn & Hands will get OnMeleeKeyFrame()
    //  at the same time, whomever's model gets to key-frame first.
    if (MeleeingStatus == ActionStatus_Started)
    {
		TraceMelee();
        MeleeAnimNotifierTriggered = true;
        MeleeingStatus = ActionStatus_HitKeyFrame;
    }
}

simulated final private function bool GetMeleeTarget(out Actor Victim, out vector HitLocation, out vector HitNormal, out Material HitMaterial)
{
	local vector StartTrace;
	local vector EndTrace;
	local rotator TraceDirection;

	GetPerfectFireStart(StartTrace, TraceDirection);

	EndTrace = StartTrace + vector(TraceDirection) * MeleeRange;

	foreach TraceActors(class'Actor', Victim, HitLocation, HitNormal, HitMaterial, EndTrace, StartTrace, /*Extent*/, /*bSkeletalBoxTest*/, /*SkeletalRegionHit*/, true)
    {
		// You shouldn't be able to hit hidden actors that block zero-extent
		// traces (i.e., projectors, blocking volumes). However, the 'Victim'
		// when you hit BSP is LevelInfo, which is hidden, so we have to
		// handle that as a special case.
		if ((Victim.bHidden || Victim.DrawType == DT_None) && !(Victim.IsA('LevelInfo')))
			continue;

		// Allow punching through open doors
		if (Victim.IsA('Door') && Door(Victim).IsOpen())
			continue;

		// Return true if we hit something that can be effected by punching
		return Victim.IsA('IReactToDazingWeapon');
	}

	return false;
}

//returns (in 'out' parameters) the location and rotation for the start of a trace
//  that represents a perfectly accurate shot.
//for local players, this will be the result of a PlayerCalcView(),
//  and other Pawns will be queried for their aim origin and aim rotation.
simulated event GetPerfectFireStart(out vector outLocation, out rotator outDirection)
{
    local Actor Junk;   //we don't care about this, it's just a required param to PlayerCalcView
	local Coords WeaponCoords;
	local bool InstigatorIsConscious;

    if (Instigator.IsA('SwatPlayer'))
    {
		InstigatorIsConscious = class'Pawn'.static.checkConscious(Instigator);

        if (InstigatorIsConscious) // is player conscious (not dead or incapacitated)?
        {
			if (Pawn(Owner).Controller != None)  // is weapon held by the local player?
			{
				// trace from the first-person viewpoint center
				PlayerController(Pawn(Owner).Controller).PlayerCalcView(Junk, outLocation, outDirection);
			}
			else // it's a remote player's pawn in MP
			{
				// use the apparent location of the 3rd person Pawn model's eyes
				outLocation = Instigator.GetThirdPersonEyesLocation();
				outDirection = Instigator.GetAimRotation();
			}
        }
        else  // it's a player's dead/incapacitated pawn
        {
			// Use the weapon's attachment location/rotation
			// This is so that if the player is killed in MP and he's autofiring while
			// dead, the bullets will shoot from the weapon rather than
			// from the 3rd person eye position.
			WeaponCoords = Pawn(Owner).GetBoneCoords('GripRHand', true);
			outLocation = WeaponCoords.Origin;
			outDirection = Rotator(-WeaponCoords.YAxis); // this gets the vector in the direction the weapon is aiming
        }
    }
    else if (Instigator.IsA('SwatAI'))
    {
      outLocation = Instigator.GetAimLocation(self);
		    //outLocation  = Instigator.GetAimOrigin();
		  outDirection = Instigator.GetAimRotation();
    }
    else
		assertWithDescription(false,
            "[tcohen] "$class.name
            $" was called to GetFireStart(), but Instigator ("$Instigator
            $") is not a SwatAI nor a SwatPlayer.  \"Wha happened?\"");
}

simulated final function TraceMelee()
{
	local Actor Victim;
	local vector HitLocation;
	local vector HitNormal;
	local Material HitMaterial;
	local HandheldEquipmentModel EffectsSource;
	local Name MeleeEventName;

	if (GetMeleeTarget(Victim, HitLocation, HitNormal, HitMaterial))
	{
		if (Level.GetEngine().EnableDevTools)
			mplog("   Melee victim " $ Victim);

		TriggerMeleeReaction(Victim);

		// Normal TraceActors() collection of material doesn't work quite right for
		// skeletal meshes, so we call this helper function to get the material manually.
		if (Victim.DrawType == DT_Mesh)
			HitMaterial = Victim.GetCurrentMaterial(0); // get skin at first index

		if (InFirstPersonView())
		{
			EffectsSource = FirstPersonModel;
			MeleeEventName = 'MeleeHit_FirstPerson';
		}
		else
		{
			EffectsSource = ThirdPersonModel;
			MeleeEventName = 'MeleeHit_ThirdPerson';
		}

		EffectsSource.TriggerEffectEvent(MeleeEventName, Victim, HitMaterial, HitLocation, Rotator(HitNormal));
	}
}

simulated function TriggerMeleeReaction(Actor Victim)
{
	// Hit something that can be stunned
	if (Victim.IsA('IReactToDazingWeapon'))
	{
		IReactToDazingWeapon(Victim).ReactToMeleeAttack(class,
														Pawn(Owner),
														MeleeDamage,
														MeleePlayerStingDuration,
														MeleeHeavilyArmoredPlayerStingDuration,
														MeleeNonArmoredPlayerStingDuration,
														MeleeAIStingDuration);
	}
}

simulated final function bool HasMeleeTarget()
{
	local Actor Victim;
	local vector HitLocation;
	local vector HitNormal;
	local Material HitMaterial;

	return GetMeleeTarget(Victim, HitLocation, HitNormal, HitMaterial);
}

simulated final function bool IsAvailable()
{
    return AvailableCount > 0 && Available;
}

simulated final function int GetAvailableCount()
{
  return AvailableCount;
}

simulated final function SetAvailableCount(int NewCount)
{
  if(NewCount == 0)
  {
    log(self$"SetAvailable(false) because SetAvailableCount is 0");
    SetAvailable(false);
  }
  else
  {
    AvailableCount = NewCount;
    SetAvailable(true);
  }
}

simulated function int GetDefaultAvailableCount()
{
  return 1;
}

simulated final function SetAvailable(bool inAvailable)
{
  if(!inAvailable)
  {
    log(self$"SetAvailable() set to "$inAvailable);
  }
  if(Available && !inAvailable)
  {
    AvailableCount = 0;
  }
  else if(inAvailable)
  {
    AvailableCount = GetDefaultAvailableCount();
  }

  Available = inAvailable;

    if ( !inAvailable )
    {
        if ( FirstPersonModel != None )
        {
            if ( GetHands() != None )
                GetHands().DetachFromBone( FirstPersonModel );
            FirstPersonModel.Hide();

            FirstPersonModel.SetEquipped(false);    //note that its HandheldEquipment is still its HandheldEquipment.Owner's ActiveItem
        }
        if ( ThirdPersonModel != None )
        {
            Pawn(Owner).DetachFromBone( ThirdPersonModel );
            ThirdPersonModel.Hide();

            ThirdPersonModel.SetEquipped(false);    //note that its HandheldEquipment is still its HandheldEquipment.Owner's ActiveItem
        }
    }
}

//An UnavailableAfterUsed HandheldEquipment is "Forgotten" after it is used,
//  and the Owner equips something else.
//For example, a Wedge is forgotten after it is placed and the Pawn
//  begins equipping its default weapon.
//This is used for the Cuffs, which "magically" become Available again
//  after they are Forgotten.
simulated function OnForgotten();

//returns a string describing the subclass's state,
//  to be concatenated into an assertion.
simulated function string HandheldEquipmentStatusString();

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
    local name OutSeqName;
    local float OutAnimFrame, OutAnimRate;

	Canvas.SetDrawColor(0,0,255);

	YPos += YL;
	YPos += YL;
	Canvas.SetPos(4,YPos);
    Canvas.DrawText("-> HandheldEquipment: "$class.name);

    GetHands().GetAnimParams(0, OutSeqName, OutAnimFrame, OutAnimRate);
	YPos += YL;
	Canvas.SetPos(4,YPos);
    Canvas.DrawText("Hands: Anim="$OutSeqName$", Frame="$OutAnimFrame);

    GetFirstPersonModel().GetAnimParams(0, OutSeqName, OutAnimFrame, OutAnimRate);
	YPos += YL;
	Canvas.SetPos(4,YPos);
    Canvas.DrawText("FirstPersonModel: Anim="$OutSeqName$", Frame="$OutAnimFrame);

    Owner.GetAnimParams(0, OutSeqName, OutAnimFrame, OutAnimRate);
	YPos += YL;
	Canvas.SetPos(4,YPos);
    Canvas.DrawText("Pawn: Anim="$OutSeqName$", Frame="$OutAnimFrame);

    GetThirdPersonModel().GetAnimParams(0, OutSeqName, OutAnimFrame, OutAnimRate);
	YPos += YL;
	Canvas.SetPos(4,YPos);
    Canvas.DrawText("ThirdPersonModel: Anim="$OutSeqName$", Frame="$OutAnimFrame);
}

static function String GetDescription()
{
    return default.Description;
}

static function String GetFriendlyName()
{
    return default.FriendlyName;
}

static function float GetRagdollDeathImpactMomentumMultiplier()
{
    return Default.RagdollDeathImpactMomentumMultiplier;
}

static function Material GetGUIImage()
{
    return default.GUIImage;
}

static function class<Actor> GetRenderableActorClass()
{
    return default.ThirdPersonModelClass;
}

simulated function vector GetDefaultLocationOffset()
{
	local vector DefaultLocationOffset;
	
	return DefaultLocationOffset;
}

simulated function Rotator GetDefaultRotationOffset()
{
	local Rotator DefaultRotationOffset;
	
	return DefaultRotationOffset;
}

simulated function vector GetIronsightsLocationOffset()
{
	local vector IronsightsLocation;

	return IronsightsLocation;
}

simulated function Rotator GetIronsightsRotationOffset()
{
	local Rotator IronsightsRotation;

	return IronsightsRotation;
}

simulated function float GetViewInertia() 
{
	local float Inertia;
	
	return Inertia;
}

simulated function float GetMaxInertiaOffset() 
{
	local float Offset;
	
	return Offset;
}

simulated function float GetIronSightAnimationProgress()
{
	local float IronSightAnimationPosition;
	
	return IronSightAnimationPosition;
}
simulated function SetIronSightAnimationProgress(float value) { }

simulated function array<vector> GetAnimationSplinePoints() 
{
	local array<vector> AnimationSplinePoints;
	
	return AnimationSplinePoints;
}
simulated function AddAnimationSplinePoint(vector value) { }

event Destroyed()
{
    if (FirstPersonModel != None)
        FirstPersonModel.Destroy();
    if (ThirdPersonModel != None)
        ThirdPersonModel.Destroy();
    Super.Destroyed();
}

//which slot should be equipped after this item becomes unavailable
simulated function EquipmentSlot GetSlotForReequip()
{
    //normally, this is just our slot
    return Slot;

    //for the curious, the exception to this is the C2Charge,
    //  which returns Slot_Detonator from GetSlotForReequip()
}

//
// Support for AIs interrupting HandheldEquipment actions
//
// Please note that using AIInterrupt() requires that the caller take
//  some responsibility that the Equipment System would otherwise take.
// For example, when calling Equip(), the Equipment System normally
//  guarantees that the HandheldEquipment will be equipped (unless
//  the Owner dies).  However, if AIInterrupt() is called, then
//  the Equipment System cannot guarantee that.  In fact, in that case,
//  the EquipmentSystem cannot even guarantee that any ActiveItem
//  is Unequipped.
// Also, if Latent forms of the Equipment Actions are used
//  (eg. LatentEquip()), the caller must be responsible for leaving
//  its state after calling AIInterrupt()
//

function AIInterrupt()
{
    if      (EquippingStatus > ActionStatus_Idle)   AIInterrupt_Equipping();
    else if (UnequippingStatus > ActionStatus_Idle) AIInterrupt_Unequipping();
    else if (UsingStatus > ActionStatus_Idle)       AIInterrupt_Using();
    else                                            AIInterruptHandheldEquipmentHook();
	Pawn(Owner).AnimStopEquipment();
}
protected function AIInterruptHandheldEquipmentHook(); //for subclasses

protected function AIInterrupt_Equipping()
{
    GotoState('');
    EquippingStatus = ActionStatus_Idle;
}

protected function AIInterrupt_Unequipping()
{
    GotoState('');
    UnequippingStatus = ActionStatus_Idle;
}

protected function AIInterrupt_Using()
{
    //GotoState('');  // for some reason this line is causing crashes...sp00ky
    UsingStatus = ActionStatus_Idle;
}

simulated function InterruptUsing();

//get the unique id for a Handheld equipment
// ID == Pawn's UniqueID + The Pocket this Equipment uses
simulated function String UniqueID()
{
    return Owner.UniqueID() $ "_" $ GetEnum(EquipmentSlot, Slot);
}

simulated function bool ShouldDisplayReticle()
{
	return true;
}

cpptext
{
    // Automatically updates the correct value of bOwnerNoSee based on
    // the current view and what this equipment is attached to.
    virtual UBOOL Tick( FLOAT DeltaSeconds, ELevelTick TickType );

    // Returns true if this weapon is currently being rendered in 1st person view,
    // otherwise returns false to indicate 3rd person view
    UBOOL InFirstPersonView();
}

simulated function float GetWeight()
{
  return AvailableCount * GetItemWeight();
}

simulated function float GetBulk()
{
  return AvailableCount * GetItemBulk();
}

simulated function float GetItemWeight()
{
  return 0.0f; // Has to be implemented by subclasses
}

simulated function float GetItemBulk()
{
  return 0.0f;
}

defaultproperties
{
    Slot=Slot_Invalid
    ThePocket=Pocket_Invalid
    Available=true
    UnavailableAfterUsed=false
    PlayerCanUnequip=true
    ShouldHaveFirstPersonModel=true
    ShouldHaveThirdPersonModel=true

    DrawType=DT_None

    EquipAnimationRate=1.0
    UnequipAnimationRate=1.0
    UseAnimationRate=1.0
	MeleeAnimationRate=1.0

	MeleeRange=85
	MeleeDamage=5
	MeleePlayerStingDuration=1.5
	MeleeHeavilyArmoredPlayerStingDuration=0.5
	MeleeNonArmoredPlayerStingDuration=2.0
	MeleeAIStingDuration=1.5

    Range=100

    ZoomedFOV=0

	ZoomBlurOverlay=Material'HUD.DefaultZoomBlurOverlay'
}
