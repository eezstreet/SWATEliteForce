// ====================================================================
//  Class:  SwatGui.SwatCampaignMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatCampaignMenu extends SwatGUIPage
     ;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;

var CustomScenarioCreatorData CustomScenarioCreatorData;

var(SWATGui) private EditInline Config GUIButton		    MyMainMenuButton;
var(SWATGui) private EditInline Config GUIButton		    MyQuitButton;
//greyed out buttons
var(SWATGui) private EditInline Config GUIButton		    CampaignTabButton;
var(SWATGui) private EditInline Config GUIButton		    MissionTabButton;
var(SWATGui) private EditInline Config GUIButton		    BriefingTabButton;
var(SWATGui) private EditInline Config GUIButton		    LoadoutTabButton;
var(SWATGui) private EditInline Config GUIButton		    StartButton;

//new campaign panel
var(SWATGui) private EditInline Config GUIEditbox		    MyNameEntry;
var(SWATGui) private EditInline Config GUIButton		    MyCreateCampaignButton;
var(SWATGui) private EditInline Config GUIComboBox			MyCampaignPathBox;
var(SWATGui) private EditInline Config GUIComboBox			MyCampaignCustomBox;
var(SWATGui) private EditInline Config GUICheckBoxButton	MyCampaignPlayerPermadeathButton;
var(SWATGui) private EditInline Config GUICheckBoxButton	MyCampaignOfficerPermadeathButton;
var(SWATGui) private EditInline Config GUIScrollTextBox		MyCampaignPathBlurbLabel;

//load campaign panel
var(SWATGui) private EditInline Config GUIComboBox          MyCampaignSelectionBox;
var(SWATGui) private EditInline Config GUIButton		    MyDeleteCampaignButton;
var(SWATGui) private EditInline Config GUIButton		    MyUseCampaignButton;
var(SWATGui) private EditInline Config GUIButton			MyCoopCampaignButton;

// Campaign Stats
var(SWATGui) private EditInline Config GUILabel         Stat_MissionsCompletedLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_TimesIncapacitatedLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_TimesInjuredLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_OfficersIncapacitatedLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_PenaltiesIssuedLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_SuspectsRemovedLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_SuspectsNeutralizedLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_SuspectsIncapacitatedLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_SuspectsArrestedLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_CiviliansRestrainedLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_TOCReportsLabel;
var(SWATGui) private EditInline Config GUILabel         Stat_EvidenceSecuredLabel;

// Stat Strings
var() private config localized string StatStringA;
var() private config localized string StatStringB;
var() private config localized string StatStringC;
var() private config localized string StatStringD;
var() private config localized string StatStringE;
var() private config localized string StatStringF;
var() private config localized string StatStringG;
var() private config localized string StatStringH;
var() private config localized string StatStringI;
var() private config localized string StatStringJ;
var() private config localized string StatStringK;
var() private config localized string StatStringL;

// Other Strings
var() private config localized string StringA;
var() private config localized string StringB;
var() private config localized string StringC;
var() private config localized string StringE;
var() private config localized string StringJ;
var() private config localized string StringK;
var() private config localized string StringL;
var() private config localized string StringM;
var() private config localized string StringN;
var() private config localized string StringO;

// Campaign custom/whatever strings
var() private config localized string MajorPathA;
var() private config localized string MajorPathB;

var() private config localized string DeadCampaignNotification;
var() private config localized string PlayerPermadeathNotification;
var() private config localized string KIAString;
var() private config localized string NoPermadeathAllowed;
var() private config localized string NoAllMissionsAllowed;

var() private config localized string CampaignPathBlurb[3];
var() private config localized string CustomPathBlurb;

var Campaign currentCampaign;

function InitComponent(GUIComponent MyOwner)
{
    local int index;
    local array<Campaign> TheCampaigns;

 	Super.InitComponent(MyOwner);

	CustomScenarioCreatorData = new class'CustomScenarioCreatorData';
	assert(CustomScenarioCreatorData != None);
    CustomScenarioCreatorData.Init(SwatGUIController(Controller).GuiConfig);

	// Campaign selection box
    TheCampaigns = SwatGUIController(Controller).GetCampaigns().GetCampaigns();
    MyCampaignSelectionBox.Clear();
	for(index = 0;index < TheCampaigns.length;index++)
	{
      if(TheCampaigns[index].PlayerPermadeath && TheCampaigns[index].PlayerDied) {
        MyCampaignSelectionBox.List.Add(TheCampaigns[index].StringName$KIAString,TheCampaigns[index]);
      } else {
        MyCampaignSelectionBox.List.Add(TheCampaigns[index].StringName,TheCampaigns[index]);
      }

	}
    MyCampaignSelectionBox.List.Sort();

    MyCampaignSelectionBox.OnChange=InternalOnChange;
	MyCampaignPathBox.OnChange=InternalOnChange;
	MyCampaignCustomBox.OnChange=InternalOnChange;

	// Campaign custom/not custom
	MyCampaignCustomBox.List.Add(MajorPathB, , , , true);
	MyCampaignCustomBox.List.Add(MajorPathA, , , , false);

    MyNameEntry.OnEntryCompleted=InternalOnClick;
    MyNameEntry.OnChange=InternalOnChange;
    MyNameEntry.OnEntryCancelled=InternalEntryCancelled;

    MyCreateCampaignButton.OnClick=InternalOnClick;
    MyUseCampaignButton.OnClick=InternalOnClick;
    MyDeleteCampaignButton.OnClick=InternalOnClick;
    MyCoopCampaignButton.OnClick=InternalOnClick;

    CampaignTabButton.bNeverFocus=false;
}

////////////////////////////////////////////////////////////////////////////////////
// Component Management
////////////////////////////////////////////////////////////////////////////////////
private function InternalOnActivate()
{
    MyQuitButton.OnClick=InternalOnClick;
    MyMainMenuButton.OnClick=InternalOnClick;

    CampaignTabButton.Focus();
    MissionTabButton.DisableComponent();
    BriefingTabButton.DisableComponent();
    LoadoutTabButton.DisableComponent();
    StartButton.DisableComponent();

	if (SwatGUIController(Controller).coopcampaign) {LoadoutTabButton.Hide();}
	else{LoadoutTabButton.Show();}

	MyCampaignPathBox.SetIndex(2);	// Use SWAT 4 missions as the default (it's sorted as the third option)

	if( MyCampaignSelectionBox.Find(SwatGUIController(Controller).GetCampaigns().CurCampaignName) == "" )
    	MyCampaignSelectionBox.SetIndex(0);

    //can only load if one already exists
    MyCampaignSelectionBox.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
    MyUseCampaignButton.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
    MyDeleteCampaignButton.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );

    MyCreateCampaignButton.SetEnabled( IsCampaignNameValid( MyNameEntry.GetText() ) );
}

private function InternalOnFocused(GUIComponent Sender)
{
    MyNameEntry.SetText(StringK);
    MyNameEntry.Focus();
}

private function StockCareersSelected()
{
	// Campaign path selection box
	MyCampaignPathBox.Clear();
    MyCampaignPathBox.List.Add(StringM, , , 0);	// Original Missions
	MyCampaignPathBox.List.Add(StringN, , , 1);	// Extra Missions
    MyCampaignPathBox.List.Add(StringO, , , 2); // All missions
}

private function CustomCareersSelected()
{
	local string PackFileName;

	MyCampaignPathBox.Clear();

	foreach FileMatchingPattern(
            "*."$CustomScenarioCreatorData.PackExtension,
            PackFilename)
    {
		MyCampaignPathBox.List.Add(PackMinusExtension(PackFileName));
    };
}

private function InternalOnChange(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyCampaignSelectionBox:
            //set current campaign to save to
            SetCampaign( Campaign(MyCampaignSelectionBox.GetObject()) );
            break;
		case MyNameEntry:
            MyCreateCampaignButton.SetEnabled( IsCampaignNameValid( MyNameEntry.GetText() ) );
            break;
		case MyCampaignPathBox:
			if(!MyCampaignCustomBox.List.GetExtraBoolData())
			{
				MyCampaignPathBlurbLabel.SetContent(CampaignPathBlurb[MyCampaignPathBox.GetInt()]);
			}
			break;
		case MyCampaignCustomBox:
			if(MyCampaignCustomBox.List.GetExtraBoolData())
			{	// Extra Bool true = we are using custom campaigns
				CustomCareersSelected();
				MyCampaignPathBlurbLabel.SetContent(CustomPathBlurb);
			}
			else
			{
				StockCareersSelected();
			}
			break;
	}
}

private function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
	    case MyQuitButton:
            Quit();
            break;
		case MyNameEntry:
		case MyCreateCampaignButton:
		    AttemptCreateCampaign( MyNameEntry.GetText(), MyCampaignPathBox.GetInt() );
			break;
		case MyUseCampaignButton:
		    //unset the pak for campaigns
	        if(currentCampaign.PlayerPermadeath && currentCampaign.PlayerDied) {
	          OnDlgReturned=InternalOnDlgReturned;
	          OpenDlg( DeadCampaignNotification, QBTN_OK, "DeadCampaignNotification" );
	        } else {
	          SwatGuiController(Controller).CoopCampaign = false;
			  GoToMissionSetup(currentCampaign);
	        }
			break;
    	case MyCoopCampaignButton:
		    if(currentCampaign.PlayerPermadeath || currentCampaign.OfficerPermadeath) {
		        OnDlgReturned=InternalOnDlgReturned;
		        OpenDlg(NoPermadeathAllowed, QBTN_OK, "NoPermadeathAllowed");
		    } else if(currentCampaign.CampaignPath == 2) {
		        OnDlgReturned=InternalOnDlgReturned;
		        OpenDlg(NoAllMissionsAllowed, QBTN_OK, "NoAllMissionsAllowed");
		    } else {
		        SwatGuiController(Controller).CoopCampaign = true;
				GoToMissionSetup(currentCampaign);
		    }
		    break;
		case MyMainMenuButton:
            PerformClose();
			break;
        case MyDeleteCampaignButton:
            OnDlgReturned=InternalOnDlgReturned;
            OpenDlg( StringJ$MyCampaignSelectionBox.Get(), QBTN_YesNo, "DeleteCampaign" );
            break;
	}
}

private function InternalEntryCancelled(GUIComponent Sender)
{
    PerformClose();
}

private function InternalOnDlgReturned( int Selection, String passback )
{
    local string campName;
	  local int campPath;
    local Campaign camp;


    switch (passback)
    {
        case "DeleteCampaign":
            if( Selection == QBTN_Yes )
            {
                camp = Campaign(MyCampaignSelectionBox.GetObject());
                campName = camp.StringName;
                DeleteCampaign(campName);

                MyCampaignSelectionBox.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
                MyUseCampaignButton.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
                MyDeleteCampaignButton.SetEnabled( MyCampaignSelectionBox.List.ItemCount != 0 );
            }
            break;
        case "PermadeathNotice":
            if(Selection == QBTN_Yes) {
              campName = MyNameEntry.GetText();
              campPath = MyCampaignPathBox.GetInt();
              CreateCampaign(campName, campPath, MyCampaignPlayerPermadeathButton.bChecked, MyCampaignOfficerPermadeathButton.bChecked);
            }
            break;
        case "OverwriteCampaign":
            if( Selection == QBTN_Yes )
            {
                DeleteCampaign(campName);
                if(MyCampaignPlayerPermadeathButton.bChecked)
                {
                  OnDlgReturned=InternalonDlgReturned;
                  OpenDlg(PlayerPermadeathNotification, QBTN_YesNo, "PermadeathNotice");
                }
            }
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Campaign Management
////////////////////////////////////////////////////////////////////////////////////
private function SetCampaign( Campaign theCampaign )
{
    if( theCampaign == None )
        return;

    if(!IsCampaignNameValid(theCampaign.StringName))
        return;

    currentCampaign = theCampaign;
    SwatGuiController(Controller).UseCampaign( theCampaign.StringName );

    Stat_MissionsCompletedLabel.SetCaption(StatStringA $ theCampaign.MissionsCompleted);
    Stat_TimesIncapacitatedLabel.SetCaption(StatStringB $ theCampaign.TimesIncapacitated);
    Stat_TimesInjuredLabel.SetCaption(StatStringC $ theCampaign.TimesInjured);
    Stat_OfficersIncapacitatedLabel.SetCaption(StatStringD $ theCampaign.OfficersIncapacitated);
    Stat_PenaltiesIssuedLabel.SetCaption(StatStringE $ theCampaign.PenaltiesIssued);
    Stat_SuspectsRemovedLabel.SetCaption(StatStringF $ theCampaign.SuspectsRemoved);
    Stat_SuspectsNeutralizedLabel.SetCaption(StatStringG $ theCampaign.SuspectsNeutralized);
    Stat_SuspectsIncapacitatedLabel.SetCaption(StatStringH $ theCampaign.SuspectsIncapacitated);
    Stat_SuspectsArrestedLabel.SetCaption(StatStringI $ theCampaign.SuspectsArrested);
    Stat_CiviliansRestrainedLabel.SetCaption(StatStringJ $ theCampaign.CiviliansRestrained);
    Stat_TOCReportsLabel.SetCaption(StatStringK $ theCampaign.TOCReports);
    Stat_EvidenceSecuredLabel.SetCaption(StatStringL $ theCampaign.EvidenceSecured);
}

private function AttemptCreateCampaign( string campName, int campPath )
{
    if( !IsCampaignNameValid( campName ) )
    {
        OnDlgReturned=InternalOnDlgReturned;
        OpenDlg( campName$StringA, QBTN_OK, "InvalidName" );
    }
    else if( SwatGuiController(Controller).CampaignExists(campName) )
    {
        OnDlgReturned=InternalOnDlgReturned;
        OpenDlg( StringC$campName$StringE, QBTN_YesNo, "OverwriteCampaign" );
    }
    else if(MyCampaignPlayerPermadeathButton.bChecked)
    {
      OnDlgReturned=InternalonDlgReturned;
      OpenDlg(PlayerPermadeathNotification, QBTN_YesNo, "PermadeathNotice");
    }
    else {
        CreateCampaign( campName, campPath, MyCampaignPlayerPermadeathButton.bChecked, MyCampaignOfficerPermadeathButton.bChecked );
    }
}

private function GoToMissionSetup(Campaign TheCampaign)
{
	local CustomScenarioPack CustomPack;

	if(TheCampaign.CustomCareerPath)
	{
		CustomPack = new class'CustomScenarioPack';
		CustomPack.Reset(PackPlusExtension(TheCampaign.CustomCareer), CustomScenarioCreatorData.ScenariosPath);
		GC.SetCustomScenarioPackData(CustomPack, PackPlusExtension(TheCampaign.CustomCareer),
			PackMinusExtension(TheCampaign.CustomCareer), CustomScenarioCreatorData.ScenariosPath);
		SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_SP_Custom );
	}
	else
	{
		GC.SetCustomScenarioPackData( None );
		SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_SP_Campaign );
	}
	Controller.OpenMenu("SwatGui.SwatMissionSetupMenu","SwatMissionSetupMenu");
}

private function CreateCampaign( string campName, int campPath, bool bPlayerPermadeath, bool bOfficerPermadeath )
{
    local Campaign NewCampaign;

    //create the new campaign
	if(MyCampaignCustomBox.List.GetExtraBoolData())
	{
		NewCampaign=SwatGuiController(Controller).AddCampaign(campName, campPath, bPlayerPermadeath, bOfficerPermadeath, true, MyCampaignPathBox.List.Get());
	}
	else
	{
		NewCampaign=SwatGuiController(Controller).AddCampaign(campName, campPath, bPlayerPermadeath, bOfficerPermadeath);
	}

    AssertWithDescription( NewCampaign != None, "Could not create campaign with name: " $ campName );

    //... and add it to the campaign selection box
    MyCampaignSelectionBox.AddItem(NewCampaign.StringName, NewCampaign);
    //select the new one as current
    SetCampaign( NewCampaign );

    //clear the campaign name entry box
    MyNameEntry.SetText("");

    GoToMissionSetup(NewCampaign);
}

private function DeleteCampaign( string campName )
{
    SwatGuiController(Controller).DeleteCampaign(campName);
    MyCampaignSelectionBox.List.RemoveItem(campName);
}

private function bool IsCampaignNameValid( string Campaign )
{
    local int i;

    // 0 - length names are invalid
    if( Campaign == "" )
        return false;

    for( i = Len(Campaign) - 1; i >= 0; i-- )
    {
        // any non-space characters make the name valid
        if( Mid( Campaign, i, 1 ) != " " )
            return true;
    }

    return false;
}

//returns a PackName with an extension
function string PackPlusExtension(string PackName)
{
    local string extension;

    extension = "." $ CustomScenarioCreatorData.PackExtension;

    if (Right(PackName, Len(extension)) == extension)
        return PackName;    //PackName already has extension
    else
        return PackName $ extension;
}

//returns a PackName without an extension
function string PackMinusExtension(string PackName)
{
    local string extension;

    extension = "." $ CustomScenarioCreatorData.PackExtension;

    if (Right(PackName, Len(extension)) != extension)
        return PackName;    //PackName already doesn't have an extension
    else
        return Left(PackName, Len(PackName) - Len(extension));
}

defaultproperties
{
    OnFocused=InternalOnFocused
	OnActivate=InternalOnActivate

	StatStringA="Missions Completed: "
	StatStringB="Times Incapacitated: "
	StatStringC="Times Injured: "
	StatStringD="Officers Down: "
	StatStringE="Penalties Issued: "
	StatStringF="Threats Removed: "
	StatStringG="Suspects Neutralized: "
	StatStringH="Suspects Incapacitated: "
	StatStringI="Suspects Arrested: "
	StatStringJ="Civilians Restrained: "
	StatStringK="Reports to TOC: "
	StatStringL="Evidence Secured: "

	StringA=" is not a valid campaign name."
	StringB="Campaign: "
	StringC="A campaign with the name "
	StringE=" already exists.  Do you wish to overwrite it?"
	StringJ="Are you sure that you want to delete campaign "
	StringK="Officer Default"
	StringL="Mission Set:"
	StringM="SWAT 4 + Expansion"
	StringN="Extra Missions"
	StringO="All Missions"

	MajorPathA="Stock Campaigns"
	MajorPathB="Quick Mission Maker"
	CustomPathBlurb="[c=FFFFFF]A campaign created in the Quick Mission Maker."

	DeadCampaignNotification="This campaign was killed in action (KIA). You will still be able to view its stats, but you cannot play with it."
	PlayerPermadeathNotification="You are about to start a campaign with Player Permadeath enabled. Once you die, you cannot play with this campaign again. Are you sure you want to do this?"
	KIAString=" (KIA)"
	NoPermadeathAllowed="You cannot play this campaign in Career CO-OP because it has a permadeath setting enabled. Try again with a different campaign."
	NoAllMissionsAllowed="You cannot play an All Missions campaign in Career CO-OP. Try again with a different campaign."

	CampaignPathBlurb[0]="[c=FFFFFF]A combined campaign of the original SWAT 4 and The Stetchkov Syndicate missions. [b]Some equipment may need to be unlocked.[\\b]"
	CampaignPathBlurb[1]="[c=FFFFFF]A campaign containing Extra Missions added by SWAT: Elite Force."
	CampaignPathBlurb[2]="[c=FFFFFF]A campaign containing all missions on your hard drive, including customs. [b]All missions and equipment are unlocked at the start.[\\b] Some additional equipment is available."
}
