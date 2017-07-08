//==============================================================================
//	Contains information about the existing voice chat channels on the server.
//	This class is simply a placeholder for the VoiceReplicationInfo, and should
//	be implemented in a multi-player capable subclass.
//
//	Created by Ron Prestenback
//	© 2003, Epic Games, Inc.  All Rights Reserved
//==============================================================================
class VoiceChatReplicationInfo extends ReplicationInfo
	dependsOn(VoiceChatRoom)
	config
	abstract
	notplaceable
	native
	nativereplication;

cpptext
{

	INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, UActorChannel* Channel );
}

const NUMPROPS = 6;

struct native VoiceChatCodec
{
	var string Codec;
	var localized string CodecName;
	var localized string CodecDescription;
};

var int PublicMask, LocalMask;

// Array of chatroom channels
var protected array<VoiceChatRoom>	Channels;
var localized array<string> PublicChannelNames;
var localized string VCDisplayText[NUMPROPS], VCDescText[NUMPROPS];

var GameReplicationInfo GRI;

var class<VoiceChatRoom>	ChatRoomClass;
var array<VoiceChatCodec>  InstalledCodec;

var globalconfig array<string>  VoIPInternetCodecs;
var globalconfig array<string>  VoIPLANCodecs;

var globalconfig bool		bEnableVoiceChat;         // Whether voice over IP is enabled on this server
var globalconfig bool 		bAllowLocalBroadcast;     // Whether this server allows local channels
var globalconfig int        MaxChatters;              // Max number of chatters allowed in a chatroom (0 - unlimited)
var              int        DefaultChannel;           // Channel that should be the default active channel for incoming clients that don't specify a default active channel

var globalconfig float      LocalBroadcastRange;	  // Maximum distance a local broadcast can be heard
var globalconfig float      DefaultBroadcastRadius;	  // Distance at which broadcast volume begins to fade
var float                   BroadcastRadius;

var bool					bPrivateChat;	          // Set by UnrealMPGameInfo.InitVoiceReplicationInfo()
var bool					bRefresh;		          // Indicates a chat room has destroyed itself

replication
{
	reliable if ( Role == ROLE_Authority && bNetInitial )
		bEnableVoiceChat;

	reliable if ( Role == ROLE_Authority && bNetInitial && bEnableVoiceChat )
		bPrivateChat;

	reliable if ( Role == ROLE_Authority && bNetInitial && bEnableVoiceChat && bAllowLocalBroadcast )
		BroadcastRadius;

	reliable if ( Role == ROLE_Authority && bNetDirty && bEnableVoiceChat )
		PublicMask, LocalMask;

	reliable if ( Role == ROLE_Authority && (bNetInitial || bNetDirty) && bEnableVoiceChat )
		DefaultChannel;
}

event Timer()
{
	// One of our channels has destroyed itself
	if (bRefresh)
		CheckChannels();
}

event PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( bAllowLocalBroadcast )
		BroadcastRadius = FMin(LocalBroadcastRange, FClamp(DefaultBroadcastRadius, 10, 1000));
}

simulated event PostNetBeginPlay()
{
	// Initialize all public channels.
	if ( bEnableVoiceChat )
	{
		InitChannels();
		SetTimer(1.0, True);
	}
}
simulated function InitChannels();

// This is called when a new player has logged into the server.
simulated function              AddVoiceChatter(PlayerReplicationInfo    NewPRI);
// Called when a player logs out
simulated function 				RemoveVoiceChatter(PlayerReplicationInfo 	PRI);
// Used to prescreen whether 'PRI' would be allowed to join channel with title 'ChannelTitle'
simulated function bool			CanJoinChannel(string ChannelTitle, PlayerReplicationInfo PRI) { return true; }

// Joins / Leaves
// Called when player requests to join channel
function VoiceChatRoom.EJoinChatResult        JoinChannel(string ChannelTitle, PlayerReplicationInfo PRI, string Password) { return JCR_Invalid;  }
function VoiceChatRoom.EJoinChatResult        JoinChannelAt(int ChannelIndex, PlayerReplicationInfo PRI, string Password)  { return JCR_Invalid;  }
// Called when player leaves channel
function bool					LeaveChannel(string ChannelTitle, PlayerReplicationInfo PRI)                 { return true; }

// Channel management
simulated function VoiceChatRoom 		AddVoiceChannel(optional PlayerReplicationInfo PRI)    { return None; }
simulated function bool 				RemoveVoiceChannel(PlayerReplicationInfo PRI) { return true; }
// Called on all voice channels when a player switches teams.  Disregarded by voice channel if TeamIndex doesn't match channel's teamindex
simulated function 						NotifyTeamChange(PlayerReplicationInfo PRI, int TeamIndex);

// Query Functions
simulated event    int                  GetChannelCount()                                            { return 0;    }
simulated event    int                  GetChannelIndex(string ChannelTitle, optional int TeamIndex) { return -1;   }

simulated function VoiceChatRoom        GetChannel(string ChatRoomName, optional int TeamIndex)      { return None; }
simulated function VoiceChatRoom		GetChannelAt(int Index)                                      { return None; }
// Returns a list of members in the specified channel
simulated function array<int> 			GetChannelMembers(string ChatRoomName, optional int TeamIndex);
simulated function array<int>			GetChannelMembersAt(int Index);
// Returns a list of channels that the specified player is a member of
simulated function array<int>			GetMemberChannels( PlayerReplicationInfo PRI );

simulated function string               GetDefaultChannel()
{
	return PublicChannelNames[Clamp(DefaultChannel,0,PublicChannelNames.Length - 1)];
}

simulated function array<VoiceChatRoom> GetChannels();
simulated function array<VoiceChatRoom>	GetPublicChannels();
simulated function array<VoiceChatRoom>	GetPlayerChannels();
simulated function int                  GetPublicChannelCount(optional bool bSingleTeam);
simulated function int                  GetPlayerChannelCount();
// Returns whether 'TestPRI' is a member of this channel.  If bNoCacade is false, will return true if player is member of child channels
simulated function bool					IsMember(PlayerReplicationInfo TestPRI, int ChannelIndex, optional bool bNoCascade) { return false; }
// Internal functions
simulated protected function VoiceChatRoom	CreateNewVoiceChannel(optional PlayerReplicationInfo PRI) { return None; }
// Called from RemoveVoiceChatter()
simulated protected function 						DestroyVoiceChannel(VoiceChatRoom Channel);
simulated private 	function			CheckChannels()
{
	local int i;

	for (i = Channels.Length - 1; i >= 0; i--)
		if (Channels[i] == None)
			Channels.Remove(i,1);

	bRefresh = False;
}

///static function FillPlayInfo( PlayInfo PlayInfo )
///{
///	Super.FillPlayInfo( PlayInfo );

///	PlayInfo.AddSetting( default.ChatGroup, "bEnableVoiceChat",        default.VCDisplayText[0], 250, 1, "Check",            , "Xv", True, True);
///	PlayInfo.AddSetting( default.ChatGroup, "bAllowLocalBroadcast",    default.VCDisplayText[1], 250, 1, "Check",            , "Xv", True, True);
///	PlayInfo.AddSetting( default.ChatGroup, "LocalBroadcastRange",     default.VCDisplayText[2], 100, 1,  "Text", "4;10:3000", "Xv", True, True);
///	PlayInfo.AddSetting( default.ChatGroup, "DefaultBroadcastRadius",  default.VCDisplayText[3], 100, 1,  "Text", "4;10:1000", "Xv", True, True);
///	PlayInfo.AddSetting( default.ChatGroup, "VoIPInternetCodecs",      default.VCDisplayText[4], 254, 1,  "Text",            , "Xv", True, True);
///	PlayInfo.AddSetting( default.ChatGroup, "VoIPLANCodecs",           default.VCDisplayText[5], 254, 1,  "Text",            , "Xv", True, True);
///}

///static event string GetDescriptionText( string PropName )
///{
///	switch ( PropName )
///	{
///	case "bEnableVoiceChat":        return default.VCDescText[0];
///	case "bAllowLocalBroadcast":    return default.VCDescText[1];
///	case "LocalBroadcastRange":     return default.VCDescText[2];
///	case "DefaultBroadcastRadius":  return default.VCDescText[3];
///	case "VoIPInternetCodecs":      return default.VCDescText[4];
///	case "VoIPLANCodecs":           return default.VCDescText[5];
///	}

///	return Super.GetDescriptionText(PropName);
///}

static function GetInstalledCodecs( out array<string> Codecs )
{
	local int i;

	Codecs.Length = default.InstalledCodec.Length;
	for ( i = 0; i < default.InstalledCodec.Length; i++ )
		Codecs[i] = default.InstalledCodec[i].Codec;
}

static function bool GetCodecInfo( string Codec, out string CodecName, out string CodecDescription )
{
	local int i;

	for ( i = 0; i < default.InstalledCodec.Length; i++ )
	{
		if ( Codec ~= default.InstalledCodec[i].Codec )
		{
			CodecName = default.InstalledCodec[i].CodecName;
			CodecDescription = default.InstalledCodec[i].CodecDescription;
			return true;
		}
	}

	return false;
}

simulated function bool ValidRoom( VoiceChatRoom Room )
{
	return bEnableVoiceChat && Room != None && Room.ChannelIndex < 2 && Room.Owner == Self;
}

function SetMask( VoiceChatRoom Room, int NewMask )
{
	if ( !ValidRoom(Room) )
		return;

	if ( Room.ChannelIndex == 0 )
		PublicMask = NewMask;

	else if ( Room.ChannelIndex == 1 )
		LocalMask = NewMask;
}

simulated function int GetMask( VoiceChatRoom Room )
{
	if ( !ValidRoom(Room) )
		return 0;

	if ( Room.ChannelIndex == 0 )
		return PublicMask;

	if ( Room.ChannelIndex == 1 )
		return LocalMask;

	return 0;
}

simulated function string GetTitle( VoiceChatRoom Room )
{
	if ( !ValidRoom(Room) )
		return "";

	return PublicChannelNames[Room.ChannelIndex];
}

DefaultProperties
{
	NetPriority=3.001
	ChatRoomClass=class'Engine.VoiceChatRoom'
	PublicChannelNames(0)="Public"
	PublicChannelNames(1)="Local"

	InstalledCodec[0]=(Codec="CODEC_48NB",CodecName="Less Bandwidth",CodecDescription="(4.8kbps) - Uses less bandwidth, but sound is not as clear.")
	InstalledCodec[1]=(Codec="CODEC_96WB",CodecName="Better Quality",CodecDescription="(9.6kbps) - Uses more bandwidth, but sound is much clearer.")

	VCDisplayText[0]="Enable Voice Chat"
	VCDisplayText[1]="Enable local Channel"
	VCDisplayText[2]="Local Chat Range"
	VCDisplayText[3]="Local Chat Radius"
	VCDisplayText[4]="Allowed VoIP Codecs"
	VCDisplayText[5]="Allowed VoIP LAN Codecs"

	VCDescText[0]="Enable voice chat on the server."
	VCDescText[1]="Determines whether the \"local\" voice chat channel is created, which allows players to broadcast voice transmissions to all players in the immediate vicinity."
	VCDescText[2]="Maximum distance at which a broadcast on the local channel may be heard"
	VCDescText[3]="Distance at which local broadcasts begin to fade"
	VCDescText[4]="Configure which codecs exist on the server and should be used in Internet games."
	VCDescText[5]="Configure which codecs exist on the server and should be used in LAN games."

	bEnableVoiceChat=True
	bAllowLocalBroadcast=True

	LocalBroadcastRange=1000
	DefaultBroadcastRadius=20

	VoIPInternetCodecs[0]="CODEC_48NB"

	VoIPLANCodecs[0]="CODEC_48NB"
	VoIPLANCodecs[1]="CODEC_96WB"
}
