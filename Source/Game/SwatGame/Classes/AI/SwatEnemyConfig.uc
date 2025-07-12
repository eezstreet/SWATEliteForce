class SwatEnemyConfig extends Core.Object
    config(AI);

var config float						LowSkillAdditionalBaseAimError;
var config float						MediumSkillAdditionalBaseAimError;
var config float						HighSkillAdditionalBaseAimError;

var config float						LowSkillMinTimeToFireFullAuto;
var config float						LowSkillMaxTimeToFireFullAuto;
var config float						MediumSkillMinTimeToFireFullAuto;
var config float						MediumSkillMaxTimeToFireFullAuto;
var config float						HighSkillMinTimeToFireFullAuto;
var config float						HighSkillMaxTimeToFireFullAuto;

var config float						MinDistanceToAffectMoraleOfOtherEnemiesUponDeath;

var config array<name>					ThrowWeaponDownAnimationsHG;
var config array<name>					ThrowWeaponDownAnimationsMG;
var config array<name>					ThrowWeaponDownAnimationsSMG;
var config array<name>					ThrowWeaponDownAnimationsSG;

var config float						LowSkillFullBodyHitChance;
var config float						MediumSkillFullBodyHitChance;
var config float						HighSkillFullBodyHitChance;

var config float            LowSkillMinTimeBeforeShooting;
var config float            LowSkillMaxTimeBeforeShooting;
var config float            MediumSkillMinTimeBeforeShooting;
var config float            MediumSkillMaxTimeBeforeShooting;
var config float            HighSkillMinTimeBeforeShooting;
var config float            HighSkillMaxTimeBeforeShooting;
//SP only time before shoot
var config float            LowSkillMinTimeBeforeShootingSP;
var config float            LowSkillMaxTimeBeforeShootingSP;
var config float            MediumSkillMinTimeBeforeShootingSP;
var config float            MediumSkillMaxTimeBeforeShootingSP;
var config float            HighSkillMinTimeBeforeShootingSP;
var config float            HighSkillMaxTimeBeforeShootingSP;

defaultproperties
{
    LowSkillMinTimeBeforeShooting = 1.0
    LowSkillMaxTimeBeforeShooting = 1.7
    MediumSkillMinTimeBeforeShooting = 0.9
    MediumSkillMaxTimeBeforeShooting = 1.3
    HighSkillMinTimeBeforeShooting = 0.6
    HighSkillMaxTimeBeforeShooting = 1.0
	
	LowSkillMinTimeBeforeShootingSP = 0.6
	LowSkillMaxTimeBeforeShootingSP = 1.0
	MediumSkillMinTimeBeforeShootingSP = 0.6
	MediumSkillMaxTimeBeforeShootingSP = 0.8
	HighSkillMinTimeBeforeShootingSP = 0.4
	HighSkillMaxTimeBeforeShootingSP = 0.6
}