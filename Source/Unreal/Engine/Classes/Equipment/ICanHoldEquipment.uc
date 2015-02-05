interface ICanHoldEquipment;

simulated function HandheldEquipment GetActiveItem();

//The PendingItem is the item that will be equipped as soon as
//  the ActiveItem is finished being UnEquipped.
//This may change while the ActiveItem is being UnEquipped
//  (for example, if the player presses another equip key).
simulated function HandheldEquipment GetPendingItem();

//These notifications are called by their respective AnimNotifys
//  when an animation playing on the ICanHoldEquipment reaches
//  a key frame in the animation.
//After it is done handling the notification, the ICanHoldEquipment
//  will forward the notification to its ActiveItem.
simulated function OnEquipKeyFrame();
simulated function OnUnequipKeyFrame();
simulated function OnUseKeyFrame();
simulated function OnLightstickKeyFrame();
simulated function OnMeleeKeyFrame();
simulated function OnReloadKeyFrame();
simulated function OnNVGogglesDownKeyFrame();
simulated function OnNVGogglesUpKeyFrame();

//play any animations for idling while holding a piece of handheld equipment
simulated function IdleHoldingEquipment();
