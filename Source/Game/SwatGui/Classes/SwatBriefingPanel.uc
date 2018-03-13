// ====================================================================
//  Class:  SwatGui.SwatBriefingPanel
//  Parent: SwatGUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatBriefingPanel extends SwatGUIPanel
     ;

var(SWATGui) private EditInline Config GUILabel         MissionNameLabel;

var(SWATGui) private EditInline Config GUIRadioButton   BriefingAudioToggle;
var(SWATGui) private EditInline Config GUIRadioButton   Swat911AudioToggle;
var(SWATGui) private EditInline Config GUIRadioButton   NoAudioToggle;
var(SWATGui) private EditInline Config GUIImage			BriefingAudioBackground;
var(SWATGui) private EditInline Config GUILabel			BriefingAudioTitle;
var(SWATGui) private EditInline Config GUILabel			BriefingAudioLabel;
var(SWATGui) private EditInline Config GUILabel			Swat911AudioLabel;
var(SWATGui) private EditInline Config GUILabel			NoAudioLabel;
var(SWATGui) private EditInline Config GUITabControl	TabControl;

var(SWATGui) private string LevelContextString;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

event Show()
{
    Super.Show();

    MissionNameLabel.SetCaption( GC.CurrentMission.FriendlyName );

	if(GC.CurrentMission.CustomScenario == None || !GC.CurrentMission.CustomScenario.DisableBriefingAudio)
	{
		Swat911AudioToggle.SetEnabled( GC.CurrentMission.bHas911DispatchAudio );

		if( !GC.CurrentMission.bBriefingPlayed )
	        SetRadioGroup( BriefingAudioToggle );
	    else
	        SetRadioGroup( NoAudioToggle );
	}

	BriefingAudioBackground.SetVisibility(GC.CurrentMission.CustomScenario == None || !GC.CurrentMission.CustomScenario.DisableBriefingAudio);
	BriefingAudioTitle.SetVisibility(GC.CurrentMission.CustomScenario == None || !GC.CurrentMission.CustomScenario.DisableBriefingAudio);
	BriefingAudioLabel.SetVisibility(GC.CurrentMission.CustomScenario == None || !GC.CurrentMission.CustomScenario.DisableBriefingAudio);
	Swat911AudioLabel.SetVisibility(GC.CurrentMission.CustomScenario == None || !GC.CurrentMission.CustomScenario.DisableBriefingAudio);
	NoAudioLabel.SetVisibility(GC.CurrentMission.CustomScenario == None || !GC.CurrentMission.CustomScenario.DisableBriefingAudio);

	// Disable the Enemies tab if necessary
	if(GC.CurrentMission.CustomScenario != None && GC.CurrentMission.CustomScenario.DisableEnemiesTab)
	{
		TabControl.MyTabs[3].TabHeader.DisableComponent();
	}
	else
	{
		TabControl.MyTabs[3].TabHeader.EnableComponent();
	}

	// Disable the Hostages tab if necessary
	if(GC.CurrentMission.CustomScenario != None && GC.CurrentMission.CustomScenario.DisableHostagesTab)
	{
		TabControl.MyTabs[2].TabHeader.DisableComponent();
	}
	else
	{
		TabControl.MyTabs[2].TabHeader.EnableComponent();
	}

	// Disable the Timeline tab if necessary
	if(GC.CurrentMission.CustomScenario != None && GC.CurrentMission.CustomScenario.DisableTimelineTab)
	{
		TabControl.MyTabs[1].TabHeader.DisableComponent();
	}
	else
	{
		TabControl.MyTabs[1].TabHeader.EnableComponent();
	}

	// Disable the New Equipment tab if necessary
	if(GC.CurrentMission.CustomScenario != None && !GC.GetCustomScenarioPack().UseGearUnlocks)
	{
		TabControl.MyTabs[0].TabHeader.DisableComponent();
	}
	else
	{
		TabControl.MyTabs[0].TabHeader.EnableComponent();
	}
}

event Hide()
{
    StopBriefingAudio();
    Stop911Audio();

    Super.Hide();
}

function SetRadioGroup( GUIRadioButton group )
{
    Super.SetRadioGroup( group );

	if(GC.CurrentMission.CustomScenario != None && GC.CurrentMission.CustomScenario.DisableBriefingAudio)
	{
		return;
	}

    switch (group)
    {
        case BriefingAudioToggle:
            Stop911Audio();
            StartBriefingAudio();
            break;
        case Swat911AudioToggle:
            StopBriefingAudio();
            Start911Audio();
            break;
        case NoAudioToggle:
            StopBriefingAudio();
            Stop911Audio();
            break;
    }
}

private function StartBriefingAudio()
{
    GC.CurrentMission.bBriefingPlayed = true;
    PlayerOwner().TriggerEffectEvent('UIMissionBriefing',,,,,,,,GetMissionContext());
}

private function StopBriefingAudio()
{
    PlayerOwner().UnTriggerEffectEvent('UIMissionBriefing',GetMissionContext());
}

private function Start911Audio()
{
    PlayerOwner().TriggerEffectEvent('UIMission911Call',,,,,,,,GetMissionContext());
}

private function Stop911Audio()
{
    PlayerOwner().UnTriggerEffectEvent('UIMission911Call',GetMissionContext());
}

private function Name GetMissionContext()
{
    return name(LevelContextString $ GC.CurrentMission.Name);
}

defaultproperties
{
    LevelContextString="Level_"
}
