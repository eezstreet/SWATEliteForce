class NoEquipment extends Engine.HandheldEquipment config(SwatEquipment);

function OnGivenToOwner()
{
	SetAvailable(false);
}
