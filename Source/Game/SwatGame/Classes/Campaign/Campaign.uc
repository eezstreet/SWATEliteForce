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

    index = GetMissionIndex(Mission);
log( "[dkaplan] getting mission results for mission " $ Mission $ ", index = " $ index );

    //(GetMissionIndex() returns MissionResults.length if Mission is not found.)
    return MissionResults[index];
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
    SaveConfig();
}
