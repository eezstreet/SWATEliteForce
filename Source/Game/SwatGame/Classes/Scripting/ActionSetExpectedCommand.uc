class ActionSetExpectedCommand extends Scripting.Action;

var() name ExpectedCommand "Should be in the form of 'Command_FallIn'.  See content/system/PlayerInterface_Command.ini for all of the commands.";
var() name ExpectedCommandTeam "Should be (empty), Element, RedTeam, or BlueTeam";
var() name ExpectedCommandTargetDoor "The Label of Door to which the ExpectedCommand should refer.";
var() name ExpectedCommandSource "The expected Label of the source giving the command. Valid labels are: an empty string (the source doesn't matter), Player, RedTeam, BlueTeam, OfficerRedOne, OfficerRedTwo, OfficerBlueOne, OfficerBlueTwo";

latent function Variable execute()
{
    local CommandInterface CommandInterface;

    if( parentScript.Level.NetMode != NM_Standalone )
        return None;

    CommandInterface = SwatGamePlayerController(parentScript.Level.GetLocalPlayerController()).GetCommandInterface();
    
    CommandInterface.SetExpectedCommand(
            ExpectedCommand,
            ExpectedCommandTeam,
            ExpectedCommandTargetDoor,
            ExpectedCommandSource);

    return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
    s = "Set the ExpectedCommand to ["$ExpectedCommand
        $"], the ExpectedCommandTeam to ["$ExpectedCommandTeam
        $"], and the ExpectedCommandTargetDoor to ["$ExpectedCommandTargetDoor
        $"], and the ExpectedCommandSource to ["$ExpectedCommandSource
        $"]";
}

defaultproperties
{
	actionDisplayName	= "Set the CommandInterface ExpectedCommand & ExpectedCommandTeam"
	actionHelp			= "Sets the ExpectedCommand and ExpectedCommandTeam for the current CommandInterface.  The CommandInterface will only send the specified command to the specified team."
	returnType			= None
	category			= "Script"
}
