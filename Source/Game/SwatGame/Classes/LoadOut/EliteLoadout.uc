class EliteLoadout extends OfficerLoadOut;

var(DEBUG) protected array<Actor> GivenEquipment;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientAddItemToGivenEquipment;
}

function ClientAddItemToGivenEquipment(Actor newItem)
{
	GivenEquipment[GivenEquipment.Length] = newItem;
}

simulated function RemoveGivenEquipment(HandHeldEquipment Equipment)
{
	local int i;
	local HandheldEquipment Item;

	for(i = 0; i < GivenEquipment.Length; i++)
	{
		Item = HandheldEquipment(GivenEquipment[i]);
		if(Item == Equipment)
		{
			GivenEquipment.Remove(i, 1);
		}
	}
}

simulated function HandHeldEquipment FindGivenItemForSlot(EquipmentSlot Slot)
{
	local int i;
	local HandHeldEquipment Item;

	for(i = 0; i < GivenEquipment.Length; i++)
    {
        Item = HandheldEquipment(GivenEquipment[i]);
        if(Item != None && Item.GetSlot() == Slot && Item.IsAvailable() && Item.IsIdle())
        {
            if(!Item.IsA('FiredWeapon') || !FiredWeapon(Item).Ammo.IsEmpty())
            {   // see above, this fixes pepper spray
                return Item;
            }
        }
    }

    return Item;
}

simulated function int AdditionalAvailableCountForItem(EquipmentSlot Slot)
{
	local int i;
	local int ExtraCount;
	local FiredWeapon Weapon;
	local HandHeldEquipment Equipment;

	ExtraCount = 0;

	for(i = 0; i < GivenEquipment.Length; i++)
	{
		Equipment = HandHeldEquipment(GivenEquipment[i]);
		if(Slot == SLOT_Detonator)
		{
			if(Equipment != None && Equipment.IsA('C2Charge'))
			{
				ExtraCount += Equipment.GetAvailableCount();
			}
		}
		else if(Equipment != None && Equipment.GetSlot() == Slot && Equipment.IsAvailable())
		{
			if(Equipment.IsA('PepperSpray'))
			{
				Weapon = FiredWeapon(Equipment);
				if(Weapon.Ammo.IsEmpty())
				{
					continue;
				}
			}
			ExtraCount += Equipment.GetAvailableCount();
		}
	}

	return ExtraCount;
}

simulated function AddToGivenEquipmentStore(HandHeldEquipment Equipment)
{
	GivenEquipment[GivenEquipment.Length] = Equipment;

	if(Role == ROLE_Authority && Level.NetMode != NM_Standalone)
	{
		ClientAddItemToGivenEquipment(Equipment);
	}
}

simulated function float GetGivenItemWeight()
{
	local float total;
	local int i;

	total = 0.0;

	for(i = 0; i < GivenEquipment.Length; i++)
	{
		if(GivenEquipment[i] == None)
		{
			continue;
		}

		total += GetEquipmentWeight(Engine.IHaveWeight(GivenEquipment[i]), i);
	}

	return total;
}

simulated function float GetGivenItemBulk()
{
	local float total;
	local int i;

	total = 0.0;

	for(i = 0; i < GivenEquipment.Length; i++)
	{
		if(GivenEquipment[i] == None)
		{
			continue;
		}

		total += GetEquipmentBulk(Engine.IHaveWeight(GivenEquipment[i]), i);
	}

	return total;
}

simulated function bool GivenEquipmentIncludes(Name EquipmentName)
{
	local int i;

	for(i = 0; i < GivenEquipment.Length; i++)
	{
		if(GivenEquipment[i] != None && GivenEquipment[i].IsA(EquipmentName))
		{
			return true;
		}
	}

	return false;
}