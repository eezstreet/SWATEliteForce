// ====================================================================
//  Class:  SwatGui.SwatAudioSettingsPanel
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatAudioSettingsPanel extends SwatSettingsPanel
     implements ISpeechClient;

import enum SpeechRecognitionConfidence from Engine.SpeechManager;

var(SWATGui) private EditInline Config GUISlider			MyMusicVolumeSlider;
var(SWATGui) private EditInline Config GUISlider			MySoundVolumeSlider;
var(SWATGui) private EditInline Config GUISlider			MyVoiceVolumeSlider;
var(SWATGui) private EditInline Config GUISlider			MyVOIPVolumeSlider;
var(SWATGui) private EditInline Config GUICheckBoxButton	RecognitionEnabled;
var(SWATGui) private EditInline Config GUICheckBoxButton	VOIPEnabled;
var(SWATGui) private EditInline Config GUICheckBoxButton  DisableDispatch;
#if IG_CAPTIONS
var(SWATGui) private EditInline Config GUICheckBoxButton MyShowSubtitlesCheck;
#endif

var() private float DefaultMusicVolume;
var() private float DefaultSoundVolume;
var() private float DefaultVoiceVolume;
var() private float DefaultVOIPVolume;
var() private float DefaultAmbientVolume;

var private localized string SpeechRecognitionDisabledHelpString;

function InitComponent(GUIComponent MyOwner)
{
    //log("SwatAudioSettingsPanel InitComponent()");
	Super.InitComponent(MyOwner);

	if (!PlayerOwner().Level.GetEngine().SpeechManager.IsInitialized())
		RecognitionEnabled.Hint = SpeechRecognitionDisabledHelpString;
	else
		RecognitionEnabled.Hint = "";

	MyMusicVolumeSlider.OnChange=OnMusicVolumeChanged;
    MySoundVolumeSlider.OnChange=OnSoundVolumeChanged;
    MyVoiceVolumeSlider.OnChange=OnVoiceVolumeChanged;
    MyVOIPVolumeSlider.OnChange=OnVOIPVolumeChanged;
	RecognitionEnabled.OnClick=OnRecognitionEnabledChanged;
  DisableDispatch.OnClick=OnDispatchDisabledChanged;
//  DisableDispatch.OnClick=OnDisableDispatchChanged;
	VOIPEnabled.OnClick=OnVOIPEnabledChanged;
}

function SaveSettings()
{
    //log("SwatAudioSettingsPanel SaveSettings()");
    #if IG_CAPTIONS
        GC.bShowSubtitles = MyShowSubtitlesCheck.bChecked;
    #endif

    GC.SaveConfig();
	class'SpeechManager'.static.StaticSaveConfig();
  SwatGUIControllerBase(Controller).SetDispatchDisabled(DisableDispatch.bChecked);
  SwatGUIControllerBase(Controller).SaveConfig();
}

function LoadSettings()
{
    //log("SwatAudioSettingsPanel LoadSettings()");

	MySoundVolumeSlider.Value = float(PlayerOwner().ConsoleCommand("get alaudio.alaudiosubsystem soundvolume"));
	MyMusicVolumeSlider.Value = float(PlayerOwner().ConsoleCommand("get alaudio.alaudiosubsystem musicvolume"));
	MyVoiceVolumeSlider.Value = float(PlayerOwner().ConsoleCommand("get alaudio.alaudiosubsystem Voicevolume"));
	MyVOIPVolumeSlider.Value = float(PlayerOwner().ConsoleCommand("get alaudio.alaudiosubsystem VOIPvolume"));

	RecognitionEnabled.SetEnabled(PlayerOwner().Level.GetEngine().SpeechManager.IsInitialized());
	RecognitionEnabled.SetChecked(PlayerOwner().Level.GetEngine().SpeechManager.IsInitialized() && PlayerOwner().Level.GetEngine().SpeechManager.IsEnabled());
  DisableDispatch.SetChecked(SwatGUIControllerBase(Controller).GetDispatchDisabled());

  #if IG_CAPTIONS
      MyShowSubtitlesCheck.SetChecked( GC.bShowSubtitles );
  #endif

	VOIPEnabled.SetEnabled(true);
	VOIPEnabled.SetChecked(bool(PlayerOwner().ConsoleCommand("get alaudio.alaudiosubsystem UseVoIP")));
}

private function OnMusicVolumeChanged( GUIComponent Sender )
{
    local float Multiplier;
    Multiplier = GUISlider(Sender).Value;

	//Log("Setting Music Volume to "$Multiplier);

    Controller.StaticExec("set alaudio.alaudiosubsystem musicvolume "$Multiplier);
}

private function OnSoundVolumeChanged( GUIComponent Sender )
{
    local float Multiplier;
    Multiplier = GUISlider(Sender).Value;

	//Log("Setting Sound Volume to "$Multiplier);

    Controller.StaticExec("set alaudio.alaudiosubsystem soundvolume "$Multiplier);
    Controller.StaticExec("set alaudio.alaudiosubsystem Ambientvolume "$Multiplier);
}

private function OnVoiceVolumeChanged( GUIComponent Sender )
{
    local float Multiplier;
    Multiplier = GUISlider(Sender).Value;

    //Log("Setting Voice Volume to "$Multiplier);

    Controller.StaticExec("set alaudio.alaudiosubsystem Voicevolume "$Multiplier);
}

private function OnVOIPVolumeChanged( GUIComponent Sender )
{
    local float Multiplier;
    Multiplier = GUISlider(Sender).Value;

	//Log("Setting VOIP Volume to "$Multiplier);

    Controller.StaticExec("set alaudio.alaudiosubsystem VOIPvolume "$Multiplier);
}

protected function ResetToDefaults()
{
    //log("SwatAudioSettingsPanel ResetToDefaults()");

    //set the audio defaults here
    MyMusicVolumeSlider.SetValue( DefaultMusicVolume );
    MySoundVolumeSlider.SetValue( DefaultSoundVolume );
    MyVoiceVolumeSlider.SetValue( DefaultVoiceVolume );
    MyVOIPVolumeSlider.SetValue( DefaultVOIPVolume );
}

event Show()
{
    Super.Show();
	//PlayerOwner().Level.GetEngine().SpeechManager.RegisterAudioLevelInterest(self);
}

event Hide()
{
	Super.Hide();
	//PlayerOwner().Level.GetEngine().SpeechManager.UnregisterAudioLevelInterest(self);
}

private function OnRecognitionEnabledChanged( GUIComponent Sender )
{
	if (RecognitionEnabled.bChecked)
	{
		log("Speech recognition enabled.");
		PlayerOwner().Level.GetEngine().SpeechManager.EnableSpeech();
	}
	else
	{
		log("Speech recognition disabled.");
		PlayerOwner().Level.GetEngine().SpeechManager.DisableSpeech();
	}
}

private function OnVOIPEnabledChanged( GUIComponent Sender )
{
	if (VOIPEnabled.bChecked)
	{
		log("VOIP enabled.");
		Controller.StaticExec("set ini:Engine.Engine.AudioDevice UseVoIP"@True);
		PlayerOwner().EnableVoiceChat();
	}
	else
	{
		log("VOIP disabled.");
		Controller.StaticExec("set ini:Engine.Engine.AudioDevice UseVoIP"@False);
		PlayerOwner().DisableVoiceChat();
	}
}

private function OnDispatchDisabledChanged(GUIComponent Sender) {
  if(DisableDispatch.bChecked)
  {
    log("Dispatch disabled");
    SwatGUIControllerBase(Controller).SetDispatchDisabled(true);
  }
  else {
    log("Dispatch enabled");
    SwatGUIControllerBase(Controller).SetDispatchDisabled(false);
  }
  SwatGUIControllerBase(Controller).SaveConfig();
  SwatGUIControllerBase(Controller).StaticSaveConfig();
}

// ISpeechClient implementation
function OnSpeechPhraseStart()
{
}

function OnSpeechCommandRecognized(name Rule, Array<name> Value, SpeechRecognitionConfidence Confidence)
{
}

function OnSpeechFalseRecognition()
{
}

function OnSpeechAudioLevel(int Value)
{
}

defaultproperties
{
    ConfirmResetString="Are you sure that you wish to reset all audio settings to their defaults?"
	SpeechRecognitionDisabledHelpString="Speech recognition could not be initialized. Please consult the manual for help."
    DefaultMusicVolume=0.9
    DefaultSoundVolume=0.9
    DefaultVoiceVolume=0.9
    DefaultVOIPVolume=0.9
	Enabled=true
}
