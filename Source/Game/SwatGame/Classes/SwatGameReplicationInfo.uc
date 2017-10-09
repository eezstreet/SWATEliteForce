///////////////////////////////////////////////////////////////////////////////
// The GRI is used to house GameInfo variables that clients and other objects
// not on the server need to know about (or have access to). Normally, the GRI
// replicates everything from server down to client, but you can use it for
// certain things, like to allow clients to change variables the GameInfo
// relies on. If you decide to use the GRI like this, it's recommended that
// you replicate functions from client to server that then change the variable
// you want.

class SwatGameReplicationInfo extends Engine.GameReplicationInfo;

import enum ObjectiveStatus from SwatGame.Objective;
import enum EEntryType from SwatStartPointBase;
import enum EMPMode from Engine.Repo;


// @NOTE: Hardcoded max player size
const MAX_PLAYERS = 16;
var SwatPlayerReplicationInfo PRIStaticArray[MAX_PLAYERS];

var float ServerCountdownTime;

// These two variables are initially zero. Once they are set, they will be set
// to either 1 (don't show names) or 2 (do show names). We do this because the
// clients need to know when these variables have been replicated to them, and
// if we just used a bool, they couldn't tell whether false meant "really
// false" or "false because it hasn't been replicated yet".
var int ShowTeammateNames;

var int TotalNumberOfBombs;
var int DiffusedBombs;


var int RoundTime;
var int SpecialTime;


var int TimedObjectiveIndex;

//true if we are waiting for players to reconnect and all current players are ready
var bool bWaitingForPlayers;

var protected PlayerReplicationInfo PlayerWithItem;

///////////////////////////////////////////////////////////////////////////////
//Objectives
const MAX_OBJECTIVES = 30;
var byte ObjectiveHidden[MAX_OBJECTIVES];
var String ObjectiveNames[MAX_OBJECTIVES];
var ObjectiveStatus ObjectiveStatus[MAX_OBJECTIVES];

//Procedures
const MAX_PROCEDURES = 30;
var String ProcedureCalculations[MAX_PROCEDURES];
var int ProcedureValue[MAX_PROCEDURES];

///////////////////////////////////////////////////////////////////////////////

var ReferendumManager RefMgr;

var String NextMap;

replication
{
	reliable if ( bNetDirty && (Role == ROLE_Authority) )
		NextMap, ServerCountdownTime, ShowTeammateNames,
        TotalNumberOfBombs, DiffusedBombs,
        ObjectiveHidden, ObjectiveNames, ObjectiveStatus, ProcedureCalculations, ProcedureValue,
        RoundTime, SpecialTime, TimedObjectiveIndex, bWaitingForPlayers,
		RefMgr, PlayerWithItem;
}

///////////////////////////////////////////////////////////////////////////////

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    // The repo needs to know what the game replication info is.
    SwatRepo(Level.GetRepo()).SetSGRI( self );

    ClearScoring();

	if (RefMgr == None && Level.NetMode != NM_Client)
		RefMgr = Spawn(class'ReferendumManager');
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    // The repo needs to know what the game replication info is.
    SwatRepo(Level.GetRepo()).SetSGRI( self );

    ClearScoring();
}

simulated function AddPRI(PlayerReplicationInfo PRI)
{
    local int i;

    Super.AddPRI(PRI);

    for (i = 0; i < ArrayCount(PRIStaticArray); ++i)
    {
        if (PRIStaticArray[i] == None)
        {
            PRIStaticArray[i] = SwatPlayerReplicationInfo(PRI);
            break;
        }
    }
}


simulated function RemovePRI(PlayerReplicationInfo PRI)
{
    local int i;

    Super.RemovePRI(PRI);

    for (i = 0; i < ArrayCount(PRIStaticArray); ++i)
    {
        if (PRIStaticArray[i] == PRI)
        {
            PRIStaticArray[i] = None;
            break;
        }
    }
}

simulated function int NumPlayers()
{
    local int i, total;

    for(i = 0; i < ArrayCount(PRIStaticArray); ++i)
    {
        if (PRIStaticArray[i] != None)
            total++;
    }

    return total;
}

function SetWaitingForPlayers( bool WaitingForReconnects )
{
    bWaitingForPlayers = WaitingForReconnects && AllPlayersAreReady();
}

// Execute only on server.
function bool AllPlayersAreReady()
{
    local int i;

    for ( i = 0; i < ArrayCount(PRIStaticArray); ++i )
    {
        if ( PRIStaticArray[i] != None )
        {
            if ( !PRIStaticArray[i].GetPlayerIsReady() )
            {
                return false;
            }
        }
    }

    return true;
}


// Execute only on server.
function bool ResetPlayerReadyValues()
{
    local int i;

    for ( i = 0; i < ArrayCount(PRIStaticArray); ++i )
    {
        if ( PRIStaticArray[i] != None )
        {
            PRIStaticArray[i].ResetPlayerIsReady();
        }
    }

    return true;
}


// Execute only on server.
function ResetPlayerScoresForMPQuickRestart()
{
    local int i;

    for ( i = 0; i < ArrayCount(PRIStaticArray); ++i )
    {
        if ( PRIStaticArray[i] != None )
        {
            PRIStaticArray[i].netScoreInfo.ResetForMPQuickRestart();
        }
    }
}

simulated function LogScoring( SwatRepo Repo )
{
    local int i;

    log( "SCORING: >>> Objectives" );
    for( i = 0; i < MAX_OBJECTIVES && i < Repo.MissionObjectives.Objectives.Length; i++ )
    {
        if( Repo.MissionObjectives.Objectives[i] != None )
            log( "SCORING: ... "$Repo.MissionObjectives.Objectives[i].Description$", Status = "$ObjectiveStatus[i] );
    }

    log( "\nSCORING: >>> Procedures" );
    for( i = 0; i < MAX_PROCEDURES && i < Repo.Procedures.Procedures.Length; i++ )
    {
        if( Repo.Procedures.Procedures[i] != None )
            log( "SCORING: ... "$Repo.Procedures.Procedures[i].Description$", Calculations = "$ProcedureCalculations[i]$", Value = "$ProcedureValue[i] );
    }
}

function ClearScoring()
{
    local int i;

    for( i = 0; i < MAX_OBJECTIVES; i++ )
    {
        ObjectiveStatus[i] = ObjectiveStatus_InProgress;
    }

    for( i = 0; i < MAX_PROCEDURES; i++ )
    {
        ProcedureCalculations[i] = "";
        ProcedureValue[i] = 0;
    }
}

///////////////////////////////////////////////////////////////////////////////
// Broadcast routing -previously done through the PlayerController
///////////////////////////////////////////////////////////////////////////////

// Called on the server instead of ClientGotoState() when we need to interrupt
// things first.
function NotifyClientsToInterruptAndGotoState( Pawn ThePlayer, name Reason, name NewControllerState, name NewPawnState )
{
    local SwatGamePlayerController SGPC;
    local Controller current;

    mplog( self$"---SGPC::NotifyClientsToInterruptAndGotoState()." );
    mplog( "...Pawn="$ThePlayer );
    mplog( "...Reason="$Reason );
    mplog( "...NewControllerState="$NewControllerState );
    mplog( "...NewPawnState="$NewPawnState );

    Assert( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer );

    for ( current = Level.ControllerList; current != None; current = current.NextController )
    {
        SGPC = SwatGamePlayerController( current );
        if ( SGPC != None )
        {
            SGPC.ClientInterruptAndGotoState( ThePlayer, Reason, NewControllerState, NewPawnState );
        }
    }
}

// Called on the server to tell all clients to interrupt their current states.
function NotifyClientsToInterruptState( Pawn ThePlayer, name Reason )
{
    local SwatGamePlayerController SGPC;
    local Controller current;

    mplog( self$"---SGPC::NotifyClientsToInterruptState()." );
    mplog( "...Pawn="$ThePlayer );
    mplog( "...Reason="$Reason );

    Assert( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer );

    for ( current = Level.ControllerList; current != None; current = current.NextController )
    {
        SGPC = SwatGamePlayerController( current );
        if ( SGPC != None )
        {
            SGPC.ClientInterruptState( ThePlayer, Reason );
        }
    }
}

// RPC on server to trigger dynamic music on remote clients
function ServerTriggerDynamicMusic()
{
    local Controller Itr;

    Itr = Level.ControllerList;
    for ( Itr = Level.ControllerList; Itr != None; Itr = Itr.NextController )
    {
        if ( Itr.IsA ( 'SwatGamePlayerController' ) )
            SwatGamePlayerController(Itr).ClientTriggerDynamicMusic();
    }
}


function SetObjectiveVisibility( name ObjectiveName, bool Visible )
{
    local Controller Itr;
    local PlayerController LPC;

    SwatRepo(Level.GetRepo()).SetObjectiveVisibility( ObjectiveName, Visible );

    LPC = Level.GetLocalPlayerController();
    Itr = Level.ControllerList;
    for ( Itr = Level.ControllerList; Itr != None; Itr = Itr.NextController )
    {
        if ( Itr.IsA ( 'SwatGamePlayerController' ) && Itr != LPC )
            SwatGamePlayerController(Itr).ClientSetObjectiveVisibility( string(ObjectiveName), Visible );
    }
}


function OnMissionEnded()
{
    local int i;

    for( i = 0; i < MAX_PLAYERS; i++ )
    {
        if( PRIStaticArray[i] != None )
            PRIStaticArray[i].OnMissionEnded();
    }

    RoundTime = 0;
    SpecialTime = 0;
}

// Let the server pick which sound to play, used when we want to play a specific sound on all clients
function int ServerChooseSoundEffectToPlay( name EffectSpecification, Actor Source, Actor Target, Material TargetMaterial )
{
    local SoundEffectsSubsystem SoundSys;
    local SoundEffectSpecification SoundSpec;
    local SoundRef SoundRef;

    SoundSys = SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem'));

	// Do the lookup of the effect spec locally
    SoundSpec = SoundEffectSpecification(SoundSys.FindEffectSpecification(EffectSpecification));

	// Get the sound to play from the specification
    SoundRef = SoundSpec.PickSoundToPlay(SoundSys.GetSoundMaterialFlags(TargetMaterial));

    return SoundRef.SoundSetIndex;
}

function StartReferendum(PlayerController PC, class<Voting.Referendum> ReferendumClass, optional PlayerController Target, optional String TargetStr)
{
	if(RefMgr == None)
		return;

	if(!ServerSettings(Level.CurrentServerSettings).bAllowReferendums)
	{
		Level.Game.Broadcast(None, "", 'ReferendumsDisabled', PC);
		return;
	}

	if(RefMgr.StartNewReferendum(PC, ReferendumClass, Target, TargetStr))
	{
		VoteYes(PC);
	}
}

function StartReferendumForPlayer(PlayerController PC, class<Voting.Referendum> ReferendumClass, string PlayerName)
{
	local PlayerController Target;

	foreach DynamicActors(class'PlayerController', Target)
	{
		if(Target.PlayerReplicationInfo.PlayerName ~= PlayerName)
		{
			StartReferendum(PC, ReferendumClass, Target);
			return;
		}
	}
}

function VoteYes(PlayerController PC)
{
	if (RefMgr == None)
		return;

	mplog(PC.PlayerReplicationInfo.PlayerName $ " submitted a yes vote");

	if (RefMgr.SubmitYesVote(PC.PlayerReplicationInfo.PlayerId, PC.PlayerReplicationInfo.Team))
	{
		if (RefMgr.GetTeam() != None)
			Level.Game.BroadcastTeam(PC, PC.PlayerReplicationInfo.PlayerName, 'YesVote');
		else
			Level.Game.Broadcast(PC, PC.PlayerReplicationInfo.PlayerName, 'YesVote');
	}
}

function VoteNo(PlayerController PC)
{
	if (RefMgr == None)
		return;

	mplog(PC.PlayerReplicationInfo.PlayerName $ " submitted a no vote");

	if (RefMgr.SubmitNoVote(PC.PlayerReplicationInfo.PlayerId, PC.PlayerReplicationInfo.Team))
	{
		if (RefMgr.GetTeam() != None)
			Level.Game.BroadcastTeam(PC, PC.PlayerReplicationInfo.PlayerName, 'NoVote');
		else
			Level.Game.Broadcast(PC, PC.PlayerReplicationInfo.PlayerName, 'NoVote');
	}
}

///////////////////////////////////////////////////////////////////////////////

simulated function SetPlayerWithItem(PlayerReplicationInfo NewPlayer)
{
    local SwatGamePlayerController LPC;

	PlayerWithItem = NewPlayer;

	LPC = SwatGamePlayerController(Level.GetLocalPlayerController());
	if (LPC != None)
		LPC.GetHUDPage().OnSmashAndGrabItemOwnerChange(NewPlayer);
}

simulated function PostNetReceive()
{
	if (Role != ROLE_Authority)
	{
		SetPlayerWithItem(PlayerWithItem);
	}
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	bNetNotify = true
}

///////////////////////////////////////////////////////////////////////////////
