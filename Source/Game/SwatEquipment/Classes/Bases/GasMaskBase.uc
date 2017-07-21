class GasMaskBase extends Engine.Headgear
    implements IProtectFromCSGas, IProtectFromPepperSpray;

function QualifyProtectedRegion()
{
    assertWithDescription(ProtectedRegion < REGION_Body_Max,
        "[Carlos] The GaskMaskBase class "$class.name
        $" specifies ProtectedRegion="$GetEnum(ESkeletalRegion, ProtectedRegion)
        $".  ProtectiveEquipment may only protect body regions or Region_None.");
}
