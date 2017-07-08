//=============================================================================
// MessagingSpectator - spectator base class for game helper spectators which receive messages
//=============================================================================

class MessagingSpectator extends PlayerController
	abstract;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	bIsPlayer = False;
}
