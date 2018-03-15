class ServerSettings extends Engine.ReplicationInfo
    config(SwatGuiState)
	dependsOn(SwatAdmin);

import enum EEntryType from SwatStartPointBase;
import enum EMPMode from Engine.Repo;
import enum AdminPermissions from SwatAdmin;

const MAX_MAPS = 40;
var(ServerSettings) config String         Maps[MAX_MAPS];
var(ServerSettings) config int            NumMaps;

var(ServerSettings) config EMPMode        GameType "What game type the server is running";
var(ServerSettings) config int            MapIndex "What map is currently being used";
var(ServerSettings) config int            NumRounds "How many rounds to play per map";
var(ServerSettings) config int            MaxPlayers "Maximum number of players allowed on this server";
var(ServerSettings) config int            RoundNumber "What is the current round number";
var(ServerSettings) config bool           bUseRoundStartTimer "Whether to have a round timer at the start of the level";
var(ServerSettings) config int            PostGameTimeLimit "Time between the end of the round and server loading the next level";
var(ServerSettings) config bool           bUseRoundEndTimer "Whether to have a round timer at the end of the level";
var(ServerSettings) config int            MPMissionReadyTime "Time (in seconds) for players to ready themselves in between rounds in a MP game";
var(ServerSettings) config bool           bShowTeammateNames "If true, will display teammates names";
var(ServerSettings) config bool           Unused "Not used.";
var(ServerSettings) config bool           bAllowReferendums "If true, allow players to start referendums";
var(ServerSettings) config bool           bNoRespawn "If true, the server will not respawn players";
var(ServerSettings) config bool           bQuickRoundReset "If true, the server will perform a quick reset in between rounds on the same map; if false, the server will do a full SwitchLevel between rounds";
var(ServerSettings) config float          FriendlyFireAmount "The damage modifier for friendly fire [0...1]";
var(ServerSettings) config string         DisabledEquipment "Equipment that is disabled on the server";
var(ServerSettings) config float          CampaignCOOP "Contains Campaign CO-OP settings (bitpacked)";
var(ServerSettings) config int            AdditionalRespawnTime "Time (in seconds) added to the delay time between respawn waves.";
var(ServerSettings) config bool           bNoLeaders "If true, new 'leader' functionality in SWAT 4 expansion is disabled.";
var(ServerSettings) config bool           bNoKillMessages "If true, incapacitation/kill/death/arrest messages will not show in the chat.";
var(ServerSettings) config bool           bEnableSnipers "Enable snipers?";

var(ServerSettings) config String         ServerName "Name of the server for display purposes";
var(ServerSettings) localized config String DefaultServerName "Default name of the server for display purposes";
var                 config String         Password "Password for the server for authenticating users";
var(ServerSettings) config bool           bPassworded "If true, the server is passworded";
var(ServerSettings) config bool           bLAN "If true, the server is hosted only over the LAN (not internet)";

var(ServerSettings)        bool           bDirty;

// Team settings
var(ServerSettings) config bool				bForceTeamBalance "If true, the teams cannot be intentionally unbalanced.";
var(ServerSettings) config bool				bForceTeamMax "If true, all teams have a forced maximum amount";
var(ServerSettings) config int				TeamForcedMax "If bForceTeamMax, the maximum number of players that can be on a team.";

// Cached stuff
var private array<class> CachedDisabledEquipment;
var private bool CacheBuilt;

// v7
var(ServerSettings) config bool						bIsQMM;
var(ServerSettings) config CustomScenario			QMMScenario;
var(ServerSettings) config bool						QMMUseCustomBriefing;
var(ServerSettings) config string					QMMCustomBriefing;
var(ServerSettings) config string			QMMScenarioQueue[MAX_MAPS];

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

replication
{
	reliable if ( bNetDirty && (Role == ROLE_Authority) )
		GameType, Maps, NumMaps, MapIndex, NumRounds,
        MaxPlayers, RoundNumber, bUseRoundStartTimer, PostGameTimeLimit,
        bUseRoundEndTimer, MPMissionReadyTime, bShowTeammateNames, Unused, bAllowReferendums, bNoRespawn,
        bQuickRoundReset, FriendlyFireAmount, DisabledEquipment,
        ServerName, Password, bPassworded, bLAN, AdditionalRespawnTime, CampaignCOOP,
		bNoLeaders, bNoKillMessages, bEnableSnipers,
		bIsQMM, QMMUseCustomBriefing, QMMCustomBriefing, QMMScenario;
}

///////////////////////////////////////////////////////////////////////////////
// Initialize the Server settings - load the map list for the game type
///////////////////////////////////////////////////////////////////////////////

function PreBeginPlay()
{
    Super.PreBeginPlay();

    LoadMapListForGameType();

	if (ServerName == "")
		ServerName = DefaultServerName;
}

///////////////////////////////////////////////////////////////////////////////
// Set the ServerSettings on the server
///////////////////////////////////////////////////////////////////////////////

function SetAdminServerSettings( PlayerController PC,
                            String newServerName,
                            String newPassword,
                            bool newbPassworded,
                            bool newbLAN )
{
log( self$"::SetAdminServerSettings( "$PC$", ServerName="$newServerName$", Password="$newPassword$", bPassworded="$newbPassworded$", bLAN="$newbLAN$" )" );
	if(Level.Game.IsA('SwatGameInfo') &&
		!SwatGameInfo(Level.Game).Admin.ActionAllowed(PC, AdminPermissions.Permission_ChangeSettings))
	{
		log("Couldn't set admin settings: not an admin");
        return;
	}

    ServerName = newServerName;
    Password = newPassword;
    bPassworded = newbPassworded;
    bLAN = newbLAN;
}

function SetQMMSettings(CustomScenario NewScenario, CustomScenarioPack Pack, bool IsCampaignCOOP, int CampaignCOOPIndex)
{
	local int i;

	QMMScenario = NewScenario;
	if(QMMScenario != None && Pack != None)
	{
		// We need to append some things to the list of disabled equipment
		bIsQMM = true;

		// First, disable the equipment that is in the pack
		for(i = 0; i < Pack.DisabledEquipment.Length; i++)
		{
			DisabledEquipment = DisabledEquipment $ string(Pack.DisabledEquipment[i]) $ ",";
		}

		// Then disable the equipment that is locked
		for(i = CampaignCOOPIndex + 1; i < Pack.FirstEquipmentUnlocks.Length; i++)
		{
			if(Pack.FirstEquipmentUnlocks[i] != None)
			{
				DisabledEquipment = DisabledEquipment $ string(Pack.FirstEquipmentUnlocks[i]) $ ",";
			}
		}

		for(i = CampaignCOOPIndex + 1; i < Pack.SecondEquipmentUnlocks.Length; i++)
		{
			if(Pack.SecondEquipmentUnlocks[i] != None)
			{
				DisabledEquipment = DisabledEquipment $ string(Pack.SecondEquipmentUnlocks[i]) $ ",";
			}
		}

		QMMUseCustomBriefing = QMMScenario.UseCustomBriefing;
		QMMCustomBriefing = QMMScenario.CustomBriefing;
	}
	else
	{
		bIsQMM = false;
	}

	log("SetQMMSettings: New DisabledEquipment is '"$DisabledEquipment$"'");
	log("SetQMMSettings: New bIsQMM is "$bIsQMM);
	SaveConfig();
}

function SetServerSettingsNoConfigSave(PlayerController PC,
                            EMPMode newGameType,
                            int newMapIndex,
                            int newNumRounds,
                            int newMaxPlayers,
                            bool newbUseRoundStartTimer,
                            int newPostGameTimeLimit,
                            bool newbUseRoundEndTimer,
                            int newMPMissionReadyTime,
                            bool newbShowTeammateNames,
                            bool newUnused,
							bool newbAllowReferendums,
                            bool newbNoRespawn,
                            bool newbQuickRoundReset,
                            float newFriendlyFireAmount,
                            string newDisabledEquipment,
							float newCampaignCOOP,
							int newAdditionalRespawnTime,
							bool newbNoLeaders,
							bool newbNoKillMessages,
							bool newbEnableSnipers)
{
	GameType = newGameType;
    MapIndex = newMapIndex;
    NumRounds = newNumRounds;
    MaxPlayers = newMaxPlayers;
    bUseRoundStartTimer = newbUseRoundStartTimer;
    PostGameTimeLimit = newPostGameTimeLimit;
    bUseRoundEndTimer = newbUseRoundEndTimer;
    MPMissionReadyTime = newMPMissionReadyTime;
    bShowTeammateNames = newbShowTeammateNames;
    Unused = newUnused;
	bAllowReferendums = newbAllowReferendums;
    bNoRespawn = newbNoRespawn;
    bQuickRoundReset = newbQuickRoundReset;
    FriendlyFireAmount = newFriendlyFireAmount;
    DisabledEquipment = newDisabledEquipment;
	CampaignCOOP = newCampaignCOOP;
	AdditionalRespawnTime = newAdditionalRespawnTime;
	bNoLeaders = newbNoLeaders;
	bNoKillMessages = newbNoKillMessages;
	bEnableSnipers = newbEnableSnipers;

    RoundNumber=0;
}

function SetServerSettings( PlayerController PC,
                            EMPMode newGameType,
                            int newMapIndex,
                            int newNumRounds,
                            int newMaxPlayers,
                            bool newbUseRoundStartTimer,
                            int newPostGameTimeLimit,
                            bool newbUseRoundEndTimer,
                            int newMPMissionReadyTime,
                            bool newbShowTeammateNames,
                            bool newUnused,
							bool newbAllowReferendums,
                            bool newbNoRespawn,
                            bool newbQuickRoundReset,
                            float newFriendlyFireAmount,
                            string newDisabledEquipment,
							float newCampaignCOOP,
							int newAdditionalRespawnTime,
							bool newbNoLeaders,
							bool newbNoKillMessages,
							bool newbEnableSnipers)
{
log( self$"::SetServerSettings( "$PC$", newGameType="$GetEnum(EMPMode,newGameType)$", newMapIndex="$newMapIndex$", newNumRounds="$newNumRounds$", newMaxPlayers="$newMaxPlayers$", newUseRoundStartTimer="$newbUseRoundStartTimer$", newPostGameTimeLimit="$newPostGameTimeLimit$", newUseRoundEndTimer="$newbUseRoundEndTimer$", newMPMissionReadyTime="$newMPMissionReadyTime$", newbShowTeammateNames="$newbShowTeammateNames$", newUnused="$newUnused$", newbAllowReferendums="$newbAllowReferendums$", newbNoRespawn="$newbNoRespawn$", newbQuickRoundReset="$newbQuickRoundReset$", newFriendlyFireAmount="$newFriendlyFireAmount$", newDisabledEquipment="$newDisabledEquipment$" )" );

	if(Level.Game.IsA('SwatGameInfo') && PC != None &&
		!SwatGameInfo(Level.Game).Admin.ActionAllowed(PC, AdminPermissions.Permission_ChangeSettings))
	{
		return;
	}

	SetServerSettingsNoConfigSave(PC, newGameType, newMapIndex, newNumRounds, newMaxPlayers, newbUseRoundStartTimer,
		newPostGameTimeLimit, newbUseRoundEndTimer, newMPMissionReadyTime, newbShowTeammateNames, newUnused, newbAllowReferendums,
		newbNoRespawn, newbQuickRoundReset, newFriendlyFireAmount, newDisabledEquipment, newCampaignCOOP, newAdditionalRespawnTime,
		newbNoLeaders, newbNoKillMessages, newbEnableSnipers);

log( self$"::SetServerSettings(...) ... saving config" );
    SaveMapListForGameType();
    SaveConfig();


    // notify clients the settings were updated by the admin
	if (PC != None)
		SwatGameInfo(Level.Game).OnServerSettingsUpdated( PC );
}

///////////////////////////////////////////////////////////////////////////////
// Set a map at a specific index on the server
///////////////////////////////////////////////////////////////////////////////

function AddMap( PlayerController PC, string MapName )
{
	if(Level.Game.IsA('SwatGameInfo'))
	{
		if(!SwatGameInfo(Level.Game).Admin.ActionAllowed(PC, AdminPermissions.Permission_ChangeSettings))
		{
			return;
		}
	}

    if( NumMaps >= MAX_MAPS )
        return;

    Maps[NumMaps] = MapName;

    NumMaps++;
}

function ClearMaps( PlayerController PC )
{
    local int i;

	if(Level.Game.IsA('SwatGameInfo'))
	{
		if(!SwatGameInfo(Level.Game).Admin.ActionAllowed(PC, AdminPermissions.Permission_ChangeSettings))
		{
			return;
		}
	}

    for( i = 0; i < MAX_MAPS; i++ )
    {
        Maps[i] = "";
    }

    NumMaps=0;
}

///////////////////////////////////////////////////////////////////////////////
// Set the settings to bDirty - basically ensures a fresh reset for next round
///////////////////////////////////////////////////////////////////////////////

function SetDirty( PlayerController PC )
{
	if(Level.Game.IsA('SwatGameInfo'))
	{
		if(!SwatGameInfo(Level.Game).Admin.ActionAllowed(PC, AdminPermissions.Permission_ChangeSettings))
		{
			return;
		}
	}

	CacheBuilt = false;
    bDirty = true;
}

function MapChangingByVote(EMPMode VotedGameType)
{
	if (GameType == VotedGameType)
		return;

	GameType = VotedGameType;

	LoadMapListForGameType();

	MapIndex = 0;

	SaveConfig();
}

///////////////////////////////////////////////////////////////////////////////
// Save/Load Maplist utilities
///////////////////////////////////////////////////////////////////////////////

private function SaveMapListForGameType()
{
    local MapRotation MapRotation;
    local int i;

    MapRotation = SwatRepo(Level.GetRepo()).GuiConfig.MapList[GameType];

    for( i = 0; i < MAX_MAPS; i++ )
    {
        MapRotation.Maps[i] = Maps[i];
    }

    MapRotation.SaveConfig();
}

private function LoadMapListForGameType()
{
    local MapRotation MapRotation;
    local int i;

    MapRotation = SwatRepo(Level.GetRepo()).GuiConfig.MapList[GameType];

    for( i = 0; i < MAX_MAPS; i++ )
    {
        Maps[i] = MapRotation.Maps[i];
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Cached settings for DisabledEquipment so we aren't running repeated computations
// DO NOT call this on the client, it has its own means of caching

function bool IsEquipmentDisabled(class EquipmentClass)
{
	local int i;
	local array<string> SplitString;

	if(!CacheBuilt)
	{
		CachedDisabledEquipment.Length = 0;
		Split(DisabledEquipment, ",", SplitString);
		for(i = 0; i < SplitString.Length; i++)
		{
			CachedDisabledEquipment[i] = class<Equipment>(DynamicLoadObject(SplitString[i], class'Class'));
		}
	}
	CacheBuilt = true;

	// iterate through all of the cached disabled equipment
	for(i = 0; i < CachedDisabledEquipment.Length; i++)
	{
		if(CachedDisabledEquipment[i] == EquipmentClass)
		{
			return true;
		}
	}

	return false;
}

///////////////////////////////////////////////////////////////////////////////

function bool IsCampaignCoop()
{
	return CampaignCOOP != (-1^0);
}

function SetCampaignCoopSettings(PlayerController PC, int CampaignPath, int AvailableIndex)
{
  local int CampaignSettings;
  local int RetrievedAvailableIndex;
  local int RetrievedCampaignPath;

  CampaignSettings = 666 ^ 666;
  CampaignSettings = (AvailableIndex << 16) | CampaignPath;
  CampaignCOOP = CampaignSettings;

  RetrievedCampaignPath = CampaignSettings & 65535;
  RetrievedAvailableIndex = (CampaignSettings & -65536) >> 16;

  log("SetCampaignCoopSettings: CampaignPath="$RetrievedCampaignPath$", AvailableIndex="$RetrievedAvailableIndex$"");
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
    bShouldReplicateDefaultProperties=true
	DefaultServerName="Swat4X Server"
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
