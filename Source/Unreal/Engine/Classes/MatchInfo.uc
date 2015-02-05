class MatchInfo extends Core.Object;

var string LevelName;
var localized string MenuName;			// usually "", otherwise, override the name in the SP menus
var string EnemyTeamName;
var string SpecialEvent;
var float DifficultyModifier;
var float GoalScore;
var string URLString;
var string MenuDescription;
var int NumBots;				// number of bots in match, besides player
var string GameType;			// GameInfo class to use
var string ThumbName;			// name of a material (in form package.group.name) to use as the thumbnail
