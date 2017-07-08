class ActionGetGameMode extends Scripting.Action;

import enum EMPMode from Engine.Repo;

latent function Variable execute()
{
    local string GameModeString;
    
    if( parentScript.Level.NetMode == NM_Standalone )
        GameModeString = "Standalone";
    else
        GameModeString = string(GetEnum(EMPMode, ServerSettings(parentScript.Level.CurrentServerSettings).GameType));
        
    log( self$"::execute() ... Game Mode  =  "$GameModeString );
	return newTemporaryVariable(class'VariableName', GameModeString );
}

// editorDisplayString
function editorDisplayString(out string s)
{
    s = "Get the Current Game Mode.";
}

defaultproperties
{
	actionDisplayName	= "Get the Current Game Mode."
	actionHelp			= "Get the Current Game Mode."
	returnType			= class'Variable'
	category			= "Variable"
}
