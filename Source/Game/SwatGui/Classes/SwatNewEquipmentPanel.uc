class SwatNewEquipmentPanel extends SwatGUIPanel;

var(SWATGui) private EditInline GUIImage NewEquipmentImage;
var(SWATGui) private EditInline GUILabel NewEquipmentName;
var(SWATGui) private EditInline GUIScrollTextBox NewEquipmentDescription;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	NewEquipmentImage = GUIImage(AddComponent("GUI.GUIImage", self.Name$"_NewEquipmentImage", true));
	NewEquipmentName = GUILabel(AddComponent("GUI.GUILabel", self.Name$"_NewEquipmentName", true));
	NewEquipmentDescription = GUIScrollTextBox(AddComponent("GUI.GUIScrollTextBox", self.Name$"_NewEquipmentDescription", true));
}

function InternalOnActivate()
{
	NewEquipmentImage.Image = GC.CurrentMission.NewEquipmentImage;
	NewEquipmentName.SetCaption(GC.CurrentMission.NewEquipmentName);
	NewEquipmentDescription.SetContent(GC.CurrentMission.NewEquipmentDescription);
}

defaultproperties
{
    OnActivate=InternalOnActivate
    
    WinLeft=0.05
    WinTop=0.21333
    WinHeight=0.66666
    WinWidth=0.875
}