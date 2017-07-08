interface IAmUsedByToolkit
    native;

// Return true iff this can be operated by a toolkit now
simulated function bool CanBeUsedByToolkitNow();

// Called when qualifying begins.
simulated function OnUsingByToolkitBegan( Pawn User );

// Called when qualifying completes successfully.
simulated function OnUsedByToolkit(Pawn User);

// Called when qualifying is interrupted.
simulated function OnUsingByToolkitInterrupted( Pawn User );


//return the time to qualify to use this with a Toolkit
simulated function float GetQualifyTimeForToolkit();
