class CSBallLauncher extends RoundBasedWeapon;

var config class<CSBallBase> CSBallClass;

var config int OfficerMaxShotsWhenGassed;

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

simulated function bool ShouldOfficerUseAgainst(Pawn OtherActor, int ShotsFired)
{
    local SwatPawn SwatPawn;

    SwatPawn = SwatPawn(OtherActor);
    if (SwatPawn == None)
    {
        return false;
    }

    if (SwatPawn.IsGassed() && ShotsFired >= OfficerMaxShotsWhenGassed)
    {   // If they're gassed then this weapon is useless, anything extra is flair
        return false;
    }

    return super.ShouldOfficerUseAgainst(OtherActor, ShotsFired);
}

defaultproperties
{
	bIsLessLethal=true
	bPenetratesDoors=false
    OfficerMaxShotsWhenGassed=5
}
