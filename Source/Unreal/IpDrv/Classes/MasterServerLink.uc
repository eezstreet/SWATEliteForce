class MasterServerLink extends Engine.Info
	native
	transient;

cpptext
{
	virtual UBOOL Poll( INT WaitTime ) { return 0; }
}

var native const int LinkPtr;
var globalconfig int LANPort;
var globalconfig int LANServerPort;
var globalconfig int CurrentMasterServer;
var globalconfig int MasterServerPort[5];
var globalconfig string MasterServerAddress[5];

native function bool Poll( int WaitTime );

event GetMasterServer( out string OutAddress, out int OutPort )
{
	if( CurrentMasterServer<0 || CurrentMasterServer>=5 || CurrentMasterServer>=5 || MasterServerAddress[CurrentMasterServer]=="" || MasterServerPort[CurrentMasterServer]==0 )
		CurrentMasterServer = 0;

	if( MasterServerAddress[0]=="" || MasterServerPort[0]==0 )
	{
		Log("Warning: No master servers found in the INI file");
        OutAddress = "ut2003master1.epicgames.com";
		OutPort = 28902;
	}
	else
	{
		OutAddress	= MasterServerAddress[CurrentMasterServer];
		OutPort		= MasterServerPort[CurrentMasterServer];
	}
}

simulated function Tick( float Delta )
{
	Poll(0);
}

defaultproperties
{
	bAlwaysTick=True
	LANPort=10489
	LANServerPort=9999
	CurrentMasterServer=0
	MasterServerPort(0)=28902
	MasterServerAddress(0)="ut2003master1.epicgames.com"
	MasterServerPort(1)=28902
	MasterServerAddress(1)="ut2003master1.epicgames.com"
}
