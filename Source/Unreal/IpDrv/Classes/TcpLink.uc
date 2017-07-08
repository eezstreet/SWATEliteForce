//=============================================================================
// TcpLink: An Internet TCP/IP connection.
//=============================================================================
class TcpLink extends InternetLink
	native
	transient;

cpptext
{
	ATcpLink();
	void PostScriptDestroyed();
	UBOOL Tick( FLOAT DeltaTime, enum ELevelTick TickType );	

	void CheckConnectionAttempt();
	void CheckConnectionQueue();
	void PollConnections();
	UBOOL FlushSendBuffer();
	void ShutdownConnection();
	virtual UBOOL ShouldTickInEntry() { return true; }
}

//-----------------------------------------------------------------------------
// Variables.

// LinkState is only valid for TcpLink at this time.
var enum ELinkState
{
	STATE_Initialized,		// Sockets is initialized
	STATE_Ready,			// Port bound, ready for activity
	STATE_Listening,		// Listening for connections
	STATE_Connecting,		// Attempting to connect
	STATE_Connected,		// Open and connected
	STATE_ListenClosePending,// Socket in process of closing
	STATE_ConnectClosePending,// Socket in process of closing
	STATE_ListenClosing,	// Socket in process of closing
	STATE_ConnectClosing	// Socket in process of closing
} LinkState;

var IpAddr	  RemoteAddr;	// Contains address of peer connected to from a Listen()

// If AcceptClass is not None, an actor of class AcceptClass will be spawned when an
// incoming connecting is accepted, leaving the listener open to accept more connections.
// Accepted() is called only in the child class.  You can use the LostChild() and GainedChild()
// events to track your children.
var class<TcpLink> AcceptClass;
var const Array<byte> SendFIFO; // send fifo
//-----------------------------------------------------------------------------
// natives.

// BindPort: Binds a free port or optional port specified in argument one.
native function int BindPort( optional int Port, optional bool bUseNextAvailable );

// Listen: Listen for connections.  Can handle up to 5 simultaneous connections.
// Returns false if failed to place socket in listen mode.
native function bool Listen();

// Open: Open a connection to a foreign host.
native function bool Open( IpAddr Addr );

// Close: Closes the current connection.   
native function bool Close();

// IsConnected: Returns true if connected.
native function bool IsConnected();

// SendText: Sends text string. 
// Appends a cr/lf if LinkMode=MODE_Line.  Returns number of bytes sent.
native function int SendText( coerce string Str );

// SendBinary: Send data as a byte array.
native function int SendBinary( int Count, byte B[255] );

// ReadText: Reads text string.
// Returns number of bytes read.  
native function int ReadText( out string Str );

// ReadBinary: Read data as a byte array.
native function int ReadBinary( int Count, out byte B[255] );

//-----------------------------------------------------------------------------
// Events.

// Accepted: Called during STATE_Listening when a new connection is accepted.
event Accepted();

// Opened: Called when socket successfully connects.
event Opened();

// Closed: Called when Close() completes or the connection is dropped.
event Closed();

// ReceivedText: Called when data is received and connection mode is MODE_Text.
event ReceivedText( string Text );

// ReceivedLine: Called when data is received and connection mode is MODE_Line.
event ReceivedLine( string Line );

// ReceivedBinary: Called when data is received and connection mode is MODE_Binary.
event ReceivedBinary( int Count, byte B[255] );

defaultproperties
{
     bAlwaysTick=True
}
