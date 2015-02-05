class BoobyTrapDoorAttachment extends RWOSupport.ReactiveWorldObject
      implements IAmUsedByToolKit;

// TODO:  BoobyTraps really need to be refactored, but at least this will make it work for designers to start placing.
// Ideally, all booby traps will have both a possible door attachment and a possible world location, both should react to 
// events, disable/trigger each other accordingly...


function PostBeginPlay()
{
    Super.PostBeginPlay();

    assertWithDescription( Owner != None && Owner.IsA('BoobyTrap'), 
                           "BoobyDoorAttachment's can only be spawned by BoobyTraps, and must have the BoobyTrap as the owner" );

    //tcohen 5/19/2004 to fix 3484: Booby traps cannot be used directly - they are only used with a toolkit
    UsableNow = false;
}

simulated function bool CanBeUsedByToolkitNow()
{
    return boobyTrap(Owner).bActive;
}

// Called when qualifying begins.
function OnUsingByToolkitBegan( Pawn User );

// Called when qualifying completes successfully.
function OnUsedByToolkit(Pawn User)
{
    ReactToUsed(User.GetActiveItem());
    // Forward to the boobytrap...
    BoobyTrap(Owner).ReactToUsed(User.GetActiveItem());
}

function ReactToUsed(Actor Other)
{
    if ( BoobyTrap(Owner).bActive && Other.IsA('Toolkit') ) 
    {
        Super.ReactToUsed(Other);
    }
}

// Called when qualifying is interrupted.
function OnUsingByToolkitInterrupted( Pawn User );


//return the time to qualify to use this with a Toolkit
simulated function float GetQualifyTimeForToolkit()
{
    return BoobyTrap(Owner).QualifyTime;
}

defaultproperties
{
    DrawType=DT_StaticMesh
    DrawScale=1
    bHidden=false
    bCollideActors=true
    bCollideWorld=true
    bBlockActors=true
}
