// ====================================================================
//  Class:  SwatGui.SwatServerBrowserMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
//
// @OPTIMIZE
// This is probably a good candidate for native optimization. There is
// a lot of linear searching through the listbox, as well as a TON of
// GameInfo.ServerResponseLine struct copying, that could benefit from
// native reference passing. [darren]
//
// ====================================================================

class SwatServerBrowserMenu extends SwatGUIPage
     ;

#define DEBUG_SERVER_PING_RESPONSE 0
#define PREVENT_SPILLOVER_INTO_LAN 1

import enum EMPMode from Engine.Repo;
import enum EPingCause from IpDrv.ServerQueryClient;

var(SWATGui) private EditInline Config GUIButton    MyQuitButton;
var(SWATGui) private EditInline Config GUIButton		    MyMainMenuButton;
var(SWATGui) private EditInline Config GUIButton		    StartButton;

var(SWATGui) private EditInline Config GUIButton		    MyUpdateButton;
var(SWATGui) private EditInline Config GUIButton		    MyRefreshButton;
var(SWATGui) private EditInline Config GUIButton		    MyFiltersButton;
var(SWATGui) private EditInline Config GUIButton		    MyJoinIPButton;
var(SWATGui) private EditInline Config GUIButton		    MyProfileButton;

var(SWATGui) private EditInline Config GUIRadioButton		MyUseLanButton;
var(SWATGui) private EditInline Config GUIRadioButton		MyUseGameSpyButton;

var(SWATGui) private EditInline Config GUIEditBox          MyNameBox;
var(SWATGui) private EditInline Config GUIMultiColumnListBox MyServerListBox;

var(SWATGui) private EditInline Config GUILabel    VersionLabel;
var(SWATGui) private EditInline Config GUILabel    ModLabel;

var(SWATGui) private EditInline GUIImage		    LockedIcon;
var(SWATGui) private EditInline GUIImage			StatsIcon;
var(SWATGui) private EditInline GUIImage			LockedStatsIcon;

var(SWATGui) private config int MaxResults;

var() private config localized string VersionFormatString;
var() private config localized string NewModFormatString;

var SwatGameSpyManager SGSM;
var bool bUseGameSpy;

var ServerQueryClient InternetPingClient; // For pinging internet games

// Contains every server currently in the listbox
var array<GameInfo.ServerResponseLine> ServerArray;


var private config localized string ConnectPasswordQueryString;

var string BuildVersion;
var string ModName;
var string ShortBuildVersion;
var string ShortModName;

var() private config string CompatibleColorString;
var() private config string InCompatibleColorString;

///DEBUGGING ONLY!
var bool bDebugging;
var int debugID;
///////////////////////////////////////////////////////////////////////////////

// Initialization & termination

function InitComponent(GUIComponent MyOwner)
{
    //log( "...InitComponent()." );

	Super.InitComponent(MyOwner);

    MyUpdateButton.OnClick=InternalOnClick;
    MyRefreshButton.OnClick=InternalOnClick;
    MyFiltersButton.OnClick=InternalOnClick;
    MyJoinIPButton.OnClick=InternalOnClick;
    MyServerListBox.OnDblClick=InternalOnClick;
    MyServerListBox.OnChange=UpdateJoinableState;
    MyUseGameSpyButton.OnChange=NetworkModeSelected;
	MyProfileButton.OnClick=OnProfile;

    MyNameBox.OnChange=UpdateJoinableState;
    MyNameBox.MaxWidth = GC.MPNameLength;
    MyNameBox.AllowedCharSet = GC.MPNameAllowableCharSet;

	LockedIcon=GUIImage(Controller.CreateComponent("GUI.GUIImage","Canvas_LockedIcon"));
	StatsIcon=GUIImage(Controller.CreateComponent("GUI.GUIImage","Canvas_StatsIcon"));
	LockedStatsIcon=GUIImage(Controller.CreateComponent("GUI.GUIImage","Canvas_LockedStatsIcon"));
}

function InternalOnActivate()
{
    //log( "...InternalOnActivate()." );
	ShortBuildVersion = PlayerOwner().Level.BuildVersion;
	ShortModName = PlayerOwner().Level.ModName;
    BuildVersion = class'ModInfo'.default.ChangeNumber;
    ModName = class'ModInfo'.default.ModName;

    VersionLabel.SetCaption( FormatTextString( VersionFormatString, BuildVersion ) );
    if( ModName ~= "SWAT 4X" )
        ModLabel.SetCaption( "" );
    else
        ModLabel.SetCaption( FormatTextString( NewModFormatString, ModName, ShortModName ) );

    MyQuitButton.OnClick=InternalOnClick;
    MyMainMenuButton.OnClick=InternalOnClick;
    StartButton.OnClick=InternalOnClick;

	SGSM = SwatGameSpyManager(PlayerOwner().Level.GetGameSpyManager());
	if (SGSM == None)
	{
		Log("Error:  no GameSpy manager found");
		return;
	}

    CreatePingClient();

    if( !SGSM.bInitialised )
    {
        SGSM.InitGameSpyClient();
    }

    SGSM.OnUpdatedServer = OnUpdatedGameSpyServer;

    bUseGameSpy = GC.bViewingGameSpy;

    MyFiltersButton.SetEnabled( bUseGameSpy );

    // alwyas re-enable refresh when activating the SB
    MyRefreshButton.EnableComponent();

    if( bUseGameSpy )
        MyUseGameSpyButton.SelectRadioButton();
    else
        MyUseLanButton.SelectRadioButton();

    MyNameBox.SetText(GC.MPName);

    UpdateServerList();
    SetTimer( 3 );

    RefreshEnabled();

	UpdateComponents();
}

function InternalOnDeActivate()
{
    //log( "...InternalOnDeActivate()." );

    DestroyPingClient();

	SwatPlayerController(PlayerOwner()).SetName( MyNameBox.GetText() );
    GC.bViewingGameSpy = bUseGameSpy;
    GC.SaveConfig();
}

function DebugServerList(int num)
{
    log("[dkaplan] >>>>>>>>>>>>>>>>>>>> Debugging Server List <<<<<<<<<<<<<<<<<<<<<<<<<");
    debugID=0;
    MaxResults=num;
    bDebugging=True;
    MyServerListBox.Clear();
    SetTimer( 0.05, true );
}

event Timer()
{
    if( bDebugging )
    {
        DebugAddServer();
        return;
    }

    if( !MyServerListBox.IsEmpty() || !bVisible )
        return;

    UpdateServerList();
    SetTimer( 3 );
}

///////////////////////////////////////////////////////////////////////////////

// Member object creation and deletion

private function CreatePingClient()
{
    log( "...CreatePingClient()." );

    // Init the query client (used for pinging)
    if( InternetPingClient == None )
    {
        InternetPingClient = PlayerOwner().Level.Spawn( class'IpDrv.ServerQueryClient' );
    }
}

private function DestroyPingClient()
{
    log( "...DestroyPingClient()." );

    if ( InternetPingClient != None && !InternetPingClient.bDeleteMe )
    {
        InternetPingClient.CancelPings();
        InternetPingClient.Destroy();
        InternetPingClient = None;
    }
}

///////////////////////////////////////////////////////////////////////////////

private function NetworkModeSelected( GUIComponent sender )
{
// dbeswick: integrated 20/6/05
    log( "...NetworkModeSelected() bUseGameSpy="$bUseGameSpy$" MyUseGameSpyButton.bChecked = "$MyUseGameSpyButton.bChecked);

#if PREVENT_SPILLOVER_INTO_LAN
    // If we're changing modes from Internet to Lan, then
    // cancel any outstanding internet pings. This will not prevent them
	// from being sent to OnReceivedPingInfoForUpdate(), but it will
	// cause their ping to be 9999. We'll use this magic ping value
	// to filter them out of the LAN browser.
	//
	// Yes, this is a horrible HACK. The right way to do it would be
	// to put some flag in the ServerResponseLine structure that
	// indicates whether it's a LAN or Internet ping and filter based
	// on that.
    if (bUseGameSpy && !MyUseGameSpyButton.bChecked)
    {
        log("Switching from Internet to LAN listing; cancelling outstanding internet pings");
        InternetPingClient.CancelPings();
    }
#endif

    bUseGameSpy = MyUseGameSpyButton.bChecked;
    MyFiltersButton.SetEnabled( bUseGameSpy );
    UpdateServerList();

	UpdateComponents();
}

function UpdateComponents()
{
	if (MyUseGameSpyButton.bChecked)
	{
		MyProfileButton.EnableComponent();
	}
	else
	{
		MyProfileButton.DisableComponent();
	}
}

private function UpdateServerList()
{
    log( "...UpdateServerList()." );

    ClearServerData();

    InternetPingClient.OnReceivedPingInfo = OnReceivedPingInfoForUpdate;

    // GameSpy initializes asynchronously, so don't make any calls on it until
    // after the get the callback that initialization has succeeded.
    if( !SGSM.bInitialised )
        return;

    if (bUseGamespy)
    {
        log( "...from GameSpy" );
        SGSM.UpdateServerList( GetGameSpyFilterString() );
    }
    else
    {
        log( "...from LAN." );
        SGSM.LANUpdateServerList();
    }
}

private function ClearServerData()
{
    log( "...ClearServerList()." );

    MyServerListBox.Clear();
    ServerArray.Remove(0, ServerArray.length);

    // Now that we've emptied the server list, disable the start button
    RefreshEnabled();
}

private function RefreshServerPings()
{
    local int i;

    log( "---SwatServerBrowserMenu::RefreshServerPings()." );

    MyRefreshButton.DisableComponent();

    InternetPingClient.OnReceivedPingInfo = OnReceivedPingInfoForRefresh;
    InternetPingClient.OnPingTimeout = OnPingTimeout;
    InternetPingClient.OnAllServersReturned = OnAllServersReturned;

    log( "...ServerArray.Length="$ServerArray.length );
    for (i = 0; i < ServerArray.length; ++i)
    {
        PingServer(ServerArray[i]);
    }
}

function InternalOnPopupReturned( GUIListElem returnObj, optional string Passback )
{
    local string URL;

    log( "...InternalOnPopupReturned()." );

    switch (passback)
    {
        case "Password":
            URL = returnObj.ExtraStrData $ "?Password=" $ returnObj.item;
            AttemptURL( URL );
            break;
        case "JoinIP":
            URL = returnObj.Item;
            AttemptURL( URL );
            break;
        case "Filters":
            //TODO: do additional filters stuff here, if necessary
            break;
    }
}

//returns a URL with the appropriate SWAT prefix
function string URLPlusSWATPrefix(string URL)
{
    local string prefix;

    prefix = "swat4xp1://";

    if (Left(URL, Len(prefix)) == prefix)
        return URL;    //URL already has prefix
    else
        return prefix $ URL;
}

function AttemptURL( string URL )
{
    log( "...AttemptURL()." );

    URL = URLPlusSWATPrefix( URL );

    GC.FirstTimeThrough = true;

    if( MyNameBox.GetText() != "" )
        URL = URL $ "?Name=" $ MyNameBox.GetText();
    log( "Trying to join to: " $ URL );
    SwatGUIController(Controller).LoadLevel(URL);
}

function InternalOnClick(GUIComponent Sender)
{
    local string URL;

    //log( "...InternalOnClick()." );

	switch (Sender)
	{
	    case MyQuitButton:
            Quit();
            break;
		case StartButton:
    	    URL = MyServerListBox.GetColumn( "IPAddress" ).GetExtra();
            if( MyServerListBox.GetColumn( "Locked" ).GetExtraBoolData() )
                Controller.OpenMenu( "SwatGui.SwatPasswordPopup", "SwatPasswordPopup", ConnectPasswordQueryString, URL );
            else
                AttemptURL( URL );
            break;
		case MyMainMenuButton:
            Controller.CloseMenu();
            break;
		case MyUpdateButton:
            UpdateServerList();
            break;
		case MyRefreshButton:
            RefreshServerPings();
            break;
		case MyFiltersButton:
            Controller.OpenMenu( "SwatGui.SwatServerFiltersPopup", "SwatServerFiltersPopup" );
            break;
		case MyJoinIPButton:
            Controller.OpenMenu( "SwatGui.SwatJoinIPPopup", "SwatJoinIPPopup" );
            break;
	}
}

///////////////////////////////////////////////////////////////////////////////

// Internet server updating

private function OnUpdatedGameSpyServer(GameInfo.ServerResponseLine Server)
{
    ServerArray[ServerArray.length] = Server;
    PingServer(Server);
}


///////////////////////////////////////////////////////////////////////////////

private function DebugAddServer()
{
    local GameInfo.ServerResponseLine s;
    local GameInfo.KeyValuePair kvp;

    debugID++;
    if( debugID >= 5000 )
    {
        KillTimer();
        bDebugging=false;
        return;
    }

    s.MaxPlayers = Rand(16)+1;
    s.CurrentPlayers = Rand(s.MaxPlayers+1);

    // MCJ: fix this before using since we're not using 0, 1, and 2 as
    // gametypes anymore.
    s.GameType = string(Rand(3));

    switch (rand(3))
    {
        case 0:
            s.MapName = "MP-VIPTower";
            break;
        case 1:
            s.MapName = "MP-Bullseye";
            break;
        case 2:
            s.MapName = "MP-Powerplant";
            break;
    }

    switch (rand(4))
    {
        case 0:
            s.ServerName = "Crombies Crazyhouse";
            break;
        case 1:
            s.ServerName = "Mikes Mayhem";
            break;
        case 2:
            s.ServerName = "Korkys Killground";
            break;
        case 3:
            s.ServerName = "Terrys Torture Chamber";
            break;
    }

    s.IP = Rand(256)$"."$Rand(256)$"."$Rand(256)$"."$Rand(256);
    s.Port = rand(32768);

    s.Ping = rand(debugID+10);

    kvp.Key = "password";
    kvp.Value = string(rand(2));

    s.ServerInfo[0] = kvp;

    OnReceivedPingInfoForUpdate( debugID, PC_AutoPing, s );
}


// Ping sending and ping response

private function PingServer(GameInfo.ServerResponseLine Server)
{
#if DEBUG_SERVER_PING_RESPONSE
    log( "---PingServer()." );
#endif

    // Is it common knowledge that the port to ping an internet server
    // on, is the connection port + 2?? (check the
    // FMasterServerUplinkLink constructor in MasterServerUplink, for
    // where this port is actually used on the server.) Yikes, we
    // should make this nicer. [darren]
    InternetPingClient.PingServer(Server.ServerID, PC_AutoPing, Server.IP, Server.Port + 2, QI_Ping, Server);
}

private function OnReceivedPingInfoForUpdate(int ServerID, EPingCause PingCause, GameInfo.ServerResponseLine s)
{
    // For updates, we unconditionally insert the server into the listbox.
    local string PreviouslySelectedIP;
    local string GameTypeEntry;
    local int i;
    local string Key;
    local string Value;
	  local GUIImage Icon;
	  local bool bLocked, bStatsEnabled;
    local string FullIPAddress;

    if( MyServerListBox.Num() > MaxResults )
        return;

#if DEBUG_SERVER_PING_RESPONSE
    log( "---OnReceivedPingInfoForUpdate()." );
    log( "...ServerID="$ServerID );
    log( "...PingCause="$PingCause );
    log( "...ServerResponseLine:" );
    log( "......servername="$s.ServerName );
    log( "......CurrentPlayers="$s.CurrentPlayers );
    log( "......MaxPlayers="$s.MaxPlayers );
    log( "......Ping="$s.Ping );
    log( "......theServerFilters.MaxPing ="$GC.theServerFilters.MaxPing );
#endif

	// Gamespy filters servers based on the info (e.g., ping, playercount) sent
	// from the server to gamespy's server.
	// But since we re-query the server, it might have changed since gamespy
	// last queried it. So we have to do some redundant filtering here.
	if( GC.theServerFilters.MaxPing > 0 && s.Ping > GC.theServerFilters.MaxPing )
		return; // doesn't meet max ping filter
	if( GC.theServerFilters.bFull && (s.MaxPlayers - s.CurrentPlayers <= 0))
		return; // doesn't meet full server filter

// dbeswick: integrated 20/6/05
#if PREVENT_SPILLOVER_INTO_LAN
    // HACK! Prevent pings from internet games from spilling over into lan
    // listing when we switch from internet to lan before the full list
    // of internet games has been returned.
	if (s.Ping >= 9998 && !MyUseGameSpyButton.bChecked)
        return; // This is a server ping for an internet game whose ping was cancelled
#endif

    FullIPAddress = s.IP $ ":" $ s.Port;

    // Don't add this item to the list twice --eez
    if(MyServerListBox.RowElementExists("IPAddress",,FullIPAddress))
      return;

    // Remember the currently selected ip, so we can reselect it after the
    // listbox addition
    PreviouslySelectedIP = MyServerListBox.GetColumn( "IPAddress" ).GetExtra();

    // Add a new element to the listbox
    MyServerListBox.AddNewRowElement( "IPAddress",,   FullIPAddress );
    MyServerListBox.AddNewRowElement( "ServerName",,  s.ServerName );
    MyServerListBox.AddNewRowElement( "MapName",,     s.MapName );

    //GameTypeEntry = GC.GetGameModeName(EMPMode(int(s.GameType)));
    GameTypeEntry = GC.GetGameModeNameFromNonlocalizedString( s.GameType );

#if DEBUG_SERVER_PING_RESPONSE
    log( "......GameType="$s.GameType );
    log( "......GameTypeEntry="$GameTypeEntry );
#endif

    MyServerListBox.AddNewRowElement( "GameType",, GameTypeEntry );

    MyServerListBox.AddNewRowElement( "numPlayers",, s.CurrentPlayers$"/"$s.MaxPlayers );
    MyServerListBox.AddNewRowElement( "Ping",,, s.Ping );

#if DEBUG_SERVER_PING_RESPONSE
    log( "...s.ServerInfo.Length="$s.ServerInfo.Length );
#endif
    for (i = 0; i < s.ServerInfo.length; i++)
    {
		Icon = None;
        Key = s.ServerInfo[i].Key;
        Value = s.ServerInfo[i].Value;
        if( (Key == "password") && ( Value == "1" ) )
        {
#if DEBUG_SERVER_PING_RESPONSE
            log( "...passworded." );
#endif
			bLocked = true;
        }
        else
        {
#if DEBUG_SERVER_PING_RESPONSE
            log( "...not passworded." );
#endif
        }

        if( (Key == "statsenabled") && ( Value == "1" ) )
        {
#if DEBUG_SERVER_PING_RESPONSE
            log( "...stats enabled." );
#endif
			bStatsEnabled = true;
        }
        else
        {
#if DEBUG_SERVER_PING_RESPONSE
            log( "...not stats enabled." );
#endif
        }

		// We're disabling this until (if) we add dedicated server support.
        //else if (Key == "Dedicated")
        //{
        //    MyServerListBox.AddNewRowElement( "Dedicated",,,, ( Value == "1" ) );
        //}
    }

	// dbeswick:
	if (bStatsEnabled)
	{
		if (bLocked)
			Icon = LockedStatsIcon;
		else
			Icon = StatsIcon;
	}
	else if (bLocked)
	{
		Icon = LockedIcon;
	}

	if (Icon != None)
        MyServerListBox.AddNewRowElement( "Locked",Icon,,, bLocked );

    if( s.ModName == ShortModName )
        MyServerListBox.AddNewRowElement( "ModName",, CompatibleColorString$s.ModName );
    else
        MyServerListBox.AddNewRowElement( "ModName",, InCompatibleColorString$s.ModName );

    if( s.GameVersion == ShortBuildVersion )
        MyServerListBox.AddNewRowElement( "Version",, CompatibleColorString$s.GameVersion );
    else
        MyServerListBox.AddNewRowElement( "Version",, InCompatibleColorString$s.GameVersion );

    MyServerListBox.PopulateRow();

    // Reselect the previously selected server
    MyServerListBox.GetColumn( "IPAddress" ).FindExtra(PreviouslySelectedIP,,true);

    // Enable the start button, because we have at least one server in the list
    RefreshEnabled();
}

private function OnReceivedPingInfoForRefresh(int ServerID, EPingCause PingCause, GameInfo.ServerResponseLine s)
{
    local GUIList IpAndPortColumn;
    local GUIList PingColumn;
    local string IpAddressAndPort;
    local int i;

#if DEBUG_SERVER_PING_RESPONSE
    log( "...OnReceivedPingInfoForRefresh()." );
#endif

    IpAddressAndPort = s.IP$":"$s.Port;

    // For refreshes, we find the row with this ip address, and just update
    // the ping column for that row.
    IpAndPortColumn = MyServerListBox.GetColumn("IPAddress");
    PingColumn = MyServerListBox.GetColumn("Ping");
    for (i = 0; i < IpAndPortColumn.ItemCount; ++i)
    {
        if (IpAndPortColumn.GetExtraAtIndex(i) == IpAddressAndPort)
        {
            PingColumn.SetExtraIntAtIndex(i, s.Ping);
            break;
        }
    }
}

private function OnPingTimeout(int ServerID, EPingCause PingCause)
{
#if DEBUG_SERVER_PING_RESPONSE
    log( "...OnPingTimeout()." );
#endif
    // Intentionally empty, assigned to a delegate
}

private function OnAllServersReturned()
{
    log( "...OnAllServersReturned()." );

    MyRefreshButton.EnableComponent();
}

///////////////////////////////////////////////////////////////////////////////

private function OnProfile( GUIComponent sender )
{
	Controller.OpenMenu( "SwatGui.SwatGamespyProfilePopup", "SwatGamespyProfilePopup" );
}

///////////////////////////////////////////////////////////////////////////////

// Filters

private function string GetGameSpyFilterString()
{
    local string result;
    local int GameTypeNumber;

    // Remember, GameSpy can't filter by ping, so that has to be handled in
    // the ServerBrowser screen. Just don't put the server in the list if the
    // ping is greater than the filter ping amount.

    log( "...GetGameSpyFilterString()." );

    // Access theServerFilters here and construct the string appropriately.

    if ( GC.theServerFilters.bFull )
    {
        result = AppendFilterString( result, "numplayers!=maxplayers" );
    }
	if ( GC.theServerFilters.bEmpty )
    {
        result = AppendFilterString( result, "numplayers>0" );
    }
    if ( GC.theServerFilters.bPassworded )
    {
        result = AppendFilterString( result, "password=0" );
    }
    if ( GC.theServerFilters.bFilterGametype )
    {
        GameTypeNumber = int(GC.theServerFilters.GameType);
        if ( GameTypeNumber == 0 )
            result = AppendFilterString( result, "gametype='Barricaded Suspects'" );
        else if ( GameTypeNumber == 1 )
            result = AppendFilterString( result, "gametype='VIP Escort'" );
        else if ( GameTypeNumber == 2 )
            result = AppendFilterString( result, "gametype='Rapid Deployment'" );
		else if ( GameTypeNumber == 4 )
            result = AppendFilterString( result, "gametype='Smash And Grab'" );
		else if ( GameTypeNumber == 5 )
            result = AppendFilterString( result, "gametype='CO-OP QMM'" );
        else
            result = AppendFilterString( result, "gametype='CO-OP'" );
    }

    if ( GC.theServerFilters.bHideIncompatibleVersions )
    {
        result = AppendFilterString( result, "gamever='"$ShortBuildVersion$"'" );
    }
    if ( GC.theServerFilters.bHideIncompatibleMods )
    {
        result = AppendFilterString( result, "gamevariant='"$ShortModName$"'" );
    }
	if ( GC.theServerFilters.bFilterMapName )
	{
		result = AppendFilterString( result, "mapname='"$GC.theServerFilters.MapName$"'" );
	}

    // Other examples:
    // numplayers > 0 and numplayer != maxplayers
    // password = 0
    // can also use <= and >=
    // All expressions in the clause should be joined by 'and'.

    log("[dkaplan] >>> GetGameSpyFilterString, returning "$result);
    return result;
}


// Used by GetGameSpyFilterString(). Helps construct a string of clauses
// separated by " and ".
private function string AppendFilterString( string current, string newexpression )
{
    log( "...AppendFilterString()." );

    if ( current != "" )
        return current$" and "$newexpression;
    else
        return newexpression;
}

///////////////////////////////////////////////////////////////////////////////

private function UpdateJoinableState(GUIComponent Sender)
{
    RefreshEnabled();
}

private function RefreshEnabled()
{
    local bool bEnableStart;
    local string maxPlayers, numPlayers;

    maxPlayers = MyServerListBox.GetColumn( "numPlayers" ).GetExtra();
    numPlayers = GetFirstField( maxPlayers, "/" );

    bEnableStart =
        MyNameBox.GetText() != "" &&
        MyServerListBox.GetIndex() >= 0 &&
        numPlayers != maxPlayers;

    StartButton.SetEnabled( bEnableStart );
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	//OnDlgReturned=InternalOnDlgReturned
	OnPopupReturned=InternalOnPopupReturned
	OnActivate=InternalOnActivate
	OnDeActivate=InternalOnDeActivate
    bUseGamespy=true
    MaxResults=500

    ConnectPasswordQueryString="Please enter the Password for the selected server:"

    VersionFormatString="Version: %1"
    NewModFormatString="Mod: %1 (%2)"

    CompatibleColorString="[c=00ff00]"
    InCompatibleColorString="[c=ff0000]"
}
