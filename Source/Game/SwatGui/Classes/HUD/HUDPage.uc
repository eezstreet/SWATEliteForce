class HUDPage extends SwatGame.HUDPageBase
	implements ISpeechClient;

import enum SpeechRecognitionConfidence from Engine.SpeechManager;

var(HUD) EditInline SwatChatPanel ChatPanel "The chat panel.";
var(HUD) EditInline SwatImportantMessageDisplay ImportantMessageDisplay "The Important Message Display.";
var(HUD) EditInline SwatImportantMessageDisplay RespawnMessageDisplay "The Respawn Message Display (MP Only).";
var(HUD) EditInline SwatTimeDisplay SpecialTimeDisplay "The Special Time Display.";
var(HUD) EditInline SwatTimeDisplay RespawnTimeDisplay "The Respawn Time Display (MP Only).";
var(HUD) EditInline SwatTimeDisplay ReferendumTimeDisplay "The Referendum Time Display (MP Only).";

function InitComponent(GUIComponent MyOwner)
{
 	Super.InitComponent(MyOwner);
}

function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);
    
    ChatPanel = SwatChatPanel(AddComponent("SwatGUI.SwatChatPanel", "HudChatPanel"));
    ImportantMessageDisplay = SwatImportantMessageDisplay(AddComponent("SwatGUI.SwatImportantMessageDisplay", "HUDPage_ImportantMessageDisplay"));
    RespawnMessageDisplay = SwatImportantMessageDisplay(AddComponent("SwatGUI.SwatImportantMessageDisplay", "HUDPage_RespawnMessageDisplay"));
    SpecialTimeDisplay = SwatTimeDisplay(AddComponent("SwatGUI.SwatTimeDisplay", "HUDPage_SpecialTimeDisplay"));
    RespawnTimeDisplay = SwatTimeDisplay(AddComponent("SwatGUI.SwatTimeDisplay", "HUDPage_RespawnTimeDisplay"));
	ReferendumTimeDisplay = SwatTimeDisplay(AddComponent("SwatGUI.SwatTimeDisplay", "HUDPage_ReferendumTimeDisplay"));
}

function CloseGUIGenericComponents()
{
    //assert( ChatPanel != None );
    //ChatPanel.Hide();
    assert( ImportantMessageDisplay != None );
    ImportantMessageDisplay.Hide();
}

function CloseGUIMPComponents()
{
    assert( RespawnMessageDisplay != None );
    RespawnMessageDisplay.Hide();
    assert( RespawnTimeDisplay != None );
    RespawnTimeDisplay.StopTimer();
    RespawnTimeDisplay.Hide();
}

function OpenGUIGenericComponents()
{
    assert( ChatPanel != None );
    //ChatPanel.ClearChatMessages();
    //note: we only want to show the chat panel if not playing training
    if( PlayerOwner().Level.IsTraining )
        ChatPanel.Reposition( 'Training' );
    else
        ChatPanel.Reposition( 'Default' );
    ChatPanel.Show();
    
    assert( ImportantMessageDisplay != None );
    ImportantMessageDisplay.ClearDisplay();
    ImportantMessageDisplay.Hide();

	//PlayerOwner.Level.GetEngine().SpeechManager.UnRegisterRuleInterest(self, 'None');
}

function OpenGUIMPComponents()
{
    assert( RespawnMessageDisplay != None );
    RespawnMessageDisplay.Hide();
    assert( RespawnTimeDisplay != None );
    RespawnTimeDisplay.Hide();
}

protected function CloseComponents()
{
    Super.CloseComponents();

    switch (SwatGUIControllerBase(Controller).GuiConfig.SwatGameRole)
    {
        case GAMEROLE_None:
        case GAMEROLE_SP_Campaign:
        case GAMEROLE_SP_Custom:
        case GAMEROLE_SP_Other:
            break;

        case GAMEROLE_MP_Host:
        case GAMEROLE_MP_Client:
            CloseGUIMPComponents();
            break;

        default:
            assert(false);  //unexpected SwatGameRole
            break;
    }
    
    CloseGUIGenericComponents();
}

protected function OpenComponents()
{
    Super.OpenComponents();
    
    switch (SwatGUIControllerBase(Controller).GuiConfig.SwatGameRole)
    {
        case GAMEROLE_None:
        case GAMEROLE_SP_Campaign:
        case GAMEROLE_SP_Custom:
        case GAMEROLE_SP_Other:
            break;

        case GAMEROLE_MP_Host:
        case GAMEROLE_MP_Client:
            OpenGUIMPComponents();
            break;

        default:
            assert(false);  //unexpected SwatGameRole
            break;
    }
    
    OpenGUIGenericComponents();
}

function OnPlayerDied()
{
    Super.CloseComponents();
}

function OnPlayerRespawned()
{
    Super.OpenComponents();
}

function OnGameOver()
{
    Super.OnGameOver();
    
    assert( SpecialTimeDisplay != None );
    SpecialTimeDisplay.StopTimer();
    SpecialTimeDisplay.Hide();
}

simulated function OnSpeechPhraseStart()
{
	SpeechRecStatus.Image = SpeechRecStart;
	SpeechRecStatus.RePosition('Show');
}

simulated function OnSpeechCommandRecognized(name Rule, Array<name> Value, SpeechRecognitionConfidence Confidence)
{
	SpeechRecStatus.Image = SpeechRecRecognized;
	SpeechRecStatus.RePosition('Fade');
}

simulated function OnSpeechFalseRecognition()
{
	SpeechRecStatus.Image = SpeechRecBad;
	SpeechRecStatus.RePosition('Fade');
}

simulated function OnSpeechAudioLevel(int Level)
{
}

function CloseSPComponents()
{
	Super.CloseSPComponents();
	PlayerOwner().Level.GetEngine().SpeechManager.UnRegisterInterest(self);
}

function OpenSPComponents()
{
	Super.OpenSPComponents();
	PlayerOwner().Level.GetEngine().SpeechManager.RegisterInterest(self);

	SpeechRecStatus.Show();

	// flash speech rec icon to show activation of speech
	if (PlayerOwner().Level.GetEngine().SpeechManager.IsEnabled())
	{
		SpeechRecStatus.Image = SpeechRecRecognized;
		SpeechRecStatus.RePosition('SlowFade');
	}
}