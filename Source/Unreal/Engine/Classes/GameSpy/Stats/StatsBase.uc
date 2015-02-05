// StatsBase
// Server-side only.
class StatsBase extends StatsInterface;

var LevelInfo Level;

// construct
overloaded function Construct()
{
}

// overrides
function SetLevel(LevelInfo L)
{
	Level = L;
}

function SetPlayer(PlayerController P) {}

function StatStr(string Tag, optional string Value, optional PlayerController Victim, optional Name EquipmentClassName, optional Name AmmoClassName) {}
function StatInt(string Tag, optional int Value, optional PlayerController Victim, optional Name EquipmentClassName, optional Name AmmoClassName, optional bool bDoNotAccumulate) {}

// stat events
function Arrested(PlayerController Victim)
{
	StatInt("arrested", 1, Victim);
}

function Connected(int Time)
{
	StatInt("ctime", Time);
}

function Disconnected(int Time)
{
	StatInt("dtime", Time);
}

function Equipped(Name EquipmentClassName)
{
	StatInt("equipped", 1, None, EquipmentClassName);
}

function Fired(Name EquipmentClassName, Name AmmoClassName)
{
	StatInt("fired", 1, None, EquipmentClassName, AmmoClassName);
}

function Hit(Name EquipmentClassName, PlayerController Victim)
{
	StatInt("hit", 1, Victim, EquipmentClassName);
}

function IsVIP()
{
	StatInt("isvip", 1);
}

function Killed(Name EquipmentClassName, PlayerController Victim)
{
	StatInt("killed", 1, Victim, EquipmentClassName);
}

function Objective()
{
	StatInt("objective", 1);
}

function Rescued(PlayerController Victim)
{
	StatInt("rescued", 1, Victim);
}

function Skin()
{
	StatStr("skin", "FIXME");
}

function TeamChange(int TeamNum)
{
	StatInt("team", TeamNum, None, '', '', true);
}

function TeamKilled(Name EquipmentClassName, PlayerController Victim)
{
	StatInt("teamkilled", 1, Victim, EquipmentClassName);
}

function Used(Name EquipmentClassName)
{
	StatInt("used", 1, None, EquipmentClassName);
}

function EscapedAsVIP()
{
	StatInt("escapedasvip", 1);
}

function EscapedWithCase()
{
	StatInt("escapedwithcase", 1);
}

function DiffusedBomb()
{
	StatInt("diffusedbomb", 1);
}

function Score(int val)
{
	StatInt("score", val, None, '', '', true);
}
