// SwatGameSpyManager.uc

class SwatGameSpyManager extends Engine.GameSpyManager;


const MAX_REGISTERED_KEYS	= 254;
const NUM_RESERVED_KEYS		= 50;		// GameSpy reserve key ids upto 50

// Current GameSpy key ids that can be used
// Server specific
const HOSTNAME_KEY			= 1;
const GAMENAME_KEY			= 2;
const GAMEVER_KEY			= 3;
const HOSTPORT_KEY			= 4;
const MAPNAME_KEY			= 5;
const GAMETYPE_KEY			= 6;
const GAMEVARIANT_KEY		= 7;
const NUMPLAYERS_KEY		= 8;
const NUMTEAMS_KEY			= 9;
const MAXPLAYERS_KEY		= 10;
const GAMEMODE_KEY			= 11;
const TEAMPLAY_KEY			= 12;
const FRAGLIMIT_KEY			= 13;
const TEAMFRAGLIMIT_KEY		= 14;
const TIMEELAPSED_KEY		= 15;
const TIMELIMIT_KEY			= 16;
const ROUNDTIME_KEY			= 17;
const ROUNDELAPSED_KEY		= 18;
const PASSWORD_KEY			= 19;
const GROUPID_KEY			= 20;

// Player specific
const PLAYER__KEY			= 21;
const SCORE__KEY			= 22;
const SKILL__KEY			= 23;
const PING__KEY				= 24;
const TEAM__KEY				= 25;
const DEATHS__KEY			= 26;
const PID__KEY				= 27;

// Team specific
const TEAM_T_KEY			= 28;
const SCORE_T_KEY			= 29;


// Add custom server/player/team key ids here. Must be > 50 and <= 254
// dbeswick: Server Stats
const STATSENABLED_KEY		= 51;

//const SAMPLEPLAYER__KEY		= 52; // sample player key note extra _
//const SAMPLETEAM_T_KEY		= 53; // sample team key note extra _T

var private bool bShouldCheckClientCDKeys;

delegate OnUpdatedServer(GameInfo.ServerResponseLine Server);
delegate OnGameSpyInitialised();

// This event is called once GameSpy as initialised
event GameSpyInitialised()
{
    OnGameSpyInitialised();
}

function InitGameSpyData()
{
	mplog( "SwatGameSpyManager::InitGameSpyData()." );

    //
	// Init server keys
    //

    // The server's name, like "Joe's Game"
	ServerKeyIds[ServerKeyIds.Length] = HOSTNAME_KEY;
	ServerKeyNames[ServerKeyNames.Length] = "hostname";

	ServerKeyIds[ServerKeyIds.Length] = NUMPLAYERS_KEY;
	ServerKeyNames[ServerKeyNames.Length] = "numplayers";

	ServerKeyIds[ServerKeyIds.Length] = MAXPLAYERS_KEY;
	ServerKeyNames[ServerKeyNames.Length] = "maxplayers";

	ServerKeyIds[ServerKeyIds.Length] = GAMETYPE_KEY;
	ServerKeyNames[ServerKeyNames.Length] = "gametype";

	ServerKeyIds[ServerKeyIds.Length] = GAMEVARIANT_KEY;
	ServerKeyNames[ServerKeyNames.Length] = "gamevariant";

	ServerKeyIds[ServerKeyIds.Length] = MAPNAME_KEY;
	ServerKeyNames[ServerKeyNames.Length] = "mapname";

    // Do we actually need this, or can we get the port from the server list?
	ServerKeyIds[ServerKeyIds.Length] = HOSTPORT_KEY;
	ServerKeyNames[ServerKeyNames.Length] = "hostport";

	ServerKeyIds[ServerKeyIds.Length] = PASSWORD_KEY;
	ServerKeyNames[ServerKeyNames.Length] = "password";

	ServerKeyIds[ServerKeyIds.Length] = GAMEVER_KEY;
	ServerKeyNames[ServerKeyNames.Length] = "gamever";

	//ServerKeyIds[ServerKeyIds.Length] = NUMTEAMS_KEY;
	//ServerKeyNames[ServerKeyNames.Length] = "numteams";

	// Init player keys
	PlayerKeyIds[PlayerKeyIds.Length] = PLAYER__KEY;
	PlayerKeyNames[PlayerKeyNames.Length] = "player_"; // Note: player key names end in _ (same goes for custom player keys)

	PlayerKeyIds[PlayerKeyIds.Length] = SCORE__KEY;
	PlayerKeyNames[PlayerKeyNames.Length] = "score_"; // Note: player key names end in _ (same goes for custom player keys)

	PlayerKeyIds[PlayerKeyIds.Length] = PING__KEY;
	PlayerKeyNames[PlayerKeyNames.Length] = "ping_"; // Note: player key names end in _ (same goes for custom player keys)

	// Init team keys
	//TeamKeyIds[TeamKeyIds.Length] = TEAM_T_KEY;
	//TeamKeyNames[TeamKeyNames.Length] = "team_t"; // Note: team key names end in _t (same goes for custom team keys)

	// Init custom server keys
	// dbeswick: stats
	CustomServerKeyIds[CustomServerKeyIds.Length] = STATSENABLED_KEY;
	CustomServerKeyNames[CustomServerKeyNames.Length] = "statsenabled";

	// Init custom player keys

	// Init custom team keys

	checkKeyIds();
	checkKeyNames();
}

function checkKeyIds()
{
	local int i;

	mplog( "SwatGameSpyManager::checkKeyIds()." );

	assert(ServerKeyIds.Length +
		   PlayerKeyIds.Length +
		   TeamKeyIds.Length +
		   CustomServerKeyIds.Length +
		   CustomPlayerKeyIds.Length +
		   CustomTeamKeyIds.Length <= MAX_REGISTERED_KEYS);

	for (i = 0; i < ServerKeyIds.Length; ++i)
		assert(ServerKeyIds[i] > 0 && ServerKeyIds[i] <= 50);

	for (i = 0; i < PlayerKeyIds.Length; ++i)
		assert(PlayerKeyIds[i] > 0 && PlayerKeyIds[i] <= 50);

	for (i = 0; i < TeamKeyIds.Length; ++i)
		assert(TeamKeyIds[i] > 0 && TeamKeyIds[i] <= 50);

	for (i = 0; i < CustomServerKeyIds.Length; ++i)
		assert(CustomServerKeyIds[i] > 50 && CustomServerKeyIds[i] <= 254);

	for (i = 0; i < CustomPlayerKeyIds.Length; ++i)
		assert(CustomPlayerKeyIds[i] > 50 && CustomPlayerKeyIds[i] <= 254);

	for (i = 0; i < CustomTeamKeyIds.Length; ++i)
		assert(CustomTeamKeyIds[i] > 50 && CustomTeamKeyIds[i] <= 254);
}

function checkKeyNames()
{
	local int i;

	mplog( "SwatGameSpyManager::checkKeyNames()." );

	for (i = 0; i < ServerKeyNames.Length; ++i)
		assert(Right(ServerKeyNames[i], 1) != "_" && Right(ServerKeyNames[i], 2) != "_t");

	for (i = 0; i < CustomServerKeyNames.Length; ++i)
		assert(Right(CustomServerKeyNames[i], 1) != "_" && Right(CustomServerKeyNames[i], 2) != "_t");

	for (i = 0; i < PlayerKeyNames.Length; ++i)
		assert(Right(PlayerKeyNames[i], 1) == "_");

	for (i = 0; i < CustomPlayerKeyNames.Length; ++i)
		assert(Right(CustomPlayerKeyNames[i], 1) == "_");

	for (i = 0; i < TeamKeyNames.Length; ++i)
		assert(Right(TeamKeyNames[i], 2) == "_t");

	for (i = 0; i < CustomTeamKeyNames.Length; ++i)
		assert(Right(CustomTeamKeyNames[i], 2) == "_t");
}

function bool SwatGetNextServer(out GameInfo.ServerResponseLine Server)
{
	local Array<String> serverData;
	local bool notDone;
    local GameInfo.KeyValuePair kvp;

#if !IG_THIS_IS_SHIPPING_VERSION
	mplog( "SwatGameSpyManager::SwatGetNextServer()." );
#endif

	notDone = GetNextServer(Server.ServerId, Server.IP, serverData);

    // HOSTNAME_KEY, NUMPLAYERS_KEY, GAMETYPE_KEY, MAPNAME_KEY, HOSTPORT_KEY, STATSENABLED_KEY
	if (Server.ServerId != 0)
	{
		Server.ServerName = serverData[0];
		Server.CurrentPlayers = int(serverData[1]);
        Server.MaxPlayers = int(serverData[2]);
		Server.GameType = serverData[3];
		Server.ModName = serverData[4];
		Server.Mapname = serverData[5];
		Server.Port = int(serverData[6]);

        kvp.Key = "password";
        kvp.Value = serverData[7];
        Server.ServerInfo[0] = kvp;

        kvp.Key = "statsenabled";
        kvp.Value = serverData[9];
        Server.ServerInfo[1] = kvp;

		Server.GameVersion = serverData[8];

#if !IG_THIS_IS_SHIPPING_VERSION
		mplog( "...mapname="$Server.Mapname );
#endif
	}

	return notDone;
}


event UpdatedServerData(int serverId, String ipAddress, int Ping, Array<String> serverData, Array<String> playerData, Array<String> teamData)
{
    local GameInfo.ServerResponseLine Server;
    local GameInfo.KeyValuePair kvp;

	//log("PING IS "$ping$" FOR SERVER "$serverData[0]);
    assert(serverId != 0);
    if (serverId != 0)
    {
        Server.ServerId         = serverId;
        Server.IP               = ipAddress;
        Server.Ping             = Ping; // not strictly needed, since we re-ping later
        Server.ServerName       = serverData[0];
        Server.CurrentPlayers   = int(serverData[1]);
        Server.MaxPlayers       = int(serverData[2]);
        Server.GameType         = serverData[3];
        Server.ModName          = serverData[4];
        Server.Mapname          = serverData[5];
        Server.Port             = int(serverData[6]);

        kvp.Key = "password";
        kvp.Value = serverData[7];
        Server.ServerInfo[0] = kvp;

        kvp.Key = "statsenabled";
        kvp.Value = serverData[9];
        Server.ServerInfo[1] = kvp;

        Server.GameVersion      = serverData[8];

        OnUpdatedServer(Server);
    }
}

function UpdateComplete()
{
	mplog( "SwatGameSpyManager::UpdateComplete()." );

	// Do anything you want to do when a server list update completes
}

// This function is how GameSpy gets the info about our server that is
// transmits to the master server. It should returns strings for all keys'
// values.

function string GetValueForKey(int key)
{
#if !IG_THIS_IS_SHIPPING_VERSION
	mplog( "SwatGameSpyManager::GetValueForKey()." );
#endif

    // HOSTNAME_KEY, NUMPLAYERS_KEY, GAMETYPE_KEY, MAPNAME_KEY, HOSTPORT_KEY, STATSENABLED_KEY
	switch(key)
	{
	case HOSTNAME_KEY:
		return GetLevelInfo().Game.GameReplicationInfo.ServerName;

	case NUMPLAYERS_KEY:
		return String(GetLevelInfo().Game.NumberOfPlayersForServerBrowser());

	case MAXPLAYERS_KEY:
		return String(GetLevelInfo().Game.MaxPlayersForServerBrowser());

	case GAMETYPE_KEY:
        //log( "...SwatGameSpyManager...GameModeString="$GetLevelInfo().Game.GameModeString );
		return GetLevelInfo().Game.GetGameModeName();

	case GAMEVARIANT_KEY:
        return GetLevelInfo().ModName;

	case MAPNAME_KEY:
		if (GetLevelInfo() != None)
			return GetLevelInfo().Title;
		break;

	case HOSTPORT_KEY:
		return String(GetLevelInfo().Game.GetServerPort());

	case PASSWORD_KEY:
        if ( GetLevelInfo().Game.GameIsPasswordProtected() )
            return "1";
        else
            return "0";

	case GAMEVER_KEY:
		return GetLevelInfo().BuildVersion;

	case STATSENABLED_KEY: // dbeswick: stats
		if (bTrackingStats)
			return "1";
		else
			return "0";
	}

	return "";
}

function string GetValueForPlayerKey(int key, int index)
{
	local PlayerController pc;

#if !IG_THIS_IS_SHIPPING_VERSION
	mplog( "SwatGameSpyManager::GetValueForPlayerKey()." );
#endif

	pc = GetPlayerControllerFromIndex(index);

	if (pc == None)
		return "";

	switch (key)
	{
    case PLAYER__KEY:
        return GetLevelInfo().Game.GetPlayerName( pc );
    case SCORE__KEY:
        return String( GetLevelInfo().Game.GetPlayerScore( pc ));
    case PING__KEY:
        return String( Min( 999, GetLevelInfo().Game.GetPlayerPing( pc )));
	}

	return "";
}

function PlayerController GetPlayerControllerFromIndex(int index)
{
	local int i;
	local LevelInfo li;
	local Controller c;
	local PlayerController pc;

#if !IG_THIS_IS_SHIPPING_VERSION
	mplog( "SwatGameSpyManager::GetPlayerControllerFromIndex()." );
#endif

	li = GetLevelInfo();

	if (li == None)
		return None;

	i = 0;
	For (c = li.ControllerList; c != None; c = c.NextController)
	{
		pc = PlayerController(c);

		if (pc != None)
		{
			if (i == index)
				return pc;

			++i;
		}
	}

	return None;
}


event bool ShouldCheckClientCDKeys()
{
    return false;
	//bInitAsServer && bShouldCheckClientCDKeys;
}

function SetShouldCheckClientCDKeys( bool NewValue )
{
	return;
	/*mplog( "---SGSM::SetShouldCheckClientCDKeys(). Value="$NewValue );
    bShouldCheckClientCDKeys = NewValue;*/
}

// Returns true if we should advertise the server on the Internet using
// GameSpy's master server, or false if this is just a LAN game.
event int ShouldAdvertiseServerOnInternet()
{
    local Repo theRepo;

    // Get the Repo out of the Engine variable.
    theRepo = Engine.GetRepo();
    Assert( theRepo != None );
    
    if ( theRepo.IsLANOnlyGame() )
    {
        log( "ShouldAdvertiseServerOnInternet() returning 0" );
        return 0;
    }
    else
    {
        log( "ShouldAdvertiseServerOnInternet() returning 1" );
        return 1;
    }
}

event EmailAlreadyTaken()
{
	OnProfileResult(GSR_BAD_EMAIL, 0);
}

event ProfileCreateResult(EGameSpyResult result, int profileId)
{
	OnProfileResult(result, profileID);
}

event ProfileCheckResult(EGameSpyResult result, int profileId)
{
	OnProfileResult(result, profileID);
}

event UserConnectionResult(EGameSpyResult result, int profileId, string UniqueNick)
{
	Super.UserConnectionResult(result, profileID, UniqueNick);
	OnProfileResult(result, profileID);
}

delegate OnProfileResult(EGameSpyResult result, int profileId);

defaultproperties
{
	bTrackingStats=false
	bUsingPresence=true
    bShouldCheckClientCDKeys=false
}
