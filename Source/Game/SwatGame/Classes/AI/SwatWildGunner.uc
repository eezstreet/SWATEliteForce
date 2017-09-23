///////////////////////////////////////////////////////////////////////////////
// WildGunners shoot wildy and inaccurately with their light machine gun

class SwatWildGunner extends SwatEnemy
	implements SwatAICommon.ISwatWildGunner;

var bool bIsFiring;
var protected WildGunnerAdjustAimGoal	AdjustAimGoal;

const            LowSkillMinTimeBeforeShooting = 0.75;
const            LowSkillMaxTimeBeforeShooting = 1.1;
const            MediumSkillMinTimeBeforeShooting = 0.7;
const            MediumSkillMaxTimeBeforeShooting = 0.85;
const            HighSkillMinTimeBeforeShooting = 0.5;
const            HighSkillMaxTimeBeforeShooting = 0.65;

///////////////////////////////////////////////////////////////////////////////
// ISwatWildGunner implementation

function bool isFiring()
{
	return bIsFiring;
}

///////////////////////////////////////////////////////////////////////////////

simulated function OnUsingBegan()
{
	super.OnUsingBegan();
	bIsFiring = true;
}

simulated function OnUsingFinished()
{
	super.OnUsingFinished();
	bIsFiring = false;
}

///////////////////////////////////////////////////////////////////////////////

protected function CleanupClassGoals()
{
	if (AdjustAimGoal != None)
	{
		AdjustAimGoal.Release();
		AdjustAimGoal = None;
	}

	Super.CleanupClassGoals();
}

///////////////////////////////////////////////////////////////////////////////

// Create SwatWildGunner specific abilities
protected function ConstructCharacterAI()
{
    local AI_Resource characterResource;
    characterResource = AI_Resource(characterAI);
    assert(characterResource != none);
	
	characterResource.addAbility(new class'SwatAICommon.WildGunnerAdjustAimAction');

	AdjustAimGoal = new class'WildGunnerAdjustAimGoal'(characterResource);
	assert(AdjustAimGoal != None);
	AdjustAimGoal.AddRef();
	AdjustAimGoal.postGoal(None);

	// call down the chain
    Super.ConstructCharacterAI();
}

///////////////////////////////////////////////////////////////////////////////
// Only the WildGunner's primary weapon fires wildly

function bool FireWhereAiming()
{
	return GetPrimaryWeapon() != None && !GetPrimaryWeapon().IsEmpty();
}