class BlockingVolumeFleeSafeguard extends Engine.BlockingVolumePawnsOnly
    hidecategories(Object,Advanced,Collision,Display,Havok,LightColor,Movement);

var() bool bFleeSafeguard;

simulated function Touch(Actor Other)
{
	Super.Touch(Other);

	if (bFleeSafeguard && Other.IsA('SwatEnemy'))
	{
		SwatEnemy(Other).bEnteredFleeSafeguard = true;
		log("Blocking volume"@self.Name@"activated flee safeguard for"@Other.name);
	}
}

defaultproperties
{
	bFleeSafeguard=true
	bOfficersOnly=true
}