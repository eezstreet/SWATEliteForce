class SwatPlayerConfig extends Core.Object
	config(SwatPawn);

var config float MinimumLongThrowSpeed;         //if a ThrownWeapon is thrown at a speed less than this, then the 'short' animations are played, otherwise, 'long' animations are used

var config name PreThrowAnimation;
var config name ThrowShortAnimation;
var config name ThrowLongAnimation;

var config name	 ThrowAnimationRootBone;

var config float ThrowSpeedTimeFactor;      //when a ThrownWeapon is thrown, its speed will be this times the time that the throw button is held
var config Range ThrowSpeedRange;           //clamp the throw speed

// NonLethal Effects
var config bool bTestingCameraEffects; // allow the player to be hit with nonlethals in standalone

//in unreal distance units, the farthest shake distance
var config float TasedViewEffectAmplitude;
//how often to recenter
var config float TasedViewEffectFrequency;

var config float LowReadyFireTweenTime;

var config float LimpThreshold;
var config float       StandardLimpPenalty;

var config float PawnModelApparentBaseEyeHeight;        //the apparent Z distance between the pawn's origin and the eyes of the 3rd person model when standing
var config float PawnModelApparentCrouchEyeHeight;      //the apparent Z distance between the pawn's origin and the eyes of the 3rd person model when standing

var config class<HandheldEquipment> GivenFlashbangClass;
var config class<HandheldEquipment> GivenGasClass;
var config class<HandheldEquipment> GivenStingerClass;
var config class<HandheldEquipment> GivenC2Class;
var config class<HandheldEquipment> GivenPepperSprayClass;
var config class<HandheldEquipment> GivenWedgeClass;

static function float GetMinimumLongThrowSpeed()
{
	return default.MinimumLongThrowSpeed;
}

static function name GetPreThrowAnimation()
{
	return default.PreThrowAnimation;
}

static function name GetThrowShortAnimation()
{
	return default.ThrowShortAnimation;
}

static function name GetThrowLongAnimation()
{
	return default.ThrowLongAnimation;
}

static function name GetThrowAnimationRootBone()
{
	return default.ThrowAnimationRootBone;
}

static function float GetThrowSpeedTimeFactor()
{
	return default.ThrowSpeedTimeFactor;
}

static function Range GetThrowSpeedRange()
{
	return default.ThrowSpeedRange;
}

static function bool GetTestingCameraEffects()
{
	return default.bTestingCameraEffects;
}

static function float GetTasedViewEffectAmplitude()
{
	return default.TasedViewEffectAmplitude;
}

static function float GetTasedViewEffectFrequency()
{
	return default.TasedViewEffectFrequency;
}

static function float GetLowReadyFireTweenTime()
{
	return default.LowReadyFireTweenTime;
}

static function float GetLimpThreshold()
{
	return default.LimpThreshold;
}

static function float GetStandardLimpPenalty()
{
	return default.StandardLimpPenalty;
}

static function float GetPawnModelApparentBaseEyeHeight()
{
	return default.PawnModelApparentBaseEyeHeight;
}

static function float GetPawnModelApparentCrouchEyeHeight()
{
	return default.PawnModelApparentCrouchEyeHeight;
}

static function class<HandheldEquipment> GetGivenFlashbangClass()
{
	return default.GivenFlashbangClass;
}

static function class<HandheldEquipment> GetGivenGasClass()
{
	return default.GivenGasClass;
}

static function class<HandheldEquipment> GetGivenStingerClass()
{
	return default.GivenStingerClass;
}

static function class<HandheldEquipment> GetGivenC2Class()
{
	return default.GivenC2Class;
}

static function class<HandheldEquipment> GetGivenPepperSprayClass()
{
	return default.GivenPepperSprayClass;
}

static function class<HandheldEquipment> GetGivenWedgeClass()
{
	return default.GivenWedgeClass;
}