// This is an interface for equipment that modifies the vision of the player,
// such as night vision.
interface IVisionEnhancement;

simulated function bool IsActive();
simulated function bool ShowOverlay();
simulated function Activate();
simulated function Deactivate();
simulated function ToggleActive();
simulated function ApplyEnhancement();