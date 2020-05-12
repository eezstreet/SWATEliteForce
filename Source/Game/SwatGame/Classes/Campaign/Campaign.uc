class Campaign extends Core.Object
    dependsOn(SwatGUIConfig)
    config(Campaign)
    perObjectConfig;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;

var config localized string StringName;

var config array<Name> MissionResultNames;
var array<MissionResults> MissionResults;
var config private int availableIndex;  //the index of the highest mission that is unlocked in the Campaign
var config private bool HACK_HasPlayedCreditsOnCampaignCompletion;

// SEF additions
var config int CampaignPath;  // Which campaign path we're on (0 = SWAT 4 + TSS, 1 = Extra Missions, 2 = All Missions)
var config bool PlayerPermadeath; // Whether the campaign has player permadeath enabled
var config bool PlayerDied; // Player permadeath only - true if the campaign is KIA
var config bool OfficerPermadeath; // Whether the campaign has officer permadeath enabled
var config bool RedOneDead; // Whether Red One is dead.
var config bool RedTwoDead; // Whether Red Two is dead.
var config bool BlueOneDead; // Whether Blue One is dead.
var config bool BlueTwoDead; // Whether Blue Two is dead.
var config bool CustomCareerPath; // Whether this career is a Quick Mission Maker career
var config string CustomCareer; // The pack associated with this Quick Mission Maker career
var config bool HardcoreMode; // New in v7: Hardcore mode doesn't allow failure of any kind. (Player permadeath is implied)
var config bool HardcoreFailed; // Hardcore only - true if the campaign was failed

// Stats
var(Stats) config int MissionsCompleted; // The number of missions that have been successfully completed
var(Stats) config int TimesIncapacitated; // Number of times that you have been incapacitated in this campaign
var(Stats) config int TimesInjured; // Number of times that you have been injured in this campaign
var(Stats) config int OfficersIncapacitated; // Total number of officers that have been incapacitated in this campaign
var(Stats) config int PenaltiesIssued; // The number of penalties that have been issued on your campaign
var(Stats) config int SuspectsRemoved; // Total number of suspects "removed" (neutralized, incapacitated, arrested)
var(Stats) config int SuspectsNeutralized; // Total number of suspects neutralized
var(Stats) config int SuspectsIncapacitated; // Total number of suspects incapacitated
var(Stats) config int SuspectsArrested; // Total number of suspects arrested
var(Stats) config int CiviliansRestrained; // Total number of civilians restrained
var(Stats) config int TOCReports; // Total number of reports filed to TOC
var(Stats) config int EvidenceSecured; // Total number of evidence secured

overloaded function Construct()
{
    local int i;

    for (i=0; i<MissionResultNames.Length; i++)
    {
        MissionResults[i] = new(,StringName$"_"$MissionResultNames[i]) class'SwatGame.MissionResults';

        Assert(MissionResults[i] != None);
    }
}

final function int GetAvailableIndex()
{
    return AvailableIndex;
}

final function bool HasPlayedCreditsOnCampaignCompletion()
{
    return HACK_HasPlayedCreditsOnCampaignCompletion;
}

final function SetHasPlayedCreditsOnCampaignCompletion()
{
    HACK_HasPlayedCreditsOnCampaignCompletion = true;
    SaveConfig();
}

final function MissionEnded(name Mission, eDifficultyLevel difficulty, bool Completed, int Score, bool bMetDifficultyScoreRequirement)
{
    local int index;

log("[dkaplan] Adding Mission result for mission: "$Mission);
    index = GetMissionIndex(Mission);

    if( (index >= MissionResults.length) ) //mission was never played before
    {
        MissionResults[index] = new(,(StringName$"_"$Mission)) class'SwatGame.MissionResults';
        MissionResultNames[index] = Mission;
    }

    Assert( MissionResults[index] != None );

    //add this mission result
    MissionResults[index].AddResult( difficulty, Completed, Score );

    if( Completed && bMetDifficultyScoreRequirement && availableIndex == index )
        availableIndex = index + 1;

    SaveConfig();
}

//returns the MissionResults of the specified Mission.
//if the mission was played, then MissionResults.Mission will equal the Mission argument.
//otherwise, MissionResults is empty (ie. MissionResults.Mission is None)
final function MissionResults GetMissionResults(name Mission)
{
    local int index;

    if(CampaignPath == 2)
    { // In All Missions, we can complete the missions in whatever order we want to
      for(index = 0; index < MissionResultNames.length; index++)
      {
        if(MissionResultNames[index] == Mission)
        {
          return MissionResults[index];
        }
      }
    }
    else
    { // It's safe to assume we have a score, since they need to be completed sequentially
      index = GetMissionIndex(Mission);
      log( "[dkaplan] getting mission results for mission " $ Mission $ ", index = " $ index );

      //(GetMissionIndex() returns MissionResults.length if Mission is not found.)
      return MissionResults[index];
    }

}

//returns the index of Mission in MissionResults, or MissionResults.length if not found.
private function int GetMissionIndex(name Mission)
{
    local int i;

    for (i=0; i<MissionResults.length; ++i)
        if (MissionResults[i] != None && MissionResultNames[i] == Mission)
            break;

    return i;
}

function PreDelete()
{
    local int i;

    for (i=0; i<MissionResults.length; ++i)
        MissionResults[i].PreDelete();

    MissionResults.Remove( 0, MissionResults.Length );
    MissionResultNames.Remove( 0, MissionResultNames.Length );
    availableIndex = 0;
    StringName = "";
	CampaignPath = 0;
	PlayerPermadeath = false;
	PlayerDied = false;
	OfficerPermadeath = false;
	RedOneDead = false;
	RedTwoDead = false;
	BlueOneDead = false;
	BlueTwoDead = false;
	CustomCareerPath = false;
	CustomCareer = "";
	MissionsCompleted = 0;
	TimesIncapacitated = 0;
	TimesInjured = 0;
	OfficersIncapacitated = 0;
	PenaltiesIssued = 0;
	SuspectsRemoved = 0;
	SuspectsNeutralized = 0;
	SuspectsIncapacitated = 0;
	SuspectsArrested = 0;
	CiviliansRestrained = 0;
	TOCReports = 0;
	EvidenceSecured = 0;
    SaveConfig();
}
