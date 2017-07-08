//=============================================================================
// GameReplicationInfo.
//=============================================================================
class GameReplicationInfo extends ReplicationInfo
	native nativereplication;

var string GameName;						// Assigned by GameInfo.
var string GameClass;						// Assigned by GameInfo.
var bool bTeamGame;							// Assigned by GameInfo.
var bool bStopCountDown;
var bool bMatchHasBegun;
var bool bTeamSymbolsUpdated;
var int  RemainingTime, ElapsedTime, RemainingMinute;
var float SecondCount;
var int GoalScore;
var int TimeLimit;
var int MaxLives;

#if IG_SWAT
var TeamInfo Teams[3];
#else
var TeamInfo Teams[2];
#endif

var() globalconfig string ServerName;		// Name of the server, i.e.: Bob's Server.
var() globalconfig string ShortName;		// Abbreviated name of server, i.e.: B's Serv (stupid example)
var() globalconfig string AdminName;		// Name of the server admin.
var() globalconfig string AdminEmail;		// Email address of the server admin.
var() globalconfig int	  ServerRegion;		// Region of the game server.

var() globalconfig string MOTDLine1;		// Message
var() globalconfig string MOTDLine2;		// Of
var() globalconfig string MOTDLine3;		// The
var() globalconfig string MOTDLine4;		// Day

var Actor Winner;			// set by gameinfo when game ends
var VoiceChatReplicationInfo VoiceReplicationInfo;

var() array<PlayerReplicationInfo> PRIArray;

var vector FlagPos;	// replicated 2D position of one object

enum ECarriedObjectState
{
    COS_Home,
    COS_HeldFriendly,
    COS_HeldEnemy,
    COS_Down,
};
var ECarriedObjectState CarriedObjectState[2];

// stats
var int MatchID;

replication
{
	reliable if ( bNetDirty && (Role == ROLE_Authority) )
		RemainingMinute, bStopCountDown, Winner, Teams, FlagPos, CarriedObjectState, bMatchHasBegun, MatchID;

	reliable if ( bNetInitial && (Role==ROLE_Authority) )
		GameName, GameClass, bTeamGame, 
		RemainingTime, ElapsedTime,MOTDLine1, MOTDLine2, 
		MOTDLine3, MOTDLine4, ServerName, ShortName, AdminName,
		AdminEmail, ServerRegion, GoalScore, MaxLives, TimeLimit,
		VoiceReplicationInfo; 
}

simulated function SetCarriedObjectState(int Team, name NewState)
{
	switch( NewState )
	{
		case 'Down':
			CarriedObjectState[Team] = COS_Down;
			break;
		case 'HeldEnemy ':
			CarriedObjectState[Team] = COS_HeldEnemy;
			break;
		case 'Home ':
			CarriedObjectState[Team] = COS_Home;
			break;
		case 'HeldFriendly ':
			CarriedObjectState[Team] = COS_HeldFriendly;
			break;
	}
}

simulated function name GetCarriedObjectState(int Team)
{
	switch( CarriedObjectState[Team] )
	{
		case COS_Down:
			return 'Down';
		case COS_HeldEnemy:
			return 'HeldEnemy';
		case COS_Home:
			return 'Home';
		case COS_HeldFriendly:
			return 'HeldFriendly';
	}
	return '';
}			

simulated function PostNetBeginPlay()
{
	local PlayerReplicationInfo PRI;

	if ( VoiceReplicationInfo == None )
		foreach DynamicActors(class'VoiceChatReplicationInfo', VoiceReplicationInfo)
			break;

	ForEach DynamicActors(class'PlayerReplicationInfo',PRI)
		AddPRI(PRI);
	if ( Level.NetMode == NM_Client )
		TeamSymbolNotify();
}

simulated function TeamSymbolNotify()
{
	local Actor A;

	if ( (Teams[0] == None) || (Teams[1] == None)
		|| (Teams[0].TeamIcon == None) || (Teams[1].TeamIcon == None) )
		return;
	bTeamSymbolsUpdated = true;
	ForEach AllActors(class'Actor', A)
		A.SetGRI(self);
}

simulated function PostBeginPlay()
{
	if( Level.NetMode == NM_Client )
	{
		// clear variables so we don't display our own values if the server has them left blank 
		ServerName = "";
		AdminName = "";
		AdminEmail = "";
		MOTDLine1 = "";
		MOTDLine2 = "";
		MOTDLine3 = "";
		MOTDLine4 = "";
	}

	SecondCount = Level.TimeSeconds;
	SetTimer(1, true);
}

/* Reset() 
reset actor to initial state - used when restarting level without reloading.
*/
function Reset()
{
	Super.Reset();
	Winner = None;
}

simulated function Timer()
{
	if ( Level.NetMode == NM_Client )
	{
		if (Level.TimeSeconds - SecondCount >= Level.TimeDilation)
		{
			ElapsedTime++;
			if ( RemainingMinute != 0 )
			{
				RemainingTime = RemainingMinute;
				RemainingMinute = 0;
			}
			if ( (RemainingTime > 0) && !bStopCountDown )
				RemainingTime--;
			SecondCount += Level.TimeDilation;
		}
		if ( !bTeamSymbolsUpdated )
			TeamSymbolNotify();
	}
}

simulated function AddPRI(PlayerReplicationInfo PRI)
{
    PRIArray[PRIArray.Length] = PRI;
}

simulated function RemovePRI(PlayerReplicationInfo PRI)
{
    local int i;

    for (i=0; i<PRIArray.Length; i++)
    {
        if (PRIArray[i] == PRI)
            break;
    }

    if (i == PRIArray.Length)
    {
        log("GameReplicationInfo::RemovePRI() pri="$PRI$" not found.", 'Error');
        return;
    }

    PRIArray.Remove(i,1);
	}

simulated function GetPRIArray(out array<PlayerReplicationInfo> pris)
{
    local int i;
    local int num;

    pris.Remove(0, pris.Length);
    for (i=0; i<PRIArray.Length; i++)
    {
        if (PRIArray[i] != None)
            pris[num++] = PRIArray[i];
    }
}


#if IG_SWAT //dkaplan: broadcast Triggers
///////////////////////////////////////////////////////////////////////////////
// Broadcast routing -previously done through the PlayerController
///////////////////////////////////////////////////////////////////////////////

// returns the index of the sound to play...
function int ServerChooseSoundEffectToPlay( name EffectSpecification, Actor Source, Actor Target, Material TargetMaterial );

function ServerBroadcastSoundEffectSpecification( name EffectSpecification,
                                                  Actor Source,
                                                  Actor Target,
                                                  optional Material Material,
                                                  optional vector overrideWorldLocation,
                                                  optional rotator overrideWorldRotation,
                                                  optional IEffectObserver Observer,
                                                  optional bool SameOnAllMachines )
{
    local Controller Itr;
    local int SpecificSoundRefIndex;
    
    // Default is -1 because 0 is a valid sound ref index.
    SpecificSoundRefIndex = -1;

    // Just in case the source isn't relevant on the client, save off the source location to send to the client RPC.  Unless of course, we're already specifying a world location
    if ( VSize(overrideWorldLocation) == 0 )
        overrideWorldLocation = Source.Location;

    Itr = Level.ControllerList;
    while ( Itr != None ) // Walk the controller list
    {    
		// Actually choose the sound if requested
        if ( SameOnAllMachines )
        {
            SpecificSoundRefIndex = ServerChooseSoundEffectToPlay( EffectSpecification, Source, Target, Material );
        }

        if ( Itr.IsA( 'PlayerController' ) )
            PlayerController(Itr).ClientBroadcastSoundEffectSpecification( EffectSpecification, Source, Target, SpecificSoundRefIndex, Material, overrideWorldLocation, overrideWorldRotation, Observer );
        Itr = Itr.NextController;
    }
}

// Carlos: ServerBroadcastEffectEvent is an RPC that runs on the server, and RPC's all remote clients to play the given effect event.
function ServerBroadcastEffectEvent(    Actor SourceActor, 
                                        String UniqueIdentifier,
                                        name EffectEvent, 
                                        optional Actor Other,
                                        optional Material TargetMaterial,
                                        optional Vector HitLocation,
                                        optional Rotator HitNormal,
                                        optional bool PlayOnOther,
                                        optional bool QueryOnly,
                                        optional IEffectObserver Observer,
                                        optional name ReferenceTag )
{
    local Controller Itr;

    if (Level.GetEngine().EnableDevTools)
        log( self$"::ServerBroadcastEffectEvent( "$SourceActor );
    
    Itr = Level.ControllerList;
    while ( Itr != None ) // Walk the controller list
    {    
        if ( Itr.IsA( 'PlayerController' ) )
        {
            if (Level.GetEngine().EnableDevTools)
                log( self$"::ServerBroadcastEffectEvent() ... sending ClientBroadcastEffectEvent to: "$PlayerController(Itr) );

            PlayerController(Itr).ClientBroadcastEffectEvent( SourceActor, UniqueIdentifier, string(EffectEvent), Other, TargetMaterial, HitLocation, HitNormal, PlayOnOther, QueryOnly, Observer, String(ReferenceTag) );
        }
        Itr = Itr.NextController;
    }
}

// dkaplan: ServerBroadcastUnTriggerEffectEvent is an RPC that runs on the server, and RPC's all remote clients to play the given effect event.
function ServerBroadcastUnTriggerEffectEvent(    Actor SourceActor, 
                                        String UniqueIdentifier,
                                        name EffectEvent, 
                                        optional name ReferenceTag )
{
    local Controller Itr;
    
    if (Level.GetEngine().EnableDevTools)
        log( self$"::ServerBroadcastUnTriggerEffectEvent( "$SourceActor );

    Itr = Level.ControllerList;
    while ( Itr != None ) // Walk the controller list
    {    
        if ( Itr.IsA( 'PlayerController' ) )
        {
            if (Level.GetEngine().EnableDevTools)
                log( self$"::ServerBroadcastUnTriggerEffectEvent() ... sending ClientBroadcastUnTriggerEffectEvent to: "$PlayerController(Itr) );

            PlayerController(Itr).ClientBroadcastUnTriggerEffectEvent( SourceActor, UniqueIdentifier, string(EffectEvent), String(ReferenceTag) );
        }
        Itr = Itr.NextController;
    }
}



// Dkaplan: ServerBroadcastTrigger is an RPC that runs on the server, and RPC's all remote clients to Trigger the give source actor.
function ServerBroadcastTrigger( Actor SourceActor, 
                                 String UniqueIdentifier, 
                                 Actor Other, 
                                 Pawn EventInstigator )
{
    local Controller Itr;
    
    Itr = Level.ControllerList;
    while ( Itr != None ) // Walk the controller list
    {    
        if ( Itr.IsA( 'PlayerController' ) )
            PlayerController(Itr).ClientBroadcastTrigger( SourceActor, UniqueIdentifier, Other, EventInstigator );
        Itr = Itr.NextController;
    }
}

#endif //IG_SWAT

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	CarriedObjectState[0]=COS_Home
	CarriedObjectState[1]=COS_Home
	bStopCountDown=true
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	ServerName="Another Server"
	ShortName="Server"
	MOTDLine1=""
	MOTDLine2=""
	MOTDLine3=""
	MOTDLine4=""
    bNetNotify=true
}
