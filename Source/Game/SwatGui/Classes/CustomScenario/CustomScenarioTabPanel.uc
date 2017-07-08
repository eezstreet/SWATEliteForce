class CustomScenarioTabPanel extends SwatGUIPanel;

var(SWATGui) EditInline Config CustomScenarioPage CustomScenarioPage;
var(SWATGui) EditInline Config GUIImage pnl_InvalidOverlay;

var CustomScenarioCreatorData Data;

//take the data from GC.GetCustomScenario() and _completely_
//  populate all fields that represent data from the Scenario,
//  including resetting components to their default values if
//  the Scenario doesn't specify their data
function PopulateFieldsFromScenario(bool NewScenario);
//NewScenario can be used to distinguish whether the TabPanel
//  should prepare to populate from user-defined values,
//  or if it should populate from defaults for a new scenario.
//For example, the Hostages and Enemies tab panels will
//  initialize the Archetypes dlist: if NewScenario, then
//  any ByDefault Archetypes will go into the Selected list;
//  but if !NewScenario, then all Archetypes will go into the
//  Available list (in preparation for populating from user
//  specifications).

//take the data from all fields that represent data in the Scenario,
//  and set the related data in GC.GetCustomScenario()
function GatherScenarioFromFields();

function bool AllowChat()
{
	return true;
}