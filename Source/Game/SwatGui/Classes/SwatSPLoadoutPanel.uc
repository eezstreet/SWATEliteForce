// ====================================================================
//  Class:  SwatGui.SwatSPLoadoutPanel
//  Parent: SwatGUIPanel
//
//  Menu to load gear for each officer.
// ====================================================================

class SwatSPLoadoutPanel extends SwatLoadoutPanel
     ;

import enum ELightType from Engine.Actor;

var enum LoadOutOwner
{
    LoadOutOwner_Player,
    LoadOutOwner_RedOne,
    LoadOutOwner_RedTwo,
    LoadOutOwner_BlueOne,
    LoadOutOwner_BlueTwo
} ActiveLoadOutOwner;

var(SWATGui) private EditInline Config array<GUIRadioButton>         MyPlayerSelectorButtons;
var(SWATGui) private EditInline Config array<GUILabel>               MyPlayerNameLabels;

var(SWATGui) protected EditInline Config GUIScrollTextBox MyOfficerInfoBox "Holds all the custom loadouts that can be applied to the current loadout";
var(SWATGui) protected EditInline Config GUIScrollTextBox MyOfficerVitalsBox "Holds all the custom loadouts that can be applied to the current loadout";

var(SWATGui) private EditInline Config GUIButton         MyApplyToAllButton;

var(SWATGui) private EditInline Config GUIButton         MyLoadDefaultButton;
var(SWATGui) private EditInline Config GUIButton         MySaveCustomButton;
var(SWATGui) private EditInline Config GUIButton         MyDeleteCustomButton;

var(SWATGui) protected EditInline Config GUIComboBox     MyCustomLoadoutCombo "Holds all the custom loadouts that can be applied to the current loadout";

var(SWATGui) private EditInline EditConst DynamicLoadOutSpec MyCurrentLoadOuts[LoadOutOwner.EnumCount] "holds all current loadout info";

var(SWATGui) config localized String NoLoadoutNameEntered;
var(SWATGui) config localized String ConfirmOverwrite;
var(SWATGui) config localized String ConfirmDelete;
var(SWATGui) config localized String ConfirmApplyToAll;
var(SWATGui) config localized String EquipmentNotUnlocked;

var private bool bDontLoadCustom;
var private bool bSavePopupOpen;

var(SWATGui) config localized String OfficerInfo[LoadOutOwner.EnumCount];
var(SWATGui) config localized String OfficerVitals[LoadOutOwner.EnumCount];


///////////////////////////
// Initialization & Page Delegates
///////////////////////////
function InitComponent(GUIComponent MyOwner)
{
	local int i;

	Super.InitComponent(MyOwner);

    MyApplyToAllButton.OnClick=AttemptApplyToAll;

	//custom loadout controls
	if( MyCustomLoadoutCombo != None )
	{
	    for( i = 0; i < GC.CustomEquipmentLoadouts.Length; i++ )
	    {
	        MyCustomLoadoutCombo.AddItem(GC.CustomEquipmentLoadoutFriendlyNames[i],,GC.CustomEquipmentLoadouts[i],,(i<GC.LoadoutIsUndeletable.Length && GC.LoadoutIsUndeletable[i]));
	    }
        MyCustomLoadoutCombo.SetIndex(0);
	    MyCustomLoadoutCombo.OnChange=AttemptLoadCustomLoadout;
    }

    MyCustomLoadoutCombo.Edit.bReadOnly=true;

	if( MySaveCustomButton != None )
	    MySaveCustomButton.OnClick=AttemptSaveCustomLoadout;
	if( MyLoadDefaultButton != None )
	    MyLoadDefaultButton.OnClick=AttemptLoadDefaultLoadout;
	if( MyDeleteCustomButton != None )
        MyDeleteCustomButton.OnClick=AttemptDeleteCustomLoadout;
}

event Activate()
{
    local Campaign theCampaign;

    if( bActiveInput )
    {
        InitialDisplay();
        return;
    }

    Super.Activate();

    Assert( GC.CurrentMission != None );

    CheckCustomScenarioOfficerSettings(GC.CurrentMission.CustomScenario);

    //MyPlayerNameLabels[LoadOutOwner.LoadOutOwner_Player].SetCaption( SwatGUIController(Controller).GetCampaigns().CurCampaignName );
    MyPlayerSelectorButtons[ActiveLoadOutOwner].SelectRadioButton();
    SetOfficerInfo(ActiveLoadOutOwner);

    MyDeleteCustomButton.SetEnabled( !MyCustomLoadoutCombo.List.GetExtraBoolData() );
    MyPlayerSelectorButtons[1].SetEnabled(true);
    MyPlayerSelectorButtons[2].SetEnabled(true);
    MyPlayerSelectorButtons[3].SetEnabled(true);
    MyPlayerSelectorButtons[4].SetEnabled(true);

    theCampaign = SwatGUIController(Controller).GetCampaign();
    if(theCampaign != None && theCampaign.OfficerPermadeath) {
      if(theCampaign.RedOneDead) {
        MyPlayerSelectorButtons[1].SetEnabled(false);
      }
      if(theCampaign.RedTwoDead) {
        MyPlayerSelectorButtons[2].SetEnabled(false);
      }
      if(theCampaign.BlueOneDead) {
        MyPlayerSelectorButtons[3].SetEnabled(false);
      }
      if(theCampaign.BlueTwoDead) {
        MyPlayerSelectorButtons[4].SetEnabled(false);
      }
    }

    SwatGUIController(Controller).SPLoadoutPanel = Self;
}


protected function SpawnLoadouts()
{
    local int i;
    local LoadOutOwner LastOwner;

    if( bSavePopupOpen )
    {
        LastOwner = ActiveLoadOutOwner;
    }

    for( i = 0; i < LoadOutOwner.EnumCount; i++ )
    {
        if( MyCurrentLoadOuts[ i ] != None )
            continue;

        ActiveLoadOutOwner=LoadOutOwner(i);
        LoadLoadOut( "Current"$GetConfigName(ActiveLoadOutOwner), true );
    	MyCurrentLoadOuts[ i ] = MyCurrentLoadOut;
    	MyCurrentLoadOut = None;
    }

    if( bSavePopupOpen )
    {
        bSavePopupOpen = false;
        ActiveLoadOutOwner = LastOwner;
    }
    else
    {
    	ActiveLoadOutOwner = LoadOutOwner_Player;
    }

    MyCurrentLoadOut = MyCurrentLoadOuts[ ActiveLoadOutOwner ];

    Super.UpdateWeights();
}

protected function DestroyLoadouts()
{
    local int i;

    //destroy the actual loadouts here?
    for( i = 0; i < LoadOutOwner.EnumCount; i++ )
    {
        if( MyCurrentLoadOuts[i] != None )
            MyCurrentLoadOuts[i].destroy();
        MyCurrentLoadOuts[i] = None;
    }


    if( MyCurrentLoadOut != None )
        MyCurrentLoadOut.destroy();
    MyCurrentLoadOut = None;
}

///////////////////////////
//Utility functions used for managing loadouts
///////////////////////////
function LoadLoadOut( String loadOutName, optional bool bForceSpawn )
{
    Super.LoadLoadOut( loadOutName, bForceSpawn );

    //MyCurrentLoadOut.ValidateLoadOutSpec();

    Super.UpdateWeights();
}

function CopyLoadOutWeaponry( DynamicLoadOutSpec to, DynamicLoadOutSpec from )
{
    local int i;
    Assert( from != None );
    Assert( to != None );

    for( i = 0; i < Pocket.EnumCount; i++ )
    {
      log("SwatSPLoadoutPanel: Copying "$from.LoadOutSpec[i]$" to "$to.LoadOutSpec[i]);
      to.LoadOutSpec[i] = from.LoadOutSpec[i];
    }

    to.PrimaryWeaponAmmoCount = from.PrimaryWeaponAmmoCount;
    to.SecondaryWeaponAmmoCount = from.SecondaryWeaponAmmoCount;

    Super.UpdateWeights();
}

function String GetConfigName( LoadOutOwner theOfficer )
{
    local String ret;
    switch (theOfficer)
    {
        case LoadOutOwner_Player:
            ret="PlayerLoadOut";
            break;
        case LoadOutOwner_RedOne:
            ret="OfficerRedOneLoadOut";
            break;
        case LoadOutOwner_RedTwo:
            ret="OfficerRedTwoLoadOut";
            break;
        case LoadOutOwner_BlueOne:
            ret="OfficerBlueOneLoadOut";
            break;
        case LoadOutOwner_BlueTwo:
            ret="OfficerBlueTwoLoadOut";
            break;
    }
    return ret;
}

function SaveCurrentLoadout()
{
  SaveLoadOut("Current"$GetConfigName(ActiveLoadOutOwner));
}

function ChangeLoadOut( Pocket thePocket )
{
    Super.ChangeLoadOut( thePocket );
    SaveCurrentLoadout();
}

function bool CheckValidity( eNetworkValidity type )
{
    local int CampaignPath;

    CampaignPath = SwatGUIControllerBase(Controller).GetCampaign().CampaignPath;
    if(CampaignPath == 2) {
      return true;
    }

    return (type == NETVALID_SPOnly) || (Super.CheckValidity( type ));
}

function bool CheckCampaignValid( class EquipmentClass )
{
	local int MissionIndex;
	local int i;
	local int CampaignPath;

  if(EquipmentClass == None) {
    return true;
  }

	assert(SwatGUIControllerBase(Controller) != None);
	assertWithDescription(SwatGUIControllerBase(Controller).GetCampaign() != None, "GetCampaign() returned None. Campaign progression for equipment access wont work correctly.");

	MissionIndex = SwatGUIControllerBase(Controller).GetCampaign().GetAvailableIndex();
	CampaignPath = SwatGUIControllerBase(Controller).GetCampaign().CampaignPath;

	// Any equipment above the MissionIndex is currently unavailable
	if(CampaignPath == 0) { // We only do this for the regular SWAT 4 missions
    // Check first set of equipment
		for (i = MissionIndex + 1; i < GC.MissionName.Length; ++i)
			if (GC.MissionEquipment[i] == EquipmentClass) {
        log("CheckCampaignValid failed on "$EquipmentClass);
				return false;
      }

    // Check second set of equipment
    for(i = GC.MissionName.Length + MissionIndex + 1; i < GC.MissionEquipment.Length; ++i)
      if(GC.MissionEquipment[i] == EquipmentClass) {
        log("CheckCampaignValid failed on "$EquipmentClass);
        return false;
      }
	}
	return true;
}

// Returns true if this loadout has any equipment that cannot be unlocked.
function bool CheckLoadoutForInvalidUnlocks(DynamicLoadOutSpec Loadout) {
  local int i;
  for(i = 0; i < Pocket.EnumCount; i++) {
    if(!CheckCampaignValid(Loadout.LoadoutSpec[i])) {
      return true;
    }
  }
  return false;
}

///////////////////////////
// Component delegates
///////////////////////////
function AttemptApplyToAll(GUIComponent Sender)
{
	Assert(Sender == MyApplyToAllButton);

    Controller.TopPage().OnDlgReturned=OnApplyToAllDlgReturned;
    Controller.TopPage().OpenDlg( ConfirmApplyToAll , QBTN_YesNo );
}

function OnApplyToAllDlgReturned( int returnButton, optional string Passback )
{
    if( returnButton == QBTN_Yes )
    {
        ApplyToAll();
    }
}

function ApplyToAll()
{
    local int i;

	//apply current loadout to all officers
    for( i = 0; i < LoadOutOwner.EnumCount; i++ )
    {
        if( ActiveLoadOutOwner == i )
            continue;
        CopyLoadOutWeaponry( MyCurrentLoadOuts[ i ], MyCurrentLoadOut );
        SaveLoadOut( "Current"$GetConfigName(LoadOutOwner(i)) );
    }
}

function SetRadioGroup(GUIRadioButton group)
{
    local String ForcedLoadout;

    Super.SetRadioGroup( group );

	switch (group)
    {
		case MyPlayerSelectorButtons[LoadOutOwner.LoadOutOwner_Player]:
		    ActiveLoadOutOwner = LoadOutOwner_Player;
            break;
		case MyPlayerSelectorButtons[LoadOutOwner.LoadOutOwner_RedOne]:
		    ActiveLoadOutOwner = LoadOutOwner_RedOne;
            if( GC.CurrentMission.CustomScenario != None &&
                GC.CurrentMission.CustomScenario.RedOneLoadOut != 'Any' )
            {
                ForcedLoadout = string(GC.CurrentMission.CustomScenario.RedOneLoadOut);
            }
           break;
		case MyPlayerSelectorButtons[LoadOutOwner.LoadOutOwner_RedTwo]:
		    ActiveLoadOutOwner = LoadOutOwner_RedTwo;
            if( GC.CurrentMission.CustomScenario != None &&
                GC.CurrentMission.CustomScenario.RedTwoLoadOut != 'Any' )
            {
                ForcedLoadout = string(GC.CurrentMission.CustomScenario.RedTwoLoadOut);
            }
            break;
		case MyPlayerSelectorButtons[LoadOutOwner.LoadOutOwner_BlueOne]:
		    ActiveLoadOutOwner = LoadOutOwner_BlueOne;
            if( GC.CurrentMission.CustomScenario != None &&
                GC.CurrentMission.CustomScenario.BlueOneLoadOut != 'Any' )
            {
                ForcedLoadout = string(GC.CurrentMission.CustomScenario.BlueOneLoadOut);
            }
            break;
		case MyPlayerSelectorButtons[LoadOutOwner.LoadOutOwner_BlueTwo]:
		    ActiveLoadOutOwner = LoadOutOwner_BlueTwo;
            if( GC.CurrentMission.CustomScenario != None &&
                GC.CurrentMission.CustomScenario.BlueTwoLoadOut != 'Any' )
            {
                ForcedLoadout = string(GC.CurrentMission.CustomScenario.BlueTwoLoadOut);
            }
            break;
	}

    MyCurrentLoadOut = MyCurrentLoadOuts[ ActiveLoadOutOwner ];
    SetOfficerInfo(ActiveLoadOutOwner);
    if( ForcedLoadout != "" )
    {
        LoadLoadOut( ForcedLoadout );
        InitialDisplay();
        MyScrollLeftButton.DisableComponent();
        MyScrollRightButton.DisableComponent();
        MySaveCustomButton.DisableComponent();
        MyLoadDefaultButton.DisableComponent();
        MyCustomLoadoutCombo.DisableComponent();
        MyApplyToAllButton.DisableComponent();
        MyDeleteCustomButton.DisableComponent();
    }
    else
    {
        MyScrollLeftButton.EnableComponent();
        MyScrollRightButton.EnableComponent();
        MySaveCustomButton.EnableComponent();
        MyLoadDefaultButton.EnableComponent();
        MyCustomLoadoutCombo.EnableComponent();
        MyApplyToAllButton.EnableComponent();
        MyDeleteCustomButton.EnableComponent();
        InitialDisplay();
    }

    if( GC.CurrentMission.CustomScenario != None && GC.CurrentMission.CustomScenario.LoneWolf )
        MyApplyToAllButton.DisableComponent();

    //CheckCustomScenarioOfficerSettings( GC.CurrentMission.CustomScenario );
}

private function CheckCustomScenarioOfficerSettings( CustomScenario Scenario )
{
    MyPlayerSelectorButtons[LoadOutOwner.LoadOutOwner_RedOne].SetEnabled( Scenario == None || ( !Scenario.LoneWolf && Scenario.HasOfficerRedOne ) );
    MyPlayerNameLabels[LoadOutOwner.LoadOutOwner_RedOne].SetEnabled( Scenario == None || ( !Scenario.LoneWolf && Scenario.HasOfficerRedOne ) );

    MyPlayerSelectorButtons[LoadOutOwner.LoadOutOwner_RedTwo].SetEnabled( Scenario == None || ( !Scenario.LoneWolf && Scenario.HasOfficerRedTwo ) );
    MyPlayerNameLabels[LoadOutOwner.LoadOutOwner_RedTwo].SetEnabled( Scenario == None || ( !Scenario.LoneWolf && Scenario.HasOfficerRedTwo ) );

    MyPlayerSelectorButtons[LoadOutOwner.LoadOutOwner_BlueOne].SetEnabled( Scenario == None || ( !Scenario.LoneWolf && Scenario.HasOfficerBlueOne ) );
    MyPlayerNameLabels[LoadOutOwner.LoadOutOwner_BlueOne].SetEnabled( Scenario == None || ( !Scenario.LoneWolf && Scenario.HasOfficerBlueOne ) );

    MyPlayerSelectorButtons[LoadOutOwner.LoadOutOwner_BlueTwo].SetEnabled( Scenario == None || ( !Scenario.LoneWolf && Scenario.HasOfficerBlueTwo ) );
    MyPlayerNameLabels[LoadOutOwner.LoadOutOwner_BlueTwo].SetEnabled( Scenario == None || ( !Scenario.LoneWolf && Scenario.HasOfficerBlueTwo ) );
}


private function SetOfficerInfo(LoadOutOwner Officer)
{
    local string content;

    content = OfficerVitals[Officer];

    if( Officer == LoadOutOwner_Player )
        content = SwatGUIController(Controller).GetCampaigns().CurCampaignName $ content;
    MyOfficerVitalsBox.SetContent( content );

    content = OfficerInfo[Officer];
    MyOfficerInfoBox.SetContent( content );
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Custom Loadout Management
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
private function SaveCustomLoadout(string SaveName)
{
    local string SaveLoadoutName;

    //delete it first
    DeleteCustomLoadout( SaveName );

    SaveLoadoutName = ComputeMD5Checksum( SaveName );
//log("[dkaplan] Saving custom loadout of name: "$SaveLoadoutName$" and friendly name "$savename);

    //save the loadout
    SaveLoadOut(SaveLoadoutName);

    //save the GC
    GC.CustomEquipmentLoadouts[GC.CustomEquipmentLoadouts.Length]=SaveLoadoutName;
    GC.CustomEquipmentLoadoutFriendlyNames[GC.CustomEquipmentLoadoutFriendlyNames.Length]=SaveName;
    GC.SaveConfig();

    //update the combo box
    bDontLoadCustom=true;
    //if not overwriting, add it to the list
    MyCustomLoadoutCombo.AddItem(SaveName,,SaveLoadoutName);
    MyCustomLoadoutCombo.Find(SaveName);
    bDontLoadCustom=false;
}

private function DeleteCustomLoadout(string DeleteName)
{
    local int i;

//log("[dkaplan] Deleting custom loadout of name: "$DeleteName);

    for( i = 0; i < GC.CustomEquipmentLoadouts.Length; i++ )
    {
        if( GC.CustomEquipmentLoadoutFriendlyNames[i]==DeleteName )
        {
            AssertWithDescription( !GC.LoadoutIsUndeletable[i], "Attempted to delete predefined loadout "$DeleteName );
            //save the GC
            GC.CustomEquipmentLoadouts.Remove( i, 1 );
            GC.CustomEquipmentLoadoutFriendlyNames.Remove( i, 1 );
            GC.SaveConfig();
            break;
        }
    }

    //update the combo box
    bDontLoadCustom=true;
    if( MyCustomLoadoutCombo.Find( DeleteName ) != "" )
        MyCustomLoadoutCombo.RemoveItem(MyCustomLoadoutCombo.GetIndex(),1);
    bDontLoadCustom=false;
}

private function LoadCustomLoadout()
{
    local string LoadName;
    local string LoadLoadoutName;
    local DynamicLoadOutSpec CustomLO;

    if( bDontLoadCustom )
        return;

    //get the loadout name
    LoadName = MyCustomLoadoutCombo.List.Get();
    LoadLoadoutName = MyCustomLoadoutCombo.List.GetExtra();
//log("[dkaplan] Loading custom loadout of name: "$LoadLoadoutName$" and friendly name "$LoadName);

    //load the loadout
    CustomLO = PlayerOwner().Spawn( class'DynamicLoadOutSpec', None, name( LoadLoadoutName ) );
    log("Loading custom loadout: ("$LoadLoadoutName$" / "$CustomLO$"");

    if(CheckLoadoutForInvalidUnlocks(CustomLO)) {
      Controller.TopPage().OnPopupReturned=InternalOnPopupReturned;
      Controller.TopPage().OpenDlg( EquipmentNotUnlocked, QBTN_Ok, "EquipmentNotUnlocked" );

      CustomLO.Destroy();
      return;
    }

    CopyLoadOutWeaponry(MyCurrentLoadOut,CustomLO);
    CustomLO.Destroy();

    SaveLoadOut( "Current"$GetConfigName(ActiveLoadOutOwner) );

    //display the new loadout
    InitialDisplay();

    Super.UpdateWeights();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Custom Loadout Delegates
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function AttemptSaveCustomLoadout(GUIComponent Sender)
{
    Controller.TopPage().OnPopupReturned=InternalOnPopupReturned;
    bSavePopupOpen=True;
    SwatGuiPage(Controller.TopPage()).OpenPopup( "SwatGui.SwatSaveCustomPopup", "SwatSaveCustomPopup" );
}

function AttemptLoadCustomLoadout(GUIComponent Sender)
{
    MyDeleteCustomButton.SetEnabled( !MyCustomLoadoutCombo.List.GetExtraBoolData() );
    LoadCustomLoadout();
}

function AttemptDeleteCustomLoadout(GUIComponent Sender)
{
    local string DeleteName;

    DeleteName = MyCustomLoadoutCombo.GetText();

    Controller.TopPage().OnDlgReturned=InternalOnDeleteDlgReturned;
    Controller.TopPage().OpenDlg( FormatTextString( ConfirmDelete, DeleteName ), QBTN_YesNo, DeleteName );
}

function AttemptLoadDefaultLoadout(GUIComponent Sender)
{
    LoadLoadout( "Default"$GetConfigName(ActiveLoadOutOwner) );
    SaveLoadOut( "Current"$GetConfigName(ActiveLoadOutOwner) );
    InitialDisplay();
}

function TryToSaveLoadout(string SaveName)
{
    //dont save dups
    if( MyCustomLoadoutCombo.Find( SaveName,, true ) != "" )
    {
        Controller.TopPage().OnDlgReturned=InternalOnSaveDlgReturned;
        Controller.TopPage().OpenDlg( FormatTextString( ConfirmOverwrite, SaveName ), QBTN_YesNo, SaveName );
    }
    else
        SaveCustomLoadout(SaveName);
}

function InternalOnPopupReturned( GUIListElem returnObj, optional string Passback )
{
    switch (passback)
    {
        case "SaveCustom":
            TryToSaveLoadout( returnObj.Item );
            break;
    }
}

function InternalOnSaveDlgReturned( int returnButton, optional string Passback )
{
    if( returnButton == QBTN_Yes )
    {
        SaveCustomLoadout(Passback);
    }
}

function InternalOnDeleteDlgReturned( int returnButton, optional string Passback )
{
    if( returnButton == QBTN_Yes )
    {
        DeleteCustomLoadout(Passback);
    }
}

function TooMuchWeightModal() {
  Controller.TopPage().OnDlgReturned=None;
  Super.TooMuchWeightModal();
}

function TooMuchBulkModal() {
  Controller.TopPage().OnDlgReturned=None;
  Super.TooMuchBulkModal();
}

function bool CheckWeightBulkValidity() {
  local int i;

  for(i = 0; i < LoadOutOwner.EnumCount; i++) {
    if(MyCurrentLoadOuts[i].GetTotalWeight() > MyCurrentLoadOuts[i].GetMaximumWeight()) {
      TooMuchWeightModal();
      return false;
    } else if(MyCurrentLoadOuts[i].GetTotalBulk() > MyCurrentLoadOuts[i].GetMaximumBulk()) {
      TooMuchBulkModal();
      return false;
    }
  }
  return true;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// defaultproperties
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    ConfirmOverwrite="A loadout named '%1' already exists; are you sure that you wish to overwrite it?"
    ConfirmDelete="Delete loadout '%1'?"
    ConfirmApplyToAll="Are you sure that you wish to apply the selected loadout to your entire team?"

    EquipmentNotUnlocked="This loadout contains equipment that hasn't been unlocked yet. You are not able to use it until you have unlocked the equipment."

    OfficerInfo(0)="A recent transfer from Los Angeles, the Sergeant is cool under fire and always business like.  With a new element to command he will have to gain the respect of his squad while on the job."
    OfficerInfo(1)="A thirty year veteran of the force, and 25 year veteran of SWAT, Officer Reynolds is the most experienced member of the element.  His experience has taught him that staying calm can be the key to survival as a SWAT officer.  Realizing the value of his experience, he is always willing to give his advice to the element."
    OfficerInfo(2)="Officer Girard is a local boy, born and raised in the metropolitan area.  Girard has been a member of SWAT for 6 years and been decorated for his bravery on 2 occasions."
    OfficerInfo(3)="Spending only 2 years on the street before passing the rigorous SWAT training course and trials, Officer Fields is one of the youngest officers on the force to be promoted to SWAT.  Although a bit of a loudmouth, he has proven to be a very capable operator."
    OfficerInfo(4)="Officer Jackson has had a long and distinguished career on SWAT.  As well as being a top-notch operator, Jackson prides himself on being an athlete.  He is in peak physical condition and can be an intimidating presence on any operation."
    OfficerVitals(0)="|Nickname:  Boss|Badge No.:  3187|Years of Service:  13"
    OfficerVitals(1)="Officer Steven Reynolds|Nickname:  Gramps|Badge No.:  3077|Years of Service: 28"
    OfficerVitals(2)="Officer Anthony Girard|Nickname:  Subway|Badge No.:  3518|Years of Service: 12"
    OfficerVitals(3)="Officer Zachary Fields|Nickname:  Hollywood|Badge No.: 3975|Years of Service:  4"
    OfficerVitals(4)="Officer Allen Jackson|Nickname:  Python|Badge No.:  3248|Years of Service:  16"

    EquipmentOverWeightString="One of your officers is equipped with too much weight. You need to change their gear before you may continue."
    EquipmentOverBulkString="One of your officers is equipped with too much bulk. You need to change their gear before you may continue."
}
