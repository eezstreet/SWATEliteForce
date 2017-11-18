class NoWeapon extends Engine.FiredWeapon config(SwatEquipment);

function OnGivenToOwner()
{
	SetAvailable(false);
}
