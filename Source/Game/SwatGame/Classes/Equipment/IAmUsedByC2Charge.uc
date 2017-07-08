interface IAmUsedByC2Charge;

function OnUsedByC2Charge(ICanUseC2Charge Instigator);

//return the time to qualify to use this with a Wedge
simulated function float GetQualifyTimeForC2Charge();
