//=============================================================================
// Player start location.
//=============================================================================
class PlayerStart extends SmallNavigationPoint 
#if !IG_SWAT // ckline: Should place SwatPlayerStarts and SwatOfficerStarts, not PlayerStarts 
	placeable
#endif
	native;

#if !IG_SWAT // ckline: All this stuff is handled in SwatPlayerStart and SwatOfficerStart 
// Players on different teams are not spawned in areas with the
// same TeamNumber unless there are more teams in the level than
// team numbers.
var() byte TeamNumber;			// what team can spawn at this start
var() bool bSinglePlayerStart;	// use first start encountered with this true for single player
var() bool bCoopStart;			// start can be used in coop games	
var() bool bEnabled; 
var() bool bPrimaryStart;		// None primary starts used only if no primary start available
var() float LastSpawnCampTime;	// last time a pawn starting from this spot died within 5 seconds
#else
//var() byte TeamNumber;
var editconst bool bSinglePlayerStart;
//var() bool bCoopStart;
var editconst bool bEnabled; 
//var() bool bPrimaryStart;
var editconst float LastSpawnCampTime;
#endif // !IG_SWAT


defaultproperties
{
//#if !IG_SWAT // ckline: All this stuff is handled in SwatPlayerStart and SwatOfficerStart 
//	 bPrimaryStart=true
//#endif
 	 bEnabled=true
     bSinglePlayerStart=True
//#if !IG_SWAT // ckline: All this stuff is handled in SwatPlayerStart and SwatOfficerStart 
//     bCoopStart=True
//#endif
     bDirectional=True
     Texture=Texture'Engine_res.S_Player'
}
