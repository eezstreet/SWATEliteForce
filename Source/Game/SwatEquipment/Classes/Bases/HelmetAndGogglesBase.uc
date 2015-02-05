class HelmetAndGogglesBase extends Engine.ProtectiveEquipment
    implements  SwatGame.IProtectFromFlashbang;

function QualifyProtectedRegion() 
{
    assertWithDescription(ProtectedRegion < REGION_Body_Max,
        "[Carlos] The HelmetAndGogglesBase class "$class.name
        $" specifies ProtectedRegion="$GetEnum(ESkeletalRegion, ProtectedRegion)
        $".  ProtectiveEquipment may only protect body regions or Region_None.");
}
