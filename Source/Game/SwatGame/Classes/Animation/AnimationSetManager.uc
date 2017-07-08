///////////////////////////////////////////////////////////////////////////////

class AnimationSetManager extends Core.Object
    config(SwatPawnAnimationSets);

///////////////////////////////////////////////////////////////////////////////

enum EAnimationSet
{
	kAnimationSetNull,

    kAnimationSetDynamicStanding,
	kAnimationSetDynamicStandingNoArmor,
	kAnimationSetDynamicStandingHeavyArmor,
	kAnimationSetDynamicStandingUpStairs,
	kAnimationSetDynamicStandingDownStairs,
    kAnimationSetStealthStanding,
	kAnimationSetStealthStandingNoArmor,
	kAnimationSetStealthStandingHeavyArmor,
	kAnimationSetStealthStandingUpStairs,
	kAnimationSetStealthStandingDownStairs,
    kAnimationSetCrouching,
	kAnimationSetCrouchingNoArmor,
	kAnimationSetCrouchingHeavyArmor,
	kAnimationSetInjuredStanding,
	kAnimationSetInjuredStandingUpStairs,
	kAnimationSetInjuredStandingDownStairs,
    kAnimationSetInjuredCrouching,
	kAnimationSetOfficerInjuredStanding,
	kAnimationSetOfficerInjuredCrouching,

	kAnimationSetCivilianWalk,
	kAnimationSetCivilianRun,
	kAnimationSetTrainer,

	// Enemy Animation Sets
	kAnimationSetGangWalkHG,
	kAnimationSetGangWalkSMG,
	kAnimationSetGangWalkMG,
	kAnimationSetGangWalkSG,
    kAnimationSetGangRunHG,
	kAnimationSetGangRunSMG,
	kAnimationSetGangRunMG,
	kAnimationSetGangRunSG,
	kAnimationSetGangSprint,
	kAnimationSetGangSprintHG,
	kAnimationSetGangSprintSMG,
	kAnimationSetGangSprintMG,
	kAnimationSetGangSprintSG,

	kAnimationSetAICharacterInjuredStanding,
	kAnimationSetAICharacterInjuredStandingUpStairs,
	kAnimationSetAICharacterInjuredStandingDownStairs,
    kAnimationSetAICharacterInjuredCrouching,


	// TODO: do we need to remove these, like if the characters run without a weapon, etc.? [crombie]
	// BEGIN OLD ANIMATION SETS
	kAnimationSetGangRun,
	kAnimationSetGangWalk,
	// END OLD ANIMATION SETS 

	kAnimationSetEnemyPatrolHG,
	kAnimationSetEnemyPatrolSMG,
	kAnimationSetEnemyPatrolMG,
	kAnimationSetEnemyPatrolSG,

	kAnimationSetCompliant,
	kAnimationSetRestrained,

	// General weapon animation sets
    kAnimationSetHandgun,
    kAnimationSetHandgunLowReady,
    kAnimationSetHandgunCrouched,
    kAnimationSetHandgunLowReadyCrouched,
    kAnimationSetHandgunExtremeLowReady,
	kAnimationSetSubMachineGun,
	kAnimationSetSubMachineGunLowReady,
	kAnimationSetSubMachineGunCrouched,
	kAnimationSetSubMachineGunLowReadyCrouched,
	kAnimationSetSubMachineGunExtremeLowReady,
    kAnimationSetMachineGun,
    kAnimationSetMachineGunLowReady,
    kAnimationSetMachineGunCrouched,
    kAnimationSetMachineGunLowReadyCrouched,
    kAnimationSetMachineGunExtremeLowReady,
	kAnimationSetShotgun,
	kAnimationSetShotgunLowReady,
	kAnimationSetShotgunCrouched,
	kAnimationSetShotgunLowReadyCrouched,
	kAnimationSetShotgunExtremeLowReady,
    kAnimationSetThrownWeapon,
    kAnimationSetThrownWeaponLowReady,
    kAnimationSetThrownWeaponCrouched,
    kAnimationSetThrownWeaponLowReadyCrouched,
    kAnimationSetThrownWeaponExtremeLowReady,
    kAnimationSetTacticalAid,
    kAnimationSetTacticalAidLowReady,
    kAnimationSetTacticalAidCrouched,
    kAnimationSetTacticalAidLowReadyCrouched,
    kAnimationSetTacticalAidExtremeLowReady,
    kAnimationSetTacticalAidUse,

    // More specific weapon animation sets
    kAnimationSetPepperSpray,
    kAnimationSetPepperSprayLowReady,
    kAnimationSetPepperSprayCrouched,
    kAnimationSetPepperSprayLowReadyCrouched,
    kAnimationSetPepperSprayExtremeLowReady,
    kAnimationSetM4,
    kAnimationSetM4LowReady,
    kAnimationSetM4Crouched,
    kAnimationSetM4LowReadyCrouched,
    kAnimationSetM4ExtremeLowReady,
    kAnimationSetUMP,
    kAnimationSetUMPLowReady,
    kAnimationSetUMPCrouched,
    kAnimationSetUMPLowReadyCrouched,
    kAnimationSetUMPExtremeLowReady,
	kAnimationSetP90,
    kAnimationSetP90LowReady,
    kAnimationSetP90Crouched,
    kAnimationSetP90LowReadyCrouched,
    kAnimationSetP90ExtremeLowReady,
    kAnimationSetOptiwand,
    kAnimationSetOptiwandLowReady,
    kAnimationSetOptiwandCrouched,
    kAnimationSetOptiwandLowReadyCrouched,
    kAnimationSetOptiwandExtremeLowReady,
    kAnimationSetPaintball,
    kAnimationSetPaintballLowReady,
    kAnimationSetPaintballCrouched,
    kAnimationSetPaintballLowReadyCrouched,
    kAnimationSetPaintballExtremeLowReady,

	kAnimationSetGangHandgun,
	kAnimationSetGangMachinegun,

	kAnimationSetCuffed,
	kAnimationSetCompliantLookAt,

    // Aimpose reaction to non-lethals sets, used by players
    kAnimationSetFlashbanged,
    kAnimationSetFlashbangedCuffed,
    kAnimationSetGassed,
    kAnimationSetGassedCuffed,
    kAnimationSetPepperSprayed,
    kAnimationSetPepperSprayedCuffed,
    kAnimationSetStung,
    kAnimationSetStungCuffed,
    kAnimationSetTased,
    kAnimationSetTasedCuffed,

    // Full-body reaction to non-lethals sets, used by AIs
    kAnimationSetAIFlashbanged,
    kAnimationSetAIGassed,
    kAnimationSetAIPepperSprayed,
    kAnimationSetAIStung,
    kAnimationSetAITased,

    kAnimationSetMouthOpen,
};

///////////////////////////////////////////////////////////////////////////////

var private AnimationSet m_animationSets[EAnimationSet.EnumCount];

///////////////////////////////////////////////////////////////////////////////

overloaded function Construct()
{
	CreateSet(kAnimationSetNull,									"AnimationSetNull");

    // Movement Sets
    CreateSet(kAnimationSetDynamicStanding,							"AnimationSetDynamicStanding");
	CreateSet(kAnimationSetDynamicStandingNoArmor,					"AnimationSetDynamicStandingNoArmor");
	CreateSet(kAnimationSetDynamicStandingHeavyArmor,				"AnimationSetDynamicStandingHeavyArmor");
	CreateSet(kAnimationSetDynamicStandingUpStairs,					"AnimationSetDynamicStandingUpStairs");
	CreateSet(kAnimationSetDynamicStandingDownStairs,				"AnimationSetDynamicStandingDownStairs");
    CreateSet(kAnimationSetStealthStanding,							"AnimationSetStealthStanding");
	CreateSet(kAnimationSetStealthStandingNoArmor,					"AnimationSetStealthStandingNoArmor");
	CreateSet(kAnimationSetStealthStandingHeavyArmor,				"AnimationSetStealthStandingHeavyArmor");
	CreateSet(kAnimationSetStealthStandingUpStairs,					"AnimationSetStealthStandingUpStairs");
	CreateSet(kAnimationSetStealthStandingDownStairs,				"AnimationSetStealthStandingDownStairs");
    CreateSet(kAnimationSetCrouching,								"AnimationSetCrouching");
	CreateSet(kAnimationSetCrouchingNoArmor,						"AnimationSetCrouchingNoArmor");
	CreateSet(kAnimationSetCrouchingHeavyArmor,						"AnimationSetCrouchingHeavyArmor");
	CreateSet(kAnimationSetInjuredStanding,							"AnimationSetInjuredStanding");
    CreateSet(kAnimationSetInjuredCrouching,						"AnimationSetInjuredCrouching");

	CreateSet(kAnimationSetOfficerInjuredStanding,					"AnimationSetOfficerInjuredStanding");
	CreateSet(kAnimationSetInjuredStandingUpStairs,					"AnimationSetOfficerInjuredStandingUpStairs");
	CreateSet(kAnimationSetInjuredStandingDownStairs,				"AnimationSetOfficerInjuredStandingDownStairs");
    CreateSet(kAnimationSetOfficerInjuredCrouching,					"AnimationSetOfficerInjuredCrouching");

	CreateSet(kAnimationSetCivilianWalk,							"AnimationSetCivilianWalk");
	CreateSet(kAnimationSetCivilianRun,								"AnimationSetCivilianRun");
	CreateSet(kAnimationSetTrainer, 								"AnimationSetTrainer");

	CreateSet(kAnimationSetGangWalk,								"AnimationSetGangWalk");
    CreateSet(kAnimationSetGangRun,									"AnimationSetGangRun");
	

	CreateSet(kAnimationSetGangWalkHG,								"AnimationSetGangWalkHG");
	CreateSet(kAnimationSetGangWalkSMG,								"AnimationSetGangWalkSMG");
	CreateSet(kAnimationSetGangWalkMG,								"AnimationSetGangWalkMG");
	CreateSet(kAnimationSetGangWalkSG,								"AnimationSetGangWalkSG");

	CreateSet(kAnimationSetGangRunHG,								"AnimationSetGangRunHG");
	CreateSet(kAnimationSetGangRunSMG,								"AnimationSetGangRunSMG");
	CreateSet(kAnimationSetGangRunMG,								"AnimationSetGangRunMG");
	CreateSet(kAnimationSetGangRunSG,								"AnimationSetGangRunSG");

	CreateSet(kAnimationSetGangSprint,								"AnimationSetGangSprint");
	CreateSet(kAnimationSetGangSprintHG,							"AnimationSetGangSprintHG");
	CreateSet(kAnimationSetGangSprintSMG,							"AnimationSetGangSprintSMG");
	CreateSet(kAnimationSetGangSprintMG,							"AnimationSetGangSprintMG");
	CreateSet(kAnimationSetGangSprintSG,							"AnimationSetGangSprintSG");
	
	CreateSet(kAnimationSetAICharacterInjuredStanding,				"AnimationSetAICharacterInjuredStanding");
	CreateSet(kAnimationSetAICharacterInjuredStandingUpStairs,		"AnimationSetAICharacterInjuredStandingUpStairs");
	CreateSet(kAnimationSetAICharacterInjuredStandingDownStairs,	"AnimationSetAICharacterInjuredStandingDownStairs");
    CreateSet(kAnimationSetAICharacterInjuredCrouching,				"AnimationSetAICharacterInjuredCrouching");

	CreateSet(kAnimationSetCompliant,								"AnimationSetCompliant");
	CreateSet(kAnimationSetRestrained,								"AnimationSetRestrained");
	
	CreateSet(kAnimationSetEnemyPatrolHG,							"AnimationSetEnemyPatrolHG");
	CreateSet(kAnimationSetEnemyPatrolSMG,							"AnimationSetEnemyPatrolSMG");
	CreateSet(kAnimationSetEnemyPatrolMG,							"AnimationSetEnemyPatrolMG");
	CreateSet(kAnimationSetEnemyPatrolSG,							"AnimationSetEnemyPatrolSG");

	// Aiming Sets
    CreateSet(kAnimationSetHandgun,									"AnimationSetHandgun");
    CreateSet(kAnimationSetHandgunLowReady,							"AnimationSetHandgunLowReady");
    CreateSet(kAnimationSetHandgunCrouched,							"AnimationSetHandgunCrouched");
    CreateSet(kAnimationSetHandgunLowReadyCrouched,					"AnimationSetHandgunLowReadyCrouched");
    CreateSet(kAnimationSetHandgunExtremeLowReady,					"AnimationSetHandgunExtremeLowReady");
	CreateSet(kAnimationSetSubMachineGun,							"AnimationSetSubMachineGun");
	CreateSet(kAnimationSetSubMachineGunLowReady,					"AnimationSetSubMachineGunLowReady");
	CreateSet(kAnimationSetSubMachineGunCrouched,					"AnimationSetSubMachineGunCrouched");
	CreateSet(kAnimationSetSubMachineGunLowReadyCrouched,			"AnimationSetSubMachineGunLowReadyCrouched");
	CreateSet(kAnimationSetSubMachineGunExtremeLowReady,			"AnimationSetSubMachineGunExtremeLowReady");
    CreateSet(kAnimationSetMachinegun,								"AnimationSetMachinegun");
    CreateSet(kAnimationSetMachinegunLowReady,						"AnimationSetMachinegunLowReady");
    CreateSet(kAnimationSetMachinegunCrouched,						"AnimationSetMachinegunCrouched");
    CreateSet(kAnimationSetMachinegunLowReadyCrouched,				"AnimationSetMachinegunLowReadyCrouched");
    CreateSet(kAnimationSetMachinegunExtremeLowReady,				"AnimationSetMachinegunExtremeLowReady");
    CreateSet(kAnimationSetShotgun,									"AnimationSetShotgun");
    CreateSet(kAnimationSetShotgunLowReady,							"AnimationSetShotgunLowReady");
    CreateSet(kAnimationSetShotgunCrouched,							"AnimationSetShotgunCrouched");
    CreateSet(kAnimationSetShotgunLowReadyCrouched,					"AnimationSetShotgunLowReadyCrouched");
    CreateSet(kAnimationSetShotgunExtremeLowReady,					"AnimationSetShotgunExtremeLowReady");
    CreateSet(kAnimationSetThrownWeapon,							"AnimationSetThrownWeapon");
    CreateSet(kAnimationSetThrownWeaponLowReady,					"AnimationSetThrownWeaponLowReady");
    CreateSet(kAnimationSetThrownWeaponCrouched,					"AnimationSetThrownWeaponCrouched");
    CreateSet(kAnimationSetThrownWeaponLowReadyCrouched,			"AnimationSetThrownWeaponLowReadyCrouched");
    CreateSet(kAnimationSetThrownWeaponExtremeLowReady,			    "AnimationSetThrownWeaponExtremeLowReady");
    CreateSet(kAnimationSetTacticalAid,								"AnimationSetTacticalAid");
    CreateSet(kAnimationSetTacticalAidLowReady,						"AnimationSetTacticalAidLowReady");
    CreateSet(kAnimationSetTacticalAidCrouched,						"AnimationSetTacticalAidCrouched");
    CreateSet(kAnimationSetTacticalAidLowReadyCrouched,				"AnimationSetTacticalAidLowReadyCrouched");
    CreateSet(kAnimationSetTacticalAidExtremeLowReady,				"AnimationSetTacticalAidExtremeLowReady");
    CreateSet(kAnimationSetTacticalAidUse,							"AnimationSetTacticalAidUse");

    CreateSet(kAnimationSetPepperSpray,								"AnimationSetPepperSpray");
    CreateSet(kAnimationSetPepperSprayLowReady,						"AnimationSetPepperSprayLowReady");
    CreateSet(kAnimationSetPepperSprayCrouched,						"AnimationSetPepperSprayCrouched");
    CreateSet(kAnimationSetPepperSprayLowReadyCrouched,				"AnimationSetPepperSprayLowReadyCrouched");
    CreateSet(kAnimationSetPepperSprayExtremeLowReady,				"AnimationSetPepperSprayExtremeLowReady");
    CreateSet(kAnimationSetM4,										"AnimationSetM4");
    CreateSet(kAnimationSetM4LowReady,								"AnimationSetM4LowReady");
    CreateSet(kAnimationSetM4Crouched,								"AnimationSetM4Crouched");
    CreateSet(kAnimationSetM4LowReadyCrouched,						"AnimationSetM4LowReadyCrouched");
    CreateSet(kAnimationSetM4ExtremeLowReady,						"AnimationSetM4ExtremeLowReady");
    CreateSet(kAnimationSetUMP,										"AnimationSetUMP");
    CreateSet(kAnimationSetUMPLowReady,								"AnimationSetUMPLowReady");
    CreateSet(kAnimationSetUMPCrouched,								"AnimationSetUMPCrouched");
    CreateSet(kAnimationSetUMPLowReadyCrouched,						"AnimationSetUMPLowReadyCrouched");
    CreateSet(kAnimationSetUMPExtremeLowReady,						"AnimationSetUMPExtremeLowReady");
	CreateSet(kAnimationSetP90,										"AnimationSetP90");
    CreateSet(kAnimationSetP90LowReady,								"AnimationSetP90LowReady");
    CreateSet(kAnimationSetP90Crouched,								"AnimationSetP90Crouched");
    CreateSet(kAnimationSetP90LowReadyCrouched,						"AnimationSetP90LowReadyCrouched");
    CreateSet(kAnimationSetP90ExtremeLowReady,						"AnimationSetP90ExtremeLowReady");
    CreateSet(kAnimationSetOptiwand,								"AnimationSetOptiwand");
    CreateSet(kAnimationSetOptiwandLowReady,						"AnimationSetOptiwandLowReady");
    CreateSet(kAnimationSetOptiwandCrouched,						"AnimationSetOptiwandCrouched");
    CreateSet(kAnimationSetOptiwandLowReadyCrouched,				"AnimationSetOptiwandLowReadyCrouched");
    CreateSet(kAnimationSetOptiwandExtremeLowReady,				    "AnimationSetOptiwandExtremeLowReady");
    CreateSet(kAnimationSetPaintball,								"AnimationSetPaintball");
    CreateSet(kAnimationSetPaintballLowReady,						"AnimationSetPaintballLowReady");
    CreateSet(kAnimationSetPaintballCrouched,						"AnimationSetPaintballCrouched");
    CreateSet(kAnimationSetPaintballLowReadyCrouched,				"AnimationSetPaintballLowReadyCrouched");
    CreateSet(kAnimationSetPaintballExtremeLowReady,				"AnimationSetPaintballExtremeLowReady");

	CreateSet(kAnimationSetGangHandgun,								"AnimationSetGangHandgun");
    CreateSet(kAnimationSetGangMachinegun,							"AnimationSetGangMachinegun");

    CreateSet(kAnimationSetCuffed,									"AnimationSetCuffed");
    CreateSet(kAnimationSetCompliantLookAt,							"AnimationSetCompliantLookAt");

    CreateSet(kAnimationSetFlashbanged,								"AnimationSetFlashbanged");
    CreateSet(kAnimationSetFlashbangedCuffed,						"AnimationSetFlashbangedCuffed");
    CreateSet(kAnimationSetGassed,									"AnimationSetGassed");
    CreateSet(kAnimationSetGassedCuffed,							"AnimationSetGassedCuffed");
    CreateSet(kAnimationSetPepperSprayed,							"AnimationSetPepperSprayed");
    CreateSet(kAnimationSetPepperSprayedCuffed,					    "AnimationSetPepperSprayedCuffed");
    CreateSet(kAnimationSetStung,									"AnimationSetStung");
    CreateSet(kAnimationSetStungCuffed,							    "AnimationSetStungCuffed");
    CreateSet(kAnimationSetTased,									"AnimationSetTased");
    CreateSet(kAnimationSetTasedCuffed,							    "AnimationSetTasedCuffed");

    CreateSet(kAnimationSetAIFlashbanged,							"AnimationSetAIFlashbanged");
    CreateSet(kAnimationSetAIGassed,								"AnimationSetAIGassed");
    CreateSet(kAnimationSetAIPepperSprayed,							"AnimationSetAIPepperSprayed");
    CreateSet(kAnimationSetAIStung,									"AnimationSetAIStung");
    CreateSet(kAnimationSetAITased,									"AnimationSetAITased");

    CreateSet(kAnimationSetMouthOpen,								"AnimationSetMouthOpen");
}

///////////////////////////////////////

function AnimationSet GetAnimationSet(EAnimationSet set)
{
    return m_animationSets[set];
}

///////////////////////////////////////////////////////////////////////////////

private function CreateSet(EAnimationSet set, string configEntryName)
{
    m_animationSets[int(set)] = new(none, configEntryName, 0) class'AnimationSet';
    assertWithDescription(m_animationSets[int(set)] != none,
        "Animation set "$configEntryName$" (enum "$GetEnum(enum'EAnimationSet', set)$") could not be created.");
#if !IG_THIS_IS_SHIPPING_VERSION
    if (set != kAnimationSetNull)
    {
        assertWithDescription(m_animationSets[int(set)].IsSetNull() == false,
            "Animation set "$configEntryName$" (enum "$GetEnum(enum'EAnimationSet', set)$") was created, but empty.");
    }
#endif
}

///////////////////////////////////////////////////////////////////////////////
