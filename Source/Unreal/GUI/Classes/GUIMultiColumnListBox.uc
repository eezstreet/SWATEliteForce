/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIMultiColumnListBox extends GUIListBoxBase
    HideCategories(Menu,Object)
	native;

cpptext
{
	void PreDraw(UCanvas* Canvas);
	void UpdateComponent(UCanvas* Canvas);
	int MouseOverColumnBorder();
	UGUIComponent* UnderCursor(FLOAT MouseX, FLOAT MouseY);
	UBOOL MousePressed(UBOOL IsRepeat);
	UBOOL MouseReleased();
}

var(MultiColumnListBox)   Editinline EditConst array<GUIMultiColumnList>	MultiColumnList "The Array of lists of data";
var(MultiColumnListBox)   config array<String>   ListNames  "Name of the lists to polulate this MCLB";
var(MultiColumnListBox)   config    int             ActiveIndex "Index of the active column";
var(MultiColumnListBox)   editconst int             ActiveRowIndex "Index of the active row";
var(MultiColumnListBox)   Editinline EditConst private  GUIButton ActiveButton;
var(MultiColumnListBox)   Editinline EditConst private  array<GUIListElem> ActiveRow;

var(MultiColumnListBox)   config	bool	        bResizable "If true, MultiColumnList box columns are resizable.";
var(MultiColumnListBox)   config    float           DragSpacing "Number of pixels of leeway allowed for column resizing";
var(DEBUG) editconst int ColumnBorder;

function OnConstruct(GUIController MyController)
{
    local int i;

    Super.OnConstruct(MyController);

    for( i = 0; i < ListNames.Length; i++ )
    {
        AddComponent( "GUI.GUIMultiColumnList", self.Name$"_"$ListNames[i]);
    }
}

//initializes the MultiColumnListBox
function InitComponent(GUIComponent MyOwner)
{
    local int i;
	Super.InitComponent(MyOwner);

    for( i = 0; i < ListNames.Length; i++ )
    {
        InitColumn( ListNames[i] );
    }

    ClearRow();
}

//initializes the given column
private function InitColumn( string ListName )
{
    local GUIMultiColumnList newList;
    newList=FindColumn( ListName, true );
    if( newList == None )
        newList = GUIMultiColumnList(AddComponent( "GUI.GUIMultiColumnList" ,self.Name$"_"$ListName, true));
    Assert( newList != None );

    newList.IndexID=MultiColumnList.Length;
    InitBaseList( newList.MCList );
    newList.MCList.OnChange=InternalOnChange;
    newList.MCList.OnAdjustTop=InternalOnAdjustTop;
    newList.MCList.SwapIndices=SwapMCLBIndices;
    newList.MCButton.OnClick=InternalOnClick;

    MultiColumnList[MultiColumnList.Length]=newList;

    if( ActiveIndex == newList.IndexID )
    {
        ActiveButton = newList.MCButton;
        SetActiveList( newList.MCList );
    }
}

//Sets the active column in the MultiColumnListBox
function SetActiveColumn( string theName, optional bool bExact )
{
    local GUIMultiColumnList column;
    column = FindColumn( theName, bExact );
    if( column == None )
        return;
    ActiveIndex = column.IndexID;
    ActiveButton = column.MCButton;
    SetActiveList( column.MCList );
}

//Get the column's list specified by the given header
function GUIList GetColumn( string Header )
{
    local GUIMultiColumnList GMCList;

    GMCList = FindColumn( Header );

    AssertWithDescription( GMCList != None, "Specified column \""$Header$"\" not found in "$self.name );

    return GMCList.MCList;
}

//modeled after FindComponent in GUIMultiComponent
private function GUIMultiColumnList FindColumn( string theName, optional bool bExact )
{
    local int i;

    for( i = 0; i < MultiColumnList.Length; i++ )
    {
        if( ( theName ~= string(MultiColumnList[i].Name) ) || ( !bExact && InStr(Caps(MultiColumnList[i].Name), Caps(theName)) >= 0 ) )
            return( MultiColumnList[i] );
    }
    return None;
}

//clears the entire MultiColumnListBox
function Clear()
{
    local int i;

    for( i = 0; i < MultiColumnList.Length; i++ )
    {
        MultiColumnList[i].MCList.Clear();
    }
}

//Handles clicking on a field in this MCLB
private function InternalOnClick(GUIComponent Sender)
{
    ActiveButton = GUIButton(Sender);
    ActiveIndex = GUIMultiColumnList(ActiveButton.MenuOwner).IndexID;
    if( MultiColumnList[ActiveIndex].bIgnoreHeader )
    {
        Click();
        return;
    }
    SetActiveList( MultiColumnList[ActiveIndex].MCList );

    if( GUIList(MyActiveList).bListIsDirty )
        GUIList(MyActiveList).Sort();
    else
        GUIList(MyActiveList).ReverseList();
    MyScrollBar.AlignThumb();
	Click();
}

//Handles changes to this MCLB
private function InternalOnChange(GUIComponent Sender)
{
    local int i, curTop;

    SetActiveList( GUIListBase(Sender) );
    ActiveRowIndex = GetIndex();
    curTop = MyActiveList.Top;
    for( i = 0; i < MultiColumnList.Length; i++ )
    {
        MultiColumnList[i].MCList.SetIndex( ActiveRowIndex, true, true );
        MultiColumnList[i].MCList.Top=curTop;
    }
    SetDirty();
	OnChange(Self);
}

//Handles scrolling in the MCLB
private function InternalOnAdjustTop(GUIComponent Sender)
{
    local int i, curTop;

    SetActiveList( GUIListBase(Sender) );
    curTop = MyActiveList.Top;
    for( i = 0; i < MultiColumnList.Length; i++ )
    {
        MultiColumnList[i].MCList.Top=curTop;
    }
}


//////////////////////////////////////////////////////////////////////
// Row Management
//////////////////////////////////////////////////////////////////////

function bool RowElementExists(string ColumnHeader, optional Object obj, optional string Str, optional int intData, optional bool bData)
{
  local int i;
  local GUIMultiColumnList Column;
  local GUIListElem Current;

  Column = FindColumn(ColumnHeader);
  if(Column == None)
  {
    return false;
  }

  for(i = 0; i < Column.MCList.Elements.Length; i++)
  {
    Current = Column.MCList.Elements[i];
    if(Str != "" && Current.ExtraStrData == Str) {
      return true;
    }
  }
  return false;
}

function AddNewRowElement( string ColumnHeader, optional Object obj, optional string Str, optional int intData, optional bool bData )
{
    AddRowElement( CreateElement( ColumnHeader, obj, Str, intData, bData ) );
}

function AddRowElement( GUIListElem theElem )
{
    local int i;

    for( i = 0; i < MultiColumnList.Length; i++ )
    {
        if( Controller.FixGUIComponentName(self.Name$"_"$theElem.Item) ~= String(MultiColumnList[i].Name) )
            ActiveRow[i]=theElem;
        else if( i == ActiveRow.Length )
            ActiveRow.Insert( i, 1 );
    }
}

//Clears the row's active data
function ClearRow()
{
    ActiveRow.Remove(0,ActiveRow.Length);

    //ensure the active row is large enough to hold all possible data
    ActiveRow[MultiColumnList.Length] = CreateElement( "" );
}

//returns the index the row was inserted at
function int PopulateRow( optional string DontReplaceHeader )
{
    local int i, rowIndex;
    local GUIMultiColumnList column;

    if( DontReplaceHeader != "" )
    {
        column = FindColumn( DontReplaceHeader );
        if( column != None )
        {
            i = column.MCList.FindElement( ActiveRow[column.IndexID] );
            if( i >= 0 )
                return i;
        }
    }

    // add w/ insertion sort
    rowIndex = MultiColumnList[ActiveIndex].MCList.AddElement( ActiveRow[ActiveIndex], false, true );
    if( rowIndex < 0 )
        return rowIndex;
    for( i = 0; i < MultiColumnList.Length; i++ )
    {
        if( i == ActiveIndex )
            continue;
        MultiColumnList[i].MCList.InsertElement( rowIndex, ActiveRow[i], false, true );
    }
    ClearRow();
    SetDirty();
    return rowIndex;
}

//////////////////////////////////////////////////////////////////////
// Sorting (bubble sort)
//////////////////////////////////////////////////////////////////////
private function SwapMCLBIndices( int indexA, int indexB )
{
    local int j;

    for( j = 0; j < MultiColumnList.Length; j++ )
    {
        MultiColumnList[j].MCList.Swap( indexA, indexB, j == ActiveIndex );
    }
}

//Sorts over the given column (or active column if none specified) maintaining row cohesion
function Sort(optional string byColumn)
{
    local int oldColumnIndex;
    //save old active column
    oldColumnIndex = ActiveIndex;
    //set the column to sort by
    SetActiveColumn( byColumn );
    //sort based on current column
    GUIList(MyActiveList).Sort();
    //restore old column
    SetActiveColumn( string(MultiColumnList[oldColumnIndex].Name), true );
}

defaultproperties
{
	bVisibleWhenEmpty=True
    ActiveRowIndex=-1
    DragSpacing=2.0
	bPropagateStyle=False
}
