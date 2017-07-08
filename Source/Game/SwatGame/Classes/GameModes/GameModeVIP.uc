// GameModeVIP.uc

// What do we need for VIP mode?
//
// 1. We need a VIP goal point, with goal spawners and the actual goal
//    objects. The object needs a distinctive visual appearance.
//
// 2. I need to select one of the officers as the VIP. The VIP needs an
//    altered loadout and a different visual appearance.
//
// 3. I need to play a HUD message for the person who is the VIP.
//
// 4. Respawning is like Rapid Deployment.
//
// 5. HUD message for when the VIP is cuffed.
//
// 6. Designer settable countdown timer starting when the VIP is cuffed. The
//    round ends when the timer reaches zero.
//
// 7. There's 
//
// For now, put the texture VestMaterials=Material'mp_OfficerTex.VIPvest' to
// give the VIP a pink vest.
//

class GameModeVIP extends GameModeMPBase
    implements IInterested_GameEvent_PawnUnarrestBegan,
               IInterested_GameEvent_PawnUnarrested,
               IInterested_GameEvent_VIPReachedGoal
    dependsOn(SwatGameInfo);

import enum ESwatRoundOutcome from SwatGameInfo;
import enum eSwatGameState from SwatGame.SwatGUIConfig;

var private Timer respawnTimer;

// For testing only, until we get the new VIP mesh.
var private Material VIPVestMaterial;

var private int DefaultVIPArrestedCountdown;
var private int VIPArrestedCountdown;
var private Timer VIPArrestedTimer;
var private bool VIPArrestedTimerExpired;

var private array<VIPGoalBase> VIPGoals;

var private bool bHasRoundEnded;

var private array<SwatGamePlayerController> PlayersOnSWATTeam;
var private array<SwatGamePlayerController> PlayersOnSuspectsTeam;


/////////////////////////////////////////
/////////////////////////////////////////
/////////////////////////////////////////


function OnMissionEnded()
{
    Super.OnMissionEnded();
    VIPArrestedTimer.StopTimer();
    respawnTimer.StopTimer();
    SGI.gameEvents.pawnUnarrested.UnRegister(self);
    SGI.gameEvents.pawnUnarrestBegan.UnRegister(self);
    SGI.gameEvents.VIPReachedGoal.UnRegister(self);
}

function Initialize()
{
    local VIPGoalBase VIPGoal;
    local int NumberOfVIPGoals;

    mplog( "Initialize() in GameModeVIP." );
    Super.Initialize();

    SGI.gameEvents.pawnUnarrested.Register(self);
    SGI.gameEvents.pawnUnarrestBegan.Register(self);
    SGI.gameEvents.VIPReachedGoal.Register(self);

    respawnTimer = Spawn(class'Timer');
    assert(respawnTimer != None);
    respawnTimer.timerDelegate = DecrementRespawnTimers;

    VIPArrestedTimer = Spawn(class'Timer');
    assert(VIPArrestedTimer != None);
    VIPArrestedTimer.timerDelegate = DecrementVIPArrestedTimer;

    // Spawn the VIPGoal here.
    Level.SpawningManager.DoMPSpawning( SwatGameInfo(Level.Game), 'VIPGoalRoster' );

    NumberOfVIPGoals = 0;
    foreach AllActors( class'VIPGoalBase', VIPGoal )
    {
        mplog( "...found a VIPGoal="$VIPGoal );
        VIPGoals[VIPGoals.Length] = VIPGoal;
        ++NumberOfVIPGoals;
    }
    AssertWithDescription( NumberOfVIPGoals > 0, "There are no VIP goals in the level!" );
}

function OnMissionStarted()
{
    respawnTimer.StartTimer( 1.0, true );
}

// This is meant to do things like select which player is the VIP. Do nothing
// in BS and RD, but override in VIP mode.
function AssignPlayerRoles()
{
    local Controller controller;
    local SwatGamePlayerController player;
    local int RandomIndex;

    Super.AssignPlayerRoles();
    
    mplog( self$"---GameModeVIP::AssignPlayerRoles()." );

    PlayersOnSWATTeam.Remove( 0, PlayersOnSWATTeam.Length );
    PlayersOnSuspectsTeam.Remove( 0, PlayersOnSuspectsTeam.Length );

    // Select which player on the SWAT team is to be the VIP, and mark
    // it. This should be called right before the players are given their
    // pawns after they have all reconnected (or when the waiting timer runs
    // out).

    for (controller = level.controllerList; controller != none; controller = controller.nextController)
    {
        player = SwatGamePlayerController(controller);
        if (player != None && player.SwatRepoPlayerItem.TeamID == 0) // SWAT==0 
        {
            mplog( "...adding SGPC to SWAT array: player="$player );
            PlayersOnSWATTeam[PlayersOnSWATTeam.Length] = player;
        }
    }

    if ( PlayersOnSWATTeam.Length == 0 )
    {
        // Find a random player on the Suspects team and "promote" him to the
        // SWAT team.
        for (controller = level.controllerList; controller != none; controller = controller.nextController)
        {
            player = SwatGamePlayerController(controller);
            if (player != None && player.SwatRepoPlayerItem.TeamID == 1) // Suspects==1
            {
                mplog( "...adding SGPC to Suspects array: player="$player );
                PlayersOnSuspectsTeam[PlayersOnSuspectsTeam.Length] = player;
            }
        }

        Assert( PlayersOnSuspectsTeam.Length > 0 );
        RandomIndex = Rand(PlayersOnSuspectsTeam.Length);

        //promote PlayersOnSuspectsTeam[RandomIndex]
        SGI.ChangePlayerTeam( PlayersOnSuspectsTeam[RandomIndex] );

        // There will now be only one player on the SWAT team
        PlayersOnSWATTeam[0] = PlayersOnSuspectsTeam[RandomIndex];
    }

    RandomIndex = Rand(PlayersOnSWATTeam.Length);
    mplog( "...length of array="$PlayersOnSWATTeam.Length );
    mplog( "...RandomIndex="$RandomIndex );
    mplog( "......setting to true, player="$PlayersOnSWATTeam[RandomIndex] );

    PlayersOnSWATTeam[RandomIndex].ThisPlayerIsTheVIP = true;
    SwatPlayerReplicationInfo(PlayersOnSWATTeam[RandomIndex].PlayerReplicationInfo).bIsTheVIP = true;

    // Flush arrays
    PlayersOnSWATTeam.Remove( 0, PlayersOnSWATTeam.Length );
    PlayersOnSuspectsTeam.Remove( 0, PlayersOnSuspectsTeam.Length );
}


function bool ValidSpawnClusterForMode( SwatMPStartCluster theCluster )
{
    return theCluster.UseInVIPEscort;
}


function bool ClusterPointValidForRoundStart( SwatMPStartCluster thePoint )
{
    return thePoint.UseInVIPEscort && thePoint.NeverFirstSpawnInVIPRound == false;
}

function OnPawnArrested( Pawn Arrestee, Pawn Arrester )
{
    local SwatGamePlayerController SGPC;

    mplog( self$"---GameModeVIP::OnPawnArrested(). Arrestee="$Arrestee$", Arrester="$Arrester );

    Super.OnPawnArrested( Arrestee, Arrester );

    SGPC = SwatGamePlayerController(Arrestee.Controller);
    if ( SGPC != None && SGPC.SwatPlayer.IsTheVIP() )
    {
        VIPArrestedCountdown = DefaultVIPArrestedCountdown;
        VIPArrestedTimer.StartTimer( 1.0, true );
        DisplayBroadcastMessage( "", 'VIPCaptured' );
    }
}


function OnPlayerDied(PlayerController player, Controller killer)
{
    local SwatGamePlayerController SGPC_Killed;
    local SwatGamePlayerController SGPC_Killer;
    local NetTeam swatKillerTeam;
    local SwatPlayerReplicationInfo swatKillerInfo;
    local int TeamOfKiller;

    mplog( self$"---GameModeVIP::OnPlayerDied(). player="$player$", killer="$killer );

    Super.OnPlayerDied( player, killer );

    SGPC_Killed = SwatGamePlayerController(player);
    if ( SGPC_Killed != None )
    {
        if ( SGPC_Killed.SwatPlayer.IsTheVIP() )
        {
            SGPC_Killer = SwatGamePlayerController(killer);
            
            //if the VIP dropped from the server (suicided), end the round in a tie
            if( SGPC_Killed == SGPC_Killer )
            {
                NetRoundFinished( SRO_RoundEndedInTie );
                return;
            }

            TeamOfKiller = SGPC_Killer.SwatRepoPlayerItem.TeamID;

            swatKillerInfo = SwatPlayerReplicationInfo(SGPC_Killer.PlayerReplicationInfo);
            swatKillerTeam = NetTeam(SGPC_Killer.playerReplicationInfo.team);

            if ( TeamOfKiller == 0 ) // SWAT
            {
                swatKillerInfo.netScoreInfo.IncrementKilledVIPInvalid();
                swatKillerTeam.netScoreInfo.IncrementKilledVIPInvalid();

                NetRoundFinished( SRO_SuspectsVictoriousSwatKilledVIP );
            }
            else
            {
                if ( VIPArrestedTimerExpired )
                {
                    swatKillerInfo.netScoreInfo.IncrementKilledVIPValid();
                    swatKillerTeam.netScoreInfo.IncrementKilledVIPValid();

                    NetRoundFinished( SRO_SuspectsVictoriousKilledVIPValid );
                }
                else
                {
                    swatKillerInfo.netScoreInfo.IncrementKilledVIPInvalid();
                    swatKillerTeam.netScoreInfo.IncrementKilledVIPInvalid();

                    NetRoundFinished( SRO_SwatVictoriousSuspectsKilledVIPInvalid );
                }
            }
        }
    }
}


function OnPawnUnarrestBegan( Pawn Arrester, Pawn Arrestee )
{
    mplog( self$"---GameModeVIP::OnPawnUnarrestBegan(). Arrester="$Arrester$", Arrestee="$Arrestee );

    // Commenting this line out because design decided that starting to
    // unarrest the VIP should not reset the timer. If we ever want starting
    // to unarrest to restart it, just uncomment the following line.
    //VIPArrestedCountdown = DefaultVIPArrestedCountdown;
}


function OnPawnUnarrested( Pawn Arrester, Pawn Arrestee )
{
    local SwatGamePlayerController ArresterController;
    local SwatPlayerReplicationInfo ArresterInfo;
    local NetTeam ArresterTeam;

    local int i;
    local VIPGoalBase CurrentGoal;

    mplog( self$"---GameModeVIP::OnPawnUnarrested(). Arrester="$Arrester$", Arrestee="$Arrestee );

    if ( SwatPlayer(Arrestee).IsTheVIP() )
    {
        VIPArrestedCountdown = 0;
        SwatGameReplicationInfo(SGI.GameReplicationInfo).SpecialTime = VIPArrestedCountdown;
    
        VIPArrestedTimer.StopTimer();
        VIPArrestedTimerExpired = false;
        DisplayBroadcastMessage( "", 'VIPRescued' );

        ArresterController = SwatGamePlayerController(Arrester.Controller);
        ArresterInfo = SwatPlayerReplicationInfo(ArresterController.PlayerReplicationInfo);
        ArresterTeam = NetTeam(ArresterController.playerReplicationInfo.team);

        ArresterInfo.netScoreInfo.IncrementUnarrestedVIP();
        ArresterTeam.netScoreInfo.IncrementUnarrestedVIP();

        // If the VIP is touching the VIPGoal, SWAT has won the round.
        for ( i = 0; i < VIPGoals.Length; ++i )
        {
            CurrentGoal = VIPGoals[i];
            mplog( "...VIPGoal="$CurrentGoal );

            if ( VIPIsInGoal( Arrestee, CurrentGoal ) )
            {
                HandleSWATWonRound( SwatPlayer(Arrestee) );
            }
        }
    }
}

private function bool VIPIsInGoal( Pawn VIPPawn, VIPGoalBase TheGoal )
{
    local float Distance2D;
    local float CriticalDistance2D;
    local float HeightDifference;
    local float CriticalHeightDifference;

    Distance2D = VSize2D( VIPPawn.Location - TheGoal.Location );
    CriticalDistance2D = VIPPawn.CollisionRadius + TheGoal.CollisionRadius;

    HeightDifference = abs( VIPPawn.Location.Z - TheGoal.Location.Z );
    CriticalHeightDifference = VIPPawn.CollisionHeight + TheGoal.CollisionHeight;

    return Distance2D < CriticalDistance2D && HeightDifference < CriticalHeightDifference;
}


// This will get called multiple times. Ignore all but the first.
function OnVIPReachedGoal( SwatPlayer Triggerer )
{
    mplog( self$"---GameModeVIP::OnVIPReachedGoal()." );

    if ( !bHasRoundEnded )
    {
        if ( !Triggerer.IsArrested() )
        {
            HandleSWATWonRound( Triggerer );
        }
        else
        {
            mplog( "...The VIP reached the goal but was arrested." );
        }
    }
}

private function HandleSWATWonRound( SwatPlayer VIPPlayer )
{
    local SwatGamePlayerController VIPController;
    local SwatPlayerReplicationInfo VIPInfo;
    local NetTeam VIPTeam;

    mplog( "---GameModeVIP::HandleSWATWonRound()." );

    bHasRoundEnded = true;

    VIPController = SwatGamePlayerController(VIPPlayer.Controller);
    VIPInfo = SwatPlayerReplicationInfo(VIPController.PlayerReplicationInfo);
    VIPTeam = NetTeam(VIPController.playerReplicationInfo.team);

    // Update the VIP's stats
    VIPInfo.netScoreInfo.IncrementVIPPlayerEscaped();
	if (VIPController != None)
		VIPController.Stats.EscapedAsVIP();
    VIPTeam.netScoreInfo.IncrementVIPPlayerEscaped();
    
    DisplayBroadcastMessage( "", 'VIPSafe' );
    
    InterestingViewTarget = VIPPlayer;
    
    NetRoundFinished( SRO_SwatVictoriousVIPEscaped );
}


private function DecrementRespawnTimers()
{
    //mplog( self$"---GameModeVIP::DecrementRespawnTimers()." );
    DecrementRespawnTimer( 0 );
    DecrementRespawnTimer( 1 );
}


function NetRoundTimerExpired()
{
    respawnTimer.StopTimer();
    NetRoundFinished( SRO_RoundEndedInTie );
}


private function DecrementVIPArrestedTimer()
{
    --VIPArrestedCountdown;
    
    SwatGameReplicationInfo(SGI.GameReplicationInfo).SpecialTime = VIPArrestedCountdown;

    if ( VIPArrestedCountdown == 0 )
    {
        VIPArrestedTimerExpired=true;
        VIPArrestedTimer.StopTimer();
    }
}


private function DisplayBroadcastMessage( coerce string Message, name Event )
{
    // @NOTE: This is a temporary piece of code.
    // Remove once the real hud is in place.
    local Controller controller;
    local SwatGamePlayerController player;

    // Restart players
    for (controller = level.controllerList; controller != none; controller = controller.nextController)
    {
        player = SwatGamePlayerController(controller);
        if (player != none)
        {
            player.ClientMessage( Message, Event );
        }
    }
}

simulated event Destroyed()
{
    local VIPGoalBase VIPGoal;
    
    SGI.gameEvents.pawnUnarrested.UnRegister(self);
    SGI.gameEvents.pawnUnarrestBegan.UnRegister(self);
    SGI.gameEvents.VIPReachedGoal.UnRegister(self);
    
    foreach AllActors( class'VIPGoalBase', VIPGoal )
    {
        VIPGoal.Destroy();
    }
    
    VIPGoals.Remove(0,VIPGoals.Length);
    
    if (respawnTimer != None)
    {
        respawnTimer.Destroy();
        respawnTimer = None;
    }

    if (VIPArrestedTimer != None)
    {
        VIPArrestedTimer.Destroy();
        VIPArrestedTimer = None;
    }
  
    Super.Destroyed();
}


defaultproperties
{
    VIPVestMaterial=Material'mp_OfficerTex.VIPvest'
    DefaultVIPArrestedCountdown=120
    VIPArrestedTimerExpired=false
    bHasRoundEnded=false
}
