// ====================================================================
//  Class:  GUI.GUIList
//
//  The GUIList is a basic list component.   
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================
/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIList extends GUIVertList
        HideCategories(Menu,Object)
		Native;

cpptext
{
	void DrawItem(UCanvas* Canvas, INT Item, FLOAT X, FLOAT Y, FLOAT W, FLOAT H);
}

enum eSortType
{
    SORT_AlphaItem,  // Alphabetical sorting - based off of Item
    SORT_AlphaExtra, // Alphabetical sorting - based off of ExtraStrData
    SORT_Numeric,    // strictly numerical sorting - based off of ExtraIntData
    SORT_Bool,       // sort based off of whether the ExtraBoolData is true
    SORT_IP,         // treat the ExtraStrData as an ip and sort by ip
    SORT_Players,    // treat the ExtraStrData as a current/max string and sort by max, then current
};


var(GUIList) config eSortType TypeOfSort "Determines what type of sort to use for this list";
var(GUIList) config eListElemDisplay DisplayItem "Determines which element member will be shown in this list";
var(GUIList) EditConst bool bSortForward "If true, will sort forward, else will sort backwards";
var(GUIList) EditConst bool bListIsDirty "If true, the list may be unsorted";
var(GUIList) config bool bNeverSort "If true, the list should never be sorted";

var(GUIList) config  eTextAlign	TextAlign "How is text Aligned in the control";

var(GUIList) editinline editconst	    array<GUIListElem>	Elements;

// Used by Sort.
delegate bool CompareItem(GUIListElem ElemA, GUIListElem ElemB)
{
    return false;
}

delegate bool ElementsEqual(GUIListElem ElemA, GUIListElem ElemB)
{
    return false;
}

delegate SwapIndices( int indexA, int indexB )
{
    Swap( indexA, indexB, true );
}

//////////////////////////////////////////////////////////////////////
// Sorting (bubble sort)
//////////////////////////////////////////////////////////////////////
function Sort()
{
    local int i, j, curHead, prevIndex;
    local bool compare;
    if( bNeverSort || !bListIsDirty )
        return;
    prevIndex=Index;
    i = 0;
    j = 1;
    curHead = 1;
    while( curHead < Elements.Length )
    {
        compare = CompareItem( Elements[i], Elements[j] );
        if( bSortForward ) //handles sorting in reverse
            compare = !compare;
        if( compare )
        {
            i = curHead;
            j = i+1;
            curHead = j;
        }
        else
        {
            if( prevIndex == j )
                prevIndex = i;
            else if( prevIndex == i )
                prevIndex = j;
            SwapIndices( i, j );
            i--;
            j--;
            if( i < 0 )
            {
                i = curHead;
                j = i+1;
                curHead = j;
            }
        }
    }
    bListIsDirty = false;
    SetIndex(prevIndex);
}

//////////////////////////////////////////////////////////////////////
// Sorting (Reverse)
//////////////////////////////////////////////////////////////////////
function ReverseList()
{
    local int i, j, prevIndex;
    prevIndex=Index;
    for( i = 0; i < Elements.Length / 2; i++ ) 
    {
        j = Elements.Length - i - 1;
        if( prevIndex == j )
            prevIndex = i;
        else if( prevIndex == i )
            prevIndex = j;
        SwapIndices( i, j );
    }
    bSortForward = !bSortForward;
    SetIndex(prevIndex);
}

////////////////////////////////////////////////////////////////////////
// Init component
////////////////////////////////////////////////////////////////////////
function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
    
    switch (TypeOfSort)
    {
        case SORT_AlphaItem:
            CompareItem=AlphabeticalCompareItem;
            break;
        case SORT_AlphaExtra:
            CompareItem=AlphabeticalCompareExtra;
            break;
        case SORT_Numeric:
            CompareItem=NumericCompare;
            break;
        case SORT_Bool:
            CompareItem=BooleanCompare;
            break;
        case SORT_IP:
            CompareItem=IPCompare;
            break;            
        case SORT_Players:
            CompareItem=PlayersCompare;
            break;            
    }
    
    switch (DisplayItem)
    {
        case LIST_ELEM_Item:
            ElementsEqual=EqualsItem;
            break;
        case LIST_ELEM_ExtraData:
            ElementsEqual=EqualsObject;
            break;
        case LIST_ELEM_ExtraStrData:
            ElementsEqual=EqualsExtra;
            break;
        case LIST_ELEM_ExtraIntData:
            ElementsEqual=EqualsInt;
            break;
        case LIST_ELEM_ExtraBoolData:
            ElementsEqual=EqualsBool;
            break;            
    }
}

function bool AlphabeticalCompare( string ElemA, string ElemB )
{
    return ElemA > ElemB;
}

function bool AlphabeticalCompareItem( GUIListElem ElemA, GUIListElem ElemB )
{
    return AlphabeticalCompare( ElemA.Item, ElemB.Item );
}

function bool AlphabeticalCompareExtra( GUIListElem ElemA, GUIListElem ElemB )
{
    return AlphabeticalCompare( ElemA.ExtraStrData, ElemB.ExtraStrData );
}

function bool NumericCompare( GUIListElem ElemA, GUIListElem ElemB )
{
    return ElemA.ExtraIntData > ElemB.ExtraIntData;
}

function bool BooleanCompare( GUIListElem ElemA, GUIListElem ElemB )
{
    return !ElemA.ExtraBoolData && ElemB.ExtraBoolData;
}

function bool IPCompare( GUIListElem ElemA, GUIListElem ElemB )
{
    local int IPA, IPB;
    local string PortA, PortB, IPStrA, IPStrB;
    
    PortA = ElemA.ExtraStrData;
    PortB = ElemB.ExtraStrData;
    
    IPStrA = GetFirstField( PortA, ":" );
    IPStrB = GetFirstField( PortB, ":" );
    
    while( IPA == IPB && IPStrA != "" && IPStrB != "")
    {
        IPA = int(GetFirstField( IPStrA, "." ));
        IPB = int(GetFirstField( IPStrB, "." ));
    }
        
    return IPA > IPB ||
           ( IPA == IPB &&
             ( int(PortA) > int(PortB) ) );
}

function bool PlayersCompare( GUIListElem ElemA, GUIListElem ElemB )
{
    local int PlayersA, PlayersB, MaxPlayersA, MaxPlayersB;
    local string PlayerStrA, PlayerStrB;
    
    PlayerStrA = ElemA.ExtraStrData;
    PlayerStrB = ElemB.ExtraStrData;
    
    PlayersA = int(GetFirstField( PlayerStrA, "/" ));
    PlayersB = int(GetFirstField( PlayerStrB, "/" ));
    MaxPlayersA = int(PlayerStrA);
    MaxPlayersB = int(PlayerStrB);

    return MaxPlayersA > MaxPlayersB || 
           ( MaxPlayersA == MaxPlayersB && 
             ( PlayersA > PlayersB ) );
}


function bool EqualsItem(GUIListElem ElemA, GUIListElem ElemB)
{
    return ElemA.Item == ElemB.Item;
}

function bool EqualsObject(GUIListElem ElemA, GUIListElem ElemB)
{
    return ElemA.ExtraData == ElemB.ExtraData;
}

function bool EqualsExtra(GUIListElem ElemA, GUIListElem ElemB)
{
    return ElemA.ExtraStrData == ElemB.ExtraStrData;
}

function bool EqualsInt(GUIListElem ElemA, GUIListElem ElemB)
{
    return ElemA.ExtraIntData == ElemB.ExtraIntData;
}

function bool EqualsBool(GUIListElem ElemA, GUIListElem ElemB)
{
    return ElemA.ExtraBoolData == ElemB.ExtraBoolData;
}


// Accessor function for the items.

event string SelectedText( int offsetIndex )
{
    if( offsetIndex < 0 )
        offsetIndex = Index;
	if ( (offsetIndex >=0) && (offsetIndex <Elements.Length) )
    {
        switch (DisplayItem)
        {
            case LIST_ELEM_Item:
                return Elements[offsetIndex].item;
                break;
            case LIST_ELEM_ExtraData:
                if( Elements[offsetIndex].ExtraData != None )
                    return string(Elements[offsetIndex].ExtraData.Name);
                break;
            case LIST_ELEM_ExtraStrData:
                return Elements[offsetIndex].ExtraStrData;
                break;
            case LIST_ELEM_ExtraIntData:
                return string(Elements[offsetIndex].ExtraIntData);
                break;
            case LIST_ELEM_ExtraBoolData:
                return string(Elements[offsetIndex].ExtraBoolData);
                break;            
        }
    }
	return "";
}

function Add(string NewItem, optional Object obj, optional string Str, optional int intData, optional bool bData, optional bool bDontReplace, optional bool bDontReAlign )
{
    AddElement( CreateElement( NewItem, obj, Str, intData, bData ), bDontReplace, bDontReAlign );
}

function int AddElement( GUIListElem theElem, optional bool bDontReplace, optional bool bDontReAlign )
{
    local int i;
    local bool compare;
    if( !bNeverSort && !bListIsDirty )
    {
        //insertion sort
        for( i = 0; i < Elements.Length; i++ )
        {
            if( bDontReplace && ElementsEqual( Elements[i], theElem ) )
                return i;
            compare = CompareItem( theElem, Elements[i] );
            if( bSortForward ) //handles sorting in reverse
                compare = !compare;
            if( compare )
                return InsertElement( i, theElem, true, bDontReAlign );
            else if( i == Elements.Length-1 ) //handle the case where it sorts to the end of the list
                return InsertElement( Elements.Length, theElem, true, bDontReAlign );
        }
    }
    if( bDontReplace )
    {
        i = FindElement( theElem );
        if( i >= 0 )
            return i;
    }
    return InsertElement( Elements.Length, theElem, false, bDontReAlign );
}

function int InsertElement( int NewIndex, optional GUIListElem theElem, optional bool bInsertSorted, optional bool bDontReAlign )
{
    if( !bInsertSorted && Elements.Length > 0 )
        bListIsDirty = true;
	if ( (NewIndex<0) || (NewIndex>Elements.Length) )
        NewIndex = Elements.Length;
        
    Elements.Insert( NewIndex, 1 );
    Elements[NewIndex]=theElem;
    
	ItemCount=Elements.Length;
	
	if( bDontReAlign )
	{
	    if( bInsertSorted && NewIndex < Index )
	    {
	        Top++;
	        Index++;
    	    OnChange(self);
	    }
	}
	else
	{
    	SetIndex(NewIndex);
    }
    
	return NewIndex;
}

function Replace(int index, string NewItem, optional Object obj, optional string Str, optional int intData, optional bool bData)
{
    ReplaceElement( Index, CreateElement( NewItem, obj, Str, intData, bData ) );
}

function ReplaceElement( int index, GUIListElem theElem )
{
    bListIsDirty = true;
	if ( (index<0) || (index>=Elements.Length) )
		AddElement(theElem);
	else
		Elements[index]=theElem;
}		

function Insert(int index, string NewItem, optional Object obj, optional string Str, optional int intData, optional bool bData )
{
    InsertElement( index, CreateElement( NewItem, obj, Str, intData, bData ) );
}	

event Swap(int IndexA, int IndexB, optional bool bIsSorting)
{
	local GUI.GUIListElem elem;
    if( !bIsSorting )
        bListIsDirty = true;
        
	if ( (IndexA<0) || (IndexA>=Elements.Length) || (IndexB<0) || (IndexB>=Elements.Length) )
		return;

	elem = Elements[IndexA];
	Elements[IndexA] = Elements[IndexB];
	Elements[IndexB] = elem;
}
	
function string GetItemAtIndex(int i)
{
	if ((i<0) || (i>Elements.Length))
		return "";
		
	return Elements[i].Item;
}

function SetItemAtIndex(int i, string NewItem)
{
	if ((i<0) || (i>Elements.Length))
		return;
		
	Elements[i].Item = NewItem;
}

function object GetObjectAtIndex(int i)
{
	if ((i<0) || (i>Elements.Length))
		return None;
		
	return Elements[i].ExtraData;
}

function string GetExtraAtIndex(int i)
{
	if ((i<0) || (i>Elements.Length))
		return "";
		
	return Elements[i].ExtraStrData;
}

function SetExtraAtIndex(int i, string NewExtra)
{
	if ((i<0) || (i>Elements.Length))
		return;
		
	Elements[i].ExtraStrData = NewExtra;
}

function int GetExtraIntAtIndex(int i)
{
	if ((i<0) || (i>Elements.Length))
		return 0;
		
	return Elements[i].ExtraIntData;
}

function SetExtraIntAtIndex(int i, int NewExtra)
{
	if ((i<0) || (i>Elements.Length))
		return;
		
	Elements[i].ExtraIntData = NewExtra;
}

function GUIListElem GetAtIndex(int i)
{
    local GUIListElem nothing;
	if ((i<0) || (i>Elements.Length))
		return nothing;
    return Elements[i];
}  

function GUIListElem GetElement()
{
    local GUIListElem nothing;
	if ((Index<0) || (Index>Elements.Length))
		return nothing;
    return Elements[Index];
}  

function LoadFrom(GUIList Source, optional bool bClearFirst)
{
	local int i;

	if (bClearfirst)
		Clear();
	
	for (i=0;i<Source.Elements.Length;i++)
	{
		AddElement(Source.GetAtIndex(i));
	}
}

function Remove(int i, optional int Count)
{
	if (Count==0)
		Count=1;
		
	Elements.Remove(i, Count);

	ItemCount = Elements.Length;		
		
	if( i == 0 )
	    i = ItemCount;
	SetIndex(i-1);
    if( MyScrollBar != None )
	MyScrollBar.AlignThumb();
} 

function RemoveItem(string Item)
{
	local int i;

	// Work through array. If we find it, remove it (will reduce Elements.Length).
	// If we don't, move on to next one.
	i=0;
	while(i<Elements.Length)
	{
		if(Item ~= Elements[i].Item)
			Elements.Remove(i, 1);
		else
			i++;
	}

	ItemCount = Elements.Length;

	SetIndex(i-1);
    if( MyScrollBar != None )
	MyScrollBar.AlignThumb();
}

function Clear()
{
	Elements.Remove(0,Elements.Length);

	Super.Clear();
	
	bListIsDirty = false;
	OnChange(self);
}	

function string Get()
{
	if ( (Index<0) || (Index>=ItemCount) )
		return "";
	else
		return Elements[Index].Item;
}

function object GetObject()
{
	if ( (Index<0) || (Index>=ItemCount) )
		return none;
	else
		return Elements[Index].ExtraData;
}	

function string GetExtra()
{
	if ( (Index<0) || (Index>=ItemCount) )
		return "";
	else
		return Elements[Index].ExtraStrData;
}
	
function int GetExtraIntData()
{
	if ( (Index<0) || (Index>=ItemCount) )
		return 0;
	else
		return Elements[Index].ExtraIntData;
}
	
function bool GetExtraBoolData()
{
	if ( (Index<0) || (Index>=ItemCount) )
		return false;
	else
		return Elements[Index].ExtraBoolData;
}
	
function int FindElement(GUIListElem theElem)
{
	local int i;
	for (i=0;i<ItemCount;i++)
	{
        if( ElementsEqual( Elements[i], theElem ) )
            return i;
	}
	return -1;
}

function string find(string Text, optional bool bExact, optional bool bDontSetIndex, optional bool bDontReAlign )
{
	local int i;
	for (i=0;i<ItemCount;i++)
	{
		if (bExact)
		{
			if (Text == Elements[i].Item)
			{
				if( !bDontSetIndex )
    				SetIndex(i,false,bDontReAlign);
				return  Elements[i].Item;
			}
		}
		else
		{
			if (Text ~=  Elements[i].Item)
			{
				if( !bDontSetIndex )
    				SetIndex(i,false,bDontReAlign);
				return  Elements[i].Item;
			}
		}
	}
	return "";
}

// find an element by the 'extra' string
// only sets the index if it finds the string
// returns the string of the found item
function string FindExtra (string ExtraText, optional bool bExact, optional bool bDontSetIndex, optional bool bDontReAlign )
{
	local int i;
	for (i=0;i<ItemCount;i++)
	{
		if (bExact)
		{
			if (ExtraText == Elements[i].ExtraStrData)
			{
				if( !bDontSetIndex )
    				SetIndex(i,false,bDontReAlign);
				return Elements[i].Item;
			}
		}
		else
		{
			if (ExtraText ~=  Elements[i].ExtraStrData)
			{
				if( !bDontSetIndex )
    				SetIndex(i,false,bDontReAlign);
				return Elements[i].Item;
			}
		}
	}
	return "";
}

//returns the index of the found element
function int FindExtraIntData(int TheIntToFind, optional bool bDontSetIndex, optional bool bDontReAlign )
{
	local int i;
	for (i=0;i<ItemCount;i++)
	{
		if (TheIntToFind == Elements[i].ExtraIntData)
		{
			if( !bDontSetIndex )
    			SetIndex(i,false,bDontReAlign);
			return i;
		}
	}
	return -1;
}

defaultproperties
{
	bSortForward=True
	bListIsDirty=false
	bNeverSort=false
	TypeOfSort=SORT_AlphaItem
}
