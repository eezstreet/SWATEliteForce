// ====================================================================
//  Class:  SwatGui.SwatLoadoutPanel
//  Parent: SwatGUIPanel
//
//  Menu to load gear for each officer.
// ====================================================================

class SwatLoadoutPanel extends SwatGUIPanel
     ;

import enum eNetworkValidity from SwatGame.SwatGUIConfig;
import enum eTeamValidity from SwatGame.SwatGUIConfig;
import enum Pocket from Engine.HandheldEquipment;

var(SWATGui) protected EditInline Config GUIImage          MyEquipmentImage;
var(SWATGui) protected EditInline Config GUIImage          MyAmmoImage;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentNameLabel;
var(SWATGui) protected EditInline Config GUILabel          MyAmmoNameLabel;
var(SWATGui) protected EditInline Config GUIScrollTextBox  MyWeaponInfoBox;
var(SWATGui) protected EditInline Config GUIScrollTextBox  MyEquipmentInfoBox;
var(SWATGui) protected EditInline Config GUIButton         MyScrollLeftButton;
var(SWATGui) protected EditInline Config GUIButton         MyScrollRightButton;
var(SWATGui) protected EditInline Config GUIButton         MyScrollAmmoLeftButton;
var(SWATGui) protected EditInline Config GUIButton         MyScrollAmmoRightButton;

var(SWATGui) protected EditInline Config GUINumericEdit    MyAmmoMagazineCountSpinner;
var(SWATGui) protected EditInline Config GUILabel          MyAmmoMagazineCountLabel;

// Advanced Information panel
// tabs
var(SWATGui) protected EditInline Config GUILabel          MyAdvManufacturerTab;
var(SWATGui) protected EditInline Config GUILabel          MyAdvCartridgeTab;
var(SWATGui) protected EditInline Config GUILabel          MyAdvFiringTab;
// Manufacturer Information
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentManufacturerLabel;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentCountryOfOriginLabel;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentProductionStartLabel;
// Ammunition Information
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentCaliberLabel;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentMagazineSizeLabel;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentTotalAmmoLabel;
// Firing Information
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentFireModesLabel;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentMuzzleVelocityLabel;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentRateOfFireLabel;

// Weight/Bulk system
var(SWATGui) protected EditInline Config GUIProgressBar    MyEquipmentWeightBar;
var(SWATGui) protected EditInline Config GUIProgressBar    MyEquipmentBulkBar;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentWeightLabel;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentBulkLabel;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentWeightName;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentBulkName;

var(SWATGui) Config Localized String EquipmentOverWeightString;
var(SWATGui) Config Localized String EquipmentOverBulkString;


var(SWATGui) protected EditInline EditConst DynamicLoadOutSpec   MyCurrentLoadOut "Holds all current loadout info";

struct sPocketTab
{
    var() config Pocket DefaultPocket "The default pocket to be used when this tab is selected";
    var() Pocket CurrentPocket "The current (main) pocket to be used when this tab is selected";
    var() config Pocket AmmoPocket "The ammo pocket to be used, Pocket_Invalid if it has none";
    var() config array<Pocket> SelectablePockets "The pockets that can be selected by buttons on this tab";
    var() config array<Pocket> DisplayablePockets "The pockets that can be selected by buttons on this tab";
    var() EditInline GUIButton TabButton;
    var() EditInline GUIPanel TabPanel;
};

var(SWATGui) protected EditInline config array<sPocketTab> PocketTabs "These are the tabs of selectable equipment";

var(SWATGui) protected EditInline array<GUIList> EquipmentList "these are the lists of equipment";
var(SWATGui) protected EditInline array<GUILabel> EquipmentLabel "These go next to the paperdoll figure";
var(SWATGui) protected EditInline array<GUIButton> EquipmentSelectionButton "These go next to the paperdoll figure";

var private int     ActiveTab;
var protected Pocket  ActivePocket;
var private Pocket  ActiveAmmoPocket;
var private int     FailedToValidate;

///////////////////////////
// Initialization & Page Delegates
///////////////////////////
function InitComponent(GUIComponent MyOwner)
{
    local int i,j;
    local string PocketName;
    local Pocket PocketID;
    local class<object> EquipmentClass;

	Super.InitComponent(MyOwner);

    //scroll button delegates
    MyScrollLeftButton.OnClick=InternalOnScrollClick;
    MyScrollRightButton.OnClick=InternalOnScrollClick;
    MyScrollAmmoLeftButton.OnClick=InternalOnScrollClick;
    MyScrollAmmoRightButton.OnClick=InternalOnScrollClick;
    MyAmmoMagazineCountSpinner.OnChange=MagazineCountChange;

    //equipment lists
	for( i = 0; i < Pocket.EnumCount; i++ )
	{
	    //ensure this category is supposed to be displayed
	    if( !CheckValidity( GC.AvailableEquipmentPockets[i].DisplayValidity ) ||
	        GC.AvailableEquipmentPockets[i].EquipmentClassName.Length <= 0 )
	        Continue;

        PocketName = string(GetEnum(Pocket,i));

        EquipmentLabel[i] = GUILabel(AddComponent( "GUI.GUILabel", self.Name$"_"$PocketName$"_Label", true ));

        EquipmentList[i] = GUIList(AddComponent( "GUI.GUIList", self.Name$"_"$PocketName$"_EquipmentList", true ));
        EquipmentList[i].bAcceptsInput=False;
        EquipmentList[i].bCanBeShown=False;
        EquipmentList[i].bNeverSort=true;

        for( j = 0; j < GC.AvailableEquipmentPockets[i].EquipmentClassName.Length; j++ )
        {
            if( GC.AvailableEquipmentPockets[i].bSelectable[j] == 0 ||
                !CheckValidity( GC.AvailableEquipmentPockets[i].Validity[j] ) )
                Continue;

            EquipmentClass = class<Object>(DynamicLoadObject( GC.AvailableEquipmentPockets[i].EquipmentClassName[j], class'Class'));

			EquipmentList[i].Add( string(EquipmentClass.Name), EquipmentClass );
        }
	}

	for( i = 0; i < PocketTabs.Length; i++ )
	{
	    PocketTabs[i].TabPanel = GUIPanel(AddComponent( "GUI.GUIPanel", self.Name$"_"$i$"_TabPanel", true ));
	    PocketTabs[i].TabButton = GUIButton(AddComponent( "GUI.GUIButton", self.Name$"_"$i$"_TabButton", true ));

        PocketTabs[i].TabButton.OnClick=InternalTabButtonOnClick;
        PocketTabs[i].CurrentPocket = PocketTabs[i].DefaultPocket;

        for( j = 0; j < PocketTabs[i].SelectablePockets.Length; j++ )
        {
            PocketID = PocketTabs[i].SelectablePockets[j];

            PocketName = string(GetEnum(Pocket,PocketID));

            EquipmentSelectionButton[PocketID] = GUIButton(PocketTabs[i].TabPanel.AddComponent( "GUI.GUIButton", self.Name$"_"$PocketName$"_Button", true ));
            //EquipmentSelectionButton[PocketID].SetCaption(GC.AvailableEquipmentPockets[PocketID].PocketFriendlyName );
            EquipmentSelectionButton[PocketID].OnClick=InternalSelectorButtonOnClick;
        }
    }

    ActiveTab = 0;
}


event Activate()
{
    Super.Activate();

    SpawnLoadouts();
	InitialDisplay();
}

event Hide()
{
    DestroyLoadouts();
    Super.Hide();
}

//should be subclasses
protected function SpawnLoadouts() {}
protected function DestroyLoadouts() {}

function InitialDisplay()
{
    local int i;

    for( i = 0; i < Pocket.EnumCount; i++ )
    {
	    if( !CheckValidity( GC.AvailableEquipmentPockets[i].DisplayValidity ) )
	        Continue;

		ValidatePocketForSelection( Pocket(i) );

        UpdateIndex( Pocket(i) );

        DisplayEquipment( Pocket(i) );
		
		Scrolled( Pocket(i), false);
		Scrolled( Pocket(i), true );
    }

    DisplayTab(ActiveTab);
}

function ValidatePocketForSelection( Pocket thePocket )
{
	if( EquipmentList[thePocket] == None )
        return;

	if( !CheckTeamValidity(GetTeamValidity(thePocket, class<actor>(EquipmentList[thePocket].GetObject()))) )
	{
		EquipmentList[thePocket].SetIndex( 0 );
		ChangeLoadOut( thePocket );
	}
}

///////////////////////////
// Functions for erroring if we have too much Weight
///////////////////////////

function TooMuchWeightModal() {
  Controller.TopPage().OpenDlg( EquipmentOverWeightString, QBTN_Ok, "TooMuchWeight" );
}

function TooMuchBulkModal() {
  Controller.TopPage().OpenDlg( EquipmentOverBulkString, QBTN_Ok, "TooMuchBulk" );
}

function bool CheckWeightBulkValidity() {
  assertWithDescription(false, "CheckWeightBulkValidity got called in SwatLoadoutPanel. Use a child class member instead.");

  return false;
}

///////////////////////////
// Function for updating the bar display
///////////////////////////
function UpdateWeights() {
  local float bulkDisplay;
  local class<SwatAmmo> WeaponAmmo;

  if(ActivePocket == Pocket_PrimaryWeapon) {
    WeaponAmmo = class<SwatAmmo>(MyCurrentLoadOut.LoadOutSpec[1]);
    MyAmmoMagazineCountSpinner.MinValue = WeaponAmmo.default.MinReloadsToCarry;
    MyAmmoMagazineCountSpinner.MaxValue = WeaponAmmo.default.MaxReloadsToCarry;
    MyAmmoMagazineCountSpinner.SetValue(MyCurrentLoadOut.GetPrimaryAmmoCount());
    MyAmmoMagazineCountLabel.Caption = WeaponAmmo.default.ReloadsString;
  } else if(ActivePocket == Pocket_SecondaryWeapon) {
    WeaponAmmo = class<SwatAmmo>(MyCurrentLoadOut.LoadOutSpec[3]);
    MyAmmoMagazineCountSpinner.MinValue = WeaponAmmo.default.MinReloadsToCarry;
    MyAmmoMagazineCountSpinner.MaxValue = WeaponAmmo.default.MaxReloadsToCarry;
    MyAmmoMagazineCountSpinner.SetValue(MyCurrentLoadOut.GetSecondaryAmmoCount());
    MyAmmoMagazineCountLabel.Caption = WeaponAmmo.default.ReloadsString;
  }

  MyEquipmentWeightBar.Value = MyCurrentLoadOut.GetWeightPercentage();
  MyEquipmentBulkBar.Value = MyCurrentLoadOut.GetBulkPercentage();

  if(MyEquipmentWeightBar.Value < 0.0) {
    MyEquipmentWeightBar.Value = 0.0;
  } else if(MyEquipmentWeightBar.Value > 1.0) {
    MyEquipmentWeightBar.Value = 1.0;
    MyEquipmentWeightBar.BarColor.R = 255;
    MyEquipmentWeightBar.BarColor.B = 0;
    MyEquipmentWeightBar.BarColor.G = 0;
    // TODO disable start button
  } else {
    MyEquipmentWeightBar.BarColor.R = 255;
    MyEquipmentWeightBar.BarColor.B = 255;
    MyEquipmentWeightBar.BarColor.G = 255;
  }

  if(MyEquipmentBulkBar.Value < 0.0) {
    MyEquipmentBulkBar.Value = 0.0;
  } else if(MyEquipmentBulkBar.Value > 1.0) {
    MyEquipmentBulkBar.Value = 1.0;
    MyEquipmentBulkBar.BarColor.R = 255;
    MyEquipmentBulkBar.BarColor.B = 0;
    MyEquipmentBulkBar.BarColor.G = 0;
  } else {
    MyEquipmentBulkBar.BarColor.R = 255;
    MyEquipmentBulkBar.BarColor.B = 255;
    MyEquipmentBulkBar.BarColor.G = 255;
  }

  bulkDisplay = MyCurrentLoadOut.GetBulkPercentage();
  bulkDisplay *= 100.0;

  MyEquipmentWeightLabel.Caption = ""$MyCurrentLoadOut.GetTotalWeight()$"kg";
  MyEquipmentBulkLabel.Caption =""$bulkDisplay$"%";
}

///////////////////////////
//Utility functions used for managing loadouts
///////////////////////////
function LoadLoadOut( String loadOutName, optional bool bForceSpawn )
{
    if( MyCurrentLoadOut != None && bForceSpawn )
    {
        MyCurrentLoadOut.destroy();
    }

    if( MyCurrentLoadOut == None || bForceSpawn )
    {
        MyCurrentLoadOut = PlayerOwner().Spawn( class'DynamicLoadOutSpec', None, name( loadOutName ) );
    }
    else
    {
        MyCurrentLoadOut.ResetConfig( loadOutName );  //Loads the transient reference from the config data for this object
    }
    AssertWithDescription( MyCurrentLoadOut != None, "[dkaplan]: Failed to load loadout ["$loadOutName$"]");
}

function SaveLoadOut( String loadOutName )
{
    MyCurrentLoadOut.SaveConfig( loadOutName );
}

function bool CheckValidity( eNetworkValidity type )  //should be further subclassed
{
    return (type == NETVALID_All);
}

function bool CheckTeamValidity( eTeamValidity type )  //should be further subclassed
{
	return (type == TEAMVALID_ALL);
}

function bool CheckCampaignValid( class EquipmentClass )  //should be further subclassed
{
	return true;
}

function eTeamValidity GetTeamValidity(Pocket pock, class<Actor> CheckClass)
{
	local string ClassName;
	local class<Actor> DLOClass;
	local int i;
	local ServerSettings Settings;

	Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);

	// Custom skins always need to be team checked. All other team specific stuff can be disabled
	if( pock != Pocket.Pocket_CustomSkin && Settings != None && Settings.bDisableTeamSpecificWeapons )
		return TEAMVALID_ALL;

	for( i = 0; i < GC.AvailableEquipmentPockets[pock].EquipmentClassName.Length; ++i )
	{
		ClassName = GC.AvailableEquipmentPockets[pock].EquipmentClassName[i];

		DLOClass = class<Actor>(DynamicLoadObject(ClassName, class'class'));

		AssertWithDescription( DLOClass != None, self.Name$":  Could not DLO invalid equipment class "$ClassName$" specified in the pocket specifications section of SwatEquipment.ini." );

		if (DLOClass == CheckClass)
			return GC.AvailableEquipmentPockets[pock].TeamValidity[i];
	}

	return TEAMVALID_ALL;
}

///////////////////////////
//GUI display and updating of loadout information
///////////////////////////



//set the available ammo for the current weapon
function LoadAmmoForWeapon( Pocket thePocket, class<FiredWeapon> WeaponClass )
{
    local Pocket OtherPocket;
    local string str;

    OtherPocket = GC.AvailableEquipmentPockets[thePocket].DependentPocket;

    AssertWithDescription( WeaponClass.default.PlayerAmmoOption.Length > 0, "The weapon class "$WeaponClass.Name$" must have at least one PlayerAmmoOption specified in SwatEquipment.ini." );

    MyScrollAmmoLeftButton.SetActive( WeaponClass.default.PlayerAmmoOption.Length > 1 );
    MyScrollAmmoRightButton.SetActive( WeaponClass.default.PlayerAmmoOption.Length > 1 );

    MyAmmoMagazineCountSpinner.MaxValue = 200;

    if(thePocket == Pocket_PrimaryWeapon && ActivePocket == thePocket) {
      MyAmmoMagazineCountSpinner.SetValue(MyCurrentLoadOut.GetPrimaryAmmoCount());
    } else if(thePocket == Pocket_SecondaryWeapon && ActivePocket == thePocket) {
      MyAmmoMagazineCountSpinner.SetValue(MyCurrentLoadOut.GetSecondaryAmmoCount());
    }

    //set the current ammo for this loadout
    str = String(MyCurrentLoadOut.LoadOutSpec[OtherPocket].Name);
    EquipmentList[OtherPocket].Find( Str );

    // if the current ammo is invalid,
    // set the default ammo for this weapon
    //
    // if the item that would be selected is invalid given other items in the loadout, select the next item
    if( !MyCurrentLoadOut.ValidForLoadoutSpec( class<actor>(EquipmentList[OtherPocket].GetObject()), OtherPocket ) )
    {
        Scrolled( OtherPocket, false );
    }

    UpdateWeights();
}

// change the Loadout for the selected pocket
function ChangeLoadOut( Pocket thePocket )
{
    local class<actor> theItem;

    theItem = class<actor>(EquipmentList[thePocket].GetObject());

    MyCurrentLoadOut.LoadOutSpec[thePocket] = theItem;
    log("LoadoutChange("$thePocket$") - "$theItem);

    //load out updated with selection from equipment list
    switch (thePocket)
    {
        case Pocket_PrimaryWeapon:
        case Pocket_SecondaryWeapon:
            LoadAmmoForWeapon( thePocket, class<FiredWeapon>(theItem) );
            break;
        case Pocket_Breaching:
            if( theItem == class'SwatEquipment.C2Charge' )
            {
                MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_HiddenC2Charge1] = class'SwatEquipment.C2Charge';
                MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_HiddenC2Charge2] = class'SwatEquipment.C2Charge';
            }
            else
            {
                MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_HiddenC2Charge1] = None;
                MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_HiddenC2Charge2] = None;
            }
            break;
    }
}

//display the info about the equipment in the current pocket
function DisplayEquipment( Pocket thePocket )
{
    local class<ICanBeSelectedInTheGUI> Equipment;
    local class<SwatWeapon> EquipmentWeaponClass;


    if( EquipmentList[thePocket] == None )
        return;

    Equipment = class<ICanBeSelectedInTheGUI>(EquipmentList[thePocket].GetObject());

    EquipmentLabel[thePocket].SetCaption( Equipment.static.GetFriendlyName() );

    if( EquipmentSelectionButton[thePocket] != None )
        EquipmentSelectionButton[thePocket].SetCaption( Equipment.static.GetFriendlyName() );


    //dont update anything on the panel if this is not on the active panel
    if( !IsPocketDisplayedInActiveTab( thePocket ) )
        return;

    //handle displaying the info for this pocket in the panel
    switch(thePocket)
    {
        case Pocket_PrimaryWeapon:
        case Pocket_PrimaryAmmo:
            EquipmentWeaponClass = class<SwatWeapon>(EquipmentList[0].GetObject());
            break;
        case Pocket_SecondaryWeapon:
        case Pocket_SecondaryAmmo:
            EquipmentWeaponClass = class<SwatWeapon>(EquipmentList[2].GetObject());
            break;
        default:
            EquipmentWeaponClass = None;
    }

    if(EquipmentWeaponClass != None)
    {
      MyEquipmentManufacturerLabel.SetCaption(EquipmentWeaponClass.static.GetManufacturer());
      MyEquipmentCountryOfOriginLabel.SetCaption(EquipmentWeaponClass.static.GetCountryOfOrigin());
      MyEquipmentProductionStartLabel.SetCaption(EquipmentWeaponClass.static.GetProductionStart());
      MyEquipmentCaliberLabel.SetCaption(EquipmentWeaponClass.static.GetCaliber());
      MyEquipmentMagazineSizeLabel.SetCaption(EquipmentWeaponClass.static.GetMagSize());
      MyEquipmentTotalAmmoLabel.SetCaption(EquipmentWeaponClass.static.GetTotalAmmoString());
      MyEquipmentFireModesLabel.SetCaption(EquipmentWeaponClass.static.GetFireModes());
      MyEquipmentMuzzleVelocityLabel.SetCaption(EquipmentWeaponClass.static.GetMuzzleVelocityString());
      MyEquipmentRateOfFireLabel.SetCaption(EquipmentWeaponClass.static.GetRateOfFire());

      MyAmmoMagazineCountSpinner.SetVisibility(true);
      MyAmmoMagazineCountLabel.SetVisibility(true);
      MyAmmoMagazineCountSpinner.SetActive(true);
    } else {
      MyAmmoMagazineCountSpinner.SetVisibility(false);
      MyAmmoMagazineCountLabel.SetVisibility(false);
    }

    switch(thePocket)
    {
        case Pocket_PrimaryWeapon:
        case Pocket_SecondaryWeapon:
            //MyEquipmentNameLabel.SetCaption(EquipmentWeaponClass.static.GetManufacturer());
            MyEquipmentNameLabel.SetCaption( Equipment.static.GetFriendlyName() );
            MyEquipmentImage.Image = Equipment.static.GetGUIImage();
            MyWeaponInfoBox.SetContent( Equipment.static.GetDescription() );
            break;
        case Pocket_PrimaryAmmo:
        case Pocket_SecondaryAmmo:
            MyAmmoImage.Image = Equipment.static.GetGUIImage();
            MyAmmoNameLabel.SetCaption( Equipment.static.GetFriendlyName() );
            MyWeaponInfoBox.SetContent( Equipment.static.GetDescription() );
            break;
        default:
            MyEquipmentImage.Image = Equipment.static.GetGUIImage();
            MyEquipmentNameLabel.SetCaption( Equipment.static.GetFriendlyName() );
            MyEquipmentInfoBox.SetContent( Equipment.static.GetDescription() );
            break;
    }

    UpdateWeights();
}

// update must be made whenever a scroll button is pressed
function Scrolled( Pocket thePocket, bool bLeftUsed )
{
    if( bLeftUsed )
        EquipmentList[thePocket].SetIndex( EquipmentList[thePocket].GetIndex()+1 );
    else
        EquipmentList[thePocket].SetIndex( EquipmentList[thePocket].GetIndex()-1 );

    //if the sepcified index is invalid, wrap around
    if( EquipmentList[thePocket].GetIndex() < 0 )
    {
        if( bLeftUsed )
            EquipmentList[thePocket].SetIndex( 0 );
        else
            EquipmentList[thePocket].SetIndex( EquipmentList[thePocket].Elements.length-1 );
    }

    //if the item that would be selected is invalid given other items in the loadout and the players team, select the next item
    if( !MyCurrentLoadOut.ValidForLoadoutSpec( class<actor>(EquipmentList[thePocket].GetObject()), thePocket ) ||
		!CheckTeamValidity( GetTeamValidity(thePocket, class<actor>(EquipmentList[thePocket].GetObject()) ) ) ||
		!CheckCampaignValid( class<actor>(EquipmentList[thePocket].GetObject()) ) )
    {
        if( FailedToValidate >= 0 )
        {
            if( FailedToValidate == EquipmentList[thePocket].GetIndex() )
            {
                Log( "!!!!!!!Failed to validate equipment for the following loadout:" );
                MyCurrentLoadOut.PrintLoadOutSpecToMPLog();
                AssertWithDescription( false, "None of the equipment specified in SwatEquipment.ini for pocket "$GetEnum(Pocket,thePocket)$" validates for dynamic loadout spec "$MyCurrentLoadOut);
            }
        }
        else
            FailedToValidate = EquipmentList[thePocket].GetIndex();

        Scrolled( thePocket, bLeftUsed );

        return;
    }

	FailedToValidate=-1;

    ChangeLoadOut( thePocket );
	DisplayEquipment( thePocket );
}


// update must be made whenever the ActivePocket or ActiveLoadOutOwner is changed
function UpdateIndex( Pocket thePocket )
{
    local string str;

    if( EquipmentList[thePocket] == None )
        return;

    str = String(MyCurrentLoadOut.LoadOutSpec[thePocket].Name);

    EquipmentList[thePocket].Find( Str );

    if( thePocket == Pocket.Pocket_PrimaryWeapon ||
        thePocket == Pocket.Pocket_SecondaryWeapon )
    {
        LoadAmmoForWeapon( thePocket, class<FiredWeapon>(EquipmentList[thePocket].GetObject()) );
    }
}

function SaveCurrentLoadout()
{
  assert(false); // needs to be implemented by children
}

///////////////////////////
// Component delegates
///////////////////////////
protected function MagazineCountChange(GUIComponent Sender) {
  local GUINumericEdit SenderEdit;
  SenderEdit = GUINumericEdit(Sender);

  if(ActivePocket == Pocket_PrimaryWeapon) {
    MyCurrentLoadOut.SetPrimaryAmmoCount(SenderEdit.Value);
  } else if(ActivePocket == Pocket_SecondaryWeapon) {
    MyCurrentLoadOut.SetSecondaryAmmoCount(SenderEdit.Value);
  }
  UpdateWeights();
  SaveCurrentLoadout();
}

private function InternalOnScrollClick(GUIComponent Sender)
{
    local bool bLeftScrollUsed; //scrolling left?
    bLeftScrollUsed = false;

	switch (Sender)
	{
		case MyScrollLeftButton:
		    bLeftScrollUsed = true;
		case MyScrollRightButton:
            UpdateIndex(ActivePocket);
            Scrolled( ActivePocket, bLeftScrollUsed );
            break;

		case MyScrollAmmoLeftButton:
		    bLeftScrollUsed = true;
		case MyScrollAmmoRightButton:
            UpdateIndex(ActiveAmmoPocket);
            Scrolled( ActiveAmmoPocket, bLeftScrollUsed );
            break;
	}
}


private function InternalSelectorButtonOnClick(GUIComponent Sender)
{
    local int i;

    for( i = 0; i < EquipmentSelectionButton.Length; i++ )
    {
        if( EquipmentSelectionButton[i] == None )
            continue;

        if( EquipmentSelectionButton[i] == Sender )
        {
            ActivePocket = Pocket(i);
            EquipmentSelectionButton[i].DisableComponent();
        }
        else
        {
            EquipmentSelectionButton[i].EnableComponent();
        }
    }

    MyAmmoMagazineCountSpinner.MaxValue = 200; // temp

    UpdateIndex(ActivePocket);
    DisplayEquipment(ActivePocket);
    UpdateWeights();
}

private function InternalTabButtonOnClick(GUIComponent Sender)
{
    local int i;

    for( i = 0; i < PocketTabs.Length; i++ )
    {
        if( PocketTabs[i].TabButton == Sender )
        {
            ActiveTab = i;
            break;
        }
    }

    MyAmmoMagazineCountSpinner.MaxValue = 200; // temp

    DisplayTab( ActiveTab );
    UpdateWeights();
}

private function DisplayTab(int tabNum)
{
    local int i;

    MyAmmoMagazineCountSpinner.MaxValue = 200; // temp

    for( i = 0; i < PocketTabs.Length; i++ )
    {
        if( i == tabNum )
        {
            PocketTabs[i].TabPanel.Show();
            PocketTabs[i].TabPanel.Activate();
            PocketTabs[i].TabButton.DisableComponent();

            ActivePocket = PocketTabs[i].CurrentPocket;
            ActiveAmmoPocket = PocketTabs[i].AmmoPocket;

            MyScrollAmmoLeftButton.SetVisibility( ActiveAmmoPocket != Pocket.Pocket_Invalid );
            MyScrollAmmoRightButton.SetVisibility( ActiveAmmoPocket != Pocket.Pocket_Invalid );
            MyScrollAmmoLeftButton.SetActive( ActiveAmmoPocket != Pocket.Pocket_Invalid );
            MyScrollAmmoRightButton.SetActive( ActiveAmmoPocket != Pocket.Pocket_Invalid );
            MyAmmoMagazineCountSpinner.SetActive(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyAmmoMagazineCountLabel.SetActive(ActiveAmmoPocket != Pocket.Pocket_Invalid);

            MyWeaponInfoBox.SetVisibility( ActiveAmmoPocket != Pocket.Pocket_Invalid );
            MyEquipmentInfoBox.SetVisibility( ActiveAmmoPocket == Pocket.Pocket_Invalid );

            //Advanced info is only for weapons
            MyAdvManufacturerTab.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyAdvCartridgeTab.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyAdvFiringTab.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentManufacturerLabel.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentCountryOfOriginLabel.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentProductionStartLabel.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentCaliberLabel.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentMagazineSizeLabel.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentTotalAmmoLabel.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentFireModesLabel.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentMuzzleVelocityLabel.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentRateOfFireLabel.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);

            MyAmmoImage.SetVisibility( ActiveAmmoPocket != Pocket.Pocket_Invalid );
            MyAmmoNameLabel.SetVisibility( ActiveAmmoPocket != Pocket.Pocket_Invalid );

            if( ActiveAmmoPocket != Pocket.Pocket_Invalid )
            {
                MyEquipmentImage.RePosition( 'Weapon', true );
                MyEquipmentNameLabel.RePosition( 'Weapon', true );
                MyScrollRightButton.RePosition( 'Weapon', true );
            }
            else
            {
                MyEquipmentImage.RePosition( 'Equipment', true );
                MyEquipmentNameLabel.RePosition( 'Equipment', true );
                MyScrollRightButton.RePosition( 'Equipment', true );
            }

            if( EquipmentSelectionButton[ActivePocket] != None )
            {
                InternalSelectorButtonOnClick( EquipmentSelectionButton[ActivePocket] );
            }
        }
        else
        {
            PocketTabs[i].TabPanel.Hide();
            PocketTabs[i].TabPanel.DeActivate();
            PocketTabs[i].TabButton.EnableComponent();
        }
    }
    UpdateIndex(ActivePocket);
    UpdateIndex(ActiveAmmoPocket);
    DisplayEquipment(ActiveAmmoPocket);
    DisplayEquipment(ActivePocket);
    UpdateWeights();
}

function DynamicLoadOutSpec GetCurrentLoadout()
{
    return MyCurrentLoadOut;
}

private function bool IsPocketDisplayedInActiveTab( Pocket pock )
{
    local int i;

    for( i = 0; i < PocketTabs[ActiveTab].DisplayablePockets.Length; i++ )
    {
        if( PocketTabs[ActiveTab].DisplayablePockets[i] == pock )
            return true;
    }

    return false;
}

defaultproperties
{
	FailedToValidate = -1
}
