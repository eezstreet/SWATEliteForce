class ColtAccurizedRifle extends ClipBasedWeapon;

var config float ZoomedAimErrorModifier;

simulated function float GetBaseAimError()
{
	local float BaseAimError;
	local Pawn OwnerPawn;
	local PlayerController OwnerController;

	BaseAimError = super.GetBaseAimError();

	OwnerPawn = Pawn(Owner);

	if (OwnerPawn!= None)
	{
		OwnerController = PlayerController(OwnerPawn.Controller);

		if (OwnerController != None && OwnerController.WantsZoom)
		{
			return BaseAimError * ZoomedAimErrorModifier;
		}
	}

	return BaseAimError;
}