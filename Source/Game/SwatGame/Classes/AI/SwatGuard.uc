///////////////////////////////////////////////////////////////////////////////

class SwatGuard extends SwatEnemy;

///////////////////////////////////////////////////////////////////////////////

protected function ConstructCharacterAIHook(AI_Resource characterResource)
{
    // Guards can attack, but not flee, regroup, threaten hostages, or
    // converse with hostages. See SwatEnemy::ConstructCharacterAIHook
    characterResource.addAbility(new class'SwatAICommon.AttackOfficerAction');
	characterResource.addAbility(new class'SwatAICommon.TakeCoverAndAttackAction');
}

///////////////////////////////////////////////////////////////////////////////
