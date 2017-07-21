class QualifiedUseEquipmentModel extends HandheldEquipmentModel
    abstract;

import enum EAnimPlayType from Pawn;

var(QualifiedUseEquipmentModelAnimations) name BeginQualifyAnimation;
var(QualifiedUseEquipmentModelAnimations) name QualifyAnimation;
var(QualifiedUseEquipmentModelAnimations) name EndQualifyAnimation;

var(QualifiedUseEquipmentModelAnimations) name HolderBeginQualifyAnimation;
var(QualifiedUseEquipmentModelAnimations) name HolderQualifyLoopAnimation;
var(QualifiedUseEquipmentModelAnimations) name HolderEndQualifyAnimation;

var(QualifiedUseEquipmentModelAnimations) name BeginAlternateQualifyAnimation;
var(QualifiedUseEquipmentModelAnimations) name AlternateQualifyLoopAnimation;
var(QualifiedUseEquipmentModelAnimations) name EndAlternateQualifyAnimation;

var(QualifiedUseEquipmentModelAnimations) name HolderBeginAlternateQualifyAnimation;
var(QualifiedUseEquipmentModelAnimations) name HolderAlternateQualifyLoopAnimation;
var(QualifiedUseEquipmentModelAnimations) name HolderEndAlternateQualifyAnimation;

var(QualifiedUseEquipmentModelAnimations) EAnimPlayType HolderAnimationBlending;
var(QualifiedUseEquipmentModelAnimations) bool  HolderShouldHideBeginAndEndAnims;

var(QualifiedUseEquipmentModelAnimations) float FinishQualifyTweenTime;

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();
}

// set the HandheldEquipment that this is a model of
simulated function SetHandHeldEquipment(HandheldEquipment HHE)
{
	Super.SetHandHeldEquipment(HHE);
}

simulated function PlayBeginQualify(bool UseAlternate, float RateModification)
{
    local name ModelAnimation;
    local name HolderAnimation;

    if (!UseAlternate)
    {
        ModelAnimation = BeginQualifyAnimation;
        HolderAnimation = HolderBeginQualifyAnimation;
    }
    else
    {
        ModelAnimation = BeginAlternateQualifyAnimation;
        HolderAnimation = HolderBeginAlternateQualifyAnimation;
    }

    //play any specified animations on model and holder
    if (ModelAnimation != '')
        PlayAnim(ModelAnimation, RateModification);
    if (HolderAnimation != '')
    {
        if (Owner.IsA('SwatPawn'))
        {
            HolderUseAnimationChannel = Pawn(Owner).AnimPlayEquipment(HolderAnimationBlending, HolderAnimation, , HolderAnimationRootBone, RateModification);
        }
        else
        {
            Owner.PlayAnim(HolderAnimation, RateModification);
            HolderUseAnimationChannel = 0;
        }

        if (Owner.IsA('Pawn') && HolderShouldHideBeginAndEndAnims)
        {
            // MCJ: If we set the alpha to zero, the engine optimizes it out
            // and the animation finishes instantly. This is bad, since we
            // still want the animation to play for its normal duration.
            // Setting it to a really small value will work.
            Pawn(Owner).EnableAnimEquipmentAlphaOverride(0.01);
        }
    }
}

simulated latent function FinishBeginQualify(bool UseAlternate)
{
    local name ModelAnimation;
    local name HolderAnimation;

    if (!UseAlternate)
    {
        ModelAnimation = BeginQualifyAnimation;
        HolderAnimation = HolderBeginQualifyAnimation;
    }
    else
    {
        ModelAnimation = BeginAlternateQualifyAnimation;
        HolderAnimation = HolderBeginAlternateQualifyAnimation;
    }

    //finish any animations that were played
    if (ModelAnimation != '')
        FinishAnim();
    if (HolderAnimation != '')
        Owner.FinishAnim(HolderUseAnimationChannel);

    if (Owner.IsA('Pawn') && HolderShouldHideBeginAndEndAnims)
    {
        Pawn(Owner).DisableAnimEquipmentAlphaOverride();
    }
}

simulated function PlayQualifyLoop(bool UseAlternate, float RateModification)
{
    local name ModelAnimation;
    local name HolderAnimation;

    if (!UseAlternate)
    {
        ModelAnimation = QualifyAnimation;
        HolderAnimation = HolderQualifyLoopAnimation;
    }
    else
    {
        ModelAnimation = AlternateQualifyLoopAnimation;
        HolderAnimation = HolderAlternateQualifyLoopAnimation;
    }

    //play any specified animations on model and holder
    if (ModelAnimation != '')
        PlayAnim(ModelAnimation, RateModification);
    if (HolderAnimation != '')
    {
        if (Owner.IsA('SwatPawn'))
        {
            Pawn(Owner).AnimLoopEquipment(HolderAnimationBlending, HolderAnimation, , HolderAnimationRootBone, RateModification);
        }
        else
        {
            Owner.LoopAnim(HolderAnimation, RateModification);
            HolderUseAnimationChannel = 0;
        }
    }
}

simulated function PlayEndQualify(bool UseAlternate)
{
    local name ModelAnimation;
    local name HolderAnimation;

    if (!UseAlternate)
    {
        ModelAnimation = EndQualifyAnimation;
        HolderAnimation = HolderEndQualifyAnimation;
    }
    else
    {
        ModelAnimation = EndAlternateQualifyAnimation;
        HolderAnimation = HolderEndAlternateQualifyAnimation;
    }

    //play any specified animations on model and holder
    if (ModelAnimation != '')
        PlayAnim(ModelAnimation,,FinishQualifyTweenTime);
    if (HolderAnimation != '')
    {
        if (Owner.IsA('SwatPawn'))
        {
            HolderUseAnimationChannel = Pawn(Owner).AnimPlayEquipment(HolderAnimationBlending, HolderAnimation, FinishQualifyTweenTime, HolderAnimationRootBone);
        }
        else
        {
            Owner.StopAnimating();
            Owner.PlayAnim(HolderAnimation,,FinishQualifyTweenTime);
            HolderUseAnimationChannel = 0;
        }

        if (Owner.IsA('Pawn') && HolderShouldHideBeginAndEndAnims)
        {
            Pawn(Owner).EnableAnimEquipmentAlphaOverride(0.0);
        }
    }
}

simulated latent function FinishEndQualify(bool UseAlternate)
{
    local name ModelAnimation;
    local name HolderAnimation;

    if (!UseAlternate)
    {
        ModelAnimation = EndQualifyAnimation;
        HolderAnimation = HolderEndQualifyAnimation;
    }
    else
    {
        ModelAnimation = EndAlternateQualifyAnimation;
        HolderAnimation = HolderEndAlternateQualifyAnimation;
    }

    //finish any animations that were played
    if (ModelAnimation != '')
        FinishAnim();
    if (HolderAnimation != '')
        Owner.FinishAnim(HolderUseAnimationChannel);

    if (Owner.IsA('Pawn') && HolderShouldHideBeginAndEndAnims)
    {
        Pawn(Owner).DisableAnimEquipmentAlphaOverride();
    }
}

simulated function OnInterrupted()
{
    StopAnimating();

    if (Owner.IsA('Pawn') && HolderShouldHideBeginAndEndAnims)
    {
        Pawn(Owner).DisableAnimEquipmentAlphaOverride();
    }
}
