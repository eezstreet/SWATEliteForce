class AnimNotify_Lightstick extends AnimNotify_Scripted;

import enum EquipmentSlot from HandheldEquipment;

//see ICanHoldEquipment.uc for details about handling equipment notifications
simulated event Notify( Actor Owner )
{
    local ICanHoldEquipment Holder;

    Holder = ICanHoldEquipment(Owner);

    Holder.OnLightstickKeyFrame();
}
