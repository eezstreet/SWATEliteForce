//=============================================================================
// ClientBeaconReceiver: Receives LAN beacons from servers.
//=============================================================================
class ClientBeaconReceiver extends UdpBeacon
	transient;

var() editinline struct BeaconInfo
{
	var() IpAddr      Addr;
	var() float       Time;
	var() string      Text;
} Beacons[32];

function int GetBeaconCount()
{
    return (ArrayCount (Beacons));
}

function string GetBeaconAddress( int i )
{
	return IpAddrToString(Beacons[i].Addr);
}

function string GetBeaconText(int i)
{
	return Beacons[i].Text;
}

function BeginPlay()
{
	if( BindPort( BeaconPort, true ) > 0 )
		SetTimer( 1.0, true );
	else
		warn( "ClientBeaconReceiver failed: Beacon port in use." );
}

function Timer()
{
	local int i, j;

    // Remove any stale beacons and compress the list

    j = 0;

	for (i = 0; i < ArrayCount(Beacons); i++)
    {
		if (Beacons[i].Addr.Addr == 0)
            continue;
        
        if (Level.TimeSeconds - Beacons[i].Time >= BeaconTimeout)
            continue;

        if (i != j)
    		Beacons[j] = Beacons[i];

        j++;
    }

	while (j < ArrayCount(Beacons))
    {
		Beacons[j].Addr.Addr = 0;
		Beacons[j].Addr.Port = 0;
        Beacons[j].Text = "";
        j++;
    }

    BroadcastQuery();
}

function BroadcastQuery ()
{
    local IpAddr Addr;

	Addr.Addr = BroadcastAddr;
	Addr.Port = ServerBeaconPort;

	SendText( Addr, "REPORT" );	
}

event ReceivedText (IpAddr Addr, string Text)
{
	local int i, n;
    local String Product;

	n = Len (BeaconProduct);

    Product = Left (Text, n + 1);

	if (!(Product ~= (BeaconProduct$" ")))
        return;

	Text = Mid (Text, n + 1);

	Addr.Port = int (Text);

	for (i = 0; i < ArrayCount(Beacons); i++)
		if (Beacons[i].Addr == Addr)
			break;

	if (i == ArrayCount(Beacons))
	    for (i = 0; i< ArrayCount(Beacons); i++)
			if (Beacons[i].Addr.Addr == 0)
				break;

	if (i == ArrayCount(Beacons))
		return;

	Beacons[i].Addr = Addr;
	Beacons[i].Time = Level.TimeSeconds;
	Beacons[i].Text = Mid (Text, InStr (Text, " ") + 1);
}

defaultproperties
{
}

