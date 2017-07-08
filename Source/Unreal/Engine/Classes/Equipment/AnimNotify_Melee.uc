class AnimNotify_Melee extends AnimNotify_Scripted;

//see ICanHoldEquipment.uc for details about handling equipment notifications
simulated event Notify( Actor Owner )
{
    local ICanHoldEquipment Holder;

    Holder = ICanHoldEquipment(Owner);
    AssertWithDescription(Holder != None,
        "[tcohen] AnimNotify_Melee was called on "$Owner$" which cannot hold equipment.");

    Holder.OnMeleeKeyFrame();
}