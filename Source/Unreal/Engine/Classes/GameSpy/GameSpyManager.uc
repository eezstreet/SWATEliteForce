class GameSpyManager extends Core.Object
	native;

enum EGameSpyResult
{
	GSR_VALID_PROFILE,
	GSR_USER_CONNECTED,
	GSR_REGISTERED_UNIQUE_NICK,
	GSR_UNIQUE_NICK_TAKEN,
	GSR_BAD_EMAIL,
	GSR_BAD_PASSWORD,
	GSR_BAD_NICK,
	GSR_TIMED_OUT,
	GSR_GENERAL_FAILURE
};

var GameEngine	Engine;

var const bool	bAvailable;
var const bool	bFailedAvailabilityCheck;

var const bool	bInitAsServer;
var const bool	bInitAsClient;

var const bool	bInitialised;
var const bool	bFailedInitialisation;

#if IG_SWAT
var bool bServer; // true if we're a server, false if a client
#endif

var bool				bTrackingStats;				// If true try to initialise the stat tracker
var globalconfig bool	bStatsDevServer;
var const bool			bStatsInitalised;
var private const bool	bStatsNewGame;

var const bool			bUsingPresence;				// If true try to initialise the presence sdk
var const bool			bPresenceInitalised;
var const bool			bIsUserProfileConnected;
var globalconfig string	SavedProfileNickname;
var globalconfig string	SavedProfileEmail;
var globalconfig string	SavedProfilePassword;
var string				CurrentProfilePassword;
var int					SavedProfileID;

var const bool	bServerUpdateFinished;		// Used during GetNextServer
var const int	currentServerIndex;			// Used during GetNextServer

var Array<byte> ServerKeyIds;
var Array<String> ServerKeyNames;

var Array<byte> PlayerKeyIds;
var Array<String> PlayerKeyNames;

var Array<byte> TeamKeyIds;
var Array<String> TeamKeyNames;

var Array<byte> CustomServerKeyIds;
var Array<String> CustomServerKeyNames;

var Array<byte> CustomPlayerKeyIds;
var Array<String> CustomPlayerKeyNames;

var Array<byte> CustomTeamKeyIds;
var Array<String> CustomTeamKeyNames;

// The key ids for the values that will be initially retrieved during a server update
var Array<byte> InitialKeyIds;

var private globalconfig string ProductVersionID;			// for auto-patching, build number is used if this is empty
var private globalconfig localized string ProductRegionID;	// for auto-patching
var globalconfig string BaseFilePlanetPatchURL;

var private int InitialQueryPort;

// This function initialises GameSpy as a client
// Note: This function only tells GameSpy to initialise it may take longer and wont be initialised after returning from this function
// The GameSpyInitialised event will be called once GameSpy has finished initalising.
// There is no need for a script side function to init as a server as this is done automatically in native code when a server starts
final native function InitGameSpyClient();

// This event is called once GameSpy as initialised
event GameSpyInitialised();

event OnLevelChange()
{
	SendStatSnapshot(true);
// dbeswick: maybe not needed
	SendGameSpyGameModeChange();
}

event InitGameSpyData();
final native function LevelInfo GetLevelInfo();

final native function Player GetPlayerObject();

// dbeswick: maybe not needed
final native function SendGameSpyGameModeChange();

// This function starts an update of the server list
final native function UpdateServerList(optional String filter);

// This function starts an update of the server list for the LAN
final native function LANUpdateServerList();

// This function starts an update for a specific server in the list to update server specific data (player/team data)
// serverId is the server id received in UpdatedServerData during a server list update
// if refresh is true then the update will be done even if the server data is already available
final native function UpdateServer(int serverId, bool Refresh);

// This function will cancel a previously started update of the server list
final native function CancelUpdate();

// This function returns the ip address for the given serverId
final native function String GetServerIpAddress(int serverId);

// This function returns the port for the given serverId
final native function String GetServerPort(int serverId);

// This function can be used to iterate over all the servers currently in the list
// Returns true if there is still more data, but the data may not have arrived yet
// If the data has not arrived yet serverId will be zero
final native function bool GetNextServer(out int serverId, out String ipAddress, out Array<String> serverData);

// Call this function when a new game starts to tell the stat tracking server
final native function bool StatsNewGameStarted();

// Call this function to verify that a connected player has a profile id and stat response string
final native function bool StatsHasPIDAndResponse(PlayerController pc);

// Call this function to get the profile id for the given player controller
final native function String StatsGetPID(PlayerController pc);

// Call this function to get the stat response string for the given player controller
final native function String StatsGetStatResponse(PlayerController pc);

// Call this function to send a stats challenge to the client
final native function ServerSendStatChallenge(PlayerController PC);

// Call this function to add a new player to the stat tracking server
final native function StatsNewPlayer(int PlayerId, string PlayerName);

// Call this function to remove a player from the stat tracking server
final native function StatsRemovePlayer(int PlayerId);

// Stat setting and accumulating functions
final native function SetServerStatStr(string statName, string statValue);
final native function SetPlayerStatStr(string statName, string statValue, int PlayerId);
final native function SetServerStatInt(string statName, int statValue);
final native function SetPlayerStatInt(string statName, int statValue, int PlayerId);
final native function AccumulateServerStatInt(string statName, int statValue);
final native function AccumulatePlayerStatInt(string statName, int statValue, int PlayerId);

// Call this function to get the internal gamespy player ID from the ID passed to StatsNewPlayer
final native function int StatsGetPlayerIndex(int PlayerId);

// Call this function to send a snapshot of the game stats to the stat server. Set finalSnapshot to true if the game has ended (default false)
final native function SendStatSnapshot(optional bool finalSnapshot);

// Call this function to create a new user account
final native function bool CreateUserAccount(string Nick, string Email, string Password);

// Call this function to check with GameSpy that the given account details are valid
final native function bool CheckUserAccount(string Nick, string Email, string Password);

// Call this function to connect to the GameSpy server with the given account details
final native function bool ConnectUserAccount(string Nick, string Email, string Password);

event UserConnectionResult(EGameSpyResult result, int profileId, string UniqueNick)
{
	SavedProfileID = profileID;
	SendStatResponseIfNeeded();
}

final native function SendStatResponseIfNeeded();

// Call this function to disconnect the currently connected user account
final native function DisconnectUserAccount();

// Call this function to register a unique nick for the currently connected profile
final native function RegisterUniqueNick(string UniqueNick);

event UniqueNickRegistrationResult(EGameSpyResult result);

// Call this function to authenticate a profile before trying to write private data
final native function AuthenticateProfile(int profileId, string Password);

event AuthenticatedProfileResult(int profileId, int authenticated, string error);

// This function is called each time a servers data is updated
event UpdatedServerData(int serverId, String ipAddress, int Ping, Array<String> serverData, Array<String> playerData, Array<String> teamData);

// This function is called after an update of the server list completes
event UpdateComplete();

// This function is called on the server to get the data for a particular server key
event string GetValueForKey(int key);

// This function is called on the server to get the data for a particular player key
event string GetValueForPlayerKey(int key, int index);

// This function is called on the server to get the data for a particular team key
event string GetValueForTeamKey(int key, int index);

event int GetNumTeams()
{
	return 0;
}

// Client side function to get the user's GameSpy profile id
event String GetGameSpyProfileId()
{
	return string(SavedProfileID);
}

event String GetGameSpyPassword()
{
	if (SavedProfilePassword != "")
		return default.SavedProfilePassword;
	else
		return CurrentProfilePassword;
}

event EmailAlreadyTaken();
event ProfileCreateResult(EGameSpyResult result, int profileId);
event ProfileCheckResult(EGameSpyResult result, int profileId);

#if IG_SWAT
event bool ShouldCheckClientCDKeys()
{
    Assert( false );
    return false;
}

// Call this from script code to uninitialize GameSpy.
final native function CleanUpGameSpy();

// Returns 1 if we should advertise the server on the Internet using
// GameSpy's master server, or 0 if this is just a LAN game.
event int ShouldAdvertiseServerOnInternet();

// Call this, only on the server, after the level finishes loading.
final native function SendServerStateChanged();

// This is a quick check to see if the host's CDKey is valid before allowing
// it to host. It just checks the validity locally, and doesn't connect to the
// GameSpy servers.
final native function bool IsHostCDKeyValid();

#endif

// Patching
private event string GetPatchDownloadURL(int FilePlanetID)
{
	return BaseFilePlanetPatchURL $ string(FilePlanetID);
}

// Check if a patch is required. Calls OnQueryPatchResult with the result of the query.
native function QueryPatch();

private event QueryPatchCompleted(bool bNeeded, bool bMandatory, string versionName, int fileplanetID, string URL)
{
	if (fileplanetID > 0)
	{
		OnQueryPatchResult(bNeeded, bMandatory, versionName, GetPatchDownloadURL(fileplanetID));
	}
	else
	{
		OnQueryPatchResult(bNeeded, bMandatory, versionName, URL);
	}
}

delegate OnQueryPatchResult(bool bNeeded, bool bMandatory, string versionName, string URL);

private event string GetProductVersionID()
{
	if (ProductVersionID == "")
		return GetBuildNumber();
	else
		return ProductVersionID;
}

private event string GetProductRegionID()
{
	return ProductRegionID;
}

// Stats callbacks
// this delegate is called when the server validates a player for stat tracking
delegate OnServerReceivedStatsResponse(PlayerController P, int statusCode);

private final event NotifyServerReceivePIDResponse(PlayerController P, int statusCode)
{
	OnServerReceivedStatsResponse(P, statusCode);
}

event OnLevelDestroyed()
{
	OnServerReceivedStatsResponse = None;
}

native function ConnectStats();

defaultproperties
{
    bServer=false
	BaseFilePlanetPatchURL="http://www.fileplanet.com/index.asp?file="
}

