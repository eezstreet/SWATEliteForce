///////////////////////////////////////////////////////////////////////////////

class NetPlayerTeamB extends NetPlayer;


simulated function int GetTeamNumber()
{
    return 1;
}

defaultproperties
{
    TeamNumber = 1
    Skins[0] = Material'mp_OfficerTex.mpBad_BDU_odgrnShader'
    Skins[1] = Material'mp_OfficerTex.mpBad_FaceAshader'
    Skins[2] = Material'mp_OfficerTex.NameTagRedShader'
    Skins[3] = Material'mp_OfficerTex.mpBad_Vest_DefaultShader'
}
