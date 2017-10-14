class SwatServerSetupAdvancedPanel extends SwatGUIPanel
     ;

import enum EMPMode from Engine.Repo;

var SwatServerSetupMenu SwatServerSetupMenu;

var(SWATGui) EditInline Config GUINumericEdit	   MyMaxPlayersBox;
var(SWATGui) EditInline Config GUISlider           MyFriendlyFireSlider;
var(SWATGui) EditInline Config GUINumericEdit      MyPreGameTimeLimitBox;
var(SWATGui) EditInline Config GUICheckBoxButton   MyShowTeammatesButton;
var(SWATGui) EditInline Config GUICheckBoxButton   MyAllowReferendumsButton;
var(SWATGui) EditInline Config GUINumericEdit      MyPostGameTimeLimitBox;
var(SWATGui) EditInline Config GUICheckBoxButton   MyDedicatedServerCheck;
var(SWATGui) EditInline Config GUILabel            MyDedicatedServerLabel;
var(SWATGui) EditInline Config GUINumericEdit      MyAdditionalRespawnTimeBox;
var(SWATGui) EditInline Config GUICheckBoxButton   MyEnableLeadersCheck;
var(SWATGui) EditInline Config GUICheckBoxButton   MyEnableSnipers;
var(SWATGui) EditInline Config GUICheckBoxButton   MyRoundStartTimerCheck;
var(SWATGui) EditInline Config GUICheckBoxButton   MyRoundEndTimerCheck;

var private config int COOPMaxPlayers;
var private bool bIsCoop;

function SetSubComponentsEnabled( bool bSetEnabled )
{
    MyMaxPlayersBox.SetEnabled( bSetEnabled );
	MyFriendlyFireSlider.SetEnabled( bSetEnabled );
	MyPreGameTimeLimitBox.SetEnabled( bSetEnabled );
	MyShowTeammatesButton.SetEnabled( bSetEnabled );
	MyAllowReferendumsButton.SetEnabled( bSetEnabled );
	MyPostGameTimeLimitBox.SetEnabled( bSetEnabled );
	MyDedicatedServerCheck.SetEnabled( bSetEnabled );

	MyAdditionalRespawnTimeBox.SetEnabled( bSetEnabled );
	MyEnableLeadersCheck.SetEnabled( bSetEnabled );
	MyEnableSnipers.SetEnabled( bSetEnabled );
	MyRoundStartTimerCheck.SetEnabled( bSetEnabled );
	MyRoundEndTimerCheck.SetEnabled( bSetEnabled );
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
	MyAllowReferendumsButton.SetChecked( Settings.bAllowReferendums );
    MyFriendlyFireSlider.SetValue( Settings.FriendlyFireAmount );
	MyAdditionalRespawnTimeBox.SetValue( Settings.AdditionalRespawnTime );
	MyEnableSnipers.SetChecked( !Settings.bEnableSnipers );
	MyRoundStartTimerCheck.SetChecked (Settings.bUseRoundStartTimer);
	MyRoundEndTimerCheck.SetChecked(Settings.bUseRoundEndTimer);

	MyEnableLeadersCheck.SetChecked( !Settings.bNoLeaders );
}

function SaveServerSettings()
{

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
