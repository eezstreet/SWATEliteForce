class SwatGUIControllerBase extends GUI.GUIController
    dependson(Campaign)
    dependsOn(SwatGamePlayerController)
    abstract;

var(DEBUG) SwatRepo        Repo;  // GUI Config object to use
var(DEBUG) SwatGUIConfig   GuiConfig;  // GUI Config object to use

var(DEBUG) private Campaigns Campaigns;    // all the available campaigns
var(DEBUG) Campaign Campaign;      // the current campaign to use

var(DEBUG) private string ConnectingURL; //if a mission is currently loading, another connect message to the same url indicates a timeout
var(DEBUG) String CurrentFailureMessage1; //the current failure type if failed to connect
var(DEBUG) String CurrentFailureMessage2;

var(DEBUG) editconst editinline HUDPageBase HudPage;

import enum Pocket from Engine.HandheldEquipment;
import enum eSwatGameState from SwatGuiConfig;
import enum eSwatGameRole from SwatGuiConfig;
import enum NumberRow from SwatGamePlayerController;
import enum EMPMode from Engine.Repo;


// how long since we last polled
var private Float CumulativeDelta;

// Whether this is a coop campaign
var() bool coopcampaign;

function bool GetDispatchDisabled();
function SetDispatchDisabled(bool newValue);

/////////////////////////////////////////////////////////////////////////////
// Initialization
/////////////////////////////////////////////////////////////////////////////
function InitializeController()
{
log("[dkaplan] >>> InitializeController of (SwatGUIControllerBase) "$self);

    Campaigns = new( None ) class'SwatGame.Campaigns';
    AssertWithDescription( Campaigns != None, "Campaigns could not be loaded!");
    UseCampaign( Campaigns.CurCampaignName );

log("[dkaplan] ... ViewportOwner="$ViewportOwner$", ViewportOwner.Actor="$ViewportOwner.Actor$", ViewportOwner.Actor.GetEntryLevel()="$ViewportOwner.Actor.GetEntryLevel()$", ViewportOwner.Actor.GetEntryLevel().GetRepo()="$ViewportOwner.Actor.GetEntryLevel().GetRepo() );

    //set the repo
    Repo = SwatRepo(ViewportOwner.Actor.GetEntryLevel().GetRepo());
    AssertWithDescription( Repo != None, "[dkaplan]: The repo could not be retrieved by "$self$" in InitializeController()");

    //cache easy reference to the GuiConfig
    GuiConfig = Repo.GuiConfig;
    AssertWithDescription( GuiConfig != None, "[dkaplan]: The GuiConfig could not be retrieved by "$self$" in InitializeController()");

    Super.InitializeController();

    //if we are initing as a net client, display the loading menu
    if( Repo.bInitAsNetPlayer )
    {
        OnNetworkPlayerLoading();
    }
    //don't load splash/main menu if not entering via Swat4.exe
    else if( ViewportOwner.Actor.Level.Label == 'Entry' &&
             Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Client )
    {
	    LoadSplash();
    }
}


/////////////////////////////////////////////////////////////////////////////
// Tick / Polling
/////////////////////////////////////////////////////////////////////////////
event OnTick( float Delta )
{
    if( GuiConfig.SwatGameState != GAMESTATE_PreGame &&
        GuiConfig.SwatGameState != GAMESTATE_MidGame &&
        GuiConfig.SwatGameState != GAMESTATE_PostGame )
        return;

	if (HudPage != None)
		HudPage.OnTick(Delta);

	// Don't poll the GUI during the Coop QMM lobby "game type"
	if( SwatRepo(ViewportOwner.Actor.GetEntryLevel().GetRepo()).GetGameMode() == MPM_COOPQMM )
	{
		PollCoopQMMGUI();
		return;
	}

    CumulativeDelta += Delta;

    if( CumulativeDelta > GuiConfig.MPPollingDelay )
    {
        CumulativeDelta = 0;
        PollGUI();
    }
}

function PollGUI();
function PollCoopQMMGUI();

/////////////////////////////////////////////////////////////////////////////
// Game State / Game Systems Reference
/////////////////////////////////////////////////////////////////////////////
function OnRoleChange( eSwatGameRole oldRole, eSwatGameRole newRole );

function OnStateChange( eSwatGameState oldState, eSwatGameState newState, optional EMPMode CurrentGameMode );



final function SwatGameInfo GetSwatGameInfo()
{
    return SwatGameInfo(GetLevelInfo().Game);
}

final function LevelInfo GetLevelInfo()
{
//log("[dkaplan] >>> GetLevelInfo: ViewportOwner = " $ViewportOwner$ " ... ViewportOwner.Actor = " $ViewportOwner.Actor$ " ... ViewportOwner.Actor.Level = " $ViewportOwner.Actor.Level);
    return ViewportOwner.Actor.Level;
}

/////////////////////////////////////////////////////////////////////////////
// GameEvents
/////////////////////////////////////////////////////////////////////////////
function StartEndRoundSequence()
{
    HUDPage.StartEndRoundSequence();
}

function FinishEndRoundSequence()
{
    HUDPage.FinishEndRoundSequence();
}

//handle loading as a network client by displaying the mission loading menu
function OnNetworkPlayerLoading();

/////////////////////////////////////////////////////////////////////////////
// Campaigns Interface
/////////////////////////////////////////////////////////////////////////////
function UseCampaign(string inCampaign)
{
    Campaign = GetCampaign(inCampaign);
    if( Campaign != None )
    {
        Campaigns.CurCampaignName = inCampaign;
        Campaigns.SaveConfig();
    }
}

function NoCampaign()
{
  Campaign = None;
}

final function Campaigns GetCampaigns()
{
    return Campaigns;
}

final function Campaign GetCampaign(optional string inCampaign)
{
    if(inCampaign != "")
        return Campaigns.GetCampaign(inCampaign);
    return Campaign;
}

final function bool CampaignExists(string inCampaign)
{
    return Campaigns.CampaignExists(inCampaign);
}

final function Campaign AddCampaign(string inCampaign, int campPath, bool bPlayerPermadeath, bool bOfficerPermadeath, bool bHardcoreMode,
	optional bool bCustomCareer, optional string CustomCareer)
{
    return Campaigns.AddCampaign(inCampaign, campPath, bPlayerPermadeath, bOfficerPermadeath, bHardcoreMode, bCustomCareer, CustomCareer);
}

final function DeleteCampaign(string inCampaign)
{
    Campaigns.DeleteCampaign(inCampaign);
}

final function MissionResults GetMissionResults(name Mission)
{
    //TODO: get mission results from Custom Missions too!
    return Campaign.GetMissionResults(Mission);
}

final function UpdateCampaignDeathInformation(Pawn Pawn) {
  local Campaign theCampaign;

  theCampaign = GetCampaign();

  if(Pawn.IsA('SwatPlayer') && theCampaign.HardcoreMode) {
    theCampaign.HardcoreFailed = true;
  }

  if(Pawn.IsA('SwatPlayer') && theCampaign.PlayerPermadeath) {
    theCampaign.PlayerDied = true;
  } else if(Pawn.IsA('SwatOfficer') && theCampaign.OfficerPermadeath) {
    if(Pawn.IsA('OfficerRedOne')) {
      theCampaign.RedOneDead = true;
    } else if(Pawn.IsA('OfficerRedTwo')) {
      theCampaign.RedTwoDead = true;
    } else if(Pawn.IsA('OfficerBlueOne')) {
      theCampaign.BlueOneDead = true;
    } else if(Pawn.IsA('OfficerBlueTwo')) {
      theCampaign.BlueTwoDead = true;
    }
  }
}

final function bool CheckCampaignForOfficerSpawn(int StartType) {
  local Campaign theCampaign;

  theCampaign = GetCampaign();

  if(theCampaign.OfficerPermadeath){
    switch(StartType) {
      case 0:
        return !theCampaign.RedOneDead;
      case 1:
        return !theCampaign.RedTwoDead;
      case 2:
        return !theCampaign.BlueOneDead;
      case 3:
        return !theCampaign.BlueTwoDead;
    }
  } else {
    return true;
  }
}

/////////////////////////////////////////////////////////////////////////////
// Server -> Client Notifications
/////////////////////////////////////////////////////////////////////////////
function bool OnMessageRecieved( String Msg, Name Type );

final function AddChatMessage( String Msg, optional bool bIsGlobal )
{
	log("AddChatMessage: "$Msg);
    if( bIsGlobal )
        ViewportOwner.Actor.Say( Msg );
    else
        ViewportOwner.Actor.TeamSay( Msg );
}

final function AddCoopQMMMessage( String Msg )
{
	ViewportOwner.Actor.CoopQMMMessage( Msg );
}

/////////////////////////////////////////////////////////////////////////////
// Client -> Server Requests
/////////////////////////////////////////////////////////////////////////////
final function ChangeTeams()
{
    if( SwatGamePlayerController(ViewportOwner.Actor) != None )
        SwatGamePlayerController(ViewportOwner.Actor).ServerChangePlayerTeam();
}

final function SetPlayerReady()
{
    mplog( "SwatGUIControllerBase::SetPlayerReady()." );

    //signal ready to the server
    if( SwatGamePlayerController(ViewportOwner.Actor) != None )
    {
        mplog( "...sent RPC to server." );
        SwatGamePlayerController(ViewportOwner.Actor).ServerSetPlayerReady();
    }
}

final function SetPlayerNotReady()
{
    mplog( "SwatGUIControllerBase::SetPlayerNotReady()." );

    //signal ready to the server
    if( SwatGamePlayerController(ViewportOwner.Actor) != None )
    {
        mplog( "...sent RPC to server." );
        SwatGamePlayerController(ViewportOwner.Actor).ServerSetPlayerNotReady();
    }
}

final function FailedConnectionAccepted()
{
    Repo.FailedConnectionAccepted();
    ConsoleCommand( "Cancel" );
	LoadSplash();
}

final function PlayerDisconnect()
{
    //disconnect client from the server
    ConsoleCommand( "Disconnect" );
}

//callback when a disconnect occurs
final function OnDisconnected()
{
	LoadSplash();
}

function Quit()
{
    //may need to add saving info routines here
	ConsoleCommand( "quit" );
}

function GameStart()
{
    //start of game hook
    GuiConfig.SaveLastMissionPlayed();
	LoadLevel( GuiConfig.CurrentMission.MapName );
}

function GameAbort()
{
    GetSwatGameInfo().GameAbort();
}

function GameOver()
{
    //end of game hook
	LoadSplash();
}

function LoadLevel( string MapName )
{
    Repo.LoadLevel( MapName );
}

/////////////////////////////////////////////////////////////////////////////
// Server-Only GUI Functions
/////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////
// Client-Only GUI Functions
/////////////////////////////////////////////////////////////////////////////
function SetMPLoadOut( DynamicLoadOutSpec LoadOut )
{
    // This just walks the LoadOut and sends the contents of each pocket to
    // the server.
    log( " in SwatGUIControllerBase::SetMPLoadOut()" );

    if( SwatGamePlayerController(ViewportOwner.Actor) != None )
    {
        mplog( "...SGPC is valid" );
        SwatGamePlayerController(ViewportOwner.Actor).SetMPLoadOut( LoadOut );
    }
}


function SetMPLoadOutPocketWeapon( Pocket Pocket, class<actor> WeaponItem, class<actor> AmmoItem )
{
    log( " in SetMPLoadOutPocketWeapon(): Pocket="$Pocket$", WeaponItem="$WeaponItem$", AmmoItem="$AmmoItem );
    if( SwatGamePlayerController(ViewportOwner.Actor) != None )
    {
        mplog( "...SGPC is valid" );
        SwatGamePlayerController(ViewportOwner.Actor).ServerSetMPLoadOutPocketWeapon( Pocket, WeaponItem, AmmoItem );
    }
}

function SetMPLoadOutPrimaryAmmo(int Amount)
{
  if(SwatGamePlayerController(ViewportOwner.Actor) != None)
  {
    SwatGamePlayerController(ViewportOwner.Actor).ServerSetMPLoadOutPrimaryAmmo(Amount);
  }
}

function SetMPLoadOutSecondaryAmmo(int Amount)
{
  if(SwatGamePlayerController(ViewportOwner.Actor) != None)
  {
    SwatGamePlayerController(ViewportOwner.Actor).ServerSetMPLoadOutSecondaryAmmo(Amount);
  }
}

function SetMPLoadOutPocketCustomSkin( Pocket Pocket, String CustomSkinClassName )
{
	log( " in SetMPLoadOutPocketCustomSkin(): Pocket="$Pocket$", CustomSkinClassName="$CustomSkinClassName );
	if( SwatGamePlayerController(ViewportOwner.Actor) != None )
    {
        mplog( "...SGPC is valid" );
		SwatGamePlayerController(ViewportOwner.Actor).ServerSetMPLoadOutPocketCustomSkin( Pocket, CustomSkinClassName );
	}
}


function SetMPLoadOutPocketItem( Pocket Pocket, class<actor> Item )
{
    log( " in SetMPLoadOutPocketItem(): Pocket="$Pocket$", Item="$Item );
    assert( Pocket != Pocket_PrimaryWeapon );
    assert( Pocket != Pocket_PrimaryAmmo );
    assert( Pocket != Pocket_SecondaryWeapon );
    assert( Pocket != Pocket_SecondaryAmmo );
    if( SwatGamePlayerController(ViewportOwner.Actor) != None )
    {
        mplog( "...SGPC is valid" );
        SwatGamePlayerController(ViewportOwner.Actor).ServerSetMPLoadOutPocketItem( Pocket, Item );
    }
}


//function NetGameCompleted()
//{
    //send a message to the hud informing of the net game imminent completion
//log("[dkaplan] Net Game Has Been Completed!");
//}

protected function LoadSplash()
{
	ConsoleCommand( "Start"@Repo.SplashSceneMapName );
}

function HudPageBase GetHUDPage()
{
	if (HudPage == None)
	{
		HudPage = HUDPageBase(CreateComponent("SwatGui.HUDPage"));

		if (!HudPage.bInited)
			HudPage.InitComponent(None);
	}

    return HudPage;
}

//called directly from SetProgress() in UnGame.cpp on failure to connect
event SetProgress(string Message1, string Message2)
{
	local int i;

    log(self$"::SetProgress("$Message1$", "$Message2$")");

	if( Message1 == "LoadSplash" ||
        Message1 == "WaitForConnection" ||
        Message1 == "LoadMap" ||
        Message1 == "Download" )
    {
	    for (i = 0; i < MenuStack.Length; i++)
		    MenuStack[i].OnProgress(Message2, Message1);
    }
    else if( Message1 == "ConnectionFailed" ||
        Message1 == "Networking Failed" ||
        Message1 == "DemoLoadFailed" ||
        Message1 == "UrlFailed" ||
        Message1 == "Rejected By Server" ||
		Message1 == "ConfigMD5ChecksumFailed" ||
		Message1 == "ConfigMD5ChecksumCountFailed" ||
		Message1 == "PackageMD5ChecksumFailed" ||
		Message1 == "GenericFailure" ||
        ( Message1 == "ConnectingText" && Message2 == ConnectingURL ) ||
        ( Message1 == "" && Message2 == "" )
           )
    {
        ConnectingURL = "";
        CurrentFailureMessage1 = Message1;
        CurrentFailureMessage2 = Message2;
        Repo.FailedServerConnection();
    }
    else if( Message1 == "ConnectingText" )
    {
        //if a mission is currently loading, another connect message indicates a timeout
        ConnectingURL = Message2;
        return;
    }

    ConnectingURL = "";
}

function StartMissionObjectiveTimer(Objective Objective);
function StopMissionObjectiveTimer(); //FINAL, please

function PreLevelChangeCleanup()
{
    GetHudPage().PreLevelChangeCleanup();
}

function GivePlayerWeapon(class<SwatWeapon> Weapon, class<SwatAmmo> Ammo)
{
	if( SwatGamePlayerController(ViewportOwner.Actor) != None )
	{
		SwatGamePlayerController(ViewportOwner.Actor).GivenEquipmentFromMenu(Weapon, Ammo);
	}
}

function bool IsUsingMetricSystem()
{
    local SwatGuiConfig GC;

    GC = Repo.GuiConfig;

    return GC.ExtraIntOptions[5] == 0;
}

function bool IsUsingImperialMeasurements()
{
    local SwatGuiConfig GC;

    GC = Repo.GuiConfig;

    return GC.ExtraIntOptions[5] == 1;
}

///////////////////////////////////////////////////////////////////////////////////////////
// GUI EXECs
///////////////////////////////////////////////////////////////////////////////////////////

function DebugServerList(int num);
function ShowGamePopup( bool bSticky );
function ShowWeaponCabinet();

function bool CanChat();
function OpenChat( bool bGlobal );

function ScrollChatPageUp();
function ScrollChatPageDown();
function ScrollChatUp();
function ScrollChatDown();
function ScrollChatToHome();
function ScrollChatToEnd();
