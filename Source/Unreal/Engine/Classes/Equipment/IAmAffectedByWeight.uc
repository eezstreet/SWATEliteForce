interface IAmAffectedByWeight;

// Something that is affected by weight/bulk system

simulated function float GetTotalWeight();
simulated function float GetTotalBulk();
simulated function float GetWeightMovementModifier();
simulated function float GetBulkQualifyModifier();
