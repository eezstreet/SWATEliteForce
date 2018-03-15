// ====================================================================
//  Class:  SwatGui.SwatMissionSelectionPanel
//  Parent: SwatGUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatMissionSelectionPanel extends SwatGUIPanel;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;
import enum eSwatGameRole from SwatGame.SwatGUIConfig;

var(SWATGui) private EditInline Config GUILabel          MyCampaignNameLabel;
var(SWATGui) private EditInline Config GUIScrollTextBox  MyMissionInfoBox;
var(SWATGui) private EditInline Config GUIListBox        MyMissionSelectionBox;
var(SWATGui) private EditInline Config GUIComboBox       MyDifficultySelector;
var(SWATGui) private EditInline Config GUILabel          MyDifficultyLabel;

var(SWATGui) private EditInline Config GUILabel          MyMissionNameLabel;
var(SWATGui) private EditInline Config GUIImage          MyThumbnail;
var(SWATGui) private EditInline Config GUIScrollTextBox  MyMissionInfo;

var config array<Name> ExtraMissionName "Name used for this mission (extra missions)";
var config array<String> ExtraFriendlyName "Friendly name used for this mission (extra missions)";

var(DEBUG) private EditConst bool bAddingMissions;
var(DEBUG) private Campaign theCampaign;
var() private config localized string DifficultyLabelString;
var() private localized config string ByString;

// Only shows on All Missions campaigns
var(SWATGui) protected EditInline Config GUIRadioButton PrimaryEntranceSelection;
var(SWATGui) protected EditInline Config GUIRadioButton SecondaryEntranceSelection;
var(SWATGui) protected EditInline Config GUILabel PrimaryEntranceLabel;
var(SWATGui) protected EditInline Config GUILabel SecondaryEntranceLabel;
var(SWATGui) protected EditInline Config GUIButton RandomMapButton;

function InitComponent(GUIComponent MyOwner)
{
    local int i;

 	Super.InitComponent(MyOwner);

    for( i = 0; i < eDifficultyLevel.EnumCount; i++ )
    {
        MyDifficultySelector.AddItem(GC.DifficultyString[i]);
    }

    MyDifficultySelector.SetIndex( GC.CurrentDifficulty );

	MyMissionSelectionBox.OnChange=MyMissionSelectionBox_OnChange;
    MyDifficultySelector.OnChange=MyDifficultySelector_OnChange;
	RandomMapButton.OnClick=RandomMap_OnClick;
}

function InternalOnActivate()
{
    log("SwatMissionSelectionPanel("$self$"):InternalOnActivate(Role="$GC.SwatGameRole$")");

	theCampaign = SwatGUIController(Controller).GetCampaign();

	if(theCampaign.PlayerPermadeath && theCampaign.PlayerDied) {
		Controller.OpenMenu("SwatGui.SwatCampaignMenu", "SwatCampaignMenu");
		return;
	}

	MyDifficultySelector.SetIndex(GC.CurrentDifficulty);
	MyCampaignNameLabel.SetCaption(theCampaign.StringName);

	if(theCampaign.CampaignPath != 2 || GC.GetCustomScenarioPack() != None)
	{	// Use numeric sorting
		MyMissionSelectionBox.List.TypeOfSort = SORT_Numeric;
		MyMissionSelectionBox.List.UpdateSortFunction();
	}
	else
	{	// All Missions uses alphabetic sorting
		MyMissionSelectionBox.List.TypeOfSort = SORT_AlphaExtra;
		MyMissionSelectionBox.List.UpdateSortFunction();
	}

	// Populate either by what's hardcoded to specific paths or by what's in the custom scenario list
	if(GC.GetCustomScenarioPack() != None)
	{
		PopulateCustomScenarioList();
	}
	else
	{
		PopulateCampaignMissionList();
	}

	// Play the credits if we've completed the campaign and not already played them
	if( theCampaign.GetAvailableIndex() >= MyMissionSelectionBox.Num() && !theCampaign.HasPlayedCreditsOnCampaignCompletion() )
	{
		CompletedCampaign();
	}

	// Select either the current mission (if we're using a non-custom campaign) or the last one in the list
	if( GC.GetCustomScenarioPack() == None && GC.CurrentMission != None )
	{
		MyMissionSelectionBox.List.Find( string(GC.CurrentMission.Name) ) == "";
	}
	else
	{
	    MyMissionSelectionBox.SetIndex(MyMissionSelectionBox.Num()-1);
	}
}

function DisplayMissionResults( MissionResults Results )
{
    local int i;
    local MissionResult Result;
    local string scoreString;

// no "Mission not yet played" according to Paul
//    if( Results == None )
//    {
//        MyMissionInfoBox.SetContent( StringC );
//        return;
//    }

    MyMissionInfoBox.SetContent( "" );
    for( i = 0; i < eDifficultyLevel.EnumCount; i++ )
    {
        Result = Results.GetResult( eDifficultyLevel(i) );

        if( !Result.Played )
        {
            scoreString = "( - )";
        }
        else
        {
            scoreString = string(Result.Score);
            if( !Result.Completed )
                scoreString = "("@scoreString@")";
        }
        scoreString = ":"@scoreString;

        MyMissionInfoBox.AddText( GC.GetDifficultyString(eDifficultyLevel(i)) $ scoreString );
    }
}

function MyMissionSelectionBox_OnChange(GUIComponent Sender)
{
    local CustomScenario CustomScen;
	local CustomScenarioPack CustomPack;
	local class<Equipment> FirstEquipment, SecondEquipment;
	local int Index;

    if( bAddingMissions )
        return;

    CustomScen = CustomScenario(MyMissionSelectionBox.List.GetObject());
	CustomPack = GC.GetCustomScenarioPack();
	Index = MyMissionSelectionBox.List.GetIndex();

    //Set current mission to be played
    GC.SetCurrentMission(Name(MyMissionSelectionBox.List.Get()), MyMissionSelectionBox.List.GetExtra(), CustomScen );

	if(CustomScen != None && CustomPack != None && CustomPack.UseGearUnlocks)
	{	// We have to manually set the unlock and entry information
		if(CustomPack.FirstEquipmentUnlocks.Length > Index)
		{
			FirstEquipment = class<Equipment>(CustomPack.FirstEquipmentUnlocks[Index]);
		}

		if(CustomPack.SecondEquipmentUnlocks.Length > Index)
		{
			SecondEquipment = class<Equipment>(CustomPack.SecondEquipmentUnlocks[Index]);
		}

		if(SecondEquipment == None)
		{
			GC.CurrentMission.SecondEquipmentImage = None;
			GC.CurrentMission.SecondEquipmentName = "";
			GC.CurrentMission.SecondEquipmentDescription = "";
		}
		else
		{
			GC.CurrentMission.SecondEquipmentImage = SecondEquipment.static.GetGUIImage();
			GC.CurrentMission.SecondEquipmentName = SecondEquipment.static.GetFriendlyName();
			GC.CurrentMission.SecondEquipmentDescription = SecondEquipment.static.GetDescription();
		}

		if(FirstEquipment == None)
		{
			GC.CurrentMission.NewEquipmentImage = None;
			if(Index == 0)
			{
				GC.CurrentMission.NewEquipmentName = class'SwatNewEquipmentPanel'.default.FirstMissionHeader;
				GC.CurrentMission.NewEquipmentDescription = class'SwatNewEquipmentPanel'.default.FirstMissionText;
			}
			else
			{
				GC.CurrentMission.NewEquipmentName = "";
				GC.CurrentMission.NewEquipmentDescription = class'SwatNewEquipmentPanel'.default.NoEquipmentText;
			}
		}
		else
		{
			GC.CurrentMission.NewEquipmentImage = FirstEquipment.static.GetGUIImage();
			GC.CurrentMission.NewEquipmentName = FirstEquipment.static.GetFriendlyName();
			GC.CurrentMission.NewEquipmentDescription = FirstEquipment.static.GetDescription();
		}

		if(CustomScen.IsCustomMap)
		{
			GC.CurrentMission.LocationInfoText.Length = 0;
			GC.CurrentMission.Floorplans = None;
			GC.CurrentMission.EntryOptionTitle.Length = 0;
			GC.CurrentMission.EntryOptionTitle[0] = class'SwatEntryOptionsPanel'.default.PrimaryEntranceString;
			GC.CurrentMission.EntryOptionTitle[1] = class'SwatEntryOptionsPanel'.default.SecondaryEntranceString;
			GC.CurrentMission.EntryImage.Length = 0;
			GC.CurrentMission.EntryImage[0] = None;
			GC.CurrentMission.EntryImage[1] = None;
			GC.CurrentMission.EntryDescription.Length = 0;
			GC.CurrentMission.EntryDescription[0] = class'SwatEntryOptionsPanel'.default.PrimaryEntranceDesc;
			GC.CurrentMission.EntryDescription[1] = class'SwatEntryOptionsPanel'.default.SecondaryEntranceDesc;
		}
	}

    //always select the primary entry point by default
    if( CustomScen == None || !CustomScen.SpecifyStartPoint || !CustomScen.UseSecondaryStartPoint )
        GC.SetDesiredEntryPoint( ET_Primary );

    if( CustomScen != None &&
        CustomScen.Difficulty != "Any")
    {
        MyDifficultySelector.DisableComponent();

        if (CustomScen.Difficulty == "Easy")
            MyDifficultySelector.SetIndex(int(eDifficultyLevel.DIFFICULTY_Easy));
        else
        if (CustomScen.Difficulty == "Normal")
            MyDifficultySelector.SetIndex(int(eDifficultyLevel.DIFFICULTY_Normal));
        else
        if (CustomScen.Difficulty == "Hard")
            MyDifficultySelector.SetIndex(int(eDifficultyLevel.DIFFICULTY_Hard));
        else
        if (CustomScen.Difficulty == "Elite")
            MyDifficultySelector.SetIndex(int(eDifficultyLevel.DIFFICULTY_Elite));
        else
            assertWithDescription(false,
                "[tcohen] SwatMissionSelectionPanel::InternalOnActivate() CustomScenario.Difficulty was not recognized as Easy, Normal, or Hard.");
    }
    else
        MyDifficultySelector.EnableComponent();

    if( CustomScen != None )
        DisplayMissionResults( GC.GetMissionResults( name(GC.GetPakFriendlyName()$"_"$MyMissionSelectionBox.List.GetExtra()) ) );
    else
        DisplayMissionResults( theCampaign.GetMissionResults( name(MyMissionSelectionBox.List.Get()) ) );

    ShowMissionDescription();
}

function RandomMap_OnClick(GUIComponent Sender)
{
	// Pick a random map from the list
	local int Selection;

	Selection = Rand(MyMissionSelectionBox.List.ElementCount());
	MyMissionSelectionBox.SetIndex(Selection);

	// Advance us to the equipment page (?)
}

private function ShowMissionDescription()
{
    local int i;
    local string Content;
    local LevelSummary LevelSummary;

    if( GC.CurrentMission.CustomScenario == None )
    {
        Content = "";

        for( i = 0; i < GC.CurrentMission.MissionDescription.Length; i++ )
        {
            Content = Content $ GC.CurrentMission.MissionDescription[i] $ "|";
        }

        if(theCampaign.CampaignPath == 2)
        {
            LevelSummary = LevelSummary(MyMissionSelectionBox.List.GetObjectAtIndex(MyMissionSelectionBox.GetIndex()));
            MyThumbnail.Image = LevelSummary.Screenshot;
            MyMissionNameLabel.SetCaption(LevelSummary.Title);
            GC.CurrentMission.MapName = MyMissionSelectionBox.List.GetItemAtIndex(MyMissionSelectionBox.GetIndex());
            MyMissionInfo.SetContent(FormatTextString(ByString, LevelSummary.Author, LevelSummary.Description));
            MyDifficultyLabel.SetCaption( FormatTextString( DifficultyLabelString, GC.DifficultyScoreRequirement[int(GC.CurrentDifficulty)] ) );
        }
        else
        {
            MyThumbnail.Image = GC.CurrentMission.Thumbnail;
            MyMissionNameLabel.SetCaption( GC.CurrentMission.FriendlyName );
            MyMissionInfo.SetContent( Content );
        }
    }
    else
    {
        Content = GC.CurrentMission.CustomScenario.Notes;
        MyThumbnail.Image = GC.CurrentMission.Thumbnail;
        MyMissionNameLabel.SetCaption( GC.CurrentMission.FriendlyName );
        MyMissionInfo.SetContent( Content );
    }
}

function MyDifficultySelector_OnChange(GUIComponent Sender)
{
    GC.CurrentDifficulty=eDifficultyLevel(MyDifficultySelector.GetIndex());
    MyDifficultyLabel.SetCaption( FormatTextString( DifficultyLabelString, GC.DifficultyScoreRequirement[int(GC.CurrentDifficulty)] ) );
    GC.SaveConfig();
}

private function ListAllMissions()
{
  local String FileName;
  local LevelSummary Summary;
  local int i;
  local int index;

  foreach FileMatchingPattern("*.s4m", FileName) {
    if(InStr(FileName, "autosave") != -1) {
      continue; // Don't allow UnrealEd auto saves
    }

    if(InStr(FileName, "Autoplay") != -1) {
      continue; // Don't allow Unreal Autoplay
    }

    // Remove the extension
    if(Right(FileName, 4) ~= ".s4m") {
      FileName = Left(FileName, Len(FileName) - 4);
    }

    Summary = Controller.LoadLevelSummary(FileName$".LevelSummary");
    if(Summary == None) {
      log("WARNING: No summary for map "$FileName);
      continue;
    }

    for(i = 0; i < Summary.SupportedModes.Length; i++) {
      if(Summary.SupportedModes[i] == MPM_COOP) {
        MyMissionSelectionBox.List.Add(FileName, Summary, Summary.Title,index,,true);
        index++;
        break;
      }
    }
  }
}

event Timer()
{
  Controller.OpenWaitDialog();
  ListAllMissions();
  Controller.CloseWaitDialog();
}

event Show()
{
    theCampaign = SwatGUIController(Controller).GetCampaign();

    Super.Show();
    if(GC.SwatGameRole != eSwatGameRole.GAMEROLE_SP_Custom && theCampaign.CampaignPath == 2)
    {
        SetTimer(0.1);

        PrimaryEntranceSelection.Show();
        SecondaryEntranceSelection.Show();
        PrimaryEntranceLabel.Show();
        SecondaryEntranceLabel.Show();

        if(GC.GetDesiredEntryPoint() == ET_Primary)
        {
            SetRadioGroup(PrimaryEntranceSelection);
        }
        else
        {
            SetRadioGroup(SecondaryEntranceSelection);
        }

		RandomMapButton.Show();
    }
    else
    {
        PrimaryEntranceSelection.Hide();
        SecondaryEntranceSelection.Hide();
        PrimaryEntranceLabel.Hide();
        SecondaryEntranceLabel.Hide();
		RandomMapButton.Hide();
    }
}

function SetRadioGroup( GUIRadioButton group )
{
    Super.SetRadioGroup( group );

    if(GC.SwatGameRole != eSwatGameRole.GAMEROLE_SP_Custom && theCampaign.CampaignPath == 2)
    {
        switch (group)
        {
    		case PrimaryEntranceSelection:
    			GC.SetDesiredEntryPoint(ET_Primary);
    			break;
    		case SecondaryEntranceSelection:
    			GC.SetDesiredEntryPoint(ET_Secondary);
    			break;
    	}
    }

}


private function PopulateCustomScenarioList()
{
    local int i;
    local CustomScenario CustomScen;
    local string ScenarioString;

    bAddingMissions=true;

    MyMissionSelectionBox.List.Clear();

	for(i = 0; i < GC.GetCustomScenarioPack().ScenarioStrings.Length; i++)
	{
		if(GC.GetCustomScenarioPack().UseProgression && i > theCampaign.GetAvailableIndex())
		{	// not unlocked yet
			break;
		}

		ScenarioString = GC.GetCustomScenarioPack().ScenarioStrings[i];

		CustomScen = new() class'CustomScenario';

		GC.GetCustomScenarioPack().LoadCustomScenarioInPlace(
			CustomScen,
			ScenarioString,
			GC.GetPakName(),
			GC.GetPakExtension()
			);

		MyMissionSelectionBox.List.Add(string(CustomScen.LevelLabel), CustomScen, ScenarioString, i,, true);
	}

    /*MyMissionSelectionBox.List.TypeOfSort = SORT_Numeric;
    MyMissionSelectionBox.List.UpdateSortFunction();
	MyMissionSelectionBox.List.bSortForward=true;
    MyMissionSelectionBox.List.Sort();*/

    bAddingMissions=false;
}

private function PopulateCampaignMissionList()
{
    local int index;

    bAddingMissions=true;

    MyMissionSelectionBox.List.Clear();
  	if(theCampaign.CampaignPath == 0)
    {
		for(index = 0; index < class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length; index++)
  		{
  			if( index <= theCampaign.GetAvailableIndex() )
            {
				MyMissionSelectionBox.List.Add(string(class'SwatGame.SwatVanillaCareerPath'.default.Missions[index]),,
					class'SwatGame.SwatVanillaCareerPath'.default.MissionFriendlyNames[index],
					index,, true);
            }
  	     }
  	}
    else if(theCampaign.CampaignPath == 1)
    {
		for(index = 0; index < class'SwatGame.SwatSEFCareerPath'.default.Missions.Length; index++)
		{
			if(index <= theCampaign.GetAvailableIndex())
			{
				MyMissionSelectionBox.List.Add(string(class'SwatGame.SwatSEFCareerPath'.default.Missions[index]),,
					class'SwatGame.SwatSEFCareerPath'.default.MissionFriendlyNames[index],
					index,, true);
			}
		}
  	}


    if(theCampaign.CampaignPath == 2)
    {
    	MyMissionSelectionBox.List.TypeOfSort = SORT_AlphaExtra;
    }
    else
    {
    	MyMissionSelectionBox.List.TypeOfSort = SORT_Numeric;
    }
    MyMissionSelectionBox.List.UpdateSortFunction();
	MyMissionSelectionBox.List.bSortForward=true;
    MyMissionSelectionBox.List.Sort();

    bAddingMissions=false;
}

private function CompletedCampaign()
{
  if(theCampaign.CampaignPath != 2) {
     theCampaign.SetHasPlayedCreditsOnCampaignCompletion();
	   Controller.OpenMenu("SwatGui.SwatCreditsMenu", "SwatCreditsMenu");
  }
}

defaultproperties
{
	OnActivate=InternalOnActivate
//	StringC="This mission has not yet been attempted."
//	StringD="Mission Results: "
    DifficultyLabelString="Score of [b]%1[\\b] required to advance."
    ByString="by [b]%1[\\b]||%2"
}
