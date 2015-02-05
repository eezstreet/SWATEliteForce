#if IG_SWAT
//=====================================================================
// AI_DummyHead
// Action that simply sleeps
//=====================================================================

class AI_DummyHead extends AI_HeadAction
	editinlinenew;

//=====================================================================
// Variables

//=====================================================================
// Functions

//=====================================================================
// State code

state Running
{
Begin:
	if ( resource.pawn().logTyrion )
		log( self $ " started." );

	sleepForever();

	succeed();
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_DummyHeadGoal'
}
#endif // IG_SWAT