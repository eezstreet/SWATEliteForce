class AnimNotify_Use extends AnimNotify_Scripted;

//see ICanHoldEquipment.uc for details about handling equipment notifications
simulated event Notify( Actor Owner )
{
    local ICanHoldEquipment Holder;

    Holder = ICanHoldEquipment(Owner);
    AssertWithDescription(Holder != None,
        "[tcohen] AnimNotify_Use was called on "$Owner$" which cannot hold equipment.");

    Holder.OnUseKeyFrame();
}
