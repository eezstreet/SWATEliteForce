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

var(SWATGui) private string LevelContextString;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

event Show()
{
    Super.Show();

    MissionNameLabel.SetCaption( GC.CurrentMission.FriendlyName );

    Swat911AudioToggle.SetEnabled( GC.CurrentMission.bHas911DispatchAudio );

    if( !GC.CurrentMission.bBriefingPlayed )
        SetRadioGroup( BriefingAudioToggle );
    else
        SetRadioGroup( NoAudioToggle );
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