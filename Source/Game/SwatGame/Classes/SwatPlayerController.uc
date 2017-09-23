class SwatPlayerController extends Engine.PlayerController
    config(User)
    dependsOn(SwatGuiConfig)
    native;

// If set to 1, you will not be allowed to suicide in multiplayer games.
// If set to 0, you will be allowed to suicide as long as you are not
// in the process of being arrested and are not the VIP and already
// arrested.
#define DISALLOW_SUICIDE 1

import enum EMPMode from Engine.Repo;
import enum EEntryType from SwatStartPointBase;
import enum eSwatGameState from SwatGame.SwatGuiConfig;
import enum eSwatGameRole from SwatGame.SwatGuiConfig;

const MAX_PLAYERS = 16;

var config float    FlashScale;		//for flashing victim's screen
var config vector   FlashFog;

var bool ShouldDisplayPRIIds;

var int VOIPIgnoreStaticArray[MAX_PLAYERS];	//list of PlayerIDs ignored by this controller for VOIP

replication
{
    reliable if( Role<ROLE_Authority )
        ServerSetSettings, ServerSetAdminSettings, ServerSetDirty, ServerAddMap, ServerClearMaps, ServerQuickRestart, ServerCoopQMMRestart, ServerUpdateCampaignProgression;

    // replicated functions sent to server by owning client
    reliable if( Role < ROLE_Authority )
		Kick, KickBan, SAD, Switch, StartGame, AbortGame,
		ServerStartReferendum, ServerStartReferendumForPlayer, ServerVoteYes, ServerVoteNo;

	reliable if( Role < ROLE_Authority )
		VOIPIgnore, VOIPUnIgnore, VOIPClearIgnore;

	reliable if ( bNetDirty && (Role == ROLE_Authority) )
		VOIPIgnoreStaticArray;
}

///////////////////////////////////////////////////////////////////////////////

native function bool ShouldAutoJoinOnStartUp();

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

	//always clear this flag at the beginning a of a level, because a player may no longer be admin
    ShouldDisplayPRIIds = false;

	//initialise ignore list
	VOIPClearIgnore();
}

/////////////////////////////////////////////////////////////////////////////
// Game State / Game Systems Reference
/////////////////////////////////////////////////////////////////////////////
function OnRoleChange( eSwatGameRole oldRole, eSwatGameRole newRole )
{
log("[dkaplan] >>> OnRoleChange of (SwatPlayerController) "$self);
}

function OnStateChange( eSwatGameState oldState, eSwatGameState newState )
{
log("[dkaplan] >>> OnStateChange of (SwatPlayerController) "$self);
}


#if IG_GUI_LAYOUT //dkaplan - gui placement system - FIXME these are cheats to be later removed
exec function OpenMenu( string theMenu )
{
    GUIController(Player.GUIController).OpenMenu( Left(theMenu,InStr(theMenu," ")), Right(theMenu,Len(theMenu)-InStr(theMenu," ")-1) );
}

exec function CloseMenu()
{
    GUIController(Player.GUIController).CloseMenu();
}

exec function SetGuiStyle( String style )
{
    GUIController(Player.GUIController).ChangeActiveStyle( style );
}

exec function SetGuiGridSize( int size )
{
    GUIController(Player.GUIController).ChangeGridSize( size );
}

exec function SetGuiRes( int xVal, int yVal )
{
    GUIController(Player.GUIController).ChangeResolutionX( xVal );
    GUIController(Player.GUIController).ChangeResolutionY( yVal );
    GUIController(Player.GUIController).SetGuiResolution();
}
#endif

///////////////////////////////////////////////////////////////////////////////

// do view shake/flash when hit
function NotifyTakeHit(pawn InstigatedBy, vector HitLocation, int Damage, class<DamageType> damageType, vector Momentum)
{
	if ( (instigatedBy != None) && (instigatedBy != self.pawn) )
    {
        //Log("PLAYING FLASH BECAUSE TOOK "$Damage$" DAMAGE "$DamageType$" from "$InstigatedBy$", Health now = "$pawn.Health);
		if ((Damage > 0 || bGodMode) && self.pawn.Health > 0)
        {
            ClientFlash(FlashScale, FlashFog);
        }
	    DamageShake(Damage);
    }

	TriggerHitSpeech();
}

function DamageShake(int damage)
{
    /*
    local float shake;
    shake = 10;
    ShakeView(0.175 + 0.1 * Shake, 200 * Shake, Shake * vect(0,0,1000), 120000, vect(0,0,10), 9);
    */

    // ckline note: this shake blows. I should fix it.

    ShakeView(
        2, //0.15 + 0.005 * Damage,      // shaketime
        750,                // rollMag
        100000 * vect(0,1,0),    // offsetmag
        120000,                     // rollrate
        vect(1,1,1),                // offsetrate
        5                         // offsettime
        );
}

private function TriggerHitSpeech()
{
	if ((Pawn != None) && Pawn.isAlive())
	{
		if (SwatPawn(Pawn).IsIntenseInjury())
		{
			Pawn.BroadcastEffectEvent('ReactedInjuryIntense',,,,,,,,SwatPawn(Pawn).GetPlayerTag());
		}
		else
		{
			Pawn.BroadcastEffectEvent('ReactedInjuryNormal',,,,,,,,SwatPawn(Pawn).GetPlayerTag());
		}
	}
}

exec function Suicide()
{

#if DISALLOW_SUICIDE

    // Designers do not want to allow suicide, especially in MP ... to many ways to
    // cheat (e.g., suicide when nonlethaled to avoid losing points from
    // being arrested or killed) and break things.
    return;
#else

    local SwatPlayer PlayerPawn;
    local bool IsInProcessOfBeingArrested;
    local bool IsVIPAndCurrentlyArrested;

    PlayerPawn = SwatPlayer(Pawn);
    if (PlayerPawn != None)
    {
        IsInProcessOfBeingArrested = PlayerPawn.IsBeingArrestedNow();
        mplog(self$" Suicide(): IsInProcessOfBeingArrested = "$IsInProcessOfBeingArrested);

        IsVIPAndCurrentlyArrested = PlayerPawn.IsTheVIP() && PlayerPawn.IsArrested();
        mplog(self$" Suicide(): IsVIPAndCurrentlyArrested = "$IsVIPAndCurrentlyArrested$" (IsTheVIP()="$PlayerPawn.IsTheVIP()$" IsArrested()="$PlayerPawn.IsArrested()$")");
    }
    else
    {
        IsInProcessOfBeingArrested = false;
        IsVIPAndCurrentlyArrested = false;
        mplog(self$" Suicide(): SwatPlayer(Pawn) == None, allowing suicide");
    }

    // don't let the player suicide while being arrested, as this
    // will let the player cheat the arresting team out of the arrest
    // points. Also don't let the VIP suicide while he's arrested.
    if (! (IsInProcessOfBeingArrested || IsVIPAndCurrentlyArrested) )
    {
        Super.Suicide();
        mplog(self$" Suicide(): ...Allowing suicide!");
    }
    else
    {
        mplog(self$" Suicide(): ...Disallowing suicide!");
    }
#endif // DISALLOW_SUICIDE
}

function bool ShouldHideCrosshairsDueToIronsights()
{
  local HandheldEquipment Equipment;

  if(!WantsZoom)
  {
    // Not in zoom, so we don't have to worry about this
    return false;
  }
  if(GetIronsightsDisabled())
  {
    // We use the traditional zoom method instead of ironsights
    return false;
  }

  Equipment = Pawn.GetActiveItem();
  if(!Equipment.ShouldHideCrosshairsInIronsights())
  {
    // The currently selected piece of equipment always shows the crosshair when zooming
    return false;
  }

  return true;
}

function bool GetIronsightsDisabled()
{
  local SwatGuiConfig GC;

  GC = SwatRepo(Level.GetRepo()).GuiConfig;

	return GC.ExtraIntOptions[0] == 1;
}

function bool GetViewmodelDisabled()
{
  local SwatGuiConfig GC;

  GC = SwatRepo(Level.GetRepo()).GuiConfig;

	return GC.ExtraIntOptions[1] == 1;
}

function bool GetCrosshairDisabled()
{
  local SwatGuiConfig GC;

  GC = SwatRepo(Level.GetRepo()).GuiConfig;

	return GC.ExtraIntOptions[2] == 1 || ShouldHideCrosshairsDueToIronsights();
}

function bool GetInertiaDisabled()
{
  local SwatGuiConfig GC;

  GC = SwatRepo(Level.GetRepo()).GuiConfig;

	return GC.ExtraIntOptions[3] == 1;
}

//overridden from Engine.PlayerController
exec function SetName( coerce string S)
{
    local SwatGuiConfig GC;
    local int index;

    //empty string not a valid name
    if( S == "" )
        return;

    // get the guiconfig object
    GC = SwatRepo(Level.GetRepo()).GuiConfig;

    ReplaceText( S, "[b]", "{b}" );
    ReplaceText( S, "[B]", "{B}" );
    ReplaceText( S, "[i]", "{i}" );
    ReplaceText( S, "[I]", "{I}" );
    ReplaceText( S, "[u]", "{u}" );
    ReplaceText( S, "[U]", "{U}" );

    //remove invalid characters
    do
    {
        //if the current character is allowable
        if( InStr( GC.MPNameAllowableCharSet, Mid( S, index, 1 ) ) >= 0 )
        {
            //continue to the next character
            index++;
        }
        else
        {
            //remove the current character
    	    S = Left( S, index ) $ Right( S, len(S) - (index+1) );
    	}
    } until (index >= Len(S));

    //Cap the Max length = 20 characters
    if( Len(S) > GC.MPNameLength )
        S = Left(S,GC.MPNameLength);

    //empty string is still not a valid name - no change should be made
    if( S == "" )
        return;


	if( Level.GetLocalPlayerController() == self )
    {
        //set the new name & save it
	    GC.MPName = S;
        GC.SaveConfig();
    }

	ChangeName(S);

    //update the URL with the new name
	if( Level.GetLocalPlayerController() == self )
	    UpdateURL("Name", GC.MPName, true);

	//dkaplan - this was in PlayerController after UpdateURL... why? It doesn't save anything new in the player controller!
	//  this causes the failed to write SwatGame.ini error message after you quit the game
	//SaveConfig();
}

function ChangeName( coerce string S )
{
    //set the name
    Level.Game.ChangeName( self, S, true );
}

///////////////////////////////////////////////////////////////////////////////////////////
// ADMIN EXECs
///////////////////////////////////////////////////////////////////////////////////////////

private simulated function LogPlayerIDs(GameReplicationInfo GRI)
{
	local int i;

	// List the players and their IDs
	log("-----------------");
	log("ID\tPLAYERNAME");
	for (i = 0; i < GRI.PRIArray.Length; ++i)
	{
		log(i$"\t"$GRI.PRIArray[i].PlayerName);
	}
	log("-----------------");
}

// Shorthand for KickBanID
exec function KBID(String S)
{
	KickBanID(S);
}

// Kickban the player who is at index S in the GameRelicationInfo.PRIArray
exec function KickBanID(String S)
{
    KickOrBanByID( S, true );
}

// Shorthand for KickID
exec function KID(String S)
{
	KickID(S);
}

// Kick the player who is at index S in the GameRelicationInfo.PRIArray
exec function KickID(String S)
{
    KickOrBanByID( S, false );
}

simulated function KickOrBanByID( String S, bool bKickBan )
{
    local int ID, i;
    local PlayerReplicationInfo PRI;

	// Make sure it's a number. We don't want to cast to an integer without checking
	// because if the cast fails it will return 0, which would result in
	// kicking the player at ID 0 when it really shouldn't kick anyone.
	for (i = 0; i < Len(S); ++i)
	{
		if ( Asc( Mid(S,i,1) ) < 48 || Asc( Mid(S,i,1) ) > 57)
		{
			return;
		}
	}

    ID = int(S);

    //handle invalid ID number
    if( ID < 0 || ID > 15 )
        return;

    PRI = SwatGameReplicationInfo(GameReplicationInfo).PRIStaticArray[ID];

    if( PRI == None )
        return;

    if( bKickBan )
    	KickBan(PRI.PlayerName);
    else
    	Kick(PRI.PlayerName);
}

exec function KickBan( string S )
{
	SwatGameInfo(Level.Game).Admin.KickBan(Self, S);
}

exec function Kick( string S )
{
    SwatGameInfo(Level.Game).Admin.Kick(Self, S);
}

exec function SAD( string S )
{
    SwatGameInfo(Level.Game).Admin.AdminLogin(Self, S);
}

exec function Switch( string S )
{
    SwatGameInfo(Level.Game).Admin.Switch(Self, S);
}

exec function StartGame()
{
    SwatGameInfo(Level.Game).Admin.StartGame(Self);
}

exec function AbortGame()
{
    SwatGameInfo(Level.Game).Admin.AbortGame(Self);
}

exec function ShowIDs()
{
	ToggleIDs();
}

exec function ToggleIDs()
{
    if( SwatPlayerReplicationInfo(PlayerReplicationInfo).IsAdmin() )
        ShouldDisplayPRIIds = !ShouldDisplayPRIIds;
}

function ServerUpdateCampaignProgression(ServerSettings Settings, int CampaignPath, int AvailableIndex)
{
  Settings.SetCampaignCoopSettings(self, CampaignPath, AvailableIndex);
}

///////////////////////////////////////////////////////////////////////////////
// Set the ServerSettings on the server
///////////////////////////////////////////////////////////////////////////////

function ServerSetSettings( ServerSettings Settings,
                            EMPMode newGameType,
                            int newMapIndex,
                            int newNumRounds,
                            int newMaxPlayers,
                            int newDeathLimit,
                            int newPostGameTimeLimit,
                            int newRoundTimeLimit,
                            int newMPMissionReadyTime,
                            bool newbShowTeammateNames,
                            bool newbShowEnemyNames,
							bool newbAllowReferendums,
                            bool newbNoRespawn,
                            bool newbQuickRoundReset,
                            float newFriendlyFireAmount,
                            float newEnemyFireAmount,
							float newArrestRoundTimeDeduction,
							int newAdditionalRespawnTime,
							bool newbNoLeaders,
							bool newbUseStatTracking,
							bool newbDisableTeamSpecificWeapons)
{
    Settings.SetServerSettings( self,
                                newGameType,
                                newMapIndex,
                                newNumRounds,
                                newMaxPlayers,
                                newDeathLimit,
                                newPostGameTimeLimit,
                                newRoundTimeLimit,
                                newMPMissionReadyTime,
                                newbShowTeammateNames,
                                newbShowEnemyNames,
								newbAllowReferendums,
                                newbNoRespawn,
                                newbQuickRoundReset,
                                newFriendlyFireAmount,
                                newEnemyFireAmount,
								newArrestRoundTimeDeduction,
								newAdditionalRespawnTime,
								newbNoLeaders,
								newbUseStatTracking,
								newbDisableTeamSpecificWeapons );
}

///////////////////////////////////////////////////////////////////////////////
// Set the Admin ServerSettings on the server
///////////////////////////////////////////////////////////////////////////////

function ServerSetAdminSettings( ServerSettings Settings,
                            String newServerName,
                            String newPassword,
                            bool newbPassworded,
                            bool newbLAN )
{
    Settings.SetAdminServerSettings( self,
                                newServerName,
                                newPassword,
                                newbPassworded,
                                newbLAN );
}

///////////////////////////////////////////////////////////////////////////////
// Set a map at a specific index on the server
///////////////////////////////////////////////////////////////////////////////

function ServerAddMap( ServerSettings Settings, string MapName )
{
    Settings.AddMap( self, MapName );
}

function ServerClearMaps( ServerSettings Settings )
{
    Settings.ClearMaps( self );
}

///////////////////////////////////////////////////////////////////////////////
// Set the settings to bDirty - basically ensures a fresh reset for next round
///////////////////////////////////////////////////////////////////////////////

function ServerSetDirty( ServerSettings Settings )
{
    Settings.SetDirty( self );
}

///////////////////////////////////////////////////////////////////////////////
// Server Quick Restart
///////////////////////////////////////////////////////////////////////////////

function ServerQuickRestart()
{
    SwatRepo(Level.GetRepo()).QuickServerRestart( self );
}

function ServerCoopQMMRestart()
{
	SwatRepo(Level.GetRepo()).CoopQMMServerRestart( self );
}

///////////////////////////////////////////////////////////////////////////////
//  Voice Chat
// (modified from Epic's "UnrealPlayer.uc")
///////////////////////////////////////////////////////////////////////////////

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if ( Level.NetMode == NM_Client || Level.NetMode == NM_ListenServer )
	{
		bVoiceChatEnabled = bool(ConsoleCommand("get alaudio.alaudiosubsystem UseVoIP"));

		// Marc VOIP (added): replicate flag to server (Epic doesn't need to do this because they use chat rooms)
		ServerChangeVoiceChatMode( bVoiceChatEnabled );
	}
}
/*
simulated function AutoJoinVoiceChat()
{
	local int i, j, cnt;
	local string DefaultChannel;

	if ( !bVoiceChatEnabled || (Level.NetMode != NM_Client && Level.NetMode != NM_ListenServer) )
		return;

	if ( VoiceReplicationInfo == None )
	{
		log(Name@"AutoJoinVoiceChat() do not have VRI yet!",'VoiceChat');
		return;
	}

	cnt = VoiceReplicationInfo.GetPublicChannelCount(True);
	for ( i = 0; i < cnt; i++ )
	{
		if ( bool(AutoJoinMask & (1 << i)) )
		{
			Join(VoiceReplicationInfo.PublicChannelNames[i],"");
			for ( j = RejoinChannels.Length - 1; j >= 0; j-- )
				if ( RejoinChannels[j] == VoiceReplicationInfo.PublicChannelNames[i] )
					RejoinChannels.Remove(j,1);
		}
	}

	// Rejoin any channels we were members of during the last match
	for (i = 0; i < RejoinChannels.Length; i++)
		Join(RejoinChannels[i],"");

	// If we were speaking on a particular chatroom last match, re-activate the same room, if possible
	if ( LastActiveChannel != "" )
		Speak(LastActiveChannel);

	else if ( ActiveRoom == None && bEnableInitialChatRoom )
	{
		DefaultChannel = GetDefaultActiveChannel();
		if ( DefaultChannel != "" )
			Speak(DefaultChannel);
	}

	if (RejoinChannels.Length > 0 || LastActiveChannel != "")
	{
		RejoinChannels.Length = 0;
		LastActiveChannel = "";
		SaveConfig();
	}
}*/
/*
function ClientGameEnded()
{
	local int i;
	local array<VoiceChatRoom> Channels;

	if (bVoiceChatEnabled && PlayerReplicationInfo != None && VoiceReplicationInfo != None)
	{
		log(Name@PlayerReplicationInfo.PlayerName@"ClientGameEnded()",'VoiceChat');
		Channels = VoiceReplicationInfo.GetChannels();

	// Get a list of all channels currently a member of, and store them for the next match.
		for (i = 0; i < Channels.Length; i++)
		{
			if ( Channels[i] != None && Channels[i].IsMember(PlayerReplicationInfo, True) )
				RejoinChannels[RejoinChannels.Length] = Channels[i].GetTitle();
		}

		if ( ActiveRoom != None )
			LastActiveChannel = ActiveRoom.GetTitle();
	}

	if (RejoinChannels.Length > 0 || LastActiveChannel != "")
		SaveConfig();

	Super.ClientGameEnded();
}*/

// disallow VOIP from this player
simulated function VOIPIgnore(int PlayerID)
{
	local int i;
	local int freeIndex;

	freeIndex = -1;

	// check if PlayerID is already in the list
	for (i = 0; i < ArrayCount(VOIPIgnoreStaticArray); ++i)
    {
		if (VOIPIgnoreStaticArray[i] == PlayerID)
			return;

		if (VOIPIgnoreStaticArray[i] == -1 && freeIndex == -1)
			freeIndex = i;
    }

	// add PlayerID
	if ( freeIndex >= 0 )
		VOIPIgnoreStaticArray[freeIndex] = PlayerID;
}

// allow VOIP from this player
simulated function VOIPUnIgnore(int PlayerID)
{
	local int i;

	for (i = 0; i < ArrayCount(VOIPIgnoreStaticArray); ++i)
    {
		if (VOIPIgnoreStaticArray[i] == PlayerID)
		{
			VOIPIgnoreStaticArray[i] = -1;
			break;
		}
    }
}

simulated function VOIPClearIgnore()
{
	local int i;

	for (i = 0; i < ArrayCount(VOIPIgnoreStaticArray); ++i)
    {
		VOIPIgnoreStaticArray[i] = -1;
    }
}

// is this player ignoring VOIP from "PlayerID"?
simulated event bool VOIPIsIgnored(int PlayerID)
{
	local int i;

	for (i = 0; i < ArrayCount(VOIPIgnoreStaticArray); ++i)
    {
		if (VOIPIgnoreStaticArray[i] == PlayerID)
			return true;
    }

	return false;
}

// can this player hear "PlayerID" speaking?
function bool VOIPIsSpeaking(int PlayerID)
{
	local int i;

	for (i = 0; i < player.GUIController.VOIPSpeakingPlayerIDs.Length; i++)
	{
		if ( player.GUIController.VOIPSpeakingPlayerIDs[i].PlayerID == PlayerID)
			return true;
	}

	return false;
}

///////////////////////////////////////////////////////////////////////////////
// Voting replicated function
///////////////////////////////////////////////////////////////////////////////

exec function ServerStartReferendum(PlayerController PC, class<Voting.Referendum> ReferendumClass, optional PlayerController Target, optional String TargetStr)
{
  SwatGameReplicationInfo(Level.GetGameReplicationInfo()).StartReferendum(PC, ReferendumClass, Target, TargetStr);
}

exec function ServerStartReferendumForPlayer(PlayerController PC, class<Voting.Referendum> ReferendumClass, string PlayerName)
{
  SwatGameReplicationInfo(Level.GetGameReplicationInfo()).StartReferendumForPlayer(PC, ReferendumClass, PlayerName);
}

exec function ServerVoteYes()
{
	SwatGameReplicationInfo(Level.GetGameReplicationInfo()).VoteYes(self);
}

exec function ServerVoteNo()
{
	SwatGameReplicationInfo(Level.GetGameReplicationInfo()).VoteNo(self);
}

defaultproperties
{
	CheatClass=class'SwatGame.SwatCheatManager'
    bIsPlayer=true
    FlashScale=0.5
    FlashFog=(X=900.00000,Y=0.000000,Z=0.00000)
}
