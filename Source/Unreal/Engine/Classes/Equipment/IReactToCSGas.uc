interface IReactToCSGas extends IReactToGrenades;

simulated function bool IsGassed();

// This function may be *repeatedly* called often as long as the IReactToCSGas is being affected by the Gas
//
// GasContainer: 
//     The source of the gas (i.e., the gas grenade or the 
//     CS paint ball pellet) -- used to get source location
//
// Duration: 
//     The standard duration of effect players and AIs in SP and MP
//
// SPPlayerProtectiveEquipmentDurationScaleFactor: 
//     in Single Player games, if a Player (non-AI) being gassed has protective 
//     equipment that protects him from gas, then the duration of 
//     effect will be scaled by this value. 
//     I.e., PlayerDuration *= SPPlayerProtectiveEquipmentDurationScaleFactor
//     
// MPPlayerProtectiveEquipmentDurationScaleFactor: 
//     In Multi Player games, if the Player being gassed has protective 
//     equipment that protects him from gas, then the duration of 
//     effect will be scaled by this value. 
//     I.e., PlayerDuration *= MPPlayerProtectiveEquipmentDurationScaleFactor
function ReactToCSGas(Actor GasContainer, float Duration, float SPPlayerProtectiveEquipmentDurationScaleFactor, float MPPlayerProtectiveEquipmentDurationScaleFactor);
