// ====================================================================
//  Class:  SwatGui.SwatNPCPanel
//  Parent: SwatGUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatNPCPanel extends SwatGUIPanel
     ;

var(SWATGui) private EditInline array<GUIImage> MyNPCImage;
var(SWATGui) private EditInline array<GUILabel> MyNPCName;
var(SWATGui) private EditInline array<GUIScrollTextBox> MyNPCVitals;
var(SWATGui) private EditInline array<GUIScrollTextBox> MyNPCDescription;
var(SWATGui) private EditInline Config GUIImage     		MyInvalidImage;

var(SWATGui) private EditInline Config bool bIsHostagePanel;

function InitComponent(GUIComponent MyOwner)
{
    local int i;

	Super.InitComponent(MyOwner);

    for( i = 0; i < 3; i++ )
    {
        MyNPCName[i] = GUILabel(AddComponent("GUI.GUILabel", self.Name$"_NPCName_"$i, true ));
        MyNPCImage[i] = GUIImage(AddComponent("GUI.GUIImage", self.Name$"_NPCImage_"$i, true ));
        MyNPCVitals[i] = GUIScrollTextBox(AddComponent("GUI.GUIScrollTextBox", self.Name$"_NPCVitals_"$i, true ));
        MyNPCDescription[i] = GUIScrollTextBox(AddComponent("GUI.GUIScrollTextBox", self.Name$"_NPCDescription_"$i, true ));
    }
}

function InternalOnActivate()
{
    if( bIsHostagePanel )
    {
        AssertWithDescription( GC.CurrentMission.HostageName.Length == GC.CurrentMission.HostageImage.Length &&
                               GC.CurrentMission.HostageName.Length == GC.CurrentMission.HostageDescription.Length, "The number of HostageNames, HostageDescriptions, and HostageImages must be the same for mission \""$GC.CurrentMission.FriendlyName$"\" in SwatMissions.ini" );
        ShowNPCs( GC.CurrentMission.HostageName, GC.CurrentMission.HostageImage, GC.CurrentMission.HostageVitals, GC.CurrentMission.HostageDescription );
    }
    else
    {
        AssertWithDescription( GC.CurrentMission.SuspectName.Length == GC.CurrentMission.SuspectImage.Length &&
                               GC.CurrentMission.SuspectName.Length == GC.CurrentMission.SuspectDescription.Length, "The number of SuspectNames, SuspectDescriptions, and SuspectImages must be the same for mission \""$GC.CurrentMission.FriendlyName$"\" in SwatMissions.ini" );
        ShowNPCs( GC.CurrentMission.SuspectName, GC.CurrentMission.SuspectImage, GC.CurrentMission.SuspectVitals, GC.CurrentMission.SuspectDescription );
    }

	if(bIsHostagePanel)
	{
		MyInvalidImage.SetVisibility( GC.CurrentMission.CustomScenario != None && !GC.CurrentMission.CustomScenario.UseCampaignHostageSettings );
	}
	else
	{
		MyInvalidImage.SetVisibility( GC.CurrentMission.CustomScenario != None && !GC.CurrentMission.CustomScenario.UseCampaignEnemySettings );
	}
}

event Free( optional bool bForce )
{
    local int i;

    Super.Free( bForce );

    for( i = 0; i < MyNPCName.Length; i++ )
    {
        RemoveComponent(MyNPCName[i]);
        RemoveComponent(MyNPCImage[i]);
        RemoveComponent(MyNPCVitals[i]);
        RemoveComponent(MyNPCDescription[i]);
    }

    MyNPCName.Remove( 0, MyNPCName.Length );
    MyNPCImage.Remove( 0, MyNPCImage.Length );
    MyNPCVitals.Remove( 0, MyNPCVitals.Length );
    MyNPCDescription.Remove( 0, MyNPCDescription.Length );
}

private function ShowNPCs( array<string> Names, array<Material> Images, array<string> Vitals, array<string> Descriptions )
{
    local int i;

    for( i = 0; i < 3; i++ )
    {
        Assert( MyNPCName[i] != None );
        Assert( MyNPCImage[i] != None );
        Assert( MyNPCVitals[i] != None );
        Assert( MyNPCDescription[i] != None );

        if( i < Names.Length )
        {
            MyNPCName[i].SetCaption(Names[i]);
            MyNPCImage[i].Image = Images[i];
            MyNPCVitals[i].SetContent( Vitals[i] );
            MyNPCDescription[i].SetContent( Descriptions[i] );
        }
        else
        {
            MyNPCName[i].Hide();
            MyNPCImage[i].Hide();
            MyNPCVitals[i].Hide();
            MyNPCDescription[i].Hide();
        }
    }
}

defaultproperties
{
    OnActivate=InternalOnActivate

    WinLeft=0.05
    WinTop=0.21333
    WinHeight=0.66666
    WinWidth=0.875
}
