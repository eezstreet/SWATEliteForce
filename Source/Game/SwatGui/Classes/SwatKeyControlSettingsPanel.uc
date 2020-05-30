// ====================================================================
//  Class:  SwatGui.SwatKeyControlSettingsPanel
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatKeyControlSettingsPanel extends SwatSettingsPanel
     ;

import enum eCommandCategory from SwatGame.SwatGUIConfig;

var(SWATGui) private EditInline Config GUIMultiColumnListBox    MyKeyBindingsBox;
var(SWATGui) private EditInline Config GUIButton                MyKeyChoose;

var(SWATGui) private EditInline Config array<GUIButton>         MyCategoryButtons;
var(SWATGui) private eCommandCategory LastCategory;

var() config           array<string>   CommandString;
var() config localized array<string>   LocalizedCommandString;
var() config array<eCommandCategory>   CommandCategory;

var(Debug) private array<string> RestrictedKeys; //keys which are restricted and cannot be remapped

var(SWATGui) private config int MaxKeysLength; //used to limit the number of keys that may be bound for display purposes

var() private config localized string ReMappingQuery;

var private int SelectedIndex;

function InitComponent(GUIComponent MyOwner)
{
    local int i;

	Super.InitComponent(MyOwner);

	MyKeyChoose.OnClick=InternalOnClick;

    for( i = 0; i < MyCategoryButtons.Length; i++ )
    {
        MyCategoryButtons[i].OnClick=CategorySelectorOnClick;
    }

	for( i = 0; i < MyKeyBindingsBox.MultiColumnList.Length; i++ )
    {
        MyKeyBindingsBox.MultiColumnList[i].MCList.OnDblClick=InternalOnClick;
    }

    MyKeyBindingsBox.OnChange=OnListSelectionChanged;
    SelectedIndex=-1;

    //RestrictKeys();
}

function SaveSettings()
{
    //no generic save needed for this panel
}

function LoadSettings()
{
    //no generic load needed for this panel
    LoadCategory( LastCategory );
}

private function RestrictKeys()
{
    local int i;
    local string newRestrictedKeys;

    for( i = 0; i < CommandString.Length; i++ )
    {
        //only load ones in this category
        if( CommandCategory[i] != COMCAT_Reserved )
            continue;

        newRestrictedKeys = PlayerOwner().ConsoleCommand("GETKEYFORBINDING"@CommandString[i]);

        while( newRestrictedKeys != "" )
        {
            RestrictedKeys[RestrictedKeys.Length] = GetFirstField( newRestrictedKeys, ", " );
        }
    }
}

private function LoadCategory( eCommandCategory Category )
{
    local int i;
    local string boundKeys;

    LastCategory=Category;
    MyKeyBindingsBox.Clear();

    for( i = 0; i < CommandString.Length; i++ )
    {
        //only load ones in this category
        if( CommandCategory[i] != Category )
            continue;

        boundKeys = PlayerOwner().ConsoleCommand("GETLOCALIZEDKEYFORBINDING"@CommandString[i]);

        if( boundKeys == "" )
            boundKeys = "----";

        MyKeyBindingsBox.AddNewRowElement( "Functions",,LocalizedCommandString[i],i);
        MyKeyBindingsBox.AddNewRowElement( "MappedKey",,boundKeys,i);
        MyKeyBindingsBox.PopulateRow( "Functions" );
    }

    MyKeyBindingsBox.SetActiveColumn( "Functions" );
    MyKeyBindingsBox.Sort();
    MyKeyBindingsBox.SetIndex(SelectedIndex);
    SelectedIndex=-1;

    //MyKeyBindingsBox.SetEnabled( Category != COMCAT_Reserved );

    for( i = 0; i < MyCategoryButtons.Length; i++ )
    {
        MyCategoryButtons[i].SetEnabled(i != Category);
    }
}

private function bool IsRestricted( string key )
{
    local int i;
    for( i = 0; i < RestrictedKeys.Length; i++ )
    {
//log( "Testing Restricted Keys: "$RestrictedKeys[i]$" vs "$key );
        if( RestrictedKeys[i] ~= key )
            return true;
    }
    return false;
}

function OnListSelectionChanged( GUIComponent Sender )
{
    MyKeyChoose.SetEnabled( /*LastCategory != COMCAT_Reserved &&*/ MyKeyBindingsBox.GetIndex() >= 0 );
}

function InternalOnClick( GUIComponent Sender )
{
    local string LocalizedFunc, Func, Bound;

    LocalizedFunc = MyKeyBindingsBox.GetColumn( "Functions" ).GetExtra();
    Func = CommandString[MyKeyBindingsBox.GetColumn( "Functions" ).GetExtraIntData()];
    Bound = MyKeyBindingsBox.GetColumn( "MappedKey" ).GetExtra();

    if( Func != "" )
        Controller.OpenMenu( "SwatGui.SwatKeyMappingPopup", "SwatKeyMappingPopup", FormatTextString( ReMappingQuery, LocalizedFunc, Bound ), Func, Len( Bound ) );
}

function InternalOnPopupReturned( GUIListElem returnObj, optional string Passback )
{
    //if the new key attempted is restricted, dont change
    if( IsRestricted( returnObj.ExtraStrData ) )
        return;

    //Update the MCLB
    SelectedIndex=MyKeyBindingsBox.GetIndex();

    //if this key is already mapped to this func, unmap it
    if( PlayerOwner().ConsoleCommand("KEYBINDING"@returnObj.ExtraStrData) == Passback )
        Passback = "";

    //ensure we have space to apply the new key binding
    if( Passback != "" && ( returnObj.ExtraIntData + Len(returnObj.ExtraStrData) ) >= MaxKeysLength )
        return;

    //map the new binding
    Controller.StaticExec("SET Input"@returnObj.ExtraStrData@Passback);
}

private function CategorySelectorOnClick( GUIComponent Sender )
{
    local int i;

    for( i = 0; i < MyCategoryButtons.Length; i++ )
    {
        if( MyCategoryButtons[i] == sender )
        {
            LoadCategory(eCommandCategory(i));
            return;
        }
    }
}

protected function ResetToDefaults()
{
    PlayerOwner().ConsoleCommand("REMOVEALLKEYBINDINGS");
    new class'SwatInputReset'( Controller );
    LoadCategory( LastCategory );
}

defaultproperties
{
    LastCategory=COMCAT_Movement
    MaxKeysLength=50

    ReMappingQuery="The current bindings for %1 are %2. Press a different key to add it to the list of bindings, or press a currently bound key to remove it from the bindings."
    ConfirmResetString="Are you sure that you wish to reset all key bindings to their defaults? This may take a few moments."
}
