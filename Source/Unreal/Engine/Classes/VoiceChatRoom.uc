//==============================================================================
//	Contains information about a single voice chat room on the server
//
//	If public channel - owner will be GameInfo.VoiceReplicationInfo
//	If private channel - owner is client's PlayerReplicationInfo
//
//	Written by Ron Prestenback
//	© 2003, Epic Games, Inc.  All Rights Reserved
//==============================================================================
class VoiceChatRoom extends Info
	config(User)
	abstract
	notplaceable
	native;

enum EJoinChatResult
{
	JCR_Invalid,                    // Unspecified error (replication hasn't finished, etc.)
	JCR_Member,                     // Already a member
	JCR_NeedPassword,               // Password protected
	JCR_WrongPassword,              // Incorrect password specified in join request
	JCR_Banned,                     // Player is banned from this channel
	JCR_Full,                       // Channel is full
	JCR_NotAllowed,                 // Improper join (opposite teams, etc.)
	JCR_Success                     // Successful join
};

var GameReplicationInfo GRI;
var VoiceChatReplicationInfo VoiceChatManager;

// Cascading channels - any communication sent to parent channel will also be sent to child channels
var VoiceChatRoom        Parent;
var array<VoiceChatRoom> Children;

var string Password;	// Password for this chatroom - ignored if public

// Channel index ensures that the server and client always reference the same chatroom
// If this is a player channel, it will be the PlayerReplication.PlayerID + number of public channels
var int ChannelIndex;
var bool bLocal;					// - not yet implemented

var private int TeamIndex;

// =====================================================================================================================
// =====================================================================================================================
//  Query Functions
// =====================================================================================================================
// =====================================================================================================================

simulated function array<PlayerReplicationInfo> GetMembers();
simulated function int    GetMaxChatters()                          { return VoiceChatManager.MaxChatters; }
simulated function int    GetMask()                                 { return 0;              }
simulated function string GetPassword()                             { return "";             }
simulated function bool   ValidMask()                               { return GetMask() > 0;  }
simulated function string GetTitle()                                { return "";             }
simulated function int    GetTeam()                                 { return TeamIndex;      }
simulated function bool   IsPublicChannel()                         { return true;           }
simulated function bool   IsTeamChannel()                           { return false;          }
simulated function bool   IsPrivateChannel()                        { return false;          }
simulated function bool   CanJoinChannel(PlayerReplicationInfo PRI) { return true;           }
simulated function bool   IsFull()                                  { return false;          }
simulated event    bool   IsMember(PlayerReplicationInfo PRI, optional bool bNoCascade)
{
	local int i;

	if ( bNoCascade )
		return false;

	for (i = 0; i < Children.Length; i++)
	{
		if ( Children[i] != None && Children[i].IsMember(PRI) )
			return true;
	}

	return false;
}

// =====================================================================================================================
// =====================================================================================================================
//  Joins / Leaves
// =====================================================================================================================
// =====================================================================================================================

// Does not actually add the player to this channel - handles authentication & access control
function EJoinChatResult JoinChannel(PlayerReplicationInfo NewPRI, string InPassword) { return JCR_Success;  }
function bool LeaveChannel(PlayerReplicationInfo LeavingPRI)                        { return true; }

// Actually adds the PlayerReplicationInfo to this channel's virtual member list
function AddMember(PlayerReplicationInfo PRI);
function RemoveMember(PlayerReplicationInfo PRI);

// =====================================================================================================================
// =====================================================================================================================
//  Utility Functions
// =====================================================================================================================
// =====================================================================================================================

simulated function SetTeam( int NewTeam )                   { TeamIndex = NewTeam; }
simulated function SetMemberMask( int NewMask );
simulated function SetChannelPassword( string InPassword )  { Password = InPassword; }

// Registers a cascaded channel
simulated function bool AddChild(VoiceChatRoom NewChild)     { return true;  }
simulated function bool RemoveChild(VoiceChatRoom Child)     { return false; }

// Called from VoiceReplicationInfo when a player changes team
simulated function bool NotifyTeamChange(PlayerReplicationInfo PRI, int NewTeamIndex) { return false; }

DefaultProperties
{
	RemoteRole=ROLE_None
	ChannelIndex=-1
}
