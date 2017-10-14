class CustomScenarioCoopPage extends CustomScenarioPage;

import enum EMPMode from Engine.Repo;

var(SWATGui) private EditInline Config SwatChatPanel MyChatPanel;
var(SWATGui) private EditInline Config GUIListBox PlayerList;

var() private config localized string ConfirmAbortString;

var bool bInitialisedAsClient;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	SwatGuiController(Controller).SetCoopPage( self );
}

function SendChangeMessage( String Msg )
{
	SwatGUIController(Controller).AddCoopQMMMessage( Msg );
}

function CoopQMMReplicationInfo findCoopQMMRI()
{
	local CoopQMMReplicationInfo repInfo;

	foreach PlayerOwner().AllActors(class'CoopQMMReplicationInfo', repInfo)
		break; // Use the first one found as there should be only one

	return repInfo;
}

function Poll()
{
	local CoopQMMReplicationInfo CoopQMMRI;

	tabs.DisableSquadTab();

	FillPlayerList();

	CoopQMMRI = findCoopQMMRI();

	if (CoopQMMRI == None)
		return;

	if (IsClient())
	{
		InitialiseAsClient();

		tabs.SetTabsForClient();

		if (CoopQMMRI.ValidQMMData)
		{
			tabs.DisableInvalidOverlays();
			tabs.GetMissionTabPanel().ClientPoll(CoopQMMRI);
			tabs.GetHostagesTabPanel().ClientPoll(CoopQMMRI);
			tabs.GetEnemiesTabPanel().ClientPoll(CoopQMMRI);
			tabs.GetNotesTabPanel().ClientPoll(CoopQMMRI);
		}
		else
		{
			tabs.EnableInvalidOverlays();
		}
	}
	else if (IsServer())
	{
		CoopQMMRI.ValidQMMData = !tabs.IsSelectionTabEnabled();

		if (CoopQMMRI.ValidQMMData)
		{
			tabs.DisableInvalidOverlays();
			tabs.GetMissionTabPanel().ServerPoll(CoopQMMRI);
			tabs.GetHostagesTabPanel().ServerPoll(CoopQMMRI);
			tabs.GetEnemiesTabPanel().ServerPoll(CoopQMMRI);
			tabs.GetNotesTabPanel().ServerPoll(CoopQMMRI);
		}
	}
}

private function FillPlayerList()
{
	local SwatGameReplicationInfo SGRI;
	local SwatPlayerReplicationInfo PlayerInfo;
	local int i;

	PlayerList.List.Clear();

	if (PlayerOwner() == None)
		return;

	SGRI = SwatGameReplicationInfo(PlayerOwner().GameReplicationInfo);

    if (SGRI == None)
        return;

	for (i = 0; i < ArrayCount(SGRI.PRIStaticArray); ++i)
    {
        PlayerInfo = SGRI.PRIStaticArray[i];

        if (PlayerInfo != None)
			PlayerList.List.Add(PlayerInfo.PlayerName);
	}
}

function InitialiseAsClient()
{
	if (bInitialisedAsClient)
		return;

	bInitialisedAsClient = true;

	tabs.OpenTabByIndex(ETabPanels.Tab_Mission);
}

function PerformClose()
{
	OnDlgReturned = InternalOnDlgReturned;
	OpenDlg( ConfirmAbortString, QBTN_YesNo, "Abort" );
}

private function InternalOnDlgReturned( int Selection, String Passback )
{
    switch (Passback)
    {
        case "Abort":
            if( Selection == QBTN_Yes )
                 SwatGuiController(Controller).PlayerDisconnect();

            break;
    }
}

function PlayScenario( string ScenarioName, string PackName )
{
	local CustomScenario CustomScen;
	local ServerSettings CurrentSettings;
	local ServerSettings PendingSettings;

    //reset the current pack
    SetCustomScenarioPack( PackName );

    //store the selected pack & scenario data
	GC.SetCustomScenarioPackData( CustomScenarioPack, PackPlusExtension( PackName ), PackMinusExtension( PackName ), CustomScenarioCreatorData.ScenariosPath );
    GC.SetScenarioName( ScenarioName );

	// Load the scenario we're about to play
	CustomScen = new() class'CustomScenario';
	GC.GetCustomScenarioPack().LoadCustomScenarioInPlace(CustomScen, ScenarioName, GC.GetPakName(), GC.GetPakExtension());
	GC.SetCurrentMission(CustomScen.LevelLabel, ScenarioName, CustomScen);

	// Modify the server settings to restart as a coop server
	PendingSettings = ServerSettings(PlayerOwner().Level.PendingServerSettings);

	// Set the map list to contain only the custom scenario map
	SwatPlayerController(PlayerOwner()).ServerClearMaps(PendingSettings);
	SwatPlayerController(PlayerOwner()).ServerAddMap(PendingSettings, String(CustomScen.LevelLabel));

	// Set the rest of the server settings to the current settings except set the game type to coop, the map index to 0, and the pre game time
	CurrentSettings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);
	SwatPlayerController(PlayerOwner()).ServerSetSettings(
		PendingSettings,
        MPM_COOP,
        0,
        CurrentSettings.NumRounds,
        CurrentSettings.MaxPlayers,
        CurrentSettings.bUseRoundStartTimer,
        CurrentSettings.PostGameTimeLimit,
        CurrentSettings.bUseRoundEndTimer,
        480,
        CurrentSettings.bShowTeammateNames,
        CurrentSettings.Unused,
				CurrentSettings.bAllowReferendums,
        CurrentSettings.bNoRespawn,
        CurrentSettings.bQuickRoundReset,
        CurrentSettings.FriendlyFireAmount,
        CurrentSettings.Unused2,
				CurrentSettings.CampaignCOOP,
		CurrentSettings.AdditionalRespawnTime,
		CurrentSettings.bNoLeaders,
		CurrentSettings.Unused3,
		CurrentSettings.bEnableSnipers );

	// Set the server settings to dirty
	SwatPlayerController(PlayerOwner()).ServerSetDirty(PendingSettings);

	// Restart the server
	SwatPlayerController(PlayerOwner()).ServerCoopQMMRestart();
}

protected function bool HandleKeyEventFirstCrack( out byte Key, out byte State, float delta )
{
    if( State == EInputAction.IST_Press )
    {
        //don't handle first crack on chat up/down if the chat entry is open
        if( !MyChatPanel.MyChatEntry.bActiveInput )
        {
            if( KeyMatchesBinding( Key, "ScrollChatUp" ) )
            {
                SwatGUIController(Controller).ScrollChatUp();
                return true;
            }
            if( KeyMatchesBinding( Key, "ScrollChatDown" ) )
            {
                SwatGUIController(Controller).ScrollChatDown();
                return true;
            }
        }
        if( KeyMatchesBinding( Key, "ScrollChatPageUp" ) )
        {
            SwatGUIController(Controller).ScrollChatPageUp();
            return true;
        }
        if( KeyMatchesBinding( Key, "ScrollChatPageDown" ) )
        {
            SwatGUIController(Controller).ScrollChatPageDown();
            return true;
        }
        if( KeyMatchesBinding( Key, "ScrollChatToEnd" ) )
        {
            SwatGUIController(Controller).ScrollChatToEnd();
            return true;
        }
        if( KeyMatchesBinding( Key, "ScrollChatToHome" ) )
        {
            SwatGUIController(Controller).ScrollChatToHome();
            return true;
        }
    }

    return false;
}

protected function bool HandleKeyEvent( out byte Key, out byte State, float delta )
{
    if( tabs.AllowChat() && State == EInputAction.IST_Press )
    {
        if( KeyMatchesBinding( Key, "OpenHudChat 1" ) )
        {
            SwatGUIController(Controller).OpenChat( true );
            return true;
        }
        if( KeyMatchesBinding( Key, "OpenHudChat 0" ) )
        {
            SwatGUIController(Controller).OpenChat( false );
            return true;
        }
    }

    return Super.HandleKeyEvent( Key, State, delta );
}

defaultproperties
{
	ConfirmAbortString="Disconnect from the current game?"
	OnKeyEventFirstCrack=HandleKeyEventFirstCrack
}
