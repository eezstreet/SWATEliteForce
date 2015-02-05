// ====================================================================
//  Class:  SwatGui.SwatEntryOptionsPanel
//  Parent: GUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatEntryOptionsPanel extends SwatGUIPanel
     ;

import enum EEntryType from SwatStartPointBase;

var(SWATGui) private EditInline Config GUIScrollTextBox MyLocationInfoText;
var(SWATGui) private EditInline Config GUIImage MyLocationImage;

var(SWATGui) private EditInline  array<GUIImage> MyEntryImages;
var(SWATGui) private EditInline  array<GUILabel> MyEntrySelectors;
var(SWATGui) private EditInline  array<GUIScrollTextBox> MyEntryDescriptors;
var(SWATGui) private EditInline  array<GUIRadioButton> MyEntryChecks;

function OnConstruct(GUIController MyController)
{
    local int i;

    Super.OnConstruct(MyController);

    for( i = 0; i < 2; i++ )
    {
        MyEntryImages[i] = GUIImage(AddComponent("GUI.GUIImage", self.Name$"_EntryImage_"$i ));
        MyEntrySelectors[i] = GUILabel(AddComponent("GUI.GUILabel", self.Name$"_EntryLabel_"$i ));
        MyEntryDescriptors[i] = GUIScrollTextBox(AddComponent("GUI.GUIScrollTextBox", self.Name$"_EntryDescription_"$i ));
        MyEntryChecks[i] = GUIRadioButton(AddComponent("GUI.GUIRadioButton", self.Name$"_EntryCheck_"$i ));
    }
}

function InitComponent(GUIComponent MyOwner)
{
    local int i;

	Super.InitComponent(MyOwner);

    for( i = 0; i < 2; i++ )
    {
        MyEntryImages[i].RadioGroup = MyEntryChecks[i];
        MyEntrySelectors[i].RadioGroup = MyEntryChecks[i];
        MyEntryDescriptors[i].RadioGroup = MyEntryChecks[i];
    }
}

function InternalOnShow()
{
    local int i;
    local string Content;

    Content = "";
    for( i = 0; i < GC.CurrentMission.LocationInfoText.Length; i++ )
    {
        Content = Content $ GC.CurrentMission.LocationInfoText[i] $ "|";
    }
    MyLocationInfoText.SetContent( Content );

    MyLocationImage.Image = GC.CurrentMission.Floorplans;
    
    AssertWithDescription( GC.CurrentMission.EntryOptionTitle.Length > 0, "There must be at least one entry option specified for mission \""$GC.CurrentMission.FriendlyName$"\" in SwatMissions.ini" );
    AssertWithDescription( GC.CurrentMission.EntryOptionTitle.Length <= 2, "There cannot be more than two entry options specified for mission \""$GC.CurrentMission.FriendlyName$"\" in SwatMissions.ini" );
    AssertWithDescription( GC.CurrentMission.EntryOptionTitle.Length == GC.CurrentMission.EntryImage.Length && 
                           GC.CurrentMission.EntryOptionTitle.Length == GC.CurrentMission.EntryDescription.Length, "The number of EntryOptionTitles, EntryDescriptions, and EntryImages must be the same for mission \""$GC.CurrentMission.FriendlyName$"\" in SwatMissions.ini" );

    for( i = 0; i < GC.CurrentMission.EntryOptionTitle.Length; i++ )
    {
        MyEntryImages[i].Image = GC.CurrentMission.EntryImage[i];
        MyEntrySelectors[i].SetCaption( GC.CurrentMission.EntryOptionTitle[i] );
        MyEntryDescriptors[i].SetContent( GC.CurrentMission.EntryDescription[i]);
    }
}

function InternalOnActivate()
{
    Assert( MyEntryChecks[0] != None );
    Assert( MyEntryChecks[1] != None );

    MyEntryChecks[0].EnableComponent();
    MyEntryChecks[1].EnableComponent();

    if  (
            GC.CurrentMission.CustomScenario != None
        &&  GC.CurrentMission.CustomScenario.SpecifyStartPoint
        )
    {
        MyEntryChecks[0].SetEnabled(!GC.CurrentMission.CustomScenario.UseSecondaryStartPoint);
        MyEntryChecks[1].SetEnabled(GC.CurrentMission.CustomScenario.UseSecondaryStartPoint);

        if (GC.CurrentMission.CustomScenario.UseSecondaryStartPoint)
            MyEntryChecks[1].SelectRadioButton();
        else
            MyEntryChecks[0].SelectRadioButton();

    }
    else if( GC.GetDesiredEntryPoint() == EEntryType.ET_Secondary && GC.CurrentMission.EntryOptionTitle.Length >= 2 )
        MyEntryChecks[1].SelectRadioButton();
    else
        MyEntryChecks[0].SelectRadioButton();
    
    //hide the second entry option if it is not valid
    if( GC.CurrentMission.EntryOptionTitle.Length < 2 )
    {
        MyEntryImages[1].Hide();
        MyEntrySelectors[1].Hide();
        MyEntryDescriptors[1].Hide();
        MyEntryChecks[1].Hide();
        MyEntryChecks[1].DeActivate();
        MyEntryChecks[1].DisableComponent();
    }    
}

event Free( optional bool bForce )
{
    local int i;
    
    Super.Free( bForce );
    
    for( i = 0; i < MyEntryImages.Length; i++ )
    {
        RemoveComponent(MyEntryImages[i]);
        RemoveComponent(MyEntrySelectors[i]);
        RemoveComponent(MyEntryDescriptors[i]);
        RemoveComponent(MyEntryChecks[i]);
    }
       
    MyEntryImages.Remove( 0, MyEntryImages.Length );
    MyEntrySelectors.Remove( 0, MyEntrySelectors.Length );
    MyEntryDescriptors.Remove( 0, MyEntryDescriptors.Length );
    MyEntryChecks.Remove( 0, MyEntryChecks.Length );
}

function SetRadioGroup( GUIRadioButton group )
{
    if( MyEntryChecks[0] != group && MyEntryChecks[1] != group)
        return;
        
    if( GC.CurrentMission.EntryOptionTitle.Length < 2 )
    {
        group = MyEntryChecks[0];
    }
    
    Super.SetRadioGroup( group );

    if( MyEntryChecks[1] == group )
        GC.SetDesiredEntryPoint( EEntryType.ET_Secondary );
    else
        GC.SetDesiredEntryPoint( EEntryType.ET_Primary );
}

defaultproperties
{
    OnShow=InternalOnShow
    OnActivate=InternalOnActivate
    
    WinLeft=0.05
    WinTop=0.21333
    WinHeight=0.66666
    WinWidth=0.875
}
