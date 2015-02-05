class Admin extends PlayerController;

replication
{
	reliable if( Role<ROLE_Authority )
		RestartMap, Switch, Kick, KickBan, Admin;
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	AddCheats();
}

// Execute an administrative console command on the server.
exec function Admin( string CommandLine )
{
	local string Result;

	Result = ConsoleCommand( CommandLine );
	if( Result!="" )
		ClientMessage( Result );
}

exec function KickBan( string S )
{
#if !IG_SWAT //kicking handled by swat admin class
	Level.Game.KickBan(S);
#endif
}

// center print admin messages which start with #
exec function Say( string Msg )
{
	local controller C;

	if ( left(Msg,1) == "#" )
	{
		Msg = right(Msg,len(Msg)-1);
		for( C=Level.ControllerList; C!=None; C=C.nextController )
			if( C.IsA('PlayerController') )
			{
				PlayerController(C).ClearProgressMessages();
				PlayerController(C).SetProgressTime(6);
				PlayerController(C).SetProgressMessage(0, Msg, class'Canvas'.Static.MakeColor(255,255,255));
			}
		return;
	}
	Super.Say(Msg);
}

exec function Kick( string S )
{
#if !IG_SWAT //kicking handled by swat admin class
	Level.Game.Kick(S);
#endif
}

exec function PlayerList()
{
	local PlayerReplicationInfo PRI;

	log("Player List:");
	ForEach DynamicActors(class'PlayerReplicationInfo', PRI)
		log(PRI.PlayerName@"( ping"@PRI.Ping$")");
}

exec function RestartMap()
{
	ClientTravel( "?restart", TRAVEL_Relative, false );
}

exec function Switch( string URL )
{
	Level.ServerTravel( URL, false );
}

defaultproperties
{
}