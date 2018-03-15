class SwatNewEquipmentPanel extends SwatGUIPanel;

var(SWATGui) private EditInline GUIImage NewEquipmentImage;
var(SWATGui) private EditInline GUILabel NewEquipmentName;
var(SWATGui) private EditInline GUIScrollTextBox NewEquipmentDescription;
var(SWATGui) private EditInline GUIImage SecondEquipmentImage;
var(SWATGui) private EditInline GUILabel SecondEquipmentName;
var(SWATGui) private EditInline GUIScrollTextBox SecondEquipmentDescription;

var() localized config string FirstMissionHeader;
var() localized config string FirstMissionText;
var() localized config string NoEquipmentText;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	NewEquipmentImage = GUIImage(AddComponent("GUI.GUIImage", self.Name$"_NewEquipmentImage", true));
	NewEquipmentName = GUILabel(AddComponent("GUI.GUILabel", self.Name$"_NewEquipmentName", true));
	NewEquipmentDescription = GUIScrollTextBox(AddComponent("GUI.GUIScrollTextBox", self.Name$"_NewEquipmentDescription", true));

	SecondEquipmentImage = GUIImage(AddComponent("GUI.GUIImage", self.Name$"_SecondEquipmentImage", true));
	SecondEquipmentName = GUILabel(AddComponent("GUI.GUILabel", self.Name$"_SecondEquipmentName", true));
	SecondEquipmentDescription = GUIScrollTextBox(AddComponent("GUI.GUIScrollTextBox", self.Name$"_SecondEquipmentDescription", true));
}

function InternalOnActivate()
{
	NewEquipmentImage.Image = GC.CurrentMission.NewEquipmentImage;
	NewEquipmentName.SetCaption(GC.CurrentMission.NewEquipmentName);
	NewEquipmentDescription.SetContent(GC.CurrentMission.NewEquipmentDescription);

	SecondEquipmentImage.Image = GC.CurrentMission.SecondEquipmentImage;
	SecondEquipmentName.SetCaption(GC.CurrentMission.SecondEquipmentName);
	SecondEquipmentDescription.SetContent(GC.CurrentMission.SecondEquipmentDescription);
}

defaultproperties
{
    OnActivate=InternalOnActivate

	FirstMissionHeader="INFORMATION"
	FirstMissionText="As you progress through the campaign, you will unlock new pieces of equipment, including weapons, less lethal equipment, and protective gear. This tab will show you the equipment that you have unlocked on each mission. If you wish to replay an earlier mission for a higher score, your new equipment may come in handy."
	NoEquipmentText="No new equipment is available on this mission."

    WinLeft=0.05
    WinTop=0.21333
    WinHeight=0.66666
    WinWidth=0.875
}
