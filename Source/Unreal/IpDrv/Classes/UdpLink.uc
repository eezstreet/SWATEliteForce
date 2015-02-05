//=============================================================================
// UdpLink: An Internet UDP connectionless socket.
//=============================================================================
class UdpLink extends InternetLink
	native
	transient;

cpptext
{
	AUdpLink();
	void PostScriptDestroyed();
	UBOOL Tick( FLOAT DeltaTime, enum ELevelTick TickType );	
	FSocketData GetSocketData();
}

//-----------------------------------------------------------------------------
// Variables.

var() const int BroadcastAddr;

//-----------------------------------------------------------------------------
// Natives.

// BindPort: Binds a free port or optional port specified in argument one.
native function int BindPort( optional int Port, optional bool bUseNextAvailable );

// SendText: Sends text string.  
// Appends a cr/lf if LinkMode=MODE_Line .
native function bool SendText( IpAddr Addr, coerce string Str );

// SendBinary: Send data as a byte array.
native function bool SendBinary( IpAddr Addr, int Count, byte B[255] );

// ReadText: Reads text string.
// Returns number of bytes read.  
native function int ReadText( out IpAddr Addr, out string Str );

// ReadBinary: Read data as a byte array.
native function int ReadBinary( out IpAddr Addr, int Count, out byte B[255] );

//-----------------------------------------------------------------------------
// Events.

// ReceivedText: Called when data is received and connection mode is MODE_Text.
event ReceivedText( IpAddr Addr, string Text );

// ReceivedLine: Called when data is received and connection mode is MODE_Line.
event ReceivedLine( IpAddr Addr, string Line );

// ReceivedBinary: Called when data is received and connection mode is MODE_Binary.
event ReceivedBinary( IpAddr Addr, int Count, byte B[255] );

defaultproperties
{
     bAlwaysTick=True
	 BroadcastAddr=-1;
}
