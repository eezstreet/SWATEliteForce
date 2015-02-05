///////////////////////////////////////////////////////////////////////////////
// BaseIdleAction.uc - BaseIdleAction class
// The base Action class for animator or procedural idles

class BaseIdleAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum EnemyState from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////
//
// BaseIdleAction Member Variables
var   protected IdleDefinition	OurIdleDefinition;
var	  private	bool			bIsCurrentIdle;

///////////////////////////////////////////////////////////////////////////////
//
// Constructor / Initialization

overloaded function construct(IdleDefinition IdleDefinition)
{
    assert(IdleDefinition != None);
    OurIdleDefinition = IdleDefinition;
}

function initAction(AI_Resource r, AI_Goal goal)
{
    super.initAction(r, goal);
    ISwatAI(m_pawn).SetUpperBodyAnimBehavior(kUBAB_FullBody, kUBABCI_BaseIdleAction);
}

function cleanup()
{
	super.cleanup();
    ISwatAI(m_pawn).UnsetUpperBodyAnimBehavior(kUBABCI_BaseIdleAction);
}

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

// test to see if we can use this idle action based on our idle definition
// and the pawn's current active item
private function bool CanUseIdleBasedOnWeapon()
{
//	if (m_Pawn.logTyrion)
//		log(self.name@" CanUseIdleBasedOnWeapon - IdleWeaponStatus:"@OurIdleDefinition.IdleWeaponStatus@" EquipmentName:"@m_Pawn.GetActiveItem().Name);

	// if the idle is based on an active item, make sure we have it equipped
	if (OurIdleDefinition.IdleWeaponStatus != IdleWeaponDoesNotMatter)
	{
		// if the idle definition says that we can idle with any weapon, just make sure we have an active item
		if ((OurIdleDefinition.IdleWeaponStatus == IdleWithAnyWeapon) && (m_Pawn.GetActiveItem() == None))
		{
			return false;
		}
		// dbeswick: SAW idle definition
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithSAW) && 
			     ((m_Pawn.GetActiveItem() == None) || ! m_Pawn.GetActiveItem().IsA('SAWMG')))
		{
			return false;
		}
		// if the idle definition says that we should be idling with a machine gun, make sure we have it equipped
		// special case: if it's an G36k MG, we have a special idle set
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithMachineGun) && 
			     ((m_Pawn.GetActiveItem() == None) || !m_Pawn.GetActiveItem().IsA('MachineGun') || m_Pawn.GetActiveItem().IsA('SAWMG') || m_Pawn.GetActiveItem().IsA('G36kMG')))
		{
			return false;
		}
		// if the idle definition says that we should be idling with the G36k MG, make sure we have it equipped
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithG36) && 
				 ((m_Pawn.GetActiveItem() == None) || ! m_Pawn.GetActiveItem().IsA('G36kMG')))
		{
			return false;
		}
		// if the idle definition says that we should be idling with a sub machine gun, make sure we have it equipped
		// special case: if it's an UMP SMG, we have a special idle set
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithSubMachineGun) && 
			     ((m_Pawn.GetActiveItem() == None) || ! m_Pawn.GetActiveItem().IsA('SubMachineGun') || m_Pawn.GetActiveItem().IsA('UMP45SMG')))
		{
			return false;
		}
		// if the idle definition says that we should be idling with the UMP 45 SMG, make sure we have it equipped
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithUMP) && 
				 ((m_Pawn.GetActiveItem() == None) || ! m_Pawn.GetActiveItem().IsA('UMP45SMG')))
		{
			return false;
		}
		// if the idle definition says that we should be idling with a handgun, make sure we have it equipped
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithHandgun) && 
				 ((m_Pawn.GetActiveItem() == None) || ! m_Pawn.GetActiveItem().IsA('Handgun')))
		{
			return false;
		}
		// if the idle definition says that we should be idling with a shotgun, make sure we have it equipped
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithShotgun) && 
			     ((m_Pawn.GetActiveItem() == None) || ! m_Pawn.GetActiveItem().IsA('Shotgun')))
		{
			return false;			
		}
		// if the idle definition says that we should be idling with a paintball gun, make sure we have it equipped
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithPaintballGun) &&
				 ((m_Pawn.GetActiveItem() == None) || ! m_Pawn.GetActiveItem().IsA('CSBallLauncher')))
		{
			return false;
		}
		// if the idle definition says that we should be idling with a grenade, make sure we have it equipped
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithGrenade) &&
				 ((m_Pawn.GetActiveItem() == None) || ! m_Pawn.GetActiveItem().IsA('ThrownWeapon')))
		{
			return false;
		}
		// if the idle definition says that we should be idling without a weapon, make sure we have none equipped
		else if ((OurIdleDefinition.IdleWeaponStatus == IdleWithoutWeapon) && (m_Pawn.GetActiveItem() != None))
		{
			return false;
		}
	}

	// no problems with the weapon
	return true;
}

// depending on whether we're aiming or not, use the correct idle
private function bool CanUseIdleBasedOnState()
{
	// if we're aiming, just use the aiming idles
	if (OurIdleDefinition.IdleTime == IdleAnytime)
	{
		return true;
	}
	else if (ISwatAI(m_Pawn).GetUpperBodyAnimBehavior() == kUBAB_AimWeapon)
	{
		return (OurIdleDefinition.IdleTime == IdleAiming);
	}
	else
	{
		return (OurIdleDefinition.IdleTime == IdleAnytimeExceptAiming);
	}
}

function bool CanUseIdleBasedOnAggression()
{
	assert(m_Pawn != None);

	// only test for problems if we are a SwatAICharacter (hostage or enemy), 
	// and this idle definition says that aggression does matter
	if (m_Pawn.IsA('SwatAICharacter') && (OurIdleDefinition.IdleCharacterAggression != AggressionDoesNotMatter))
	{
		if (ISwatAI(m_Pawn).IsAggressive())
			return (OurIdleDefinition.IdleCharacterAggression == AggressiveCharactersOnly);
		else
			return (OurIdleDefinition.IdleCharacterAggression == PassiveCharactersOnly);
	}

	// no problems with this idle based on aggression values
	return true;
}

function bool CanUseIdleBasedOnPosition()
{
	assert(m_Pawn != None);

	if (OurIdleDefinition.CharacterIdlePosition == IdlePositionDoesNotMatter)
		return true;
	else if (m_Pawn.bIsCrouched)
		return (OurIdleDefinition.CharacterIdlePosition == IdleCrouching);
	else
		return (OurIdleDefinition.CharacterIdlePosition == IdleStanding);
}

// returns true if the categories match, otherwise false
function bool CanUseIdleBasedOnCategory()
{
	local name CurrentIdleCategory;

	CurrentIdleCategory = ISwatAI(m_Pawn).GetIdleCategory();

	if (OurIdleDefinition.IdleCategory != CurrentIdleCategory)
	{
		return false;
	}

	// no problems with the character's Idle category
	return true;
}

// returns true if all resources this idle requires are available
// expected to be overridden in subclasses
function bool AreResourcesAvailableToIdle(AI_Goal goal)
{
	assert(false);
	return false;
}

// Test to see if we can use this particular idle action based on the current state of the AI
// Since all tests here can change, we can't precompute this information (we've already precomputed the AI class)

// TODO: add in ability to check for crouching
function bool CanUseIdleAction()
{
	assert(m_Pawn != None);

	if (! CanUseIdleBasedOnWeapon())
	{
//		if (m_Pawn.logTyrion)
//			log("CanUseIdleBasedOnWeapon failed for " $ m_Pawn $ " on animation name: " $ AnimatorIdleDefinition(OurIdleDefinition).AnimationName);

		return false;
	}
	else if (! CanUseIdleBasedOnState())
	{
//		if (m_Pawn.logTyrion)
//			log("CanUseIdleBasedOnState failed for " $ m_Pawn $ " on animation name: " $ AnimatorIdleDefinition(OurIdleDefinition).AnimationName);

		return false;
	}
	else if (! CanUseIdleBasedOnAggression())
	{
//		if (m_Pawn.logTyrion)
//			log("CanUseIdleBasedOnAggression failed for " $ m_Pawn $ " on animation name: " $ AnimatorIdleDefinition(OurIdleDefinition).AnimationName);

		return false;
	}
	else if (! CanUseIdleBasedOnPosition())
	{
//		if (m_Pawn.logTyrion)
//			log("CanUseIdleBasedOnPosition failed for " $ m_Pawn $ " on animation name: " $ AnimatorIdleDefinition(OurIdleDefinition).AnimationName);

		return false;
	}
	else if (! CanUseIdleBasedOnCategory())
	{
//		if (m_Pawn.logTyrion)
//			log("CanUseIdleBasedOnCategory failed for " $ m_Pawn $ " on animation name: " $ AnimatorIdleDefinition(OurIdleDefinition).AnimationName);

		return false;
	}
	
//	if (m_Pawn.logTyrion)
//		log(m_Pawn $ " for anim. " $ AnimatorIdleDefinition(OurIdleDefinition).AnimationName $ " is " $ OurIdleDefinition.Weight);

	// we can only use this idle action if the weight is greater than 0.0
	return (OurIdleDefinition.Weight > 0.0);
}

function float GetIdleWeight()
{
	return OurIdleDefinition.Weight;
}

function SetCurrentIdle(bool inIsCurrentIdle)
{
	bIsCurrentIdle = inIsCurrentIdle;
}

function float selectionHeuristic( AI_Goal goal )
{
    local float Heuristic;
	assert(goal.IsA('IdleGoal'));
	
	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	// make sure we can use it before determining our heuristic
	if (AreResourcesAvailableToIdle(goal))
	{
		if (!ISwatAI(m_Pawn).IsIdleCurrent())
		{
			ISwatAI(m_Pawn).ChooseIdle();
		}

		// if we are the current idle, return 1.0 so we are chosen
		if (bIsCurrentIdle)
		{
//			log(m_Pawn.Name $ " is going to use animation " $ AnimatorIdleDefinition(OurIdleDefinition).AnimationName);

			Heuristic = 1.0;
		}
	}
    
    return Heuristic;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'IdleGoal'
}