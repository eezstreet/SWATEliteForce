//=====================================================================
// AI_DummyWeapon
// Action that simply sleeps
//=====================================================================

class AI_DummyWeapon extends AI_WeaponAction
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
		log( self.name @ "started." );

	pause();

	succeed();
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_DummyWeaponGoal'
}