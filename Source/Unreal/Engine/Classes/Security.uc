// ====================================================================
//  Class:  Engine.Security
//  Parent: Engine.Info
//
//  The security package is spawned and owned by each PlayerController as they
//  enter the game.  It allows for the server to check various aspects 
//  of the client.
// ====================================================================

class Security extends Info
		Native;

// When a command is executed, it's stored here in so we always know what the 
// last command was.		
		
var int LastType;
var string LastParams[2];
		
replication
{
	reliable if (Role==ROLE_Authority)
		ClientPerform, ClientMessage;
		
	reliable if (ROLE<ROLE_Authority)
		ServerCallBack;
}	

// ====================================================================
// The security system works as follows.  The Server performs a security command
// by executing a ClientPerform call.  This will replicate to the client which then passes it 
// nativly using NativePerform.  Native perform nativally replicates the response back to the 
// response handler (ServerCallBack) for this client.
// ====================================================================

native function NativePerform(int SecType, string Param1, string Param2);

simulated function ClientPerform(int SecType, string Param1, string Param2)
{
	NativePerform(SecType, Param1, Param2);
}

event ServerCallback(int SecType, string Data)	// Should be Subclassed
{
	SetTimer(0,false);
	GotoState('');
}

// ====================================================================
// Perform causes the security system to perform a command, and then 
// wait for a response.

function Perform(int SecType, string Param1, string Param2, float TimeOut)
{
	// Store the command

	LastType = SecType;
	LastParams[0] = Param1;
	LastParams[1] = Param2;

	ClientPerform(SecType, Param1, Param2);	// Tell the client to perform the command
	SetTimer(TimeOut,false);				// Setup a timeout for the command
	GotoState('Probation');					// Client is now on probation while we await the response
}

// ====================================================================
// When the Security actor performs a security command, it enters the probationary state while
// it awaits a response.  If the TimeOut value is exceeded, the client is removed from the server.

state Probation
{
	function Timer()			// Should be SubClassed
	{
		BadClient(LastType,LastParams[0]$","$LastParams[1]);
	}
}



// ====================================================================
// The Final portion of the security is the communitcation system between
// the server and the client when something goes wrong. 
 
function BadClient(int Code, string data)	// Should be subclassed
{	
	ClientMessage("The Server has determined that your client is illegal and you have been removed! Code: "$Code$" ["$Data$"]");
	Owner.Destroy();
	Destroy();
}			
	
simulated function ClientMessage(string s)	// Should be subclassed
{
	log(S,'Security');
}
	
defaultproperties
{

}
