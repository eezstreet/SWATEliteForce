class HandheldEquipmentModel extends Actor
    implements IEvidence
    dependson(Pawn)
    HideCategories(Advanced, Events, Force, LightColor, Lighting, Movement, Object, Sound)
    config(SwatGame)
    native
    abstract;

import enum EAnimPlayType from Pawn;
import enum Pocket from HandheldEquipment;

//Each HandheldEquipment has two HandheldEquipmentModels,
//  one to be held by the Pawn, and one to be held by the Hands.
//The one held by the Pawn is a FirstPersonEqiupmentModel,
//  and the other is a ThirdPersonEquipmentModel.

//model animations
var(HandheldEquipmentModelAnimations) name EquipAnimation;
var(HandheldEquipmentModelAnimations) name UnequipAnimation;
var(HandheldEquipmentModelAnimations) name UseAnimation;
var(HandheldEquipmentModelAnimations) name MeleeAnimation;

//holder (Pawn or Hands)
struct native IdleAnimation
{
    var() int Chance;
    var() name Animation;
};
var(HandheldEquipmentModelAnimations) array<IdleAnimation> HolderIdleAnimations;
var int IdleChanceSum;
var(HandheldEquipmentModelAnimations) name HolderLowReadyIdleAnimation;
var(HandheldEquipmentModelAnimations) name HolderDisorientedLowReadyIdleAnimation;

var(HandheldEquipmentModelAnimations) name HolderEquipAnimation;
var(HandheldEquipmentModelAnimations) name HolderUnequipAnimation;
var(HandheldEquipmentModelAnimations) name HolderUseAnimation;
var(HandheldEquipmentModelAnimations) name HolderMeleeAnimation;

var(HandheldEquipmentModelAnimations) float HolderEquipTweenTime;

var config name HolderUnequipFromMPCuffedAnimation;

//sockets
var() name EquippedSocket;
var() name UnequippedSocket;

//extra animation sets
var(ExtraAnimationSets) array<string> ExtraAnimationSets "If you want this HandheldEquipmentModel to play any animations that are not in the default (first) Animation Set for the selected Mesh, then you must add to this list any other Animation Sets that you will use.  Each entry should look like {AnimationPackageName}.{AnimationSetName}";

//animation channels
var int HolderEquipAnimationChannel;
var int HolderUnEquipAnimationChannel;
var int HolderUseAnimationChannel;
var int HolderMeleeAnimationChannel;

var private bool bIsEquipped;

var HandheldEquipment HandheldEquipment;    //the HandheldEquipment that this is a model of

var private bool IsBusy;        //used to detect problems with start/end of states

var config name HolderAnimationRootBone;

var name SelectedUseAnimation, SelectedHolderUseAnimation;
var float SelectedUseAnimationRate, SelectedHolderUseAnimationRate;

var name SelectedMeleeAnimation, SelectedHolderMeleeAnimation;
var config float MeleeTweenTime;

var() StaticMesh DroppedStaticMesh;
var bool bIsDropped;
var private bool WasPrimary;

// Used for detecting when a weapon stops moving after it has been dropped.
var private Vector MostRecentLocation;
var private bool bNotifiedOfWeaponAtRest;
var private int AtRestCountdown; // How many times MostRecentLocation has to
                                 // equal Location before we fire the event.

var private Vector AtRestLocation;
var private rotator AtRestRotation;

var private string PrecomputedUniqueID;


simulated function PostNetBeginPlay()
{
    local int i;
    Super.PostNetBeginPlay();

    LoadAnimationSets(ExtraAnimationSets);

    for (i=0; i<HolderIdleAnimations.length; ++i)
        IdleChanceSum += HolderIdleAnimations[i].Chance;
}


simulated event FellOutOfWorld(eKillZType KillType)
{
    local Controller i;
    local Controller theLocalPlayerController;
    local PlayerController current;
    local vector MovementDelta;

	SetPhysics(PHYS_None);

    if (Level.GetEngine().EnableDevTools)
    {
        Log("!!!! WARNING !!!!! Destroying actor "$self$" because it fell out of world at location "$Location.X$", "$Location.Y$", "$Location.Z);
        mplog( "...setting physics to PHYS_None." );
    }

    if ( Level.NetMode != NM_Client )
    {
        if (Level.GetEngine().EnableDevTools)
        {
            //AssertWithDescription( false, "!!!! WARNING !!!!! Destroying actor "$self$" because it fell out of world at location "$Location.X$", "$Location.Y$", "$Location.Z);
            mplog( "...on server" );
        }

        if ( Level.Netmode != NM_Standalone )
        {
            // Do a walk the controller list thing here.
            theLocalPlayerController = Level.GetLocalPlayerController();
            for ( i = Level.ControllerList; i != None; i = i.NextController )
            {
                current = PlayerController( i );
                if ( current != None && current != theLocalPlayerController )
                {
                    current.ClientWeaponFellOutOfWorld( UniqueID() );
                }
            }
        }

        if (Level.GetEngine().EnableDevTools)
            mplog( "...destroying." );

        Destroy();
    }
    else
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...on client" );

        // On clients, if we've already been told by the server the AtRest
        // values, go ahead and use them.
        if ( bNotifiedOfWeaponAtRest )
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "...bNotifiedOfWeaponAtRest="$bNotifiedOfWeaponAtRest$", using AtRest values." );

            SetRotation( AtRestRotation );
            MovementDelta = AtRestLocation - Location;
            Move( MovementDelta );
        }
    }
}


simulated function ProcessAtRestValuesFromServer( Vector ServerLocation, rotator ServerRotation )
{
    local vector MovementDelta;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"HEM::ProcessAtRestValuesFromServer(). ServerLocation="$ServerLocation$", ServerRotation="$ServerRotation );

    // Save off these values in case the RPC from the server arrives while the
    // weapon is still falling (on its way to falling out of the world...)
    AtRestLocation = ServerLocation;
    AtRestRotation = ServerRotation;

    // If the weapon has already fallen out of the world, go ahead and place
    // it where the server told us to.
    if ( Physics == PHYS_None )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...Physics=PHYS_None, so using AtRest values." );

        SetRotation( AtRestRotation );
        MovementDelta = AtRestLocation - Location;
        Move( MovementDelta );
    }
}


// set the HandheldEquipment that this is a model of
simulated function SetHandHeldEquipment(HandheldEquipment HHE)
{
    //mplog( self$"---HEM::SetHandheldEquipment. HHE="$HHE );

	assertWithDescription(HHE != None,
            "[tcohen] You cannot assign None as the HandheldEquipment of HandheldEquipmentModel "$class.name);

	self.HandheldEquipment = HHE;
}

simulated function bool IsEquipped() { return bIsEquipped; }
simulated function SetEquipped(bool Equipped) { bIsEquipped = Equipped; }

//The following four play/equip function pairs are default implementations
//  of HandheldEquipmentModel actions.
//Subclasses for specific equipment may wish to override these functions
//  if the concrete weapon has different behaviors.

//Q: Why have fn Play() & latent fn Finish()?
//A: The Equipment needs to play both before calling
//  finish, so that the animation will play on hands
//  and pawn simultaneously.

// EQUIP

simulated function PlayEquip()
{
	local float EquipRate;
	local Hands Hands;
	local Pawn HandsOwner;

    AssertWithDescription(!IsEquipped(),
        "[tcohen] "$name$" (of class "$class.name$") was called to PlayEquip().  But it thinks its already equipped.");

	EquipRate = HandheldEquipment.EquipAnimationRate;

	if(Owner.IsA('Hands'))
	{
		Hands = Hands(Owner);
		HandsOwner = Pawn(Hands.Owner);
		if(HandsOwner.IsA('IAmAffectedByWeight'))
		{
			EquipRate *= IAmAffectedByWeight(HandsOwner).GetBulkSpeedModifier();
		}
	}
	else if(Owner.IsA('IAmAffectedByWeight'))
	{	// apply the bulk reload speed modifier
		EquipRate *= IAmAffectedByWeight(Owner).GetBulkSpeedModifier();
	}
	else
	{
		log("PlayReload was called on "$Owner);
	}

    //play any specified animations on model and holder
    if (EquipAnimation != '')
        PlayAnim(
            EquipAnimation,
            EquipRate);
    if (HolderEquipAnimation != '')
    {
        if (Owner.IsA('SwatPawn'))
        {
			HolderEquipAnimationChannel = Pawn(Owner).AnimPlayEquipment(
				kAPT_Normal,
                HolderEquipAnimation,
                HolderEquipTweenTime,
                HolderAnimationRootBone,
                EquipRate);
        }
        else
        {
			if(HandheldEquipment.IsA('SwatGrenade') && SwatGrenade(HandheldEquipment).IsInFastUse())
			{
				Owner.PlayAnim('GlowstickEquip',
	                EquipRate,
					HolderEquipTweenTime);
			}
			else
			{
				Owner.PlayAnim(
	                HolderEquipAnimation,
	                EquipRate,
					HolderEquipTweenTime);
			}
            HolderEquipAnimationChannel = 0;
        }
    }
}

simulated latent function FinishEquip()
{
    //finish any animations that were played
    if (EquipAnimation != '')
        FinishAnim();
    if (HolderEquipAnimation != '')
        Owner.FinishAnim(HolderEquipAnimationChannel);

    if (!IsEquipped() && !class'Pawn'.static.CheckDead(Pawn(Owner)))
        log("[WARNING] "$name
        $" (of class"$class.name
        $") finished playing any equip animations.  But it doesn't think its equipped.  Check that 1) the HolderEquipAnimation is specified (currently "$HolderEquipAnimation
        $"), 2) that has an AnimNotify_Equip, and 3) the animation group is listed in SwatGame.ini section [Engine.Hands]."
        $" (This can also happen during normal gameplay if a pawn interrupts equipping before it completes.)");
}

//This is called by the HandheldEquipment of which this is a model,
//  in response to it receiving the same notification.
simulated function OnEquipKeyFrame()
{
    AssertWithDescription(EquippedSocket != '',
        "[tcohen] "$name
        $" was just equipped, but it doesn't know which socket on its owner ("$Owner
        $") to attach to.  Please specify an EquippedSocket for class "$class.name
        $".");

    Owner.DetachFromBone(self);
    Show();
    Owner.AttachToBone(self, EquippedSocket);

    SetEquipped(true);
}

// UNEQUIP

simulated function PlayUnequip()
{
    // Holds the holder unequip animation name for the given unequip context.
    // (ie. depending if we're unequiping because we're getting arrested in
    // multiplayer) [darren]
    local name HolderUnequipAnimationForContext;
	local float UnequipRate;
	local Hands Hands;
	local Pawn HandsOwner;

	UnequipRate = HandheldEquipment.UnequipAnimationRate;

	if(Owner.IsA('Hands'))
	{
		Hands = Hands(Owner);
		HandsOwner = Pawn(Hands.Owner);
		if(HandsOwner.IsA('IAmAffectedByWeight'))
		{
			UnequipRate *= IAmAffectedByWeight(HandsOwner).GetBulkSpeedModifier();
		}
	}
	else if(Owner.IsA('IAmAffectedByWeight'))
	{	// apply the bulk reload speed modifier
		UnequipRate *= IAmAffectedByWeight(Owner).GetBulkSpeedModifier();
	}
	else
	{
		log("PlayReload was called on "$Owner);
	}

    AssertWithDescription(IsEquipped(),
        "[tcohen] "$name
        $" (of class "$class.name
        $") was called to PlayUnequip().  But it doesn't think its equipped.");

    //play any specified animations on model and holder
    if (UnequipAnimation != '')
        PlayAnim(UnequipAnimation, UnequipRate);

    HolderUnequipAnimationForContext = GetHolderUnequipAnimationForContext();
    if (HolderUnequipAnimationForContext != '')
    {
        if (Owner.IsA('SwatPawn'))
        {
            HolderUnequipAnimationChannel = Pawn(Owner).AnimPlayEquipment(
				kAPT_Normal,
                HolderUnequipAnimationForContext,
                ,
                HolderAnimationRootBone,
                UnequipRate);
        }
        else
        {
			/*if(HandheldEquipment.IsA('SwatGrenade') && SwatGrenade(HandheldEquipment).IsInFastUse())
			{
				Owner.PlayAnim(
	                'GlowstickUnequip',
	                UnequipRate,
	                0.5);   //tween time
			}
			else
			{*/
				Owner.PlayAnim(
	                HolderUnequipAnimationForContext,
	                UnequipRate,
	                0.5);   //tween time
			//}
            HolderUnEquipAnimationChannel = 0;
        }
    }
}

simulated latent function FinishUnequip()
{
    //finish any animations that were played
    if (UnequipAnimation != '')
        FinishAnim();
    if (GetHolderUnequipAnimationForContext() != '')
        Owner.FinishAnim(HolderUnEquipAnimationChannel);

    AssertWithDescription(!IsEquipped() || class'Pawn'.static.CheckDead( Pawn(Owner) ),
        "[tcohen] "$name
        $" (of class"$class.name
        $") finished playing any unequip animations.  But it still thinks its equipped.  Check that 1) the HolderUnEquipAnimation is specified (currently "$HolderUnEquipAnimation
        $"), 2) that has an AnimNotify_UnEquip, and 3) the animation group is listed in SwatGame.ini section [Engine.Hands].");
}

// Returns the holder unequip animation name for the given unequip context.
// (ie. depending if we're unequiping because we're getting arrested in
// multiplayer) [darren]
simulated private function Name GetHolderUnequipAnimationForContext()
{
    local Pawn PawnOwner;
    local name HolderUnequipAnimationForContext;
    local HandheldEquipment PendingItem, ActiveItem;

    PawnOwner = Pawn(Owner);

    // Special case: if we're unequipping because this is a multiplayer game
    // and we're about to be handcuffed, use the special animation for that
    // context.
    if (Level.NetMode != NM_Standalone)
    {
        if (PawnOwner != None)
        {
            PendingItem = PawnOwner.GetPendingItem();
            if (PendingItem != None && PendingItem.IsA('IAmCuffed'))
            {
                HolderUnequipAnimationForContext = HolderUnequipFromMPCuffedAnimation;
            }
        }
    }

    if(PawnOwner != None)
    {
        ActiveItem = PawnOwner.GetActiveItem();
        if(ActiveItem != None && SwatGrenade(ActiveItem) != None && SwatGrenade(ActiveItem).IsInFastUse())
        {
            log("We should be playing GlowStickUnEquip here.");
            return 'GlowStickUnEquip';
        }
    }

    // If the animation name is empty at this point, fall back on the base
    // HolderUnequipAnimation value.
    if (HolderUnequipAnimationForContext == '')
    {
        HolderUnequipAnimationForContext = HolderUnequipAnimation;
    }

    return HolderUnequipAnimationForContext;
}

//This is called by the HandheldEquipment of which this is a model,
//  in response to it receiving the same notification.
simulated function OnUnequipKeyFrame()
{
    //mplog( self$"---HEM::OnUnequipKeyFrame()." );

    Owner.DetachFromBone(self);

    if (UnequippedSocket != '')
        Owner.AttachToBone(self, UnequippedSocket);
    else
        Hide();

    SetEquipped(false);
}

// USE

simulated function PlayUse(float TweenTime)
{
    local EAnimPlayType AnimPlayType;

    SelectUseAnimations(
        SelectedUseAnimation, SelectedUseAnimationRate,
        SelectedHolderUseAnimation, SelectedHolderUseAnimationRate,
        AnimPlayType);

    //play any specified animations on model and holder
    if (SelectedUseAnimation != '')
        PlayAnim(SelectedUseAnimation, SelectedUseAnimationRate, TweenTime);
    if (SelectedHolderUseAnimation != '')
    {
        if (Owner.IsA('SwatPawn'))
        {
            if (self == HandheldEquipment.FirstPersonModel)
            {
                HolderUseAnimationChannel = Pawn(Owner).AnimPlayEquipment(
					kAPT_Normal,
                    SelectedHolderUseAnimation,
                    ,
                    HolderAnimationRootBone,
                    SelectedHolderUseAnimationRate);
            }
            else
            {
                HolderUseAnimationChannel = Pawn(Owner).AnimPlayEquipment(
                    AnimPlayType,
                    SelectedHolderUseAnimation,
                    ,
                    HolderAnimationRootBone,
                    SelectedHolderUseAnimationRate);
            }
        }
        else
        {
            Owner.PlayAnim(
                SelectedHolderUseAnimation,
                SelectedHolderUseAnimationRate);
            HolderUseAnimationChannel = 0;
        }
    }
}

simulated latent function FinishUse()
{
    //finish any animations that were played
    if (SelectedUseAnimation != '')
        FinishAnim();
    if (SelectedHolderUseAnimation != '')
        Owner.FinishAnim(HolderUseAnimationChannel);

    //TMC TODO assert FinishHitKeyFrame

    // MCJ: If an assert is put here in the future, make sure to check if the
    // pawn is dead. If the pawn died while using the equipment, and the anim
    // finished early, some of the anim_notifies might not be sent.
    // See FinishEquip() and FinishUnequip() for an example of how to do the
    // assertion.
}

//This is called by the HandheldEquipment of which this is a model,
//  in response to it receiving the same notification.
simulated function OnUseKeyFrame();

//subclasses will override to use context-sentitive animations
simulated protected function SelectUseAnimations(
    out name outSelectedUseAnimation,       out float outSelectedUseAnimationRate,
    out name outSelectedHolderUseAnimation, out float outSelectedHolderUseAnimationRate,
    out EAnimPlayType outAnimPlayType)
{
    outSelectedUseAnimation = UseAnimation;
    outSelectedUseAnimationRate = HandheldEquipment.UseAnimationRate;
    outSelectedHolderUseAnimation = HolderUseAnimation;
    outSelectedHolderUseAnimationRate = HandheldEquipment.UseAnimationRate;
    outAnimPlayType = kAPT_Normal;
}

simulated function PlayMelee()
{
    SelectedMeleeAnimation = SelectMeleeAnimation();
    SelectedHolderMeleeAnimation = SelectHolderMeleeAnimation();

    //play any specified animations on model and holder
    if (SelectedMeleeAnimation != '')
        PlayAnim(SelectedMeleeAnimation, HandheldEquipment.MeleeAnimationRate);

    if (SelectedHolderMeleeAnimation != '')
    {
        if (Owner.IsA('SwatPawn'))
		{
            HolderMeleeAnimationChannel = Pawn(Owner).AnimPlayEquipment(
				kAPT_Normal,
                SelectedHolderMeleeAnimation,
                MeleeTweenTime,
                HolderAnimationRootBone,
                HandheldEquipment.MeleeAnimationRate);
		}
        else
		{
            Owner.PlayAnim(SelectedHolderMeleeAnimation, HandheldEquipment.MeleeAnimationRate, 0.2);
			HolderMeleeAnimationChannel = 0;
		}
    }
}

simulated latent function FinishMelee()
{
    //finish any animations that were played
    if (SelectedMeleeAnimation != '')
        FinishAnim();

    if (SelectedHolderMeleeAnimation != '')
        Owner.FinishAnim(HolderMeleeAnimationChannel);
}

simulated protected function name SelectMeleeAnimation()
{
	return MeleeAnimation;
}

simulated protected function name SelectHolderMeleeAnimation()
{
	return HolderMeleeAnimation;
}

simulated function OnDropped( bool bPrimary )
{
    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---HandheldEquipmentModel::OnDropped()." );

    WasPrimary = bPrimary;
    bIsDropped = true;

    // On the server, start ticking now. When velocity reaches zero, RPC to
    // all clients to tell them the final location and orientation.
    if ( Level.IsCOOPServer )
        MostRecentLocation = vect(0,0,0);
}

event NotifyClientsDroppedWeaponAtRest()
{
    local Controller i;
    local Controller theLocalPlayerController;
    local PlayerController current;

    Assert( Level.IsCOOPServer );

    if (Level.GetEngine().EnableDevTools)
    {
        mplog( self$"---HandheldEquipmentModel::NotifyClientsDroppedWeaponAtRest()." );
        mplog( "...UniqueID()="$UniqueID() );
        mplog( "...Location="$Location );
        mplog( "...Rotation="$Rotation );
    }

    // Do a walk the controller list thing here.
    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = PlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientDroppedWeaponAtRest( UniqueID(), Location.X, Location.Y, Location.Z, Rotation );
        }
    }
}


function NotifyClientsAIDroppedWeapon( vector ThrowDirectionImpulse )
{
    local Controller i;
    local Controller theLocalPlayerController;
    local PlayerController current;

    Assert( Level.IsCOOPServer );

    if (Level.GetEngine().EnableDevTools)
    {
        mplog( self$"---HandheldEquipmentModel::NotifyClientsAIDroppedWeapon()." );
        mplog( "...UniqueID()="$UniqueID() );
        mplog( "...Location="$Location );
        mplog( "...Rotation="$Rotation );
        mplog( "...ThrowDirectionImpulse="$ThrowDirectionImpulse );
        mplog( "...class="$class );
    }

    // Do a walk the controller list thing here.
    theLocalPlayerController = Level.GetLocalPlayerController();
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = PlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientAIDroppedWeapon( UniqueID(), Location, Rotation, ThrowDirectionImpulse, class );
        }
    }
}


simulated function bool IsDropped()
{
    return bIsDropped;
}

// IEvidence extends ICanBeUsed implementation

simulated function OnUsed(Pawn SecurerPawn)
{
    TriggerEffectEvent('Secured');
    SecurerPawn.OnEvidenceSecured(self);
}

simulated function bool CanBeUsedNow()
{
    //mplog( self$"---HandheldEquipmentModel::CanBeUsedNow(). bIsDropped="$bIsDropped$", bHidden="$bHidden );
    return bIsDropped && !bHidden;
}

simulated function PostUsed()
{
	Hide();
}


// This should only be called once for a given HandheldEquipmentModel, so
// assert this below.
simulated function SetUniqueID( string NewValue )
{
    Assert( PrecomputedUniqueID == "" );
    Assert( NewValue != "" );

    if (Level.GetEngine().EnableDevTools)
        mplog( "...caching UniqueID: "$NewValue );

    PrecomputedUniqueID = NewValue;
}


simulated function String UniqueID()
{
    local string PrimaryString;
    local string NewUniqueID;
    local bool CacheUniqueID;

    //log( self$"::UniqueID() ... Owner = "$Owner );

    if ( PrecomputedUniqueID != "" )
        return PrecomputedUniqueID;

    CacheUniqueID = false; // by default, don't cache it

    //mplog( self$"---HEM::UniqueID(). No cached UniqueID, computing one..." );

    if( ICanBeUsed(Owner) == None )
    {
        //mplog( "...cannot computer UniqueID. Owner==None. returning..." );
        // We can't compute a valid UniqueID without a valid Owner.
        return "InvalidUniqueID-OwnerWasNone";
    }

    if( bIsDropped )
    {
        if( WasPrimary )
            PrimaryString = "Pocket_PrimaryWeapon";
        else
            PrimaryString = "Pocket_SecondaryWeapon";
        CacheUniqueID = true; // the owner was valid and we know the pocket
    }
    else
    {
        // For an enemy's weapons, we don't want to go the pocket route,
        // since the weapons aren't really in pockets and the pocket variable
        // isn't always set properly.
        if ( Owner.IsA('SwatEnemy') && FiredWeapon(HandheldEquipment) != None )
        {
            if (Level.GetEngine().EnableDevTools)
                mplog( "......IsPrimaryWeapon()="$Pawn(Owner).IsPrimaryWeapon( HandheldEquipment ) );

            if ( Pawn(Owner).IsPrimaryWeapon( HandheldEquipment ))
                PrimaryString = "Pocket_PrimaryWeapon";
            else
                PrimaryString = "Pocket_SecondaryWeapon";
            CacheUniqueID = true;
        }
        else
        {
            PrimaryString = String(GetEnum( Pocket, HandheldEquipment.GetPocket() ));
            if ( PrimaryString != "Pocket_Invalid" )
            {
                // the owner was valid and we know the pocket
                CacheUniqueID = true;
            }
            else
            {
                if (Level.GetEngine().EnableDevTools)
                    mplog( "...cannot compute UniqueID. HandheldEquipment's pocket=Pocket_Invalid." );
            }
        }
    }

    // Since we didn't have a precomputed one above, but we have to compute it
    // here, cache it as our precomputed one for next time.
    NewUniqueID = ICanBeUsed(Owner).UniqueID() $ PrimaryString;
    //mplog( "...NewUniqueID="$NewUniqueID );

    // If the code above resulted in a valid UniqueID, cache it for future
    // use, but if the Owner was None or we weren't in a valid pocket, don't
    // cache the bogus UniqueID, and we'll compute a new one again the next
    // time this function is called.
    if ( CacheUniqueID )
        SetUniqueID( NewUniqueID );

    return NewUniqueID;
}


cpptext
{
    virtual void PreRenderCallback(UBOOL MainScene, FLevelSceneNode* SceneNode, FRenderInterface* RI);
    virtual void TickSpecial(FLOAT deltaSeconds);
}

defaultproperties
{
    bHidden=true
    RemoteRole=ROLE_None
    DrawType=DT_Mesh

    bAcceptsShadowProjectors=true

    // these should be part of the 3rd person shadows
    bActorShadows=true

    AtRestCountdown=5
}
