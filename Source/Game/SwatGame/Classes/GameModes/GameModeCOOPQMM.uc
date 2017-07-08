class GameModeCOOPQMM extends GameModeMPBase;

// This is a fake game mode used during the Coop-QMM lobby level

function bool AllowRoundStart()
{
	return false;
}

function bool RequiresStartClustersCache()
{
	return false;
}