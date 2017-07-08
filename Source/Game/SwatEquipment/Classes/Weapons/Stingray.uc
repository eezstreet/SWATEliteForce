class Stingray extends Taser;


simulated function TraceFire()
{
	//LOG("Stingray::tracefire() - Ammo.GetCurrentRounds()" @ RoundBasedAmmo(Ammo).GetCurrentRounds());
	if (CurrentFireMode == FireMode_SingleTaser || !Ammo.IsFull())
	{
		TraceFireInternal(Max(RoundBasedAmmo(Ammo).GetCurrentRounds()-1, 0));
	}
	else if (CurrentFireMode == FireMode_DoubleTaser)
	{
		TraceFireInternal(0);
		TraceFireInternal(1);
		Ammo.OnRoundUsed(Pawn(Owner), self);			// use an extra round
	}
	else
		AssertWithDescription(false, "Stingray::TraceFire(): invalid fire mode" @ CurrentFireMode);
}


simulated function TriggerMeleeReaction(Actor Victim)
{
	// Hit something that can be tased
	if (Victim.IsA('ICanBeTased'))
	{
		ICanBeTased(Victim).ReactToBeingTased(self, PlayerTasedDuration, AITasedDuration);
	}
}

defaultproperties
{
	VerticalSpread=-5.0
	bIsLessLethal=true
}
