//=====================================================================
// A generic test harness for Tyrion unit tests
//=====================================================================

class TyrionUnitTest extends Engine.Actor
	placeable;

//=====================================================================
// Constants

const PASS_THRESHOLD_PROXIMITY = 100;

//=====================================================================
// Variables

var() string nextLevelURL;			// next test to perform

var Engine.Pawn workPawn;
var AI_Controller workController;

//=====================================================================
// Functions

function PostBeginPlay()
{
	Super.PostBeginPlay();

	SetTimer(3.0, false);			// call Timer() in 3 seconds
}

//---------------------------------------------------------------------

event Timer()
{
	GotoState('UnitTestState');
}

//---------------------------------------------------------------------

function logTest(string text)
{
	Log("Unit Test: " $ text);
}

//---------------------------------------------------------------------

function signalPassed()
{
	Log("Test Passed");
	gotoNextLevel();
}

//---------------------------------------------------------------------

function signalFailed(string reason)
{
	Log("Test Failed: " $ reason);
	gotoNextLevel();
}

//---------------------------------------------------------------------

function gotoNextLevel()
{
	if (nextLevelURL == "")
		Log("Unit Test Chain Finished");
	else
		Level.ServerTravel(nextLevelURL, false);
}

//---------------------------------------------------------------------

function Engine.Pawn getPawn(string pawnName)
{
	return Engine.Pawn(findObject(pawnName, class'Pawn', Level.Outer));
}

//=====================================================================

defaultProperties
{
	Texture=Texture'Engine_res.S_Trigger'
	bNoDelete=true
	bHidden=true
	bCollideWhenPlacing=true
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
//	SoundVolume=0
//#endif
    CollisionRadius=+00080.000000
	CollisionHeight=+00100.000000
}