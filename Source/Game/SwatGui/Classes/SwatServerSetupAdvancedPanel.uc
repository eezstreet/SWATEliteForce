class SwatServerSetupAdvancedPanel extends SwatGUIPanel
     ;

import enum EMPMode from Engine.Repo;

var SwatServerSetupMenu SwatServerSetupMenu;

var(SWATGui) EditInline Config GUINumericEdit	   MyMaxPlayersBox;
var(SWATGui) EditInline Config GUISlider           MyFriendlyFireSlider;
var(SWATGui) EditInline Config GUINumericEdit      MyPreGameTimeLimitBox;
var(SWATGui) EditInline Config GUICheckBoxButton   MyEnableStatsCheck;
var(SWATGui) EditInline Config GUICheckBoxButton   MyShowEnemyButton;
var(SWATGui) EditInline Config GUICheckBoxButton   MyShowTeammatesButton;
var(SWATGui) EditInline Config GUICheckBoxButton   MyAllowReferendumsButton;
var(SWATGui) EditInline Config GUINumericEdit      MyPostGameTimeLimitBox;
var(SWATGui) EditInline Config GUICheckBoxButton   MyDedicatedServerCheck;
var(SWATGui) EditInline Config GUILabel            MyDedicatedServerLabel;
var(SWATGui) EditInline Config GUICheckBoxButton   MyEnemyFireButton;
var(SWATGui) EditInline Config GUIEditBox          MyAdminPasswordBox;
var(SWATGui) EditInline Config GUINumericEdit      MyArrestRoundTimeDeductionBox;
var(SWATGui) EditInline Config GUINumericEdit      MyAdditionalRespawnTimeBox;
var(SWATGui) EditInline Config GUICheckBoxButton   MyEnableLeadersCheck;
var(SWATGui) EditInline Config GUICheckBoxButton   MyEnableTeamSpecificWeapons;

var private config int COOPMaxPlayers;
var private bool bIsCoop;
 
function SetSubComponentsEnabled( bool bSetEnabled )
{
    MyMaxPlayersBox.SetEnabled( bSetEnabled );
	MyFriendlyFireSlider.SetEnabled( bSetEnabled );
	MyPreGameTimeLimitBox.SetEnabled( bSetEnabled );
	MyEnableStatsCheck.SetEnabled( bSetEnabled );
	MyShowEnemyButton.SetEnabled( bSetEnabled );
	MyShowTeammatesButton.SetEnabled( bSetEnabled );
	MyAllowReferendumsButton.SetEnabled( bSetEnabled );
	MyPostGameTimeLimitBox.SetEnabled( bSetEnabled );
	MyDedicatedServerCheck.SetEnabled( bSetEnabled );
	MyEnemyFireButton.SetEnabled( bSetEnabled );
	MyAdminPasswordBox.SetEnabled( bSetEnabled );
	MyArrestRoundTimeDeductionBox.SetEnabled( bSetEnabled );
	MyAdditionalRespawnTimeBox.SetEnabled( bSetEnabled );
	MyEnableLeadersCheck.SetEnabled( bSetEnabled );
	MyEnableTeamSpecificWeapons.SetEnabled( bSetEnabled );
}

function DoResetDefaultsForGameMode( EMPMode NewMode )
{
    SetSubComponentsEnabled( SwatServerSetupMenu.bIsAdmin );

	bIsCoop = false;

	//COOP special
    if( NewMode == EMPMode.MPM_COOP || NewMode == EMPMode.MPM_COOPQMM )
    {
        MyMaxPlayersBox.SetMaxValue( Clamp( COOPMaxPlayers, 0, 16 ) );
        MyMaxPlayersBox.SetValue( 10 );
        
        //MyShowEnemyButton.DisableComponent();
        MyEnemyFireButton.DisableComponent();

        MyFriendlyFireSlider.DisableComponent();
        MyFriendlyFireSlider.SetValue( 1.0 );

		if( NewMode == EMPMode.MPM_COOPQMM )
			MyDedicatedServerCheck.DisableComponent();
        
        //default to 480 second pre-game time for coop
		MyPreGameTimeLimitBox.SetValue( 480 );

        //default to 120 second post-game time for coop
        MyPostGameTimeLimitBox.SetValue( 120 );
        
		// default always show friendly names in coop
	    MyShowTeammatesButton.SetChecked( true );

		MyEnableLeadersCheck.SetChecked( true );
		MyEnableLeadersCheck.SetEnabled( SwatServerSetupMenu.bIsAdmin );

		bIsCoop = true;
    }
    else
    {
        MyMaxPlayersBox.SetMaxValue( 16 );
        MyMaxPlayersBox.SetValue( 16 );

        //default to 90 second pre-game time for non coop
        MyPreGameTimeLimitBox.SetValue( 90 );
        //default to 15 second pre-game time for non coop
        MyPostGameTimeLimitBox.SetValue( 15 );

		MyEnableLeadersCheck.DisableComponent();
    }

    //VIP special
    if( NewMode == EMPMode.MPM_VIPEscort )
    {
        MyEnemyFireButton.DisableComponent();
        MyFriendlyFireSlider.DisableComponent();
        MyFriendlyFireSlider.SetValue( 1.0 );
    }
    else
    {
        //Do Nothing
    }

    MyEnemyFireButton.SetChecked(false);

	if ( NewMode == EMPMode.MPM_SmashAndGrab )
	{
		MyArrestRoundTimeDeductionBox.SetValue( 30 );
		MyArrestRoundTimeDeductionBox.SetEnabled( SwatServerSetupMenu.bIsAdmin );
	}
	else
	{
		MyArrestRoundTimeDeductionBox.DisableComponent();
	}

	MyAdditionalRespawnTimeBox.SetValue(0);
}

function LoadServerSettings( optional bool ReadOnly )
{
    local ServerSettings Settings;
    
    //
    // choose the correct settings:
    //    non-admin (read-only):  Current settings
    //    admin:                  Pending settings
    //
    if( ReadOnly )
        Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);
    else
        Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);
    
    //
    // Load the rest of the settings
    //
    MyMaxPlayersBox.SetValue(Settings.MaxPlayers, true);
    MyPreGameTimeLimitBox.SetValue(Settings.MPMissionReadyTime, true);
    MyPostGameTimeLimitBox.SetValue(Settings.PostGameTimeLimit, true);
    MyShowTeammatesButton.SetChecked( Settings.bShowTeammateNames );
	MyAllowReferendumsButton.SetChecked( Settings.bAllowReferendums );
    MyEnemyFireButton.SetChecked( Settings.EnemyFireAmount == 0.0 );
    MyShowEnemyButton.SetChecked( Settings.bShowEnemyNames );
	MyEnableStatsCheck.SetChecked( Settings.bUseStatTracking );
    MyFriendlyFireSlider.SetValue( Settings.FriendlyFireAmount );
	MyArrestRoundTimeDeductionBox.SetValue( Settings.ArrestRoundTimeDeduction );
	MyAdditionalRespawnTimeBox.SetValue( Settings.AdditionalRespawnTime );
	MyEnableTeamSpecificWeapons.SetChecked( !Settings.bDisableTeamSpecificWeapons );

    MyAdminPasswordBox.SetText( GC.AdminPassword );

	MyEnableLeadersCheck.SetChecked( !Settings.bNoLeaders );
}

function SaveServerSettings()
{
    GC.AdminPassword = MyAdminPasswordBox.GetText();
}

function DoRefreshEnabled()
{
    MyEnableStatsCheck.SetEnabled( SwatServerSetupMenu.bUseGamespy && !bIsCoop && SwatServerSetupMenu.bIsAdmin );
}

event HandleParameters(string Param1, string Param2, optional int param3)
{
    LoadServerSettings( !SwatServerSetupMenu.bIsAdmin );

    MyDedicatedServerCheck.SetChecked(false);
    MyDedicatedServerCheck.SetVisibility( !SwatServerSetupMenu.bInGame );
    MyDedicatedServerCheck.SetActive( !SwatServerSetupMenu.bInGame );
    MyDedicatedServerLabel.SetVisibility( !SwatServerSetupMenu.bInGame );

    MyAdminPasswordBox.SetVisibility( GC.SwatGameRole == GAMEROLE_MP_Host );
    MyAdminPasswordBox.SetActive( GC.SwatGameRole == GAMEROLE_MP_Host );
}

function OnActivate()
{
	SwatServerSetupMenu.RefreshEnabled();
}

defaultproperties
{
    COOPMaxPlayers=10
}
	
