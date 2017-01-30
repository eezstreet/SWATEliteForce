class FiredWeaponModel extends HandheldEquipmentModel
	abstract;

var(FiredWeaponModelAnimations) name BurstAnimation;
var(FiredWeaponModelAnimations) name HolderBurstAnimation;
var(FiredWeaponModelAnimations) name UseLastRoundAnimation;
var(FiredWeaponModelAnimations) name HolderUseLastRoundAnimation;
var(FiredWeaponModelAnimations) name UseEmptyAnimation;
var(FiredWeaponModelAnimations) name HolderUseEmptyAnimation;

var(FiredWeaponModelAnimations) name ReloadAnimation;
var(FiredWeaponModelAnimations) name EmptyReloadAnimation;
var(FiredWeaponModelAnimations) name HolderReloadAnimation;
var(FiredWeaponModelAnimations) name HolderEmptyReloadAnimation;

var int HolderReloadAnimationChannel;

var name SelectedReloadAnimation, SelectedHolderReloadAnimation;

var config float ReloadTweenTime;

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();
}

simulated function SetHandHeldEquipment(HandheldEquipment HHE)
{
    Super.SetHandHeldEquipment(HHE);

    if (FiredWeapon(HHE) != None && FiredWeapon(HHE).HasFlashlight())
    {
        // copy materials to skins, so that when the flashlight goes on/off
        // and changes the texture on a sub-material, the other skins aren't
        // null.
        CopyMaterialsToSkins(true); //should not overwrite existing skins
    }

}

simulated function PlayReload()
{
    SelectedReloadAnimation = SelectReloadAnimation();
    SelectedHolderReloadAnimation = SelectHolderReloadAnimation();

    //play any specified animations on model and holder
    if (SelectedReloadAnimation != '')
        PlayAnim(
            SelectedReloadAnimation,
            FiredWeapon(HandheldEquipment).ReloadAnimationRate);
    if (SelectedHolderReloadAnimation != '')
    {
        if (Owner.IsA('SwatPawn'))
		{
            HolderReloadAnimationChannel = Pawn(Owner).AnimPlayEquipment(
				kAPT_Normal,
                SelectedHolderReloadAnimation,
                ReloadTweenTime,
                HolderAnimationRootBone,
                FiredWeapon(HandheldEquipment).ReloadAnimationRate);
		}
        else
		{
            Owner.PlayAnim(
                SelectedHolderReloadAnimation,
                FiredWeapon(HandheldEquipment).ReloadAnimationRate,
                0.2);
			HolderReloadAnimationChannel = 0;
		}
    }
}

simulated latent function FinishReload()
{
    //finish any animations that were played
    if (SelectedReloadAnimation != '')
        FinishAnim();
    if (SelectedHolderReloadAnimation != '')
        Owner.FinishAnim(HolderReloadAnimationChannel);

    //TMC TODO assert ReloadHitKeyFrame

    // MCJ: If an assert is put here in the future, make sure to check if the
    // pawn is dead. If the pawn died while reloading the weapon, and the anim
    // finished early, some of the anim_notifies might not be sent.
    // See FinishEquip() and FinishUnequip() (in HandheldEquipmentModel) for
    // an example of how to do the assertion.
}

simulated function OnReloadKeyFrame(); //TMC TODO update HUD from OnReloadKeyFrame()

simulated protected function name SelectReloadAnimation()
{
    if (EmptyReloadAnimation == '')
    {
        return ReloadAnimation;
    }

    //TMC NOTE assumes that self is Owner's ActiveItem
    if (FiredWeapon(HandheldEquipment).Ammo.NeedsReload())
    {
        return EmptyReloadAnimation;
    }
    else
    {
        return ReloadAnimation;         //no special reload animation for empty
    }
}
simulated protected function name SelectHolderReloadAnimation()
{
    if (HolderEmptyReloadAnimation == '')
    {
        return HolderReloadAnimation;
    }

    //TMC NOTE assumes that self is Owner's ActiveItem
    if (FiredWeapon(HandheldEquipment).Ammo.NeedsReload())
    {
        return HolderEmptyReloadAnimation;
    }
    else
    {
        return HolderReloadAnimation;   //no special holder reload animation for empty
    }
}

//overrides from HandheldEquipmentModel
simulated protected function SelectUseAnimations(
    out name outSelectedUseAnimation,       out float outSelectedUseAnimationRate,
    out name outSelectedHolderUseAnimation, out float outSelectedHolderUseAnimationRate,
    out EAnimPlayType outAnimPlayType)
{
    local name UseInFireMode;
    local name HolderUseInFireMode;
    local float BurstRateFactor;
    local FiredWeapon FiredWeapon;

    FiredWeapon = FiredWeapon(HandheldEquipment);

    //fired animations always want to be played additively
    outAnimPlayType = kAPT_Additive;

    //by default, use single-fire animations
    UseInFireMode = UseAnimation;
    HolderUseInFireMode = HolderUseAnimation;

    //by default, play animations at normal rate
    outSelectedUseAnimationRate = HandheldEquipment.UseAnimationRate;
    outSelectedHolderUseAnimationRate = HandheldEquipment.UseAnimationRate;

    //if burst or auto-firing, use special animations and rates if provided
    if (FiredWeapon.CurrentFireMode > FireMode_Single)
    {
        BurstRateFactor = FiredWeapon.BurstRateFactor;

        if (BurstAnimation != '')
            UseInFireMode = BurstAnimation;
        if (HolderBurstAnimation != '')
            HolderUseInFireMode = HolderBurstAnimation;

        outSelectedUseAnimationRate = BurstRateFactor;
        outSelectedHolderUseAnimationRate = BurstRateFactor;
    }

    //if last round, use "last round" animation if supplied, otherwise use standard for current fire mode
    if (FiredWeapon.Ammo.IsLastRound())
    {
        if (UseLastRoundAnimation != '')
        {
            outSelectedUseAnimation         = UseLastRoundAnimation;
            outSelectedHolderUseAnimation   = HolderUseLastRoundAnimation;
        }
        else
        {
            outSelectedUseAnimation         = UseInFireMode;
            outSelectedHolderUseAnimation   = HolderUseInFireMode;
        }
    }
    else
    //if needs reload, use "fire empty" animation if supplied, otherwise play nothing
    if (FiredWeapon.Ammo.NeedsReload())
    {
        if (UseEmptyAnimation != '')
        {
            outSelectedUseAnimation         = UseEmptyAnimation;
            outSelectedHolderUseAnimation   = HolderUseEmptyAnimation;
        }
        else
        {
            outSelectedUseAnimation         = '';
            outSelectedHolderUseAnimation   = '';
        }
    }
    else
    //normal case: use standard fire animation for current fire mode
    {
        outSelectedUseAnimation         = UseInFireMode;
        outSelectedHolderUseAnimation   = HolderUseInFireMode;
    }
}

// Default behaviour when shot is to apply an impulse
#if IG_SHARED    //tcohen: hooked, used by effects system and reactive world objects
function PostTakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
#else
function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
#endif
{
	local vector impulse;

#if IG_SHARED
    Super.PostTakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
#else
    Super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
#endif

	if(Physics == PHYS_Havok)
	{
		if(VSize(momentum) < 0.001)
			return;

		impulse = Normal(momentum) * FClamp(VSize(momentum), 0, 75);
        log("Applying impulse to FiredWeaponModel "$Name$": "$impulse$" at location "$hitLocation);
		HavokImpartImpulse(impulse, hitLocation);
    }

}

defaultproperties
{
    // default havok params. if designers want to override, they can make a
    // new HavokRigidBody subclass in the editor and assign it to the
    // firedweaponmodel subclass.
	HavokDataClass = class'DefaultFiredWeaponModelHavokParams'
}
