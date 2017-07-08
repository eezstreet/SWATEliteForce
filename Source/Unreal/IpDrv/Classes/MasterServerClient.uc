class MasterServerClient extends ServerQueryClient
	native;

cpptext
{
	// AActor interface
	void Destroy();
	void PostScriptDestroyed();
	// MasterServerLink interface
	UBOOL Poll( INT WaitTime );
	// ServerQueryClient interface
	void Init();
}

enum EClientToMaster
{
	CTM_Query,
	CTM_GetMOTD,
	CTM_QueryUpgrade,
};

enum EQueryType
{
	QT_Equals,
	QT_NotEquals,
	QT_LessThan,
	QT_LessThanEquals,
	QT_GreaterThan,
	QT_GreaterThanEquals,
};

struct native export QueryData
{
	var() string Key;
	var() string Value;
	var() EQueryType QueryType;
};

enum EResponseInfo
{
	RI_AuthenticationFailed,
	RI_ConnectionFailed,
	RI_ConnectionTimeout,
	RI_Success,	
	RI_MustUpgrade,
};

enum EMOTDResponse
{
	MR_MOTD,
	MR_MandatoryUpgrade,
	MR_OptionalUpgrade,
	MR_NewServer,
	MR_IniSetting,
	MR_Command,
};

// Internal
var native const int MSLinkPtr;


var(Query) array<QueryData> Query;
var(Query) const int ResultCount;

native function StartQuery( EClientToMaster Command );
native function Stop();
native function LaunchAutoUpdate();

delegate OnQueryFinished( EResponseInfo ResponseInfo, int Info );
delegate OnReceivedServer( GameInfo.ServerResponseLine s );
delegate OnReceivedMOTDData( EMOTDResponse Command, string Value );

defaultproperties
{
	bLANQuery=0
}