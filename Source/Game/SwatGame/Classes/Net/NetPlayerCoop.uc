///////////////////////////////////////////////////////////////////////////////

class NetPlayerCoop extends NetPlayer;

var() HandheldEquipment NextReplicatedEquipmentGiven;
var() HandheldEquipment LastEquipmentGiven;

replication
{
	// Things the server should send to the client
    reliable if ( bNetOwner && bNetDirty && (Role == ROLE_Authority) )
		NextReplicatedEquipmentGiven;
}


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	log("NetPlayerCoop PostBeginPlay()");

	if ( Level.IsPlayingCOOP )
		bAlwaysRelevant = true;

	if(Role < ROLE_Authority)
	{
		log("Enabling tick for NetPlayerCoop");
		Enable('Tick');
	}
}

function OnTick()
{
	if(Role < ROLE_Authority)
	{
		log("NetPlayerCoop tick: NextReplicatedEquipmentGiven = " $ NextReplicatedEquipmentGiven $ ", LastEquipmentGiven = " $ LastEquipmentGiven);
		if(NextReplicatedEquipmentGiven != LastEquipmentGiven)
		{
			log("Replicated equipment given: " $ NextReplicatedEquipmentGiven);
			// we got replicated to us that we received a piece of equipment, so actually give it to us

			Loadout.GivenEquipmentFromPawn(NextReplicatedEquipmentGiven);
			SwatGamePlayerController(controller).theLoadOut.GivenEquipmentFromPawn(NextReplicatedEquipmentGiven);
			LastEquipmentGiven = NextReplicatedEquipmentGiven;
		}
	}
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

simulated function OnGivenNewEquipment(HandheldEquipment Equipment)
{
	if(Role < ROLE_Authority)
	{
		log("OnGivenNewEquipment called from client with Equipment = " $ Equipment);
	}
	else 
	{
		log("OnGivenNewEquipment called from server with Equipment = " $ Equipment);
	}
	NextReplicatedEquipmentGiven = Equipment;
}

defaultproperties
{
    Skins[0] = Material'mp_OfficerTex.mpSWAT_BDU_CamoShader'
    Skins[1] = Material'mp_OfficerTex.mpSWATelementLeadShader'
    Skins[2] = Material'mp_OfficerTex.NameTagRedShader'
    Skins[3] = Material'mp_OfficerTex.mpSWAT_vest_defaultShader'
	bReplicateSkins=true
}
