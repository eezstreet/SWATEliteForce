///////////////////////////////////////////////////////////////////////////////

class NetPlayerTeamA extends NetPlayer;


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	// COOP: Note this will make ALL swat officers ALWAYS relevant until 
    // there is a mechanism on clients to determine if the game mode is COOP 	
	if ( Level.IsPlayingCOOP )
		bAlwaysRelevant = true;
}


simulated function int GetTeamNumber()
{
    return 0;
}

defaultproperties
{
	TeamNumber=0
    Skins[0] = Material'mp_OfficerTex.mpSWAT_BDU_CamoShader'
    Skins[1] = Material'mp_OfficerTex.mpSWATelementLeadShader'
    Skins[2] = Material'mp_OfficerTex.NameTagBlueShader'
    Skins[3] = Material'mp_OfficerTex.mpSWAT_vest_defaultShader'
}
