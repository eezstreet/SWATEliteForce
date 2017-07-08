class GameMessage extends LocalMessage;

var localized string	      SwitchLevelMessage;
var localized string	      LeftMessage;
var localized string	      FailedTeamMessage;
var localized string	      FailedPlaceMessage;
var localized string	      FailedSpawnMessage;
var localized string	      EnteredMessage;
var	localized string	      MaxedOutMessage;
var localized string OvertimeMessage;
var localized string GlobalNameChange;
var localized string NewTeamMessage;
var localized string NewTeamMessageTrailer;
var localized string	NoNameChange;
var localized string VoteStarted;
var localized string VotePassed;
var localized string MustHaveStats;

var localized string NewPlayerMessage;

//
// Messages common to GameInfo derivatives.
//
static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Core.Object OptionalObject
	)
{
	switch (Switch)
	{
		case 0:
			return Default.OverTimeMessage;
			break;
		case 1:
			if (RelatedPRI_1 == None)
                return Default.NewPlayerMessage;

			return RelatedPRI_1.playername$Default.EnteredMessage;
			break;
		case 2:
			if (RelatedPRI_1 == None)
				return "";

			return RelatedPRI_1.OldName@Default.GlobalNameChange@RelatedPRI_1.PlayerName;
			break;
		case 3:
			if (RelatedPRI_1 == None)
				return "";
			if (OptionalObject == None)
				return "";

            return RelatedPRI_1.playername@Default.NewTeamMessage@TeamInfo(OptionalObject).GetHumanReadableName()$Default.NewTeamMessageTrailer;
			break;
		case 4:
			if (RelatedPRI_1 == None)
				return "";

			return RelatedPRI_1.playername$Default.LeftMessage;
			break;
		case 5:
			return Default.SwitchLevelMessage;
			break;
		case 6:
			return Default.FailedTeamMessage;
			break;
		case 7:
			return Default.MaxedOutMessage;
			break;
		case 8:
			return Default.NoNameChange;
			break;
        case 9:
            return RelatedPRI_1.playername@Default.VoteStarted;
            break;
        case 10:
            return Default.VotePassed;
            break;
        case 11:
			return Default.MustHaveStats;
			break;
	}
	return "";
}

defaultproperties
{
	NewPlayerMessage="A new player entered the game."
	OverTimeMessage="Score tied at the end of regulation. Sudden Death Overtime!!!"
	GlobalNameChange="changed name to"
	NewTeamMessage="is now on"
	NewTeamMessageTrailer=""
    SwitchLevelMessage="Switching Levels"
    MaxedOutMessage="Server is already at capacity."
    EnteredMessage=" entered the game."
	FailedTeamMessage="Could not find team for player"
	FailedPlaceMessage="Could not find a starting spot"
	FailedSpawnMessage="Could not spawn player"
    LeftMessage=" left the game."
    NoNameChange="Name is already in use."
    MustHaveStats="Must have stats enabled to join this server."
    VoteStarted="started a vote."
    VotePassed="Vote passed."
    bIsSpecial=false
	bIsConsoleMessage=true
}