/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIMultiColumnList extends GUIMultiComponent
    HideCategories(Menu,Object)
    Native
    ;

cpptext
{
	void PreDraw(UCanvas* Canvas);
	void UpdateComponent(UCanvas* Canvas);
}


var GUIList MCList;
var GUIButton MCButton; 
var(GUIMultiColumnList) config float ColumnWidth "Relative size of this column within parent";
var(GUIMultiColumnList) config float HeaderHeight "Pixel height of the header button for this column (at 1024x768)";
var(GUIMultiColumnList) config bool bIgnoreHeader "This list should never be active for sorting";
var(GUIMultiColumnList) EditConst int IndexID "What index number this is in MCLB array";

function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

    MCList = GUIList(AddComponent( "GUI.GUIList" ,self.Name$"_List"));
    MCButton = GUIButton(AddComponent( "GUI.GUIGFXButton" ,self.Name$"_Button"));
}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
    
    MCButton.bNeverFocus=true;
    MCButton.SetFocusInstead(MCList);
}

defaultproperties
{
    ColumnWidth=1.0
    HeaderHeight=20.0;
}
