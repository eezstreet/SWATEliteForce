class Weapon extends HandheldEquipment
	abstract
	native
    /*nativereplication*/;

// MCJ: All the interesting stuff has moved out of this class into others. I
// don't think it needs to be native or have nativereplication anymore. Once
// everything else is working fine, change this and verify that it works.

var bool bIsLessLethal;

/* DisplayDebug()
list important controller attributes on canvas
*/
simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	local string T;
	local name Anim;
	local float frame,rate;

    Super.DisplayDebug(Canvas, YL, YPos);

	Canvas.SetDrawColor(0,255,0);
	T = "     STATE: "$GetStateName()$" Timer: "$TimerCounter;

	Canvas.DrawText(T, false);
	YPos += YL;
	Canvas.SetPos(4,YPos);

#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
	if ( DrawType == DT_StaticMesh )
		Canvas.DrawText("     StaticMesh "$StaticMesh$" AmbientSound "$AmbientSound, false);
	else
		Canvas.DrawText("     Mesh "$Mesh$" AmbientSound "$AmbientSound, false);
#else
	if ( DrawType == DT_StaticMesh )
		Canvas.DrawText("     StaticMesh ", false);
#endif

    YPos += YL;
	Canvas.SetPos(4,YPos);
	if ( Mesh != None )
	{
		// mesh animation
		GetAnimParams(0,Anim,frame,rate);
		T = "     AnimSequence "$Anim$" Frame "$frame$" Rate "$rate;
		if ( bAnimByOwner )
			T= T$" Anim by Owner";

		Canvas.DrawText(T, false);
		YPos += YL;
		Canvas.SetPos(4,YPos);
	}
}


function bool IsLessLethal()
{
	return bIsLessLethal;
}

//=============================================================================
// Inventory travelling across servers.

//event TravelPostAccept();   //TMC got rid of this stuff, since we don't carry equipment from level to level


defaultproperties
{
    bReplicateInstigator=true
	bIsLessLethal=false
}
