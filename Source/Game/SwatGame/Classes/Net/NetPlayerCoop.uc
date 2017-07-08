///////////////////////////////////////////////////////////////////////////////

class NetPlayerCoop extends NetPlayer;


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( Level.IsPlayingCOOP )
		bAlwaysRelevant = true;
}

simulated function string GetViewportType()
{
	if (TeamNumber == 0)
		return "TeamA";
	else
		return "TeamB";
}

function SetSkins(TeamInfo NewTeam)
{
	if (NetTeam(NewTeam).GetTeamNumber() == 2)
	{
		Skins[2] = Material(DynamicLoadObject("mp_OfficerTex.NameTagRedShader", class'Material'));
		ReplicatedSkins[2] = Material(DynamicLoadObject("mp_OfficerTex.NameTagRedShader", class'Material'));
	}
	else
	{
		Skins[2] = Material(DynamicLoadObject("mp_OfficerTex.NameTagBlueShader", class'Material'));
		ReplicatedSkins[2] = Material(DynamicLoadObject("mp_OfficerTex.NameTagBlueShader", class'Material'));
	}

	ReplicatedSkins[0] = Skins[0];
	ReplicatedSkins[1] = Skins[1];
	ReplicatedSkins[3] = Skins[3];
}

simulated function SetPlayerSkins( OfficerLoadOut inLoadOut )
{
	if (ReplicatedCustomSkinClassName != "SwatGame.DefaultCustomSkin")
		Super.SetPlayerSkins( inLoadOut );
}

function OnTeamChanging(TeamInfo NewTeam)
{
	TeamNumber = NetTeam(NewTeam).GetTeamNumber();
	SetSkins(NewTeam);
}

simulated function int GetTeamNumber()
{
	if (NetTeam(PlayerReplicationInfo.Team) != None)
		return NetTeam(PlayerReplicationInfo.Team).GetTeamNumber();
	else
		return 0;
}

defaultproperties
{
    Skins[0] = Material'mp_OfficerTex.mpSWAT_BDU_CamoShader'
    Skins[1] = Material'mp_OfficerTex.mpSWATelementLeadShader'
    Skins[2] = Material'mp_OfficerTex.NameTagRedShader'
    Skins[3] = Material'mp_OfficerTex.mpSWAT_vest_defaultShader'
	bReplicateSkins=true
}
