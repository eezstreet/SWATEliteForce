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
}

function InternalOnActivate()
{
    if( GC.SwatGameRole == eSwatGameRole.GAMEROLE_SP_Custom )
    {
        Assert( GC.GetCustomScenarioPack() != None );

        theCampaign = None;
        MyCampaignNameLabel.SetCaption(GC.GetPakFriendlyName());

        PopulateCustomScenarioList();

        MyMissionSelectionBox.List.FindExtra( GC.GetScenarioName() );
    }
    else
    {
        //Assert( GC.SwatGameRole == eSwatGameRole.GAMEROLE_SP_Campaign );	// ok seriously? seriously?

        theCampaign = SwatGUIController(Controller).GetCampaign();

        if(theCampaign.PlayerPermadeath && theCampaign.PlayerDied) {
          Controller.OpenMenu("SwatGui.SwatCampaignMenu", "SwatCampaignMenu");
          return;
        }

        MyDifficultySelector.SetIndex(GC.CurrentDifficulty);

        MyCampaignNameLabel.SetCaption(theCampaign.StringName);

        PopulateCampaignMissionList();

        if( theCampaign.GetAvailableIndex() >= MyMissionSelectionBox.Num() && !theCampaign.HasPlayedCreditsOnCampaignCompletion() )
            CompletedCampaign();

        //Select as default, the next mission to be played
        if( GC.CurrentMission != None )
            MyMissionSelectionBox.List.Find( string(GC.CurrentMission.Name) ) == "";
    }

    if( GC.CurrentMission == None )
        MyMissionSelectionBox.SetIndex(MyMissionSelectionBox.Num()-1);
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

    if( bAddingMissions )
        return;

    CustomScen = CustomScenario(MyMissionSelectionBox.List.GetObject());

    //Set current mission to be played
    GC.SetCurrentMission(Name(MyMissionSelectionBox.List.Get()), MyMissionSelectionBox.List.GetExtra(), CustomScen );

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
    }
    else
    {
        Content = GC.CurrentMission.CustomScenario.Notes;
    }

    MyMissionInfo.SetContent( Content );

    if(theCampaign.CampaignPath == 2) {
      LevelSummary = LevelSummary(MyMissionSelectionBox.List.GetObjectAtIndex(MyMissionSelectionBox.GetIndex()));
      MyThumbnail.Image = LevelSummary.Screenshot;
      MyMissionNameLabel.SetCaption(LevelSummary.Title);
      GC.CurrentMission.MapName = MyMissionSelectionBox.List.GetItemAtIndex(MyMissionSelectionBox.GetIndex());
    } else {
      MyThumbnail.Image = GC.CurrentMission.Thumbnail;
      MyMissionNameLabel.SetCaption( GC.CurrentMission.FriendlyName );
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

private function PopulateCustomScenarioList()
{
    local int i,ScenarioIterator;
    local CustomScenario CustomScen;
    local string ScenarioString;

    bAddingMissions=true;

    MyMissionSelectionBox.List.Clear();

    ScenarioIterator = -1;
    i = 0;
    do
    {
        ScenarioString = GC.GetCustomScenarioPack().NextScenario(ScenarioIterator);

        if (ScenarioIterator >= 0)
        {
            CustomScen = new() class'CustomScenario';

            GC.GetCustomScenarioPack().LoadCustomScenarioInPlace(
                CustomScen,
                ScenarioString,
                GC.GetPakName(),
                GC.GetPakExtension());

            MyMissionSelectionBox.List.Add(string(CustomScen.LevelLabel),CustomScen,ScenarioString,i,,true);
            i++;
        }
    }   until (ScenarioIterator < 0);

	MyMissionSelectionBox.List.bSortForward=true;
    MyMissionSelectionBox.List.Sort();

    bAddingMissions=false;
}

private function PopulateCampaignMissionList()
{
    local int index;

    bAddingMissions=true;

    MyMissionSelectionBox.List.Clear();
  	if(theCampaign.CampaignPath == 0) {
  		for(index = 0;index < GC.MissionName.length;index++)
  		{
  			if( index <= theCampaign.GetAvailableIndex() ) {
  				MyMissionSelectionBox.List.Add(string(GC.MissionName[index]),,GC.FriendlyName[index],index,,true);
        }
  		}
  	} else if(theCampaign.CampaignPath == 1) {
  		for(index = 0; index < ExtraMissionName.length; index++) {
  			if(index <= theCampaign.GetAvailableIndex() ) {
  				MyMissionSelectionBox.List.Add(string(ExtraMissionName[index]),,ExtraFriendlyName[index],index,,true);
  			}
  		}
  	} else if(theCampaign.CampaignPath == 2) {
      Controller.OpenWaitDialog();
      ListAllMissions();
      Controller.CloseWaitDialog();
    }


    if(theCampaign.CampaignPath == 2) {
      MyMissionSelectionBox.List.TypeOfSort = SORT_AlphaExtra;
    } else {
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
    DifficultyLabelString="Score of [b]%1[\b] required to advance."
}
