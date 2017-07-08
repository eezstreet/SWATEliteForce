//=============================================================================
// Scout used for path generation.
//=============================================================================
class Scout extends Pawn
	native
	notplaceable;

var const float		MaxLandingVelocity;
var const Actor		WalkMoveHitActor;
var const vector	WalkMoveHitLocation;
var const string	WalkMoveHitMessage;

function PreBeginPlay()
{
	Destroy(); //scouts shouldn't exist during play
}

defaultproperties
{
     AccelRate=+00001.000000
     CollisionRadius=+00052.000000
     CollisionHeight=+00078.000000
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
     bProjTarget=False
	 bPathColliding=True
}
