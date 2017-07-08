class AnimNotify_ChangeSkinAtIndex extends Engine.AnimNotify_Scripted;

var() Material Material;
var() int Index;

//see ICanHoldEquipment.uc for details about handling equipment notifications
simulated event Notify( Actor Owner )
{
    assert(Owner != None && Owner.DrawType == DT_Mesh);

    assertWithDescription(Material != None,
        "[tcohen] AnimNotify_ChangeSkinAtIndex::Notify() Material is None.");
    
    if (Owner.Skins.length == 0)
        Owner.CopyMaterialsToSkins();

    Owner.Skins[Index] = Material;
}
