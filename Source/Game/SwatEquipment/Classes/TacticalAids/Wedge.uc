class Wedge extends SwatGame.EquipmentUsedOnOther
    implements ITacticalAid;

simulated function UsedHook()
{
    FirstPersonModel.Hide();
    ThirdPersonModel.Hide();

    IAmUsedByWedge(Other).OnUsedByWedge();
}

// IAmAQualifiedUseEquipment implementation

simulated function float GetQualifyDuration()
{
    return IAmUsedByWedge(Other).GetQualifyTimeForWedge() * GetQualifyModifier();
}

// IAmUsedOnOther implementation

simulated protected function AssertOtherIsValid()
{
    assertWithDescription(Other.IsA('IAmUsedByWedge'),
        "[tcohen] A Wedge was called to AssertOtherIsValid(), but Other is a "$Other.class.name
        $", which is not an IAmUsedByWedge.");
}

defaultproperties
{
    Slot=SLOT_Wedge
    UnavailableAfterUsed=true
}
