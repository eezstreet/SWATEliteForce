class CustomScenarioTabControl extends GUI.GUITabControl;

enum ETabPanels
{
    Tab_Selection,
    Tab_Mission,
    Tab_Squad,
    Tab_Hostages,
    Tab_Enemies,
    Tab_Notes,
    Tab_Save,
};

var bool bSelectionTabEnabled;

function bool IsSelectionTabEnabled()
{
	return bSelectionTabEnabled;
}

function CustomScenario_MissionTabPanel GetMissionTabPanel()
{
	return CustomScenario_MissionTabPanel( MyTabs[ ETabPanels.Tab_Mission ].TabPanel );
}

function CustomScenario_HostagesTabPanel GetHostagesTabPanel()
{
	return CustomScenario_HostagesTabPanel( MyTabs[ ETabPanels.Tab_Hostages ].TabPanel );
}

function CustomScenario_EnemiesTabPanel GetEnemiesTabPanel()
{
	return CustomScenario_EnemiesTabPanel( MyTabs[ ETabPanels.Tab_Enemies ].TabPanel );
}

function CustomScenario_NotesTabPanel GetNotesTabPanel()
{
	return CustomScenario_NotesTabPanel( MyTabs[ ETabPanels.Tab_Notes ].TabPanel );
}

function bool AllowChat()
{
	return CustomScenarioTabPanel(ActiveTab.TabPanel).AllowChat();
}

function EnableInvalidOverlays()
{
	if (GetMissionTabPanel().bActiveInput)
		GetMissionTabPanel().SetActive(false);

	if (!GetMissionTabPanel().pnl_InvalidOverlay.bVisible)
		GetMissionTabPanel().pnl_InvalidOverlay.SetVisibility( true );

	if (GetHostagesTabPanel().bActiveInput)
		GetHostagesTabPanel().SetActive(false);

	if (!GetHostagesTabPanel().pnl_InvalidOverlay.bVisible)
		GetHostagesTabPanel().pnl_InvalidOverlay.SetVisibility( true );

	if (GetEnemiesTabPanel().bActiveInput)
		GetEnemiesTabPanel().SetActive(false);

	if (!GetEnemiesTabPanel().pnl_InvalidOverlay.bVisible)
		GetEnemiesTabPanel().pnl_InvalidOverlay.SetVisibility( true );

	if (GetNotesTabPanel().bActiveInput)
		GetNotesTabPanel().SetActive(false);

	if (!GetNotesTabPanel().pnl_InvalidOverlay.bVisible)
		GetNotesTabPanel().pnl_InvalidOverlay.SetVisibility( true );
}

function DisableInvalidOverlays()
{
	if (!GetMissionTabPanel().bActiveInput)
		GetMissionTabPanel().SetActive(true);

	if (GetMissionTabPanel().pnl_InvalidOverlay.bVisible)
		GetMissionTabPanel().pnl_InvalidOverlay.SetVisibility( false );

	if (!GetHostagesTabPanel().bActiveInput)
		GetHostagesTabPanel().SetActive(true);

	if (GetHostagesTabPanel().pnl_InvalidOverlay.bVisible)
		GetHostagesTabPanel().pnl_InvalidOverlay.SetVisibility( false );

	if (!GetEnemiesTabPanel().bActiveInput)
		GetEnemiesTabPanel().SetActive(true);

	if (GetEnemiesTabPanel().pnl_InvalidOverlay.bVisible)
		GetEnemiesTabPanel().pnl_InvalidOverlay.SetVisibility( false );

	if (!GetNotesTabPanel().bActiveInput)
		GetNotesTabPanel().SetActive(true);

	if (GetNotesTabPanel().pnl_InvalidOverlay.bVisible)
		GetNotesTabPanel().pnl_InvalidOverlay.SetVisibility( false );
}

function OpenTabByIndex( int index )
{
    InternalOpenTabPair( MyTabs[index] );
}

function InternalOpenTabPair( sTabButtonPair theTab )
{
    local int i;
    
    if( theTab == MyTabs[ ETabPanels.Tab_Selection ] && CustomScenarioPage(MenuOwner).CustomScenarioCreatorData.IsCurrentMisisonDirty() )
    {
        CustomScenarioPage(MenuOwner).ConfirmQuitOrSave( "Selection" );
        return;
    }
    
    Super.InternalOpenTabPair( theTab );

	bSelectionTabEnabled = ( theTab == MyTabs[ ETabPanels.Tab_Selection ] );

	if (CustomScenarioPage(MenuOwner).IsClient())
		return;

    if( theTab == MyTabs[ ETabPanels.Tab_Selection ] )
    {
        for( i = 0; i < ETabPanels.EnumCount; i++ )
        {
            if( i == ETabPanels.Tab_Selection )
                continue;
            MyTabs[i].TabHeader.DisableComponent();
        }
    }
    else if( theTab == MyTabs[ ETabPanels.Tab_Save ] )
    {
        MyTabs[ETabPanels.Tab_Selection].TabHeader.DisableComponent();
    }
    else
    {
        //enable all others
        for( i = 0; i < ETabPanels.EnumCount; i++ )
        {
            if( MyTabs[i] != theTab )
                MyTabs[i].TabHeader.EnableComponent();
        }
    }
}

function DisableSquadTab()
{
	if (MyTabs[ETabPanels.Tab_Squad].TabHeader.MenuState != MSAT_Disabled)
		MyTabs[ETabPanels.Tab_Squad].TabHeader.DisableComponent();
}

function SetTabsForClient()
{
	if (MyTabs[ETabPanels.Tab_Selection].TabHeader.MenuState != MSAT_Disabled)
		MyTabs[ETabPanels.Tab_Selection].TabHeader.DisableComponent();

	if (MyTabs[ETabPanels.Tab_Mission].TabHeader.MenuState == MSAT_Disabled)
		MyTabs[ETabPanels.Tab_Mission].TabHeader.EnableComponent();

	if (MyTabs[ETabPanels.Tab_Hostages].TabHeader.MenuState == MSAT_Disabled)
		MyTabs[ETabPanels.Tab_Hostages].TabHeader.EnableComponent();

	if (MyTabs[ETabPanels.Tab_Enemies].TabHeader.MenuState == MSAT_Disabled)
		MyTabs[ETabPanels.Tab_Enemies].TabHeader.EnableComponent();

	if (MyTabs[ETabPanels.Tab_Notes].TabHeader.MenuState == MSAT_Disabled)
		MyTabs[ETabPanels.Tab_Notes].TabHeader.EnableComponent();

	if (MyTabs[ETabPanels.Tab_Save].TabHeader.MenuState != MSAT_Disabled)
		MyTabs[ETabPanels.Tab_Save].TabHeader.DisableComponent();

}