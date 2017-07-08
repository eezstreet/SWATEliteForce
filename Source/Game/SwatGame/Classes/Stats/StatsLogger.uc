// StatsLogger
// Testing only, logs each stat function when called.
class StatsLogger extends Engine.StatsBase;

var protected SwatPlayerController Owner;
var protected SwatPlayerReplicationInfo Info;

function SetPlayer(PlayerController P)
{
	log("Created stats logger for"@P);

	Owner = SwatPlayerController(P);
	Info = SwatPlayerReplicationInfo(Owner.PlayerReplicationInfo);
	if (Info == None)
	{
		LOG("ERROR, "@name@"Info is None:"@P);
	}
}

function StatStr(string Tag, string Value, optional PlayerController Victim, optional name EquipmentClassName, optional name AmmoClassName)
{
	log("StatsLogger::StatStr: Not implemented.");
}

function StatInt(string Tag, int Value, optional PlayerController Victim, optional name EquipmentClassName, optional name AmmoClassName, optional bool bDoNotAccumulate)
{
	log("StatsLogger::StatInt: Not implemented.");
}