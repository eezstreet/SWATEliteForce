///////////////////////////////////////////////////////////////////////////////

class SwatTrainer extends SwatAICharacter
    placeable
    native;

///////////////////////////////////////////////////////////////////////////////

event PostBeginPlay()
{
    super.PostBeginPlay();
    SetIdleCategory('Trainer');
}

///////////////////////////////////////

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation, vector HitMomentum)
{
    // First stop the current sound effects playing on the trainer, then call
    // up the chain.
    SoundEffectsSubsystem(EffectsSystem(Owner.Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).StopMySchemas(self);
    Super.Died(Killer, damageType, HitLocation, HitMomentum);
}

///////////////////////////////////////

function EAnimationSet GetMovementAnimSet()
{
    return kAnimationSetTrainer;
}

///////////////////////////////////////

protected function ConstructCharacterAI()
{
    local AI_Resource characterResource;
    characterResource = AI_Resource(characterAI);
    assert(characterResource != none);

    characterResource.addAbility(new class'SwatAICommon.TrainerCommanderAction');
    characterResource.addAbility(new class'SwatAICommon.CharacterSpeechManagerAction');

    // call down the chain
    Super.ConstructCharacterAI();
}

///////////////////////////////////////

protected function bool ShouldReactToNonLethals()
{
    return false;
}

///////////////////////////////////////

private function AddIdleActions()
{
    // @NOTE: Intentionally empty, we don't want the trainer to have the
    // idle animation behavior, as his animations are all designer script-
    // controlled
}

///////////////////////////////////////

// the trainer does not play the full body hit animations
function bool ShouldPlayFullBodyHitAnimation()
{
	return false;
}

///////////////////////////////////////

// the trainer has no awareness, so we don't need to worry about this
function BecomeAware()
{
}

///////////////////////////////////////////////////////////////////////////////

cpptext
{
    virtual bool ShouldPlayerLowReadyWhenPointingAtMe(ASwatPlayer* Player);
}

defaultproperties
{
    Mesh = SkeletalMesh'SWATMaleAnimation2.SwatInstructor'
    Skins[0] = Texture'SWATinstructorTex.SI_InstructorFleshA'
    Skins[1] = Texture'SWATinstructorTex.SI_ClothesC'
    bCollisionAvoidanceEnabled = false
}

///////////////////////////////////////////////////////////////////////////////
