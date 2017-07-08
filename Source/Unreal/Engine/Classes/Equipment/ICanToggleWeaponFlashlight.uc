// This is an interface for equipment holders that should be able to toggle the state
// of the flashlight on a FiredWeapon.
interface ICanToggleWeaponFlashlight extends ICanHoldEquipment;

// Returns true if the holder desires its weapon's flashlight to be on.
simulated function bool GetDesiredFlashlightState();

// Returns the number of seconds to delay between when the desired flashlight
// state changes to false (i.e., "off") and when the flashlight actual goes 
// off. This is usually 0, but for instance when a pawn dies you can change
// this function to return X, so that the flashlight will shut off X seconds
// later (for performance).
simulated function float GetDelayBeforeFlashlightShutoff();