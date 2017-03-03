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
import enum WeaponEquipClass from Engine.SwatWeapon;
import enum WeaponEquipType from Engine.SwatWeapon;

var(SWATGui) protected EditInline Config GUIImage          MyEquipmentImage;
var(SWATGui) protected EditInline Config GUIImage          MyAmmoImage;
var(SWATGui) protected EditInline Config GUILabel          MyEquipmentNameLabel;
var(SWATGui) protected EditInline Config GUIScrollTextBox  MyWeaponInfoBox;
var(SWATGui) protected EditInline Config GUIScrollTextBox  MyEquipmentInfoBox;
var(SWATGui) protected EditInline Config GUIButton         MyScrollLeftButton;
var(SWATGui) protected EditInline Config GUIButton         MyScrollRightButton;

var(SWATGui) protected EditInline Config GUINumericEdit    MyAmmoMagazineCountSpinner;
var(SWATGui) protected EditInline Config GUILabel          MyAmmoMagazineCountLabel;

var(SWATGui) protected EditInline Config GUIComboBox       MyWeaponCategoryBox;
var(SWATGui) protected EditInline Config GUIComboBox       MyWeaponBox;
var(SWATGui) protected EditInline Config GUIComboBox       MyAmmoBox;

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
var(SWATGui) Config Localized array<String> EquipmentCategoryNames;


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

var() protected EditInline config WeaponEquipClass DefaultPrimaryClass;
var() protected EditInline config WeaponEquipClass DefaultSecondaryClass;

var protected array< class<SwatWeapon> > AllWeapons;           // All of the weapons that are available for picking, period
var protected array< class<SwatWeapon> > UnlockedWeapons;      // The weapons we have unlocked at this stage
var protected array< class<SwatWeapon> > CandidateWeapons;     // The weapons that match the category
var protected array<WeaponEquipClass> CachedAvailablePrimaryTypes; // A cache of primary weapon categories, so we don't need to rebuild this as frequently
var protected array<WeaponEquipClass> CachedAvailableSecondaryTypes; // A cache of secondary weapon categories, so we don't need to rebuild this as frequently
var protected array<string> AllAmmoNames;
var protected array< class<SwatAmmo> > AllAmmo;

// Extra Information panel for protection tab
var(SWATGui) protected EditInline config GUILabel AdvancedInfoHeadgearTitle;
var(SWATGui) protected EditInline config GUILabel AdvancedInfoBodyArmorTitle;
var(SWATGui) protected EditInline config GUILabel AdvancedInfoHeadgearRating;
var(SWATGui) protected EditInline config GUILabel AdvancedInfoHeadgearWeight;
var(SWATGui) protected EditInline config GUIScrollTextBox AdvancedInfoHeadgearSpecial;
var(SWATGui) protected EditInline config GUILabel AdvancedInfoBodyArmorRating;
var(SWATGui) protected EditInline config GUILabel AdvancedInfoBodyArmorWeight;
var(SWATGui) protected EditInline config GUIScrollTextBox AdvancedInfoBodyArmorSpecial;

var localized config string RatingString;
var localized config string WeightString;
var localized config string SpecialString;

var private int     ActiveTab;
var protected Pocket  ActivePocket;
var private Pocket  ActiveAmmoPocket;
var private int     FailedToValidate;
var private bool    SwitchedTabs;
var private bool    SwitchedWeapons;
var private bool    PopulatingAmmoInformation;

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
    MyAmmoMagazineCountSpinner.OnChange=MagazineCountChange;
    MyWeaponBox.OnChange=InternalComboBoxOnSelection;
    MyWeaponCategoryBox.OnChange=InternalComboBoxOnSelection;
    MyAmmoBox.OnChange=InternalComboBoxOnSelection;

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

    PopulateAllWeapons();

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

function PopulateAllWeapons()
{
  local int i, j;
  local class LoadedClass;
  local class<SwatWeapon> WeaponClass;
  local class<SwatAmmo> AmmoClass;

  AllAmmo.Length = 0;
  AllAmmoNames.Length = 0;
  AllWeapons.Length = 0;
  for(i = 0; i < GC.AvailableEquipmentPockets[0].EquipmentClassName.Length - 1; i++) {
    LoadedClass = class(DynamicLoadObject( GC.AvailableEquipmentPockets[0].EquipmentClassName[i], class'Class'));
    WeaponClass = class<SwatWeapon>(LoadedClass);
    AllWeapons[AllWeapons.Length] = WeaponClass;

    // Load the ammo as well
    for(j = 0; j < WeaponClass.default.PlayerAmmoOption.Length; j++) {
      AllAmmoNames[AllAmmoNames.Length] = WeaponClass.default.PlayerAmmoOption[j];
      LoadedClass = class(DynamicLoadObject(AllAmmoNames[AllAmmoNames.Length-1], class'Class'));
      AmmoClass = class<SwatAmmo>(LoadedClass);
      AllAmmo[AllAmmo.Length] = AmmoClass;
    }
  }
}

function PopulateUnlockedEquipment()
{
  local int i;
  local class<SwatWeapon> Weapon;

  UnlockedWeapons.Length = 0;
  for(i = 0; i < AllWeapons.Length; i++) {
    Weapon = AllWeapons[i];
    if(CheckCampaignValid(Weapon) && CheckValidity( GC.AvailableEquipmentPockets[0].Validity[i] ))
      UnlockedWeapons[UnlockedWeapons.Length] = Weapon;
  }
}

function InitialDisplay()
{
    local int i;

    for( i = 0; i < Pocket.EnumCount; i++ )
    {
	    if( !CheckValidity( GC.AvailableEquipmentPockets[i].DisplayValidity ) )
	    {
        continue;
      }

      UpdateIndex( Pocket(i) );

      DisplayEquipment( Pocket(i) );

    }

    CachedAvailablePrimaryTypes.Length = 0;
    CachedAvailableSecondaryTypes.Length = 0;
    PopulateUnlockedEquipment();
    DisplayTab(ActiveTab);
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

function bool CheckCampaignValid( class EquipmentClass )  //should be further subclassed
{
	return true;
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

    MyAmmoMagazineCountSpinner.MinValue = 1;
    MyAmmoMagazineCountSpinner.MaxValue = 200;

    if(thePocket == Pocket_PrimaryWeapon && ActivePocket == thePocket) {
      MyAmmoMagazineCountSpinner.SetValue(MyCurrentLoadOut.GetPrimaryAmmoCount());
    } else if(thePocket == Pocket_SecondaryWeapon && ActivePocket == thePocket) {
      MyAmmoMagazineCountSpinner.SetValue(MyCurrentLoadOut.GetSecondaryAmmoCount());
    }

    //set the current ammo for this loadout
    str = String(MyCurrentLoadOut.LoadOutSpec[OtherPocket].Name);
    EquipmentList[OtherPocket].Find( Str );

    UpdateWeights();
}

// change the Loadout for the selected pocket
function ChangeLoadOut( Pocket thePocket )
{
    local class<actor> theItem;

    if(thePocket == Pocket_PrimaryWeapon || thePocket == Pocket_SecondaryWeapon) {
      theItem = class<actor>(MyWeaponBox.GetObject());
    } else if(thePocket == Pocket_PrimaryAmmo || thePocket == Pocket_SecondaryAmmo) {
      theItem = class<actor>(MyAmmoBox.GetObject());
    } else {
      theItem = class<actor>(EquipmentList[thePocket].GetObject());
    }

    if(theItem == None) {
      return;
    }

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
    local class<ProtectiveEquipment> HeadgearClass;
    local class<ProtectiveEquipment> BodyArmorClass;


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
            EquipmentWeaponClass = class<SwatWeapon>(EquipmentList[Pocket.Pocket_PrimaryWeapon].GetObject());
            break;
        case Pocket_SecondaryWeapon:
        case Pocket_SecondaryAmmo:
            EquipmentWeaponClass = class<SwatWeapon>(EquipmentList[Pocket.Pocket_SecondaryWeapon].GetObject());
            break;
        case Pocket_HeadArmor:
        case Pocket_BodyArmor:
            HeadgearClass = class<ProtectiveEquipment>(EquipmentList[Pocket.Pocket_HeadArmor].GetObject());
            BodyArmorClass = class<ProtectiveEquipment>(EquipmentList[Pocket.Pocket_BodyArmor].GetObject());
            break;
        default:
            HeadgearClass = None;
            BodyArmorClass = None;
            EquipmentWeaponClass = None;
            break;
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

      MyWeaponCategoryBox.EnableComponent();
      MyWeaponBox.EnableComponent();
      MyAmmoBox.EnableComponent();
    } else {
      MyAmmoMagazineCountSpinner.SetVisibility(false);
      MyAmmoMagazineCountLabel.SetVisibility(false);

      MyWeaponCategoryBox.DisableComponent();
      MyWeaponBox.DisableComponent();
      MyAmmoBox.DisableComponent();
    }

    if(BodyArmorClass != None && HeadgearClass != None)
    {
      AdvancedInfoHeadgearRating.SetCaption(RatingString$HeadgearClass.static.GetProtectionRating());
      //AdvancedInfoHeadgearWeight.SetCaption(WeightString$HeadgearClass.static.GetWeight()$"kg");  // FIXME
      AdvancedInfoHeadgearSpecial.SetContent(SpecialString$HeadgearClass.static.GetSpecialProtection());
      AdvancedInfoBodyArmorRating.SetCaption(RatingString$BodyArmorClass.static.GetProtectionRating());
      //AdvancedInfoBodyArmorWeight.SetCaption(WeightString$string(BodyArmorClass.static.GetWeight())$"kg");  // FIXME
      AdvancedInfoBodyArmorSpecial.SetContent(SpecialString$BodyArmorClass.static.GetSpecialProtection());
    }

    switch(thePocket)
    {
        case Pocket_PrimaryWeapon:
        case Pocket_SecondaryWeapon:
            MyEquipmentImage.Image = Equipment.static.GetGUIImage();
            MyWeaponInfoBox.SetContent( Equipment.static.GetDescription() );
            break;
        case Pocket_PrimaryAmmo:
        case Pocket_SecondaryAmmo:
            MyAmmoImage.Image = Equipment.static.GetGUIImage();
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

    MyAmmoMagazineCountSpinner.MinValue = 1;
    MyAmmoMagazineCountSpinner.MaxValue = 200; // temp

    UpdateIndex(ActivePocket);
    DisplayEquipment(ActivePocket);
    UpdateWeights();
}

private function InternalComboBoxOnSelection(GUIComponent Sender)
{
  switch(Sender) {
    case MyWeaponCategoryBox:
      if(!SwitchedTabs) {
        RepopulateWeaponInformationForNewCategory(WeaponEquipClass(GUIComboBox(Sender).List.GetExtraIntData()));
      }
      break;
    case MyWeaponBox:
      SwitchedWeapons = true;

      if(ActiveTab == 0) {
          ActivePocket = Pocket_PrimaryWeapon;
          ActiveAmmoPocket = Pocket_PrimaryAmmo;
      } else {
          ActivePocket = Pocket_SecondaryWeapon;
          ActiveAmmoPocket = Pocket_SecondaryAmmo;
      }
      ChangeLoadOut(ActivePocket);
      RepopulateAmmoInformationForNewWeapon(class<SwatWeapon>(MyCurrentLoadout.LoadoutSpec[ActivePocket]));

      // If the cause of the change was due to a tab switch, then reset the ammo
      if(SwitchedTabs) {
        MyAmmoBox.List.FindObjectData(class<SwatAmmo>(MyCurrentLoadout.LoadoutSpec[ActiveAmmoPocket]), false, true);
      } else {
        ChangeLoadOut(ActiveAmmoPocket);
      }

      // Either way, we need to update the ammo display
      UpdateIndex(ActiveAmmoPocket);
      DisplayEquipment(ActiveAmmoPocket);

      SwitchedWeapons = false;
      break;
    case MyAmmoBox:
      if(PopulatingAmmoInformation) {
        break;
      }

      if(!SwitchedTabs && !SwitchedWeapons) {
        if(ActiveTab == 0) {
          ActivePocket = Pocket_PrimaryAmmo;
        } else {
          ActivePocket = Pocket_SecondaryAmmo;
        }
        ChangeLoadOut(ActivePocket);
      }
      else {
        if(ActiveTab == 0) {
          ActivePocket = Pocket_PrimaryWeapon;
          ChangeLoadOut(Pocket_PrimaryAmmo);
          UpdateIndex(Pocket_PrimaryAmmo);
          DisplayEquipment(Pocket_PrimaryAmmo);
        } else {
          ActivePocket = Pocket_SecondaryWeapon;
          ChangeLoadOut(Pocket_SecondaryAmmo);
          UpdateIndex(Pocket_SecondaryAmmo);
          DisplayEquipment(Pocket_SecondaryAmmo);
        }
        DisplayEquipment(ActivePocket);
      }
      break;
  }

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

    MyAmmoMagazineCountSpinner.MinValue = 1;
    MyAmmoMagazineCountSpinner.MaxValue = 200; // temp

    DisplayTab( ActiveTab );
    UpdateWeights();
}

// Update the categorization info. This is only done when switching tabs.
protected function UpdateCategorizationInfo(bool bPrimaryWeapon) {
  local class<SwatWeapon> CurrentWeapon;
  local class<SwatAmmo> CurrentAmmo;
  local WeaponEquipClass CurrentWeaponEquipClass;
  local int i, j;
  local int CategoryNum, WeaponNum;

  //log("Ascertain the weapon information...");
  if(bPrimaryWeapon) {
    CurrentWeapon = class<SwatWeapon>(MyCurrentLoadout.LoadoutSpec[0]);
    CurrentAmmo = class<SwatAmmo>(MyCurrentLoadout.LoadoutSpec[1]);
  } else {
    CurrentWeapon = class<SwatWeapon>(MyCurrentLoadout.LoadoutSpec[2]);
    CurrentAmmo = class<SwatAmmo>(MyCurrentLoadout.LoadoutSpec[3]);
  }
  CurrentWeaponEquipClass = CurrentWeapon.default.WeaponCategory;

  //log("Clear all of the combobox lists...");
  MyAmmoBox.Clear();
  MyWeaponCategoryBox.Clear();
  MyWeaponBox.Clear();

  //log("Easiest thing first: populate ammo box with the ammo choices...");
  RepopulateAmmoInformationForNewWeapon(CurrentWeapon);

  //log("Then, select the appropriate ammo type as the default...");
  MyAmmoBox.List.FindObjectData(CurrentAmmo, false, true);

  //log("Copy the list of unlocked weapons to the candidate...");
  CandidateWeapons.Length = 0;
  for(i = 0; i < UnlockedWeapons.Length; i++) {
    CandidateWeapons[CandidateWeapons.Length] = UnlockedWeapons[i];
  }

  if(!bPrimaryWeapon) {
    //log("Prune the candidate weapons so that primary weapons are not included in the secondary weapons list...");
    for(i = 0; i < CandidateWeapons.Length; i++) {
      if(CandidateWeapons[i].default.AllowedSlots == WeaponEquip_PrimaryOnly) {
        CandidateWeapons.Remove(i, 1);
        i--; // Step backwards so we don't get out of sync
      }
    }
  }

  //log("Rebuild cache and/or apply it...");
  if(bPrimaryWeapon && CachedAvailablePrimaryTypes.Length == 0) {
    for(i = 0; i < CandidateWeapons.Length; i++) {
      for(j = 0; j < CachedAvailablePrimaryTypes.Length; j++) {
        if(CandidateWeapons[i].default.WeaponCategory == CachedAvailablePrimaryTypes[j]) {
          break;
        }
      }
      if(j != CachedAvailablePrimaryTypes.Length) {
        // Don't readd the same element twice.
        continue;
      }
      CachedAvailablePrimaryTypes[CachedAvailablePrimaryTypes.Length] = CandidateWeapons[i].default.WeaponCategory;
      MyWeaponCategoryBox.AddItem(EquipmentCategoryNames[CandidateWeapons[i].default.WeaponCategory], , , CandidateWeapons[i].default.WeaponCategory);
    }
  } else if(!bPrimaryWeapon && CachedAvailableSecondaryTypes.Length == 0) {
    for(i = 0; i < CandidateWeapons.Length; i++) {
      for(j = 0; j < CachedAvailableSecondaryTypes.Length; j++) {
        if(CandidateWeapons[i].default.WeaponCategory == CachedAvailableSecondaryTypes[j]) {
          break;
        }
      }
      if(j != CachedAvailableSecondaryTypes.Length) {
        // Don't readd the same element twice.
        continue;
      }
      CachedAvailableSecondaryTypes[CachedAvailableSecondaryTypes.Length] = CandidateWeapons[i].default.WeaponCategory;
      MyWeaponCategoryBox.AddItem(EquipmentCategoryNames[CandidateWeapons[i].default.WeaponCategory], , , CandidateWeapons[i].default.WeaponCategory);
    }
  } else if(bPrimaryWeapon) {
    for(i = 0; i < CachedAvailablePrimaryTypes.Length; i++) {
      MyWeaponCategoryBox.AddItem(EquipmentCategoryNames[CachedAvailablePrimaryTypes[i]], , , CachedAvailablePrimaryTypes[i]);
    }
  } else if(!bPrimaryWeapon) {
    for(i = 0; i < CachedAvailableSecondaryTypes.Length; i++) {
      MyWeaponCategoryBox.AddItem(EquipmentCategoryNames[CachedAvailableSecondaryTypes[i]], , , CachedAvailableSecondaryTypes[i]);
    }
  }
  MyWeaponCategoryBox.List.Sort();

  //log("Update the list of weapons for the current category...");
  RepopulateWeaponInformationForNewCategory(CurrentWeaponEquipClass);

  //log("Set the selected weapon...");
  CategoryNum = MyWeaponCategoryBox.List.FindExtraIntData(CurrentWeaponEquipClass, false, true);
  WeaponNum = MyWeaponBox.List.FindObjectData(CurrentWeapon, false, true);

  if(CategoryNum == -1 || WeaponNum == -1) {
    // The equipment failed to validate. Try again.
    WeaponNum = 0;
    if(bPrimaryWeapon) {
      CurrentWeaponEquipClass = DefaultPrimaryClass;
    } else {
      CurrentWeaponEquipClass = DefaultSecondaryClass;
    }
    MyWeaponCategoryBox.List.FindExtraIntData(CurrentWeaponEquipClass, false, true);
    RepopulateWeaponInformationForNewCategory(CurrentWeaponEquipClass);
    MyWeaponBox.SetIndex(0);
    MyAmmoBox.SetIndex(0);
  }
}

// We have selected a new weapon category, reset the weapon list
protected function RepopulateWeaponInformationForNewCategory(WeaponEquipClass NewClass)
{
  local int i;
  local class<SwatWeapon> Weapon;

  MyWeaponBox.Clear();

  for(i = 0; i < CandidateWeapons.Length; i++) {
    Weapon = CandidateWeapons[i];
    if(Weapon.default.WeaponCategory != NewClass) {
      continue;
    }

    MyWeaponBox.AddItem(Weapon.static.GetFriendlyName(), Weapon);
  }

  MyWeaponBox.List.Sort();
}

// We have selected a new weapon, reset the ammo list
protected function RepopulateAmmoInformationForNewWeapon(class<SwatWeapon> TheNewWeapon)
{
  local int i, j;
  local class<SwatAmmo> Ammo;

  PopulatingAmmoInformation = true;

  MyAmmoBox.Clear();
  for(i = 0; i < TheNewWeapon.default.PlayerAmmoOption.Length; i++) {
    for(j = 0; j < AllAmmoNames.Length; j++) {
      if(AllAmmoNames[j] ~= TheNewWeapon.default.PlayerAmmoOption[i]) {
        Ammo = AllAmmo[j];
        break;
      }
    }
    if(Ammo == None) {
      log("ASSERTION FAILURE!! Ammo == None on weapon "$TheNewWeapon);
      assert(Ammo != None);
    }
    MyAmmoBox.AddItem(Ammo.static.GetFriendlyName(), Ammo);
    Ammo = None;
  }

  PopulatingAmmoInformation = false;
}

private function DisplayTab(int tabNum)
{
    local int i;

    MyAmmoMagazineCountSpinner.MinValue = 1;
    MyAmmoMagazineCountSpinner.MaxValue = 200; // temp

    SwitchedTabs = true;

    for( i = 0; i < PocketTabs.Length; i++ )
    {
        if( i == tabNum )
        {
            PocketTabs[i].TabPanel.Show();
            PocketTabs[i].TabPanel.Activate();
            PocketTabs[i].TabButton.DisableComponent();

            ActivePocket = PocketTabs[i].CurrentPocket;
            ActiveAmmoPocket = PocketTabs[i].AmmoPocket;

            MyAmmoBox.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyWeaponBox.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyWeaponCategoryBox.SetVisibility(ActiveAmmoPocket != Pocket.Pocket_Invalid);
            MyEquipmentNameLabel.SetVisibility(ActiveAmmoPocket == Pocket_Invalid);
            MyScrollLeftButton.SetVisibility(ActiveAmmoPocket == Pocket_Invalid);
            MyScrollRightButton.SetVisibility(ActiveAmmoPocket == Pocket_Invalid);

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

            // Protection information
            AdvancedInfoHeadgearTitle.SetVisibility(ActivePocket == Pocket.Pocket_BodyArmor || ActivePocket == Pocket.Pocket_HeadArmor);
            AdvancedInfoBodyArmorTitle.SetVisibility(ActivePocket == Pocket.Pocket_BodyArmor || ActivePocket == Pocket.Pocket_HeadArmor);
            AdvancedInfoHeadgearRating.SetVisibility(ActivePocket == Pocket.Pocket_BodyArmor || ActivePocket == Pocket.Pocket_HeadArmor);
            AdvancedInfoHeadgearWeight.SetVisibility(ActivePocket == Pocket.Pocket_BodyArmor || ActivePocket == Pocket.Pocket_HeadArmor);
            AdvancedInfoHeadgearSpecial.SetVisibility(ActivePocket == Pocket.Pocket_BodyArmor || ActivePocket == Pocket.Pocket_HeadArmor);
            AdvancedInfoBodyArmorRating.SetVisibility(ActivePocket == Pocket.Pocket_BodyArmor || ActivePocket == Pocket.Pocket_HeadArmor);
            AdvancedInfoBodyArmorWeight.SetVisibility(ActivePocket == Pocket.Pocket_BodyArmor || ActivePocket == Pocket.Pocket_HeadArmor);
            AdvancedInfoBodyArmorSpecial.SetVisibility(ActivePocket == Pocket.Pocket_BodyArmor || ActivePocket == Pocket.Pocket_HeadArmor);

            MyAmmoImage.SetVisibility( ActiveAmmoPocket != Pocket.Pocket_Invalid );

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

    if(ActiveAmmoPocket != Pocket_Invalid)
      UpdateCategorizationInfo(ActivePocket == Pocket_PrimaryWeapon);

      if(ActiveTab == 0)
      {
        LoadAmmoForWeapon(Pocket_PrimaryWeapon, class<FiredWeapon>(MyWeaponBox.GetObject()));
      }
      else if(ActiveTab == 1)
      {
        LoadAmmoForWeapon(Pocket_SecondaryWeapon, class<FiredWeapon>(MyWeaponBox.GetObject()));
      }

    SwitchedTabs = false;
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

  EquipmentCategoryNames[0]="Assault Rifles"
  EquipmentCategoryNames[1]="Marksman Rifles"
  EquipmentCategoryNames[2]="Submachine Guns"
  EquipmentCategoryNames[3]="Shotguns"
  EquipmentCategoryNames[4]="Light Machine Guns"
  EquipmentCategoryNames[5]="Machine Pistols"
  EquipmentCategoryNames[6]="Pistols"
  EquipmentCategoryNames[7]="Less Lethal"
  EquipmentCategoryNames[8]="Grenade Launchers"
  EquipmentCategoryNames[9]="Uncategorized"

  DefaultPrimaryClass=WeaponClass_AssaultRifle
  DefaultSecondaryClass=WeaponClass_Pistol

  RatingString="NIJ 0101.05 Rating: "
  WeightString="Weight: "
  SpecialString="Extra Protection: "
}
