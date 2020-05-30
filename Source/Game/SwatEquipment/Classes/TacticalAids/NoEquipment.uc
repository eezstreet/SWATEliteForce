class NoEquipment extends Engine.HandheldEquipment config(SwatEquipment);

static function bool IsUsableByPlayer()
{
	return true;
}

function OnGivenToOwner()
{
	SetAvailable(false);
}
