class SwatServerSetupAdvancedPanel extends SwatGUIPanel
     ;

import enum EMPMode from Engine.Repo;

var SwatServerSetupMenu SwatServerSetupMenu;

var(SWATGui) EditInline Config GUINumericEdit	   MyMaxPlayersBox;
var(SWATGui) EditInline Config GUISlider           MyFriendlyFireSlider;
var(SWATGui) EditInline Config GUINumericEdit      MyPreGameTimeLimitBox;
var(SWATGui) EditInline Config GUICheckBoxButton   MyShowTeammatesButton;
var(SWATGui) EditInline Config GUINumericEdit      MyPostGameTimeLimitBox;
var(SWATGui) EditInline Config GUICheckBoxButton   MyDedicatedServerCheck;
var(SWATGui) EditInline Config GUILabel            MyDedicatedServerLabel;
var(SWATGui) EditInline Config GUINumericEdit      MyAdditionalRespawnTimeBox;
var(SWATGui) EditInline Config GUICheckBoxButton   MyEnableLeadersCheck;
var(SWATGui) EditInline Config GUICheckBoxButton   MyEnableSnipers;
var(SWATGui) EditInline Config GUICheckBoxButton   MyRoundStartTimerCheck;
var(SWATGui) EditInline Config GUICheckBoxButton   MyRoundEndTimerCheck;
var(SWATGui) EditInline Config GUICheckBoxButton   MyEnableKillMessagesCheck;
var(SWATGui) EditInline Config GUISlider		   MyHostageSpawnSlider;
var(SWATGui) EditInline Config GUISlider		   MySuspectSpawnSlider;

var private config int COOPMaxPlayers;
var private bool bIsCoop;

function SetSubComponentsEnabled( bool bSetEnabled )
{
    MyMaxPlayersBox.SetEnabled( bSetEnabled );
	MyFriendlyFireSlider.SetEnabled( bSetEnabled );
	MyPreGameTimeLimitBox.SetEnabled( bSetEnabled );
	MyShowTeammatesButton.SetEnabled( bSetEnabled );
	MyPostGameTimeLimitBox.SetEnabled( bSetEnabled );
	MyDedicatedServerCheck.SetEnabled( bSetEnabled );

	MyAdditionalRespawnTimeBox.SetEnabled( bSetEnabled );
	MyEnableLeadersCheck.SetEnabled( bSetEnabled );
	MyEnableSnipers.SetEnabled( bSetEnabled );
	MyRoundStartTimerCheck.SetEnabled( bSetEnabled );
	MyRoundEndTimerCheck.SetEnabled( bSetEnabled );
	MyEnableKillMessagesCheck.SetEnabled(bSetEnabled);

	MyHostageSpawnSlider.SetEnabled(bSetEnabled);
	MySuspectSpawnSlider.SetEnabled(bSetEnabled);
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

		if( NewMode == EMPMode.MPM_COOPQMM )
			MyDedicatedServerCheck.DisableComponent();

        //default to 480 second pre-game time for coop
		MyPreGameTimeLimitBox.SetValue( 480 );

        //default to 120 second post-game time for coop
        MyPostGameTimeLimitBox.SetValue( 120 );

		// default always show friendly names in coop
	    MyShowTeammatesButton.SetChecked( true );

		MyEnableLeadersCheck.SetChecked( true );

		MyHostageSpawnSlider.SetValue(1.0);
		MySuspectSpawnSlider.SetValue(1.0);

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
    MyFriendlyFireSlider.SetValue( Settings.FriendlyFireAmount );
	MyAdditionalRespawnTimeBox.SetValue( Settings.AdditionalRespawnTime );
	MyEnableSnipers.SetChecked( Settings.bEnableSnipers );
	MyRoundStartTimerCheck.SetChecked (Settings.bUseRoundStartTimer);
	MyRoundEndTimerCheck.SetChecked(Settings.bUseRoundEndTimer);
	MyEnableKillMessagesCheck.SetChecked(!Settings.bNoKillMessages);
	MyHostageSpawnSlider.SetValue(GC.ExtraFloatOptions[1]);
	MySuspectSpawnSlider.SetValue(GC.ExtraFloatOptions[0]);

	MyEnableLeadersCheck.SetChecked( !Settings.bNoLeaders );
}

function SaveServerSettings()
{
	GC.ExtraFloatOptions[0] = MySuspectSpawnSlider.GetValue();
	GC.ExtraFloatOptions[1] = MyHostageSpawnSlider.GetValue();
}

event HandleParameters(string Param1, string Param2, optional int param3)
{
    LoadServerSettings( !SwatServerSetupMenu.bIsAdmin );

    MyDedicatedServerCheck.SetChecked(false);
    MyDedicatedServerCheck.SetVisibility( !SwatServerSetupMenu.bInGame );
    MyDedicatedServerCheck.SetActive( !SwatServerSetupMenu.bInGame );
    MyDedicatedServerLabel.SetVisibility( !SwatServerSetupMenu.bInGame );
}

function OnActivate()
{
	SwatServerSetupMenu.RefreshEnabled();
}

defaultproperties
{
    COOPMaxPlayers=10
}
