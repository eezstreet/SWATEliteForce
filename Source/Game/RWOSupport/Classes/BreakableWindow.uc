class BreakableWindow extends ReactiveStaticMesh;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    bWorldGeometry = true;
}


defaultproperties
{
    bAlwaysRelevant=true;
}
