class ActionSetSpawnClusterEnabled extends Scripting.Action;

var() name SpawnCluster;
var() bool Enabled;

latent function Variable Execute()
{
    local GameMode TheGameMode;

    mplog( "In ActionSetSpawnClusterEnabled::Execute(). SpawnCluster="$SpawnCluster$", Enabled="$Enabled );

    TheGameMode = SwatGameInfo(parentScript.Level.Game).GetGameMode();
    if ( SpawnCluster != '' )
    {
        TheGameMode.SetSpawnClusterEnabled( SpawnCluster, Enabled );
    }

    return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
    local string SpawnClusterString;
    
    SpawnClusterString = string( SpawnCluster );
    if( SpawnClusterString == "" )
        SpawnClusterString = "a Spawn Cluster";
    
    if( Enabled )
        s = "Enable "$SpawnClusterString;
    else
        s = "Disable "$SpawnClusterString;
}

defaultproperties
{
	actionDisplayName	= "Enable/Disable a Spawn Cluster"
	actionHelp			= "Enable/Disable a Spawn Cluster"
	returnType			= None
	category			= "Script"
}
