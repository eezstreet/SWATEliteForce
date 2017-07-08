class ActionOfficersFallIn extends Scripting.Action;

var() Name Team "Who you want to Fall-In; should be Element, Red, or Blue.";

latent function Variable execute()
{
    local SwatAICommon.OfficerTeamInfo TeamInfo;
    local Pawn Player;

    if( parentScript.Level.NetMode != NM_Standalone )
        return None;

    switch (Team)
    {
    case 'Element':
        TeamInfo = SwatAIRepository(parentScript.Level.AIRepo).GetElementSquad();
        break;
    case 'Red':
        TeamInfo = SwatAIRepository(parentScript.Level.AIRepo).GetRedSquad();
        break;
    case 'Blue':
        TeamInfo = SwatAIRepository(parentScript.Level.AIRepo).GetBlueSquad();
        break;

    default:
        assertWithDescription(false,
            "[tcohen] ActionOfficersFallIn: The 'Team' specified as "$Team
            $" is invalid.  Please specify 'Element', 'Red', or 'Blue'.");
    }

    if (TeamInfo != None)
    {
        Player = parentScript.Level.GetLocalPlayerController().Pawn;
        TeamInfo.FallIn(Player, Player.Location);
    }
    
    return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
    switch (Team)
    {
    case 'Element':
        s = "Tell the Element to Fall-In";
        break;
    case 'Red':
        s = "Tell the Red Team to Fall-In";
        break;
    case 'Blue':
        s = "Tell the Blue Team to Fall-In";
        break;
    default:
        s = "Tell an Officer Team to Fall-In";
    }
}

defaultproperties
{
	actionDisplayName	= "Tell an Officer Team to Fall-In"
	actionHelp			= "Tells an Officer Team to Fall-In"
	returnType			= None
	category			= "AI"

    Team                = Element
}
