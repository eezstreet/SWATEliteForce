class StatsGamespy extends Engine.StatsBase;

var protected SwatPlayerController Owner;
var protected SwatPlayerReplicationInfo Info;

function SetPlayer(PlayerController P)
{
	log("Created Gamespy stats logger for"@P);

	Owner = SwatPlayerController(P);
	Info = SwatPlayerReplicationInfo(Owner.PlayerReplicationInfo);
	if (Info == None)
	{
		LOG("ERROR, "@name@"Info is None:"@P);
	}
}

function string AppendKey(string Key, coerce string Append)
{
	return Key $ "-" $ Repl(Append, "_", "");
}

function NewPlayer()
{
	if (!Info.bStatsNewPlayer && Level.GetGamespyManager().bStatsInitalised)
	{
		log("[Stats] Added player"@Info.PlayerName@"with id"@Info.PlayerID);
		Level.GetGamespyManager().StatsNewPlayer(Info.PlayerID, Info.PlayerName);
		Info.bStatsNewPlayer = true;
	}
}

function string ConstructKey(string Tag, PlayerController Victim, Name EquipmentClassName, Name AmmoClassName)
{
	local SwatPlayerReplicationInfo VictimInfo;
	local string Key;

	Key = Tag;

	if (EquipmentClassName != '')
	{
		Key = AppendKey(Key, EquipmentClassName);
	}

	if (AmmoClassName != '')
	{
		Key = AppendKey(Key, AmmoClassName);
	}

	if (Victim != None)
	{
		VictimInfo = SwatPlayerReplicationInfo(Victim.PlayerReplicationInfo);
		
		if (VictimInfo != None)
			Key = AppendKey(Key, Level.GetGamespyManager().StatsGetPlayerIndex(VictimInfo.PlayerID));
	}

	return Key;
}

function StatStr(string Tag, string Value, optional PlayerController Victim, optional name EquipmentClassName, optional name AmmoClassName)
{
	local string Key;

	Key = ConstructKey(Tag, Victim, EquipmentClassName, AmmoClassName);

	if (Owner != None)
	{
		NewPlayer();
		Level.GetGamespyManager().SetPlayerStatStr(Key, Value, Info.PlayerID);
	}
	else
		Level.GetGamespyManager().SetServerStatStr(Key, Value);
}

function StatInt(string Tag, int Value, optional PlayerController Victim, optional name EquipmentClassName, optional name AmmoClassName, optional bool bDoNotAccumulate)
{
	local string Key;

	Key = ConstructKey(Tag, Victim, EquipmentClassName, AmmoClassName);

	if (!bDoNotAccumulate)
	{
		if (Owner != None)
		{
			NewPlayer();
			Level.GetGamespyManager().AccumulatePlayerStatInt(Key, Value, Info.PlayerID);
		}
		else
		{
			Level.GetGamespyManager().AccumulateServerStatInt(Key, Value);
		}
	}
	else
	{
		if (Owner != None)
		{
			NewPlayer();
			Level.GetGamespyManager().SetPlayerStatInt(Key, Value, Info.PlayerID);
		}
		else
		{
			Level.GetGamespyManager().SetServerStatInt(Key, Value);
		}
	}
}