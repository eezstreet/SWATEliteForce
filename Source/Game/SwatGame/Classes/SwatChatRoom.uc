//==============================================================================
//	Main chat room class.
//  (Adapted for SWAT4)
//
//	Created by Ron Prestenback
//	© 2003, Epic Games, Inc.  All Rights Reserved
//==============================================================================
class SwatChatRoom extends Engine.VoiceChatRoom;

simulated function SetGRI(GameReplicationInfo InGRI)
{
	GRI = InGRI;
}

simulated event Timer()
{
	if ( Owner == None )
	{
		if ( VoiceChatManager != None )
			VoiceChatManager.bRefresh = True;

		Destroy();
		return;
	}
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if ( GRI == None )
	{
		foreach DynamicActors( class'GameReplicationInfo', GRI )
			break;
	}

	SetTimer(1.0, True);
}

// =====================================================================================================================
// =====================================================================================================================
//  Query Functions
// =====================================================================================================================
// =====================================================================================================================

simulated function int GetMask()
{
	if ( IsPrivateChannel() )
		return PlayerReplicationInfo(Owner).VoiceMemberMask;

	else if ( VoiceChatReplicationInfo(Owner) != None )
		return VoiceChatReplicationInfo(Owner).GetMask(Self);

	return Super.GetMask();
}

simulated function string GetTitle()
{
	if ( IsPrivateChannel() )
		return PlayerReplicationInfo(Owner).PlayerName;

	else if ( VoiceChatReplicationInfo(Owner) != None )
		return VoiceChatReplicationInfo(Owner).GetTitle(Self);

	return Super.GetTitle();
}

simulated function int GetTeam()
{
	if ( IsPrivateChannel() )
	{
		if ( PlayerReplicationInfo(Owner).Team == None )
			return Super.GetTeam();

		return PlayerReplicationInfo(Owner).Team.TeamIndex;
	}

	else if ( VoiceChatReplicationInfo(Owner) != None )
		return Super.GetTeam();
}

simulated function string GetPassword()
{
	return Password;
}

simulated function array<PlayerReplicationInfo> GetMembers()
{
	local array<PlayerReplicationInfo> PRIArray;
	local int i;

	if ( GRI != None && ValidMask() )
	{
		for ( i = 0; i < GRI.PRIArray.Length; i++ )
			if ( IsMember(GRI.PRIArray[i]) )
				PRIArray[PRIArray.Length] = GRI.PRIArray[i];
	}

	return PRIArray;
}

simulated function bool IsPublicChannel()
{
	return ChannelIndex != default.ChannelIndex && ChannelIndex < 2;
}

simulated function bool IsPrivateChannel()
{
	return PlayerReplicationInfo(Owner) != None;
}

simulated function int Count()
{
	local int i, x;
	local int MemberMask;

	if ( !ValidMask() )
		return 0;

	MemberMask = GetMask();
	for ( i = 0; i < 32; i++ )
	{
		if ( bool(MemberMask & ( 1 << i )) )
			x++;
	}

	return x;
}

simulated function bool IsFull()
{
	return GetMaxChatters() > 0 && Count() >= GetMaxChatters();
}

simulated event bool IsMember(PlayerReplicationInfo PRI, optional bool bNoCascade)
{
	if ( Super.IsMember(PRI, bNoCascade) )
		return true;

	if ( !ValidMask() )
		return false;

	if ( PRI == None || PRI.VoiceID == 255 )
		return false;

	return bool(GetMask() & ( 1 << PRI.VoiceID ));
}

// CanJoinChannel() simply returns whether this is a valid channel for the incoming PRI
// It does not consider whether a join would be successful or not.
simulated function bool CanJoinChannel(PlayerReplicationInfo PRI)
{
	if (PRI == None)
	{
		log(GetTitle()@"CanJoinChannel PRI: None returning false",'VoiceChat');
		return false;
	}

	if (Owner == None)
	{
		log(GetTitle()@"CanJoinChannel PRI:"$PRI.PlayerName@"Owner: None returning false",'VoiceChat');
		return false;
	}

	if ( IsPrivateChannel() )
		return PlayerReplicationInfo(Owner).bOnlySpectator == PRI.bOnlySpectator;

	else if ( PRI.bOnlySpectator )
		return False;

	return Super.CanJoinChannel(PRI);
}

// =====================================================================================================================
// =====================================================================================================================
//  Joins / Leaves
// =====================================================================================================================
// =====================================================================================================================

function EJoinChatResult JoinChannel(PlayerReplicationInfo NewPRI, string InPassword)
{
	local string str;

	if (NewPRI != None)
	{
		if ( NewPRI.Team != None )
			str = string(NewPRI.Team.TeamIndex);
		else str = "No Team";
		log(NewPRI.PlayerName$"("$str$") joined channel"@GetTitle()$"("$GetTeam()$")",'VoiceChat');
	}
	else log("Invalid player joined"@GetTitle(),'VoiceChat');

	// First, check if NewPlayer.Owner is our owner...
	if (NewPRI == Owner)
		return JCR_Member;

	// Next, check that this player is not already a member in this room
	if ( IsMember(NewPRI) )
		return JCR_Member;

	// Next, check if this room is passworded...if so, check the passed in password
	str = GetPassword();
	if ( str != "" )
	{
		// If no password was passed in, open password page on client
		if ( InPassword == "" )
			return JCR_NeedPassword;

		// If the password was incorrect, open the password page on the client
		if ( InPassword != str )
			return JCR_WrongPassword;

	}

	// check if this player is banned on from this channel
	if ( IsBanned(NewPRI) )
		return JCR_Banned;

	// check if the channel is full
	if ( IsFull() )
		return JCR_Full;

	// Spectators can only join other spectators channels
	if ( NewPRI.bOnlySpectator && (!IsPrivateChannel() || !PlayerReplicationInfo(Owner).bOnlySpectator) )
		return JCR_NotAllowed;

	// Join was successful
	return Super.JoinChannel(NewPRI, Password);
}

// determines whether this player is allowed to leave this channel
function bool LeaveChannel(PlayerReplicationInfo LeavingPRI)
{
	// Never allow player to leave their own private channel
	if (LeavingPRI == Owner)
		return false;

	if ( !IsMember(LeavingPRI, True) )
		return false;

	if (LeavingPRI != none)
		log(LeavingPRI.PlayerName@"left channel"@GetTitle(),'VoiceChat');
	else log("Invalid player left channel"@GetTitle(),'VoiceChat');

	return Super.LeaveChannel(LeavingPRI);
}

function AddMember(PlayerReplicationInfo PRI)
{
	//local int i;
	//local array<PlayerReplicationInfo> Members;

	if ( IsMember(PRI) )
		return;

	if ( PRI == None || PRI.VoiceID == 255 )
		return;

	if ( PRI.Team != None )
		log("Adding member"@PRI.PlayerName@"("$PRI.Team.TeamIndex$")"@"to"@GetTitle()@"("$GetTeam()$")",'VoiceChat');
	else log("Adding member"@PRI.PlayerName@"( No Team ) to"@GetTitle()@"("$GetTeam()$")",'VoiceChat');

	// marc VOIP: no ChatRoomMessage
	//if ( Level.NetMode != NM_Client )
	//{
		// Notify all members of this channel that the player has joined the channel
	//	Members = GetMembers();
	//	for ( i = 0; i < Members.Length; i++ )
	//	{
	//		if ( Members[i] != None && PlayerController(Members[i].Owner) != None )
	//			PlayerController(Members[i].Owner).ChatRoomMessage( 11, ChannelIndex, PRI );
	//	}
	//}

	SetMask(GetMask() | (1<<PRI.VoiceID));
	Super.AddMember(PRI);
}

// Called after LeaveChannel, or when player exits the server
function RemoveMember(PlayerReplicationInfo PRI)
{
	//local array<PlayerReplicationInfo> Members;
	//local int i;

	if ( PRI != None && PRI.VoiceID != 255 && IsMember(PRI, True) )
	{
		SetMask(GetMask() & ~(1<<PRI.VoiceID));

		// marc VOIP: no ChatRoomMessage
		//if ( Level.NetMode != NM_Client )
		//{
			// Notify all member of this channel that the player has left
		//	Members = GetMembers();
		//	for ( i = 0; i < Members.Length; i++ )
		//	{
		//		log(Name@"RemoveMember Members["$i$"]:"$Members[i].PlayerName,'VoiceChat');
		//		if ( Members[i] != None && PlayerController(Members[i].Owner) != None )
		//			PlayerController(Members[i].Owner).ChatRoomMessage( 12, ChannelIndex, PRI );
		//	}
		//}
	}

	Super.RemoveMember(PRI);
}

// BANNING
function bool IsBanned(PlayerReplicationInfo PRI)
{
	// marc VOIP: no Chatmanager
	return false;

	//if ( PRI == None ||
	//     PlayerReplicationInfo(Owner) == None ||
	//     PlayerController(Owner.Owner) == None ||
	//	 PlayerController(Owner.Owner).ChatManager == None )
	//	return false;

	//return PlayerController(Owner.Owner).ChatManager.IsBanned(PRI);
}

// =====================================================================================================================
// =====================================================================================================================
//  Utility functions
// =====================================================================================================================
// =====================================================================================================================

function SetTeam( int NewTeam )
{
	if ( VoiceChatReplicationInfo(Owner) == None )
		return;

	Super.SetTeam(NewTeam);
}

function SetMask( int NewMask )
{
	if ( Owner == None )
		return;

	if ( IsPrivateChannel() )
		PlayerReplicationInfo(Owner).SetVoiceMemberMask(NewMask);
	else VoiceChatReplicationInfo(Owner).SetMask(Self, NewMask);
}

simulated function bool AddChild(VoiceChatRoom NewChild)
{
	local int i;

	if (NewChild == None)
		return false;

	for (i = 0; i < Children.Length; i++)
	{
		if (Children[i] == NewChild)
			return false;
	}

	NewChild.Parent = Self;
	Children[Children.Length] = NewChild;

	return Super.AddChild(NewChild);
}

simulated function bool RemoveChild(VoiceChatRoom Child)
{
	local int i;

	for (i = Children.Length - 1; i >= 0; i--)
	{
		if (Children[i] == None)
			Children.Remove(i, 1);

		else if ( Children[i] == Child )
		{
			Children.Remove(i, 1);
			return true;
		}
	}

	return Super.RemoveChild(Child);
}

