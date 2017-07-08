// StatsInterface
// See the stats TDD for descriptions of stat function usage.
class StatsInterface extends Core.Object;

// overrides
function SetPlayer(PlayerController P);
function SetLevel(LevelInfo L);
function StatStr(string Tag, optional string Value, optional PlayerController Victim, optional Name EquipmentClassName, optional Name AmmoClassName);
function StatInt(string Tag, optional int Value, optional PlayerController Victim, optional Name EquipmentClassName, optional Name AmmoClassName, optional bool bDoNotAccumulate);

// stat events
function Arrested(PlayerController Victim);
function Connected(int Time);
function DiffusedBomb();
function Disconnected(int Time);
function Equipped(Name EquipmentClassName);
function EscapedAsVIP();
function EscapedWithCase();
function Fired(Name EquipmentClassName, Name AmmoClassName);
function Hit(Name EquipmentClassName, PlayerController Victim);
function IsVIP();
function Killed(Name EquipmentClassName, PlayerController Victim);
function Objective();
function Rescued(PlayerController Victim);
function Score(int val);
function Skin();
function TeamChange(int TeamNum);
function TeamKilled(Name EquipmentClassName, PlayerController Victim);
function TotalScore(int score);
function Used(Name EquipmentClassName);
