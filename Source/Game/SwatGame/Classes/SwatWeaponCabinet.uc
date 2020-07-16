class SwatWeaponCabinet extends Engine.Actor
	implements Engine.ICanBeUsed
	placeable;

// ICanBeUsed implementation

simulated function bool CanBeUsedNow()
{
	local SwatGamePlayerController LocalController;

	LocalController = SwatGamePlayerController(Level.GetLocalPlayerController());

	return LocalController.HasAWeaponEquipped();
}

simulated function OnUsed(Pawn Other)
{
	local SwatGamePlayerController LocalController;

	LocalController = SwatGamePlayerController(Level.GetLocalPlayerController());

	LocalController.SwapWeapon();
}

simulated function PostUsed()
{
	// ?
}
