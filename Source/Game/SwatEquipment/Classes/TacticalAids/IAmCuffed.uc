class IAmCuffed extends Engine.HandheldEquipment;

//The IAmCuffed HandheldEquipment handles what a Pawn's
//  Hands and Pawn is doing while it is cuffed.

simulated function bool AllowedToPassItem()
{
	// we are not allowed to pass Cuffs, Detonator, or the Toolkit
	return false;
}

defaultproperties
{
    Slot=SLOT_IAmCuffed
    PlayerCanUnequip=false
}
