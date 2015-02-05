class MissionResults extends Core.Object
    ;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;

var private MissionResult Results[eDifficultyLevel.EnumCount];

overloaded function Construct()
{
    local int i;

    for (i=0; i<eDifficultyLevel.EnumCount; i++)
    {
        Results[i] = new(,self.Name$"_"$GetEnum(eDifficultyLevel,i)) class'SwatGame.MissionResult';
//        Results[i] = MissionResult(DynamicLoadObject(self.Name$"_"$GetEnum(eDifficultyLevel,i), class'MissionResult'));

        Assert(Results[i] != None);
    }
}

function AddResult( eDifficultyLevel difficulty, bool bCompleted, int score )
{
    if( !Results[difficulty].Played )
    {
        Results[difficulty].Played = true;
        Results[difficulty].Difficulty = difficulty;
        Results[difficulty].Completed = bCompleted;
        Results[difficulty].Score = score;
    }
    else
    {
        //TODO: update logic of completion scores as necessary
        Results[difficulty].Completed = Results[difficulty].Completed || bCompleted;
        Results[difficulty].Score = Max(Results[difficulty].Score,score);
    }
    //save config on the specific result
    Results[difficulty].SaveConfig();
}

function MissionResult GetResult( eDifficultyLevel difficulty )
{
    return Results[difficulty];
}

function bool EverPlayed()
{
    local int i;

    for (i=0; i<eDifficultyLevel.EnumCount; i++)
    {
        if( Results[i].Played )
            return true;
    }
    return false;
}

function PreDelete()
{
    local int i;

    for (i=0; i<eDifficultyLevel.EnumCount; i++)
    {
        Results[i].Completed = false;
        Results[i].Score = 0;
        Results[i].Played = false;
        Results[i].SaveConfig();
    }
}