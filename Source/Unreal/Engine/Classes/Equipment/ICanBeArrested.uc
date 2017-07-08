interface ICanBeArrested
    native;

//returns true if I can be arrested now according to my current state
simulated function bool CanBeArrestedNow();

//returns true if I am in the process of being arrested
simulated function bool IsBeingArrestedNow();

//a suspect will always get OnArrestingBegan() before being arrested
simulated function OnArrestBegan(Pawn Arrester);


// *** Please note that SwatPawn implements OnArrested() and classes
//     derived from SwatPawn should not override OnArrested(), but
//     should override OnArrestedSwatPawn() instead. ***
//
//if the arrester completes the qualification process,
//  then the ICanBeArrested gets OnArrested()
simulated function OnArrested(Pawn Arrester);

//if the arrester is interrupted during the qualification process,
//  then the ICanBeArrested gets OnArrestInterrupted()
simulated function OnArrestInterrupted(Pawn Arrester);


//return the time it takes for a Player to "qualify" to arrest me
simulated function float GetQualifyTimeForArrest(Pawn Arrester);

//returns whether we've been arrested
simulated function bool IsArrested();
