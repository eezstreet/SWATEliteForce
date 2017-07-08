//=============================================================================
// Info, the root of all information holding classes.
//=============================================================================
class Info extends Actor
	abstract
	hidecategories(Movement,Collision,Lighting,LightColor,Karma,Force)
	native;

//------------------------------------------------------------------------------
// Structs for reporting server state data

struct native export KeyValuePair
{
	var() string Key;
	var() string Value;
};

//dkaplan:  Note that future patches to SWAT should NOT change this struct
//  Rather, additional player information should be sent as item(s) in the PlayerInfo array
//
//  This will ensure both forwards and backwards compatibility is maintained for serialization purposes
//
struct native export PlayerResponseLine
{
	var() int PlayerNum;
	var() int PlayerID;
	var() string PlayerName;
	var() int Ping;
	var() int Score;
	var() int StatsID;
	var() array<KeyValuePair> PlayerInfo;

};

//dkaplan:  Note that future patches to SWAT should NOT change this struct
//  Rather, additional server information should be sent as item(s) in the ServerInfo array
//
//  This will ensure both forwards and backwards compatibility is maintained for serialization purposes
//
struct native export ServerResponseLine
{
	var() int ServerID;
	var() string IP;
	var() int Port;
	var() int QueryPort;
	var() string ServerName;
	var() string MapName;
	var() string GameType;
#if IG_SWAT
    var() string GameVersion;
    var() string ModName;
#endif
	var() int CurrentPlayers;
	var() int MaxPlayers;
	var() int Ping;
	
	var() array<KeyValuePair> ServerInfo;
	var() array<PlayerResponseLine> PlayerInfo;
};


defaultproperties
{
	RemoteRole=ROLE_None
	NetUpdateFrequency=10
     bHidden=True
	 bOnlyDirtyReplication=true
	 bSkipActorPropertyReplication=true
}
