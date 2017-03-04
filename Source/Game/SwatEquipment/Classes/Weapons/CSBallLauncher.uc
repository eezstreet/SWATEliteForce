class CSBallLauncher extends RoundBasedWeapon;

var config class<CSBallBase> CSBallClass;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    assertWithDescription(CSBallClass != None,
        "[tcohen] The CSBallLauncher's CSBallClass resolves to None.  Please set it in SwatEquipment.ini, [SwatEquipment.CSBallLauncher].");
}

simulated function BallisticFire(vector StartTrace, vector EndTrace)
{
    local vector ShotVector;
    local CSBallBase Ball;
    local vector BallStart;

    ShotVector = Normal(EndTrace - StartTrace);

    BallStart = StartTrace + ShotVector * 20.0;     //push ball away from the camera a bit

    Ball = Spawn(
        CSBallClass,    //SpawnClass
        self,           //SpawnOwner
        ,               //SpawnTag
        BallStart,      //SpawnLocation
        ,               //SpawnRotation
        true);          //bNoCollisionFail
    assert(Ball != None);

    Ball.Velocity = ShotVector * MuzzleVelocity;
}

defaultproperties
{
	bIsLessLethal=true
	bPenetratesDoors=false
}
