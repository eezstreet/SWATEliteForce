class MissionResult extends Core.Object
    config(MissionResults)
    perObjectConfig;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;

//TODO: remove this if not really necessary
var config eDifficultyLevel Difficulty;
var config bool Completed;
var config int Score;
var config bool Played;