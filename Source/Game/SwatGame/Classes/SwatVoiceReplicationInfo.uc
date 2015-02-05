//==============================================================================
//	Primary VoiceChatReplicationInfo for UT2004
//  (Adapted for SWAT4)
//
//	Created by Ron Prestenback
//	© 2003, Epic Games, Inc.  All Rights Reserved
//==============================================================================
class SwatVoiceReplicationInfo extends Engine.VoiceChatReplicationInfo;

var() class<Engine.BroadcastHandler> 	ChatBroadcastClass;
var Engine.BroadcastHandler				ChatBroadcastHandler;

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	local int i, j;
	local array<VoiceChatRoom> Rooms;
	local array<PlayerReplicationInfo> Members;
	local string TeamString;

	Canvas.SetDrawColor(255,220,100,230);
	Canvas.DrawText("VOICECHAT | bPrivateChat:"$bPrivateChat);

	Rooms = GetChannels();
	for (i = 0; i < Rooms.Length; i++)
	{
		YPos += YL;
		Canvas.SetPos(4,YPos);
		if ( Rooms[i] != None )
		{
			Members = Rooms[i].GetMembers();
			Canvas.DrawText(" Name:"@Rooms[i].GetTitle()@"Members:"$Members.Length@"  Index:"$Rooms[i].ChannelIndex@" Team:"$class'TeamInfo'.default.ColorNames[Rooms[i].GetTeam()]@" Mask:"$Rooms[i].GetMask()@" P:"$Rooms[i].IsPublicChannel()@" T:"$Rooms[i].IsTeamChannel());
			for (j = 0; j < Members.Length; j++)
			{
				YPos += YL;
				Canvas.SetPos(4,YPos);
				if ( Members[j].Team == None )
					TeamString = "None";
				else TeamString = class'TeamInfo'.default.ColorNames[Members[j].Team.TeamIndex];
				Canvas.DrawText("          "$Members[j].PlayerName@"ID:"$Members[j].PlayerID@"Mask:"$Members[j].VoiceID@"Team:"$TeamString);
			}
		}

		else
		{
			Canvas.DrawText("CHANNEL"@i@"IS NONE!");
		}
	}

	YPos += YL;
	Canvas.SetPos(4,YPos);
}

event PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( ChatBroadcastClass != None )
		ChatBroadcastHandler = Spawn(ChatBroadcastClass);

	else ChatBroadcastHandler = Spawn(class'Engine.BroadcastHandler');
	if ( Level.Game.BroadcastHandler != None )
		Level.Game.BroadcastHandler.RegisterBroadcastHandler(ChatBroadcastHandler);
}

simulated event PostNetBeginPlay()
{
	local PlayerReplicationInfo PRI;

	log(Name@"___________________PostNetBeginPlay",'VoiceChat');
	Super.PostNetBeginPlay();

	foreach DynamicActors(class'PlayerReplicationInfo', PRI)
		PRI.VoiceInfo = Self;
}

simulated event SetGRI(GameReplicationInfo NewGRI)
{
	// SetGRI is called at the end of GameReplicationInfo.PostNetBeginPlay()
	GRI = NewGRI;
	GRI.VoiceReplicationInfo = Self;
}

simulated function InitChannels()
{
	local VoiceChatRoom VCR;

	Super.InitChannels();

	// Add Public channel
	AddVoiceChannel();
	if ( bAllowLocalBroadcast )
	{
		// Add Local channel
		VCR = AddVoiceChannel();
		VCR.bLocal = True;
	}
}

simulated function AddVoiceChatter(PlayerReplicationInfo NewPRI)
{
	if ( NewPRI == None )
	{
		log("AddVoiceChatter() not executing: NewPRI is NONE!",'VoiceChat');
		return;
	}

	if (!bEnableVoiceChat || NewPRI.bOnlySpectator || NewPRI.bBot || (NewPRI.Owner != None && SwatPlayerController(NewPRI.Owner) == None) )
		return;

	log("AddVoiceChatter:"$NewPRI@NewPRI.PlayerName@NewPRI.VoiceID,'VoiceChat');
	AddVoiceChannel(NewPRI);
}
simulated function RemoveVoiceChatter(PlayerReplicationInfo PRI)
{
//	local PlayerController PC;
	if (PRI == None)
		return;

	log("RemoveVoiceChatter:"$PRI@PRI.PlayerName,'VoiceChat');

	// marc VOIP: no Chatmanager
	// Player logging out - remove their ban tracking information and their personal chat channel
	//if ( Role < ROLE_Authority )
	//{
	//	PC = Level.GetLocalPlayerController();
	//	if ( PC != None && PC.ChatManager != None )
	//		PC.ChatManager.UntrackPlayer(PRI.PlayerID);
	//}

	RemoveVoiceChannel(PRI);
}

simulated function bool CanJoinChannel(string ChannelTitle, PlayerReplicationInfo PRI)
{
	local VoiceChatRoom VCR;
	local int i;

	if ( PRI != None && PRI.Team != None)
		i = PRI.Team.TeamIndex;

	VCR = GetChannel(ChannelTitle, i);
	if (VCR == None)
		return false;

	return VCR.CanJoinChannel(PRI);
}

// Joins / Leaves
function VoiceChatRoom.EJoinChatResult JoinChannel(string ChannelTitle, PlayerReplicationInfo PRI, string Password)
{
	local VoiceChatRoom VCR;
	local int i;

	if (PRI != None && PRI.Team != None)
		i = PRI.Team.TeamIndex;

	VCR = GetChannel(ChannelTitle, i);
	if (VCR == None)
		return JCR_Invalid;

	return VCR.JoinChannel(PRI, Password);
}
function VoiceChatRoom.EJoinChatResult JoinChannelAt(int ChannelIndex, PlayerReplicationInfo PRI, string Password)
{
	local VoiceChatRoom VCR;

	VCR = GetChannelAt(ChannelIndex);
	if ( VCR == None )
		return JCR_Invalid;

	return VCR.JoinChannel(PRI, Password);
}
function bool LeaveChannel(string ChannelTitle, PlayerReplicationInfo PRI)
{
	local VoiceChatRoom VCR;
	local int i;

	if (PRI != None && PRI.Team != None)
		i = PRI.Team.TeamIndex;

	VCR = GetChannel(ChannelTitle, i);
	return VCR.LeaveChannel(PRI);
}

// Channel management
// player joined - create a private chatroom for that player
// Must happen after PRI.PlayerID has been assigned and replicated
simulated function VoiceChatRoom AddVoiceChannel(optional PlayerReplicationInfo PRI)
{
	local int i, cnt;
	local VoiceChatRoom VCR;

	log(Name@"AddVoiceChannel PRI:"$PRI,'VoiceChat');
	VCR = CreateNewVoiceChannel(PRI);
	if (VCR != None)
	{
		VCR.VoiceChatManager = Self;
		i = Channels.Length;
		cnt = GetPublicChannelCount();
		if (PRI == None)
			VCR.ChannelIndex = i;
		else
		{
			VCR.ChannelIndex = cnt + PRI.PlayerID;
			PRI.PrivateChatRoom = VCR;

			// Owner of the channel is always a member
			VCR.AddMember(PRI);
		}

		for ( i = 0; i < Channels.Length; i++ )
			if ( Channels[i] != None && Channels[i].ChannelIndex > VCR.ChannelIndex )
				break;

		Channels.Insert(i, 1);
		Channels[i] = VCR;
	}

	return VCR;
}
// player left - destroy the private chatroom for that player
simulated function bool	RemoveVoiceChannel(PlayerReplicationInfo PRI)
{
	local VoiceChatRoom VCR;
	local int i;

	if ( PRI != None && Role == ROLE_Authority )
		PRI.ActiveChannel = -1;

	// Remove this PRI from all channels that they were a member of
	for (i = Channels.Length - 1; i >= 0; i--)
	{
		if (Channels[i] != None)
		{
			if (Channels[i].Owner == PRI)
			{
				VCR = Channels[i];
				Channels.Remove(i,1);
			}

			else Channels[i].RemoveMember(PRI);
		}

		else Channels.Remove(i,1);
	}

	// already destroyed
	if (VCR == None)
		return Super.RemoveVoiceChannel(PRI);

	DestroyVoiceChannel(VCR);
	return Super.RemoveVoiceChannel(PRI);
}

// Query Functions
// return a single chat room
simulated function VoiceChatRoom GetChannel(string ChatRoomName, optional int TeamIndex)
{
	local int i;

	for (i = 0; i < Channels.Length; i++)
		if (Channels[i] != None && Channels[i].GetTitle() ~= ChatRoomName && Channels[i].Owner != None)
			return Channels[i];

	return Super.GetChannel(ChatRoomName, TeamIndex);
}
simulated function VoiceChatRoom GetChannelAt(int Index)
{
	local int i;

	if ( Index < 0 )
		return None;

	for (i = 0; i < Channels.Length; i++)
		if (Channels[i] != None && Channels[i].ChannelIndex == Index && Channels[i].Owner != None)
			return Channels[i];

	return Super.GetChannelAt(Index);
}
simulated function array<int> GetChannelMembers(string ChatRoomName, optional int TeamIndex)
{
	local VoiceChatRoom Room;
	local array<PlayerReplicationInfo> Members;
	local array<int> MemberIds;
	local int i;

	Room = GetChannel(ChatRoomName, TeamIndex);

	if (Room != None)
	{
		Members = Room.GetMembers();
		MemberIds.Length = Members.Length;
		for (i = 0; i < Members.Length; i++)
		{
			if ( Members[i] != None )
				MemberIds[i] = Members[i].PlayerID;
		}
	}

	return MemberIds;
}
simulated function array<int> GetChannelMembersAt(int Index)
{
	local VoiceChatRoom Room;
	local array<PlayerReplicationInfo> Members;
	local array<int> MemberIds;
	local int i;

	Room = GetChannelAt(Index);
	if (Room != None)
	{
		Members = Room.GetMembers();
		MemberIds.Length = Members.Length;
		for (i = 0; i < Members.Length; i++)
		{
			if ( Members[i] != None )
				MemberIds[i] = Members[i].PlayerID;
		}
	}

	return MemberIds;
}

simulated function array<int> GetMemberChannels(PlayerReplicationInfo PRI)
{
	local array<int> ChannelIndexArray;
	local int i;

	for ( i = 0; i < Channels.Length; i++ )
		if ( Channels[i] != None && Channels[i].IsMember(PRI) )
			ChannelIndexArray[ChannelIndexArray.Length] = Channels[i].ChannelIndex;

	return ChannelIndexArray;
}

simulated function array<VoiceChatRoom> GetChannels()
{
	return Channels;
}
simulated event int GetChannelCount()
{
	return Channels.Length;
}
simulated event int GetChannelIndex(string ChannelTitle, optional int TeamIndex)
{
	local int i;

	for (i = 0; i < Channels.Length; i++)
		if (Channels[i] != None && Channels[i].GetTitle() ~= ChannelTitle)
			return Channels[i].ChannelIndex;

	return Super.GetChannelIndex(ChannelTitle, TeamIndex);
}
simulated function array<VoiceChatRoom>	GetPublicChannels()
{
	local array<VoiceChatRoom> Rooms;
	local int i;

	for (i = 0; i < Channels.Length; i++)
		if (Channels[i] != None && Channels[i].Owner == Self)
			Rooms[Rooms.Length] = Channels[i];

	return Rooms;
}
simulated function array<VoiceChatRoom>	GetPlayerChannels()
{
	local array<VoiceChatRoom> Rooms;
	local int i;

	for (i = 0; i < Channels.Length; i++)
	{
		if (Channels[i] != None && Channels[i].Owner != None && Channels[i].Owner != Self)
			Rooms[Rooms.Length] = Channels[i];
	}

	return Rooms;
}
simulated function int GetPublicChannelCount(optional bool bSingleTeam)
{
	local int i, cnt;

	for ( i = 0; i < Channels.Length; i++ )
		if ( Channels[i] != None && Channels[i].Owner == Self && (Channels[i].GetTeam() == 0 || !bSingleTeam) )
			cnt++;

	return cnt;
}
simulated function int GetPlayerChannelCount()
{
	local array<VoiceChatRoom> Arr;
	Arr = GetPlayerChannels();
	return Arr.Length;
}

simulated function bool IsMember(PlayerReplicationInfo TestPRI, int ChannelIndex, optional bool bNoCascade)
{
	local VoiceChatRoom VCR;

	if ( TestPRI == None )
		return false;

	VCR = GetChannelAt(ChannelIndex);
	if ( VCR == None )
		return false;

	return VCR.IsMember(TestPRI, bNoCascade);
}

// Internal functions
simulated protected function VoiceChatRoom	CreateNewVoiceChannel(optional PlayerReplicationInfo PRI)
{
	local int i;

	if (PRI == None)
		return Spawn(ChatRoomClass, Self);

	for (i = 0; i < Channels.Length; i++)
		if (Channels[i].Owner == PRI)
			return Super.CreateNewVoiceChannel(PRI);

	return Spawn(ChatRoomClass, PRI);
}
simulated protected function DestroyVoiceChannel(VoiceChatRoom Channel)
{
	if (Channel != None)
	{
		Channel.Destroy();
		bRefresh = True;
	}
}

DefaultProperties
{
	DefaultChannel=1
	//ChatBroadcastClass=class'UnrealGame.UnrealChatHandler'
	ChatRoomClass=class'SwatGame.SwatChatRoom'
}
