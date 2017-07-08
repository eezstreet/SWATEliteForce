class AnimNotify_TurnOtherOfficersAway extends Engine.AnimNotify_Scripted;

// just tells the owner to drop its weapon if it is a SwatEnemy
event Notify( Actor Owner )
{
	local SwatAIRepository SwatAIRepo;
	local OfficerTeamInfo Element;
	local Pawn Officer;
	local int i;

	assert(Owner != None);
    
    if (Owner.IsA('SwatOfficer'))
    {
		SwatAIRepo = SwatAIRepository(Owner.Level.AIRepo);
		assert(SwatAIRepo != None);

		Element = SwatAIRepo.GetElementSquad();

		for(i=0; i<Element.pawns.length; ++i)
		{
			Officer = Element.pawns[i];

			if ((Officer != Owner) && class'Pawn'.static.checkConscious(Officer) && Pawn(Owner).LineOfSightTo(Officer))
			{
				SwatOfficer(Officer).PlayTurnAwayAnimation();
			}
		}
	}
}

defaultproperties
{
}
