class CoopQMMReplicationInfo extends Engine.ReplicationInfo
	placeable;

const MAX_OBJECTIVES = 20;
const MAX_HOSTAGES = 80;
const MAX_ENEMIES = 80;

var bool ValidQMMData;

// QMM mission panel data
var String MissionName;
var bool CampaignObjectivesChecked;
var bool NoTimeLimitChecked;
var int TimeLimit;
var String Difficulty;
var String AvailableObjectives[MAX_OBJECTIVES];
var String SelectedObjectives[MAX_OBJECTIVES];
var bool Primary;
var bool PrimaryEnabled;
var bool Secondary;
var bool SecondaryEnabled;
var bool Either;
var bool EitherEnabled;

// QMM hostages panel data
var bool CampaignHostagesChecked;
var String AvailableHostages[MAX_HOSTAGES];
var String SelectedHostages[MAX_HOSTAGES];
var int HostageCountMin;
var int HostageCountMax;
var int HostageCountMinValue;
var int HostageCountMaxValue;
var float HostageMoraleMin;
var float HostageMoraleMax;

// QMM enemies panel data
var bool CampaignEnemiesChecked;
var String AvailableEnemies[MAX_ENEMIES];
var String SelectedEnemies[MAX_ENEMIES];
var int EnemyCountMin;
var int EnemyCountMax;
var int EnemyCountMinValue;
var int EnemyCountMaxValue;
var String EnemySkill;
var float EnemyMoraleMin;
var float EnemyMoraleMax;
var String PrimaryWeaponType;
var String PrimaryWeaponSpecific;
var String SecondaryWeaponType;
var String SecondaryWeaponSpecific;
var bool PrimaryWeaponSpecificEnabled;
var bool SecondaryWeaponSpecificEnabled;

// QMM notes panel data
var String Notes;

replication
{
	reliable if ( Role == ROLE_Authority )
		ValidQMMData, MissionName, CampaignObjectivesChecked, NoTimeLimitChecked, TimeLimit, Difficulty, AvailableObjectives,
		SelectedObjectives, Primary, PrimaryEnabled, Secondary, SecondaryEnabled, Either, EitherEnabled, CampaignHostagesChecked,
		AvailableHostages, SelectedHostages, HostageCountMin, HostageCountMax, HostageCountMinValue, HostageCountMaxValue,
		HostageMoraleMin, HostageMoraleMax, CampaignEnemiesChecked, AvailableEnemies, SelectedEnemies, EnemyCountMin, EnemyCountMax,
		EnemyCountMinValue, EnemyCountMaxValue, EnemySkill, EnemyMoraleMin, EnemyMoraleMax, PrimaryWeaponType, PrimaryWeaponSpecific,
		SecondaryWeaponType, SecondaryWeaponSpecific, PrimaryWeaponSpecificEnabled, SecondaryWeaponSpecificEnabled, Notes;
}