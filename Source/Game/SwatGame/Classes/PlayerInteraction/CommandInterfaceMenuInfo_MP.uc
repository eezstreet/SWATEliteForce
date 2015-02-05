class CommandInterfaceMenuInfo_MP extends CommandInterfaceMenuInfo
    config(CommandInterfaceMenus_MP);

import enum EMPMode from Engine.Repo;

// dbeswick: coop specific, only leaders may access
var config bool				LeaderOnly;

//the menu that this MenuInfo represents will be available if the current MPMode is listed
//  in the AvailableIn list, or if there are no AvailableIn modes listed.
var config array<EMPMode>	AvailableIn;

function bool IsAvailable(LevelInfo Level, CommandInterface CI)
{
    local int i;
    local EMPMode MPMode;
    local SwatGamePlayerController Player;
	local ServerSettings Settings;

	Player = SwatGamePlayerController(Level.GetLocalPlayerController());

	//return early if the player is dead or has no pawn to issue commands from
	if( Player == None )
		return false;

	Settings = ServerSettings(Level.CurrentServerSettings);

	// check for leader only
	if (LeaderOnly && Settings != None && !Settings.bNoLeaders)
	{
		if( SwatPlayerReplicationInfo(Player.PlayerReplicationInfo) != None 
			&& !SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).IsLeader )
		{
			return false;
		}
	}
    
    if (AvailableIn.length == 0)
        return true;    //this menu is available in any MP game mode

    //this menu is only available in specific MP game modes

    MPMode = ServerSettings(Level.CurrentServerSettings).GameType;
    for (i=0; i<AvailableIn.length; ++i)
        if (AvailableIn[i] == MPMode)
            return true;    //this menu is available in the current MP game mode

    return false;   //the current MP game mode is not listed in the AvailableIn list
}
