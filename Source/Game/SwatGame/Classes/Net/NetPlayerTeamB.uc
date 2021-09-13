///////////////////////////////////////////////////////////////////////////////

class NetPlayerTeamB extends NetPlayer;


simulated function int GetTeamNumber()
{
    return 1;
}

defaultproperties
{
    TeamNumber = 1
    Skins[0] = Material'mp_OfficerTex.mpSWAT_BDU_CamoShader'
    Skins[1] = Material'mp_OfficerTex.mpSWATelementLeadShader'
    Skins[2] = Material'mp_OfficerTex.NameTagRedShader'
    Skins[3] = Material'mp_OfficerTex.mpSWAT_vest_defaultShader'
}
