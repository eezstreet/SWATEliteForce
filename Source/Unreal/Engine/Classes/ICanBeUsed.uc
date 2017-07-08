interface ICanBeUsed
    native;

simulated function bool CanBeUsedNow();

simulated function OnUsed(Pawn Other);

simulated function PostUsed();

simulated function String UniqueID();