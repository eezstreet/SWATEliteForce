interface ICanBeTased;

function ReactToBeingTased(Actor Taser, float PlayerDuration, float AIDuration);

//returns false if the ICanBeTased has some inherent protection from Taser, ie. HeavyArmor
simulated function bool IsVulnerableToTaser();
