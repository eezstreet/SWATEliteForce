class SpeechManager extends Core.Object
    native
	config(User);

struct native ClientInterest
{
    var ISpeechClient Client;
};
var array<ClientInterest>	ClientInterests;
var array<ClientInterest>	AudioLevelClientInterests;

var config protected bool	Enabled;
var protected bool			Active;
var protected bool			Initialized;

enum SpeechRecognitionConfidence
{
    Confidence_Low,
    Confidence_Medium,
    Confidence_High
};

var Viewport Viewport;

function bool IsEnabled()
{
	return default.Enabled;
}

function bool IsActive()
{
	return Active;
}

native function bool IsInitialized();

final function RegisterInterest(ISpeechClient Client)
{
    local ClientInterest Interest;

    if (ClientInterests.length == 0 && IsEnabled())
        StartRecognition();  // somebody interested

	Interest.Client = Client;

    //add the interested client to our interests list
    ClientInterests[ClientInterests.length] = Interest;
}

// dbeswick: failure to do this on client destroy will cause garbage collection errors
final function UnRegisterInterest(ISpeechClient Client)
{
    local int i;

    while (i < ClientInterests.length)
    {
        while   (
                    ClientInterests[i].Client == Client
                )
        {
            ClientInterests.Remove(i,1);
        }
        ++i;
    }

    if (ClientInterests.length == 0)
        StopRecognition();  //nobody interested
}

final function RegisterAudioLevelInterest(ISpeechClient Client)
{
    local ClientInterest Interest;

	if (AudioLevelClientInterests.Length == 0)
		ActivateAudioLevelNotify();

    Interest.Client = Client;

    //add the interested client to our interests list
    AudioLevelClientInterests[ClientInterests.length] = Interest;
}

final function UnRegisterAudioLevelInterest(ISpeechClient Client)
{
    local int i;

    while (i < AudioLevelClientInterests.length)
    {
        while   (
                    AudioLevelClientInterests[i].Client == Client
                )
        {
            AudioLevelClientInterests.Remove(i,1);
        }
        ++i;
    }

    if (AudioLevelClientInterests.length == 0)
        DeactivateAudioLevelNotify();  //nobody interested
}

final function Init()
{
}

function EnableSpeech(optional bool bNoLogMessage)
{
  if(!bNoLogMessage)
	   log("EnableSpeech: "$ClientInterests.length$" interested clients.");
	default.Enabled = true;
	if (ClientInterests.length > 0)
		StartRecognition();
}

function DisableSpeech()
{
	default.Enabled = false;
	StopRecognition();
}

function ToggleSpeech()
{
  if(default.Enabled) {
    DisableSpeech();
  } else {
    EnableSpeech(true);
  }
}

event OnPhraseStart()
{
	local int i;

    log("[SPEECH] Phrase start");
    for (i=0; i<ClientInterests.length; ++i)
		ClientInterests[i].Client.OnSpeechPhraseStart();
}

event OnCommandRecognized(name Rule, Array<name> Value, SpeechRecognitionConfidence Confidence)
{
    local int i;

    log("[SPEECH] Command recognized "$Rule);
    //assertWithDescription(ClientInterests.length > 0,
    //    "[tcohen] The SpeechManager was called OnCommandRecognized(), but nobody is interested.");

    for (i=0; i<ClientInterests.length; ++i)
		ClientInterests[i].Client.OnSpeechCommandRecognized(Rule, Value, Confidence);
}

event OnFalseRecognition()
{
    local int i;
    log("[SPEECH] False recognition");

    for (i=0; i<ClientInterests.length; ++i)
		ClientInterests[i].Client.OnSpeechFalseRecognition();
}

event OnAudioLevelEvent(int Value)
{
    local int i;

    for (i=0; i<AudioLevelClientInterests.length; ++i)
		AudioLevelClientInterests[i].Client.OnSpeechAudioLevel(Value);
}

native function StartRecognition();
native function StopRecognition();

native private function ActivateAudioLevelNotify();
native private function DeactivateAudioLevelNotify();
