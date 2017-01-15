class C2Charge extends QualifiedTacticalAid
    implements ITacticalAid;

simulated function UsedHook()
{
    local SwatDoor TargetDoor;

    if (FirstPersonModel != None)
        FirstPersonModel.Hide();
    if (ThirdPersonModel != None)
        ThirdPersonModel.Hide();

    TargetDoor = SwatDoor(Other);
    if (TargetDoor.ActorIsToMyLeft(Pawn(Owner)))
    {
        if (TargetDoor.GetDeployedC2ChargeLeft() != None)
            return; //someone else beat us to it... don't confuse the issue
    }
    else    //Owner is on the Door's Right
        if (TargetDoor.GetDeployedC2ChargeRight() != None)
            return; //someone else beat us to it... don't confuse the issue

    IAmUsedByC2Charge(Other).OnUsedByC2Charge(ICanUseC2Charge(Owner));
}

//which slot should be equipped after this item becomes unavailable
simulated function EquipmentSlot GetSlotForReequip()
{
    return Slot_Detonator;
}

// IAmAQualifiedUseEquipment implementation

simulated function float GetQualifyDuration()
{
    return IAmUsedByC2Charge(Other).GetQualifyTimeForC2Charge();
}

// IAmUsedOnOther implementation

simulated protected function AssertOtherIsValid()
{
    assertWithDescription(Other.IsA('IAmUsedByC2Charge'),
        "[tcohen] A C2Charge was called to AssertOtherIsValid(), but Other is a "$Other.class.name
        $", which is not an IAmUsedByC2Charge.");
}

defaultproperties
{
    Slot=SLOT_Breaching
    UnavailableAfterUsed=true
}
