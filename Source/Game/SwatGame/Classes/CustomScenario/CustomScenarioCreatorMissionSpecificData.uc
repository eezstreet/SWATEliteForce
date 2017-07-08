class CustomScenarioCreatorMissionSpecificData extends Core.Object
    config(CustomScenarioCreator)
    perObjectConfig;

var config localized string         PrimarySpawnPoint;
var config localized string         SecondarySpawnPoint;

var config localized array<string>  CampaignObjectiveEnemySpawn;
var config localized array<string>  CampaignObjectiveHostageSpawn;

var config int EnemySpawners;
var config int HostageSpawners;

