class CustomScenario_NotesTabPanel extends CustomScenarioTabPanel;

var(SWATGui) private EditInline Config GUIEditBox   txt_notes;
var(SWATGui) private EditInline Config GUIEditBox	txt_briefing;
var(SWATGui) private EditInline Config GUIScrollTextBox   scroll_preview;
var(SWATGui) private EditInline Config GUIComboBox note_selector;
var(SWATGui) private EditInline Config GUICheckBoxButton audio_enable;
var(SWATGui) private EditInline Config GUICheckBoxButton briefing_enable;

var(SWATGui) private EditInline Config GUICheckBoxButton enemies_enable;
var(SWATGui) private EditInline Config GUICheckBoxButton hostages_enable;
var(SWATGui) private EditInline Config GUICheckBoxButton timeline_enable;

var() private localized config string NotesStr;
var() private localized config string BriefingStr;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	note_selector.OnChange = note_selector_OnChange;
	note_selector.List.Add(NotesStr, , , , false);
	note_selector.List.Add(BriefingStr, , , , true);

    Data = CustomScenarioPage.CustomScenarioCreatorData;

    txt_notes.OnChange=txt_notes_OnChange;
	txt_briefing.OnChange=txt_briefing_OnChange;
}

function ServerPoll(CoopQMMReplicationInfo CoopQMMRI)
{
	CoopQMMRI.Notes = txt_notes.GetText();
}

function ClientPoll(CoopQMMReplicationInfo CoopQMMRI)
{
	txt_notes.SetText(CoopQMMRI.Notes);
}

function txt_notes_OnChange( GUIComponent Sender )
{
    scroll_preview.SetContent( txt_notes.GetText() );
}

function txt_briefing_OnChange( GUIComponent Sender)
{
	scroll_preview.SetContent( txt_briefing.GetText() );
}

function note_selector_OnChange( GUIComponent Sender )
{
	if(note_selector.List.GetExtraBoolData())
	{
		scroll_preview.SetContent(txt_briefing.GetText());
		txt_briefing.Show();
		txt_notes.Hide();
	}
	else
	{
		scroll_preview.SetContent(txt_notes.GetText());
		txt_briefing.Hide();
		txt_notes.Show();
	}
}

// CustomScenarioTabPanel overrides

function PopulateFieldsFromScenario(bool NewScenario)
{
    local CustomScenario Scenario;

    Scenario = CustomScenarioPage.GetCustomScenario();

	if(Scenario.IsCustomMap)
	{
		audio_enable.SetChecked(false);
		briefing_enable.SetChecked(true);
		enemies_enable.SetChecked(false);
		hostages_enable.SetChecked(false);
		timeline_enable.SetChecked(false);
		audio_enable.DisableComponent();
		briefing_enable.DisableComponent();
		enemies_enable.DisableComponent();
		hostages_enable.DisableComponent();
		timeline_enable.DisableComponent();
	}
	else
	{
		audio_enable.SetChecked(!Scenario.DisableBriefingAudio);
		briefing_enable.SetChecked(Scenario.UseCustomBriefing);
		enemies_enable.SetChecked(!Scenario.DisableEnemiesTab);
		hostages_enable.SetChecked(!Scenario.DisableHostagesTab);
		timeline_enable.SetChecked(!Scenario.DisableTimelineTab);
		audio_enable.EnableComponent();
		briefing_enable.EnableComponent();
		enemies_enable.EnableComponent();
		hostages_enable.EnableComponent();
		timeline_enable.EnableComponent();
	}

    txt_notes.SetText(Scenario.Notes);
	txt_briefing.SetText(Scenario.CustomBriefing);

}

function GatherScenarioFromFields()
{
    local CustomScenario Scenario;

    Scenario = CustomScenarioPage.GetCustomScenario();

    Scenario.Notes = txt_notes.GetText();
	Scenario.CustomBriefing = txt_briefing.GetText();
	Scenario.UseCustomBriefing = briefing_enable.bChecked;
	Scenario.DisableBriefingAudio = !audio_enable.bChecked;
	Scenario.DisableEnemiesTab = !enemies_enable.bChecked;
	Scenario.DisableHostagesTab = !hostages_enable.bChecked;
	Scenario.DisableTimelineTab = !timeline_enable.bChecked;
}

function bool AllowChat()
{
	return txt_notes.MenuState != MSAT_Focused;
}

defaultproperties
{
	NotesStr="Notes"
	BriefingStr="Briefing"
}
