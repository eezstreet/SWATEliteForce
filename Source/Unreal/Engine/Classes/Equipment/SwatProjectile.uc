class SwatProjectile extends Actor
    native;

defaultproperties
{
    Physics=Phys_Falling
    bCollideActors=true
    bCollideWorld=true
    bBounce=true
    bStatic=false
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=true
}
