interface IAmAQualifiedUseEquipment;

//returns true if the Alternate animation set should be used
simulated function bool ShouldUseAlternate();

//returns the time, in seconds, required to qualify to use this equipment
simulated function float GetQualifyDuration();

//HACK AIs need to be able to interrupt qualification and have the item
//  go back to UsingStatus=Idle before the next tick.
//This is ugly, but Crombie says that the AIs will clean up after themselves.
function InstantInterrupt();
