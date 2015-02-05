interface ICanBePepperSprayed;

simulated function bool IsPepperSprayed();

// This may be *repeatedly* called often as long as the ICanBePepperSprayed is being affected by the PepperSpray
//
// PepperSpray: 
//     The source of the pepper spray (i.e., the pepper spray canister) -- used to get source location
//
// PlayerDuration: 
//     The standard duration of effect on players in SP and MP
//
// AIDuration: 
//     The standard duration of effect on AIs in SP and MP
//
// SPPlayerProtectiveEquipmentDurationScaleFactor: 
//     in Single Player games, if a Player (non-AI) being peppered has protective 
//     equipment that protects him from pepper spray, then the duration of 
//     effect will be scaled by this value. 
//     I.e., PlayerDuration *= SPPlayerProtectiveEquipmentDurationScaleFactor
//     
// MPPlayerProtectiveEquipmentDurationScaleFactor: 
//     In Multi Player games, if the Player being peppered has protective 
//     equipment that protects him from pepper spray, then the duration of 
//     effect will be scaled by this value. 
//     I.e., PlayerDuration *= MPPlayerProtectiveEquipmentDurationScaleFactor

function ReactToBeingPepperSprayed(Actor PepperSpray, float PlayerDuration, float AIDuration, float SPPlayerProtectiveEquipmentDurationScaleFactor, float MPPlayerProtectiveEquipmentDurationScaleFactor);
