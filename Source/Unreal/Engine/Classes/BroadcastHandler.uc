//=============================================================================
// BroadcastHandler
//
// Message broadcasting is delegated to BroadCastHandler by the GameInfo.
// The BroadCastHandler handles both text messages (typed by a player) and
// localized messages (which are identified by a LocalMessage class and id).
// GameInfos produce localized messages using their DeathMessageClass and
// GameMessageClass classes.
//
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class BroadcastHandler extends Info;

// rjp --  Generally, you should only need to override the 'Accept' functions
var BroadcastHandler 		NextBroadcastHandler;
var class<BroadcastHandler> NextBroadcastHandlerClass;
// -- rjp

var	int			    SentText;
var config bool		bMuteSpectators;			// Whether spectators are allowed to speak.
var config bool		bPartitionSpectators;			// Whether spectators are can only speak to spectators.

function UpdateSentText()
{
	SentText = 0;
}

/* Whether actor is allowed to broadcast messages now.
*/
function bool AllowsBroadcast( actor broadcaster, int Len )
{
	if ( bMuteSpectators && (PlayerController(Broadcaster) != None)
		&& !PlayerController(Broadcaster).PlayerReplicationInfo.bAdmin
		&& (PlayerController(Broadcaster).PlayerReplicationInfo.bOnlySpectator
			|| PlayerController(Broadcaster).PlayerReplicationInfo.bOutOfLives)  )
		return false;

	SentText += Len;
	return ( (Level.Pauser != None) || (SentText < 400) );
}


function BroadcastText( PlayerReplicationInfo SenderPRI, PlayerController Receiver, coerce string Msg, optional name Type, optional string Location )
{
	Receiver.TeamMessage( SenderPRI, Msg, Type, Location );
}

function BroadcastLocalized( Actor Sender, PlayerController Receiver, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Core.Object OptionalObject )
{
	Receiver.ReceiveLocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
}

#if IG_SWAT // dbeswick: broadcast send to Target only
function Broadcast( Actor Sender, coerce string Msg, optional name Type, optional PlayerController Target, optional string Location )
#else
function Broadcast( Actor Sender, coerce string Msg, optional name Type )
#endif
{
	local Controller C;
	local PlayerController P;
	local PlayerReplicationInfo PRI;

	// see if allowed (limit to prevent spamming)

	if ( !AllowsBroadcast(Sender, Len(Msg)) )
	{
		return;
	}

	if ( Pawn(Sender) != None )
		PRI = Pawn(Sender).PlayerReplicationInfo;
	else if ( Controller(Sender) != None )
		PRI = Controller(Sender).PlayerReplicationInfo;

	if ( bPartitionSpectators && (PRI != None) && (PRI.bOnlySpectator || PRI.bOutOfLives) )
	{
		For ( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			P = PlayerController(C);
#if IG_SWAT // dbeswick: broadcast send to Target only
			if ( (P != None) && (P.PlayerReplicationInfo.bOnlySpectator || P.PlayerReplicationInfo.bOutOfLives) && (Target == None || Target == P) )
#else
			if ( (P != None) && (P.PlayerReplicationInfo.bOnlySpectator || P.PlayerReplicationInfo.bOutOfLives) )
#endif
				BroadcastText(PRI, P, Msg, Type, Location);
		}
	}
	else
	{
	For ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		P = PlayerController(C);
#if IG_SWAT // dbeswick: broadcast send to Target only
		if ( P != None && (Target == None || Target == P) )
#else
		if ( P != None )
#endif
		BroadcastText(PRI, P, Msg, Type, Location);
	}
}
}

function BroadcastTeam( Controller Sender, coerce string Msg, optional name Type, optional string Location )
{
	local Controller C;
	local PlayerController P;

	// see if allowed (limit to prevent spamming)
	if ( !AllowsBroadcast(Sender, Len(Msg)) )
		return;

	if ( bPartitionSpectators && (Sender != None) && (Sender.PlayerReplicationInfo.bOnlySpectator || Sender.PlayerReplicationInfo.bOutOfLives) )
	{
		For ( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			P = PlayerController(C);
			if ( (P != None) && (P.PlayerReplicationInfo.Team == Sender.PlayerReplicationInfo.Team)
				&& (P.PlayerReplicationInfo.bOnlySpectator || P.PlayerReplicationInfo.bOutOfLives) )
				BroadcastText(Sender.PlayerReplicationInfo, P, Msg, Type, Location);
		}
	}
	else
	{
	For ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		P = PlayerController(C);
		if ( (P != None) && (P.PlayerReplicationInfo.Team == Sender.PlayerReplicationInfo.Team) )
			BroadcastText(Sender.PlayerReplicationInfo, P, Msg, Type, Location);
	}
}
}

/*
 Broadcast a localized message to all players.
 Most messages deal with 0 to 2 related PRIs.
 The LocalMessage class defines how the PRI's and optional actor are used.
*/
event AllowBroadcastLocalized( actor Sender, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Core.Object OptionalObject )
{
	local Controller C;
	local PlayerController P;

	For ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		P = PlayerController(C);
		if ( P != None )
		BroadcastLocalized(Sender, P, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
	}
}

// rjp --- Linked list for broadcast handlers
function RegisterBroadcastHandler(BroadcastHandler NewBH)
{
	if ( NextBroadcastHandler == None )
	{
		NextBroadcastHandler = NewBH;
		default.NextBroadcastHandlerClass = NewBH.Class;
	}

	else NextBroadcastHandler.RegisterBroadcastHandler(NewBH);
}

function bool AcceptBroadcastText( PlayerController Receiver, PlayerReplicationInfo SenderPRI, out string Msg, optional name Type )
{
	if ( NextBroadcastHandler != None )
		return NextBroadcastHandler.AcceptBroadcastText(Receiver, SenderPRI, Msg, Type);

	return true;
}

function bool AcceptBroadcastLocalized(PlayerController Receiver, Actor Sender, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object Obj)
{
	if ( NextBroadcastHandler != None )
		return NextBroadcastHandler.AcceptBroadcastLocalized(Receiver, Sender, Message, Switch, RelatedPRI_1, RelatedPRI_2, Obj);

	return true;
}

function bool AcceptBroadcastSpeech(PlayerController Receiver, PlayerReplicationInfo SenderPRI)
{
	if ( NextBroadcastHandler != None )
		return NextBroadcastHandler.AcceptBroadcastSpeech(Receiver, SenderPRI);

	return true;
}

function bool AcceptBroadcastVoice(PlayerController Receiver, PlayerReplicationInfo SenderPRI)
{
	if ( NextBroadcastHandler != None )
		return NextBroadcastHandler.AcceptBroadcastVoice(Receiver, SenderPRI);

	return true;
}
// --- rjp

defaultproperties
{
}
