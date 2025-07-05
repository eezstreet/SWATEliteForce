///////////////////////////////////////////////////////////////////////////////
// ReactToBeingShotAction.uc - RestrainedAction class
// The action that causes the AI to react to taking bullet

class ReactToBeingShotAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum ESkeletalRegion from Engine.Actor;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// enums
enum TorsoHitRegion
{
	TorsoHitRegion_Front,
	TorsoHitRegion_Back,
	TorsoHitRegion_Left,
	TorsoHitRegion_Right
};

// animation config variables

// torso hit animations
var config array<name> StandingHitInFront;
var config array<name> StandingHitInBack;
var config array<name> StandingHitLeft;
var config array<name> StandingHitRight;

var config array<name> CrouchingHitInFront;
var config array<name> CrouchingHitInBack;
var config array<name> CrouchingHitLeft;
var config array<name> CrouchingHitRight;

// head hit animations
var config array<name> StandingHitInHead;
var config array<name> CrouchingHitInHead;

// right arm hit animations
var config array<name> StandingHitRightArm;
var config array<name> CrouchingHitRightArm;

// left arm hit animations
var config array<name> StandingHitLeftArm;
var config array<name> CrouchingHitLeftArm;

// right leg hit animations
var config array<name> StandingHitRightLeg;
var config array<name> CrouchingHitRightLeg;

// left leg hit animations
var config array<name> StandingHitLeftLeg;
var config array<name> CrouchingHitLeftLeg;

// compliant hits
var config array<name> CompliantHitFront;
var config array<name> CompliantHitBack;
var config array<name> CompliantHitLeft;
var config array<name> CompliantHitRight;

// restrained hits
var config array<name> RestrainedHitFront;
var config array<name> RestrainedHitBack;
var config array<name> RestrainedHitLeft;
var config array<name> RestrainedHitRight;

// quick hits
var config array<name> QuickHitFront;
var config array<name> QuickHitBack;
var config array<name> QuickHitLeft;
var config array<name> QuickHitRight;

var config name		   QuickHitBaseBone;

// restrained quick hits
var config array<name> RestrainedQuickHitFront;
var config array<name> RestrainedQuickHitBack;
var config array<name> RestrainedQuickHitLeft;
var config array<name> RestrainedQuickHitRight;

var config name		   RestrainedQuickHitBaseBone;

// copied from our goal
var(parameters) vector		HitNormal;
var(parameters) vector		HitLocation;
var(parameters) ESkeletalRegion RegionHit;

///////////////////////////////////////////////////////////////////////////////
//
// Hit Animations

private function name GetHitRightAnimation()
{
	if (ISwatAI(m_Pawn).IsCompliant())
		return CompliantHitRight[Rand(CompliantHitRight.Length)];
	else if (ISwatAI(m_Pawn).IsArrested())
		return RestrainedHitRight[Rand(RestrainedHitRight.Length)];
	else if (m_Pawn.bIsCrouched)
		return CrouchingHitRight[Rand(CrouchingHitRight.Length)];	
	else
		return StandingHitRight[Rand(StandingHitRight.Length)];
}

private function name GetHitLeftAnimation()
{
	if (ISwatAI(m_Pawn).IsCompliant())
		return CompliantHitLeft[Rand(CompliantHitLeft.Length)];
	else if (ISwatAI(m_Pawn).IsArrested())
		return RestrainedHitLeft[Rand(RestrainedHitLeft.Length)];
	else if (m_Pawn.bIsCrouched)
		return CrouchingHitLeft[Rand(CrouchingHitLeft.Length)];	
	else
		return StandingHitLeft[Rand(StandingHitLeft.Length)];
}

private function name GetHitInBackAnimation()
{
	if (ISwatAI(m_Pawn).IsCompliant())
		return CompliantHitBack[Rand(CompliantHitBack.Length)];
	else if (ISwatAI(m_Pawn).IsArrested())
		return RestrainedHitBack[Rand(RestrainedHitBack.Length)];
	else if (m_Pawn.bIsCrouched)
		return CrouchingHitInBack[Rand(CrouchingHitInBack.Length)];	
	else
		return StandingHitInBack[Rand(StandingHitInBack.Length)];
}

private function name GetHitInFrontAnimation()
{
	if (ISwatAI(m_Pawn).IsCompliant())
		return CompliantHitFront[Rand(CompliantHitFront.Length)];
	else if (ISwatAI(m_Pawn).IsArrested())
		return RestrainedHitFront[Rand(RestrainedHitFront.Length)];
	else if (m_Pawn.bIsCrouched)
		return CrouchingHitInFront[Rand(CrouchingHitInFront.Length)];	
	else
		return StandingHitInFront[Rand(StandingHitInFront.Length)];
}

private function TorsoHitRegion GetTorsoHitRegion(vector vHitLocation)
{
	local float fDot;
	local vector vPawnDirection, vPawnDirectionNoZ, vHitDirectionNoZ, vPawnsLeftDirectionNoZ;

	vPawnDirection      = vector(ISwatAI(m_Pawn).GetAimOrientation());
	vPawnDirectionNoZ   = vPawnDirection;
	vPawnDirectionNoZ.Z = 0.0;

	vHitDirectionNoZ    = Normal(vHitLocation - m_Pawn.Location);
	vHitDirectionNoZ.Z  = 0.0;   // 2D

	// this is a 2d check
	fDot = vPawnDirectionNoZ Dot vHitDirectionNoZ;

	if (fDot > 0.707)			// hit in front
	{
		return TorsoHitRegion_Front;
	}
	else if (fDot < -0.707)		// hit in back
	{
		return TorsoHitRegion_Back;
	}
	else
	{
		vPawnsLeftDirectionNoZ   = vPawnDirection Cross vect(0,0,1);
		vPawnsLeftDirectionNoZ.Z = 0.0;

		fDot = vPawnsLeftDirectionNoZ Dot vHitDirectionNoZ;

		if (fDot < 0.0)			// hit to the right
		{
			return TorsoHitRegion_Right;
		}
		else
		{
			return TorsoHitRegion_Left;
		}
	}
}

// old way of doing things.  May need to update if the torso ever doesn't match up with the location
private function name GetHitTorsoAnimation()
{
	local TorsoHitRegion TorsoHitRegion;

	TorsoHitRegion = GetTorsoHitRegion(HitLocation);

	switch(TorsoHitRegion)
	{
		case TorsoHitRegion_Front:
			return GetHitInFrontAnimation();
	
		case TorsoHitRegion_Back:
			return GetHitInBackAnimation();
	
		case TorsoHitRegion_Right:
			return GetHitRightAnimation();
		
		case TorsoHitRegion_Left:
			return GetHitLeftAnimation();
	}

	// never should get here
	assert(false);
	return '';
}

private function name GetHitHeadAnimation()
{
	if (ISwatAI(m_Pawn).IsCompliant())
		return CompliantHitFront[Rand(CompliantHitFront.Length)];
	else if (ISwatAI(m_Pawn).IsArrested())
		return RestrainedHitFront[Rand(RestrainedHitFront.Length)];
	else if (m_Pawn.bIsCrouched)
		return CrouchingHitInHead[Rand(CrouchingHitInHead.Length)];
	else
		return StandingHitInHead[Rand(StandingHitInHead.Length)];
}

private function name GetHitLeftArmAnimation()
{
	if (ISwatAI(m_Pawn).IsCompliant())
		return CompliantHitLeft[Rand(CompliantHitLeft.Length)];
	else if (ISwatAI(m_Pawn).IsArrested())
		return RestrainedHitLeft[Rand(RestrainedHitLeft.Length)];
	else if (m_Pawn.bIsCrouched)
		return CrouchingHitLeftArm[Rand(CrouchingHitLeftArm.Length)];
	else
		return StandingHitLeftArm[Rand(StandingHitLeftArm.Length)];
}

private function name GetHitRightArmAnimation()
{
	if (ISwatAI(m_Pawn).IsCompliant())
		return CompliantHitRight[Rand(CompliantHitRight.Length)];
	else if (ISwatAI(m_Pawn).IsArrested())
		return RestrainedHitRight[Rand(RestrainedHitRight.Length)];
	else if (m_Pawn.bIsCrouched)
		return CrouchingHitRightArm[Rand(CrouchingHitRightArm.Length)];
	else
		return StandingHitRightArm[Rand(StandingHitRightArm.Length)];
}

private function name GetHitLeftLegAnimation()
{
	if (ISwatAI(m_Pawn).IsCompliant())
		return CompliantHitLeft[Rand(CompliantHitLeft.Length)];
	else if (ISwatAI(m_Pawn).IsArrested())
		return RestrainedHitLeft[Rand(RestrainedHitLeft.Length)];
	else if (m_Pawn.bIsCrouched)
		return CrouchingHitLeftLeg[Rand(CrouchingHitLeftLeg.Length)];
	else
		return StandingHitLeftLeg[Rand(StandingHitLeftLeg.Length)];
}

private function name GetHitRightLegAnimation()
{
	if (ISwatAI(m_Pawn).IsCompliant())
		return CompliantHitRight[Rand(CompliantHitRight.Length)];
	else if (ISwatAI(m_Pawn).IsArrested())
		return RestrainedHitRight[Rand(RestrainedHitRight.Length)];
	else if (m_Pawn.bIsCrouched)
		return CrouchingHitRightLeg[Rand(CrouchingHitRightLeg.Length)];
	else
		return StandingHitRightLeg[Rand(StandingHitRightLeg.Length)];
}

private function name GetHitAnimationUsingBodyTargeting()
{
	switch (RegionHit)
	{
		case REGION_Head:
			return GetHitHeadAnimation();

		case REGION_Torso:
			return GetHitTorsoAnimation();

		case REGION_LeftArm:
			return GetHitLeftArmAnimation();

		case REGION_RightArm:
			return GetHitRightArmAnimation();

		case REGION_LeftLeg:
			return GetHitLeftLegAnimation();

		case REGION_RightLeg:
			return GetHitRightLegAnimation();

		default:
			// shouldn't get here
			assert(false);
			return '';
	}
}

private function name GetHitAnimation()
{
	if (RegionHit == REGION_None)
	{
		// old method using a hit location (also used for the torso)
		return GetHitTorsoAnimation();
	}
	else
	{
		return GetHitAnimationUsingBodyTargeting();
	}
}

private function name GetNormalQuickHitAnimation(TorsoHitRegion inTorsoHitRegion)
{
	switch(inTorsoHitRegion)
	{
		case TorsoHitRegion_Front:
			return QuickHitFront[Rand(QuickHitFront.Length)];
	
		case TorsoHitRegion_Back:
			return QuickHitBack[Rand(QuickHitBack.Length)];
	
		case TorsoHitRegion_Right:
			return QuickHitRight[Rand(QuickHitRight.Length)];
		
		case TorsoHitRegion_Left:
			return QuickHitLeft[Rand(QuickHitLeft.Length)];
	}

	// never should get here
	assert(false);
	return '';
}

private function name GetRestrainedQuickHitAnimation(TorsoHitRegion inTorsoHitRegion)
{
	switch(inTorsoHitRegion)
	{
		case TorsoHitRegion_Front:
			return RestrainedQuickHitFront[Rand(RestrainedQuickHitFront.Length)];
	
		case TorsoHitRegion_Back:
			return RestrainedQuickHitBack[Rand(RestrainedQuickHitFront.Length)];
	
		case TorsoHitRegion_Right:
			return RestrainedQuickHitRight[Rand(RestrainedQuickHitFront.Length)];
		
		case TorsoHitRegion_Left:
			return RestrainedQuickHitLeft[Rand(RestrainedQuickHitFront.Length)];
	}

	// never should get here
	assert(false);
	return '';
}

private function name GetQuickHitAnimation(vector vQuickHitLocation)
{
	local TorsoHitRegion TorsoHitRegion;

	TorsoHitRegion = GetTorsoHitRegion(vQuickHitLocation);

	if (ISwatAI(m_Pawn).IsArrested())
	{
		return GetRestrainedQuickHitAnimation(TorsoHitRegion);
	}
	else
	{
		return GetNormalQuickHitAnimation(TorsoHitRegion);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

private latent function PlayHitAnimation()
{
	local int AnimSpecialChannel;

	assertWithDescription((GetHitAnimation() != ''), "ReactToBeingShotAction::PlayHitAnimation - Hit Animation not found!  Ask crombie to fix this!");

	AnimSpecialChannel = m_Pawn.AnimPlaySpecial(GetHitAnimation(), 0.1);
	m_Pawn.FinishAnim(AnimSpecialChannel);
}

private function TriggerInjuredSpeech()
{
	if (ISwatAI(m_Pawn).IsIntenseInjury())
	{
		ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerIntenseInjuredSpeech();
	}
	else
	{
		ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerNormalInjuredSpeech();
	}
}

function PlayQuickHit(vector QuickHitLocation)
{
	local name QuickHitAnimation;
	
	ISwatAI(m_Pawn).AnimStopQuickHit();
	QuickHitAnimation = GetQuickHitAnimation(QuickHitLocation);
	ISwatAI(m_Pawn).AnimPlayQuickHit(QuickHitAnimation, 0.1, QuickHitBaseBone);
}

latent function LatentPlayQuickHit(vector QuickHitLocation)
{
	PlayQuickHit(QuickHitLocation);

	m_Pawn.FinishAnim(ISwatAI(m_Pawn).AnimGetQuickHitChannel());
}

function ChangeMorale()
{
	local CommanderAction CommanderAction;

	CommanderAction = ISwatAI(m_Pawn).GetCommanderAction();
	CommanderAction.ChangeMorale(-CommanderAction.GetShotMoraleModification(), "Shot", true);
}

state Running
{
 Begin:
	ChangeMorale();
	TriggerInjuredSpeech();

	if (ISwatAI(m_Pawn).ShouldPlayFullBodyHitAnimation())
	{
		useResources(class'AI_Resource'.const.RU_LEGS | class'AI_Resource'.const.RU_ARMS);

		PlayHitAnimation();
	}
	else
	{
		LatentPlayQuickHit(HitLocation);
	}

	succeed();
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'ReactToBeingShotGoal'
}
