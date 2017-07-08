//=============================================================================
// GameRules.
//
// The GameRules class handles game rule modifications for the GameInfo such as scoring, 
// finding player starts, and damage modification.
//
//=============================================================================
class GameRules extends Info;

var GameRules NextGameRules;

function AddGameRules(GameRules GR)
{
	if ( NextGameRules == None )
		NextGameRules = GR;
	else
		NextGameRules.AddGameRules(GR);
}

/* Override GameInfo FindPlayerStart() - called by GameInfo.FindPlayerStart()
if a NavigationPoint is returned, it will be used as the playerstart
*/
function NavigationPoint FindPlayerStart( Controller Player, optional byte InTeam, optional string incomingName )
{
	if ( NextGameRules != None )
		return NextGameRules.FindPlayerStart(Player,InTeam,incomingName);

	return None;
}

/* return string containing game rules information
*/
function string GetRules()
{
	local string ResultSet;

	if ( NextGameRules == None )
		ResultSet = ResultSet$NextGameRules.GetRules();

	return ResultSet;
}

//
// server querying
// append the mutator name- only used if mutator adds me and deletes itself.
function GetServerDetails( out GameInfo.ServerResponseLine ServerState );

//
// Restart the game.
//
function bool HandleRestartGame()
{
	if ( (NextGameRules != None) && NextGameRules.HandleRestartGame() )
		return true;
	return false;
}

/* CheckEndGame()
Allows modification of game ending conditions.  Return false to prevent game from ending
*/
function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
	if ( NextGameRules != None )
		return NextGameRules.CheckEndGame(Winner,Reason);

	return true;
}

/* CheckScore()
see if this score means the game ends
return true to override gameinfo checkscore, or if game was ended (with a call to Level.Game.EndGame() )
*/
function bool CheckScore(PlayerReplicationInfo Scorer)
{
	if ( NextGameRules != None )
		return NextGameRules.CheckScore(Scorer);

	return false;
}

#if !IG_SWAT // ckline: we don't support this
/* OverridePickupQuery()
when pawn wants to pickup something, gamerules given a chance to modify it.  If this function 
returns true, bAllowPickup will determine if the object can be picked up.
*/
function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
{
	if ( (NextGameRules != None) &&  NextGameRules.OverridePickupQuery(Other, item, bAllowPickup) )
		return true;
	return false;
}
#endif

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	if ( (NextGameRules != None) && NextGameRules.PreventDeath(Killed,Killer, damageType,HitLocation) )
		return true;
	return false;
}

function bool PreventSever(Pawn Killed, Name boneName, int Damage, class<DamageType> DamageType)
{
	if ( (NextGameRules != None) && NextGameRules.PreventSever(Killed, boneName, Damage, DamageType) )
		return true;
	return false;
}

function ScoreObjective(PlayerReplicationInfo Scorer, Int Score)
{
	if ( NextGameRules != None )
		NextGameRules.ScoreObjective(Scorer,Score);
}

function ScoreKill(Controller Killer, Controller Killed)
{
	if ( NextGameRules != None )
		NextGameRules.ScoreKill(Killer,Killed);
}

function bool CriticalPlayer(Controller Other)
{
	if ( (NextGameRules != None) && (NextGameRules.CriticalPlayer(Other)) )
		return true;

	return false;
}
		
function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
	if ( NextGameRules != None )
		return NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );
	return Damage;
}

defaultproperties
{
}