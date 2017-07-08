///////////////////////////////////////////////////////////////////////////////
//
// Stores and replicates the scoring data for a given entity in a multiplayer
// game. Each individual player has a NetScoreInfo, as well as each team.
//

class NetScoreInfo extends Engine.ReplicationInfo
    config(SwatGame);

////////////////////////////////////////////////////////////////////
// NOTE: Dynamic class variables should be reset to their initial state
//    in ResetForMPQuickRestart()
////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Multiplayer scoring
//

var int Ranking;

// Kills
var private int numEnemyKills;
var private int numFriendlyKills;
var private int numTimesDied;

var private int numKilledVIPValid;
var private int numKilledVIPInvalid;

// Arrests
var private int numArrests; // Does not include arrests of VIP in VIP mode.
var private int numTimesArrested;

// The player who is the VIP gets points for reaching the VIPGoal.
var private int numVIPPlayerEscaped;

// A Suspect player who arrests the VIP gets points.
var private int numArrestedVIP;

// A SWAT player who unarrests the VIP gets points for that.
var private int numUnarrestedVIP;

// A SWAT player who diffuses a bomb gets points for that.
var private int numBombsDiffused;

// Each person on the Suspects team get points if they win, so the crybabies
// won't feel bad that their scores are lower then SWAT's even though they won
// the round.
var private int numRDCrybaby;
var private int numSGCrybaby;

//the number of rounds the team/player has won
var private int numRoundsWon;

var private int numKilledSmashAndGrab;
var private int numEscapedSmashAndGrab;

///////////////////
//
// Points
//
var private config int pointsPerEnemyKill;
var private config int pointsPerFriendlyKill;
var private config int pointsPerTimeDied;

var private config int pointsPerArrest;
var private config int pointsPerTimeArrested;

var private config int pointsPerVIPPlayerEscaped;
var private config int pointsPerArrestedVIP;
var private config int pointsPerUnarrestedVIP;
var private config int pointsPerBombDiffused;
var private config int pointsPerRDCrybaby;
var private config int pointsPerSGCrybaby;
var private config int pointsPerKilledVIPInvalid;
var private config int pointsPerKilledVIPValid;

var private config int pointsPerSmashAndGrabPlayerEscaped;
var private config int pointsPerKilledSmashAndGrabPlayer;

///////////////////////////////////////////////////////////////////////////////

replication
{
    // Things the server should send to the client.
    reliable if (bNetDirty && (Role == Role_Authority))
        numEnemyKills, numFriendlyKills, numTimesDied, numArrests, numTimesArrested,
        numVIPPlayerEscaped, numArrestedVIP, numUnarrestedVIP, numBombsDiffused, numRDCrybaby,
        numKilledVIPValid, numKilledVIPInvalid,
		numKilledSmashAndGrab, numEscapedSmashAndGrab,
		numSGCrybaby,
        pointsPerEnemyKill, pointsPerFriendlyKill, pointsPerTimeDied,
        pointsPerArrest, pointsPerTimeArrested,
        pointsPerVIPPlayerEscaped, pointsPerArrestedVIP, pointsPerUnarrestedVIP,
        pointsPerBombDiffused, pointsPerRDCrybaby, pointsPerKilledVIPInvalid, pointsPerKilledVIPValid,
		pointsPerKilledSmashAndGrabPlayer, pointsPerSmashAndGrabPlayerEscaped,
		pointsPerSGCrybaby,
        numRoundsWon;
}


///////////////////////////////////////////////////////////////////////////////
//
// Aggregate score accessor.
//
simulated function int GetScore()
{
    //dkaplan: always return 0 for individual scores in COOP
    if( Level.IsPlayingCOOP )
        return 0;

//     mplog( self$"---NetScoreInfo::GetScore()." );
//     mplog( "...pointsPerEnemyKill="$    pointsPerEnemyKill );
//     mplog( "...pointsPerFriendlyKill="$ pointsPerFriendlyKill );
//     mplog( "...pointsPerTimeDied="$     pointsPerTimeDied );
//     mplog( "...pointsPerArrest="$       pointsPerArrest );
//     mplog( "...pointsPerTimeArrested="$pointsPerTimeArrested );
//     mplog( "...pointsPerVIPPlayerEscaped="$pointsPerVIPPlayerEscaped );
//     mplog( "...pointsPerArrestedVIP="$pointsPerArrestedVIP );
//     mplog( "...pointsPerUnarrestedVIP="$pointsPerUnarrestedVIP );
//     mplog( "...pointsPerBombDiffused="$pointsPerBombDiffused );
//     mplog( "...pointsPerRDCrybaby="$pointsPerRDCrybaby );

    return (numEnemyKills        * pointsPerEnemyKill)
         + (numFriendlyKills     * pointsPerFriendlyKill)
         + (numTimesDied         * pointsPerTimeDied)
         + (numArrests           * pointsPerArrest)
         + (numTimesArrested     * pointsPerTimeArrested)
         + (numVIPPlayerEscaped  * pointsPerVIPPlayerEscaped)
         + (numKilledVIPValid    * pointsPerKilledVIPValid)
         + (numKilledVIPInvalid  * pointsPerKilledVIPInvalid)
         + (numArrestedVIP       * pointsPerArrestedVIP)
         + (numUnarrestedVIP     * pointsPerUnarrestedVIP)
         + (numBombsDiffused     * pointsPerBombDiffused)
         + (numRDCrybaby         * pointsPerRDCrybaby)
         + (numSGCrybaby         * pointsPerSGCrybaby)
		 + (numEscapedSmashAndGrab * pointsPerSmashAndGrabPlayerEscaped)
		 + (numKilledSmashAndGrab * pointsPerKilledSmashAndGrabPlayer);
}


///////////////////////////////////////////////////////////////////////////////


simulated function int GetEnemyKills()        { return numEnemyKills; }
simulated function int GetFriendlyKills()     { return numFriendlyKills; }
simulated function int GetTimesDied()         { return numTimesDied; }
simulated function int GetArrests()           { return numArrests; }
simulated function int GetTimesArrested()     { return numTimesArrested; }
simulated function int GetVIPPlayerEscaped()  { return numVIPPlayerEscaped; }
simulated function int GetKilledVIPValid()    { return numKilledVIPValid; }
simulated function int GetKilledVIPInvalid()  { return numKilledVIPInvalid; }
simulated function int GetArrestedVIP()       { return numArrestedVIP; }
simulated function int GetUnarrestedVIP()     { return numUnarrestedVIP; }
simulated function int GetBombsDiffused()     { return numBombsDiffused; }
simulated function int GetRDCrybaby()         { return numRDCrybaby; }
simulated function int GetSGCrybaby()         { return numSGCrybaby; }
simulated function int GetRoundsWon()         { return numRoundsWon; }
simulated function int GetEscapedSG()		  { return numEscapedSmashAndGrab; }
simulated function int GetKilledSG()          { return numKilledSmashAndGrab; }


///////////////////////////////////////////////////////////////////////////////

function IncrementEnemyKills()        { numEnemyKills++; }
function IncrementFriendlyKills()     { numFriendlyKills++; }
function IncrementTimesDied()         { numTimesDied++; }
function IncrementArrests()           { numArrests++; }
function IncrementTimesArrested()     { numTimesArrested++; }
function IncrementVIPPlayerEscaped()  { numVIPPlayerEscaped++; }
function IncrementKilledVIPValid()    { numKilledVIPValid++; }
function IncrementKilledVIPInvalid()  { numKilledVIPInvalid++; }
function IncrementArrestedVIP()       { numArrestedVIP++; }
function IncrementUnarrestedVIP()     { numUnarrestedVIP++; }
function IncrementBombsDiffused()     { numBombsDiffused++; }
function IncrementRDCrybaby()         { numRDCrybaby++; }
function IncrementSGCrybaby()         { numSGCrybaby++; }
function IncrementSmashAndGrabEscaped() { numEscapedSmashAndGrab++; }
function IncrementSmashAndGrabKilled() { numKilledSmashAndGrab++; }
function SetRoundsWon( int val )      { numRoundsWon = val; }

////////////////////////////////////////////////////////////////////
// Reset the class variables to their initial state
////////////////////////////////////////////////////////////////////
function ResetForMPQuickRestart()
{
    numEnemyKills=0;
    numFriendlyKills=0;
    numTimesDied=0;
    numArrests=0;
    numTimesArrested=0;
    numVIPPlayerEscaped=0;
    numKilledVIPValid=0;
    numKilledVIPInvalid=0;
    numArrestedVIP=0;
    numUnarrestedVIP=0;
    numBombsDiffused=0;
    numRDCrybaby=0;
	numEscapedSmashAndGrab=0;
	numKilledSmashAndGrab=0;
	numSGCryBaby=0;
    
    //Note that numRoundsWon is intentionally ommitted from the reset
}
////////////////////////////////////////////////////////////////////

defaultproperties
{
    pointsPerEnemyKill=1
    pointsPerFriendlyKill=-1
    pointsPerTimeDied=0
    pointsPerArrest=3
    pointsPerTimeArrested=0
    pointsPerVIPPlayerEscaped=20
    pointsPerKilledVIPValid=10
    pointsPerKilledVIPInvalid=-51
    pointsPerArrestedVIP=10
    pointsPerUnarrestedVIP=10
    pointsPerBombDiffused=10
    pointsPerRDCryBaby=10
    pointsPerSmashAndGrabPlayerEscaped=10
    pointsPerKilledSmashAndGrabPlayer=2
    pointsPerSGCryBaby=10
}
