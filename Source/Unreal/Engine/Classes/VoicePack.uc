//=============================================================================
// VoicePack.
//=============================================================================
class VoicePack extends Info
	abstract;
	
/* 
ClientInitialize() sets up playing the appropriate voice segment, and returns a string
 representation of the message
*/
function ClientInitialize(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageIndex);
static function PlayerSpeech(name Type, int Index, string Callsign, Actor PackOwner);

static function byte GetMessageIndex(name PhraseName)
{
	return 0;
}

static function int PickRandomTauntFor(controller C, bool bNoMature, bool bNoHumanOnly)
{
	return 0;
}
	
defaultproperties
{
	bStatic=false
	LifeSpan=+10.0
    RemoteRole=ROLE_None
}