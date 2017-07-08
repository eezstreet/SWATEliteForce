// ====================================================================
//	GUITabControl - This control has a number of tabs
/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUITabControl extends GUIMultiComponent
        HideCategories(Menu,Object)
        ;

struct sTabButtonPair
{
    var() config Editinline GUIButton TabHeader "The header button for this tab";
    var() config Editinline GUIPanel TabPanel "The tab";
};

var(GUITabControl) EditInline Config array<sTabButtonPair> MyTabs "The tabs for this tab control";
var(GUITabControl) EditInline Config sTabButtonPair InitialTab "The initial tab for this tab control";
var(GUITabControl) EditInline EditConst sTabButtonPair ActiveTab "The active tab for this tab control";
var(GUITabControl) EditInline Config bool bAlwaysUseInitialTabWhenShown "If true, will set the active tab to the initial tab every time this is shown";

////////////////////////////////////////////////////////////////////////
//  Initialization
////////////////////////////////////////////////////////////////////////
function InitComponent(GUIComponent MyOwner)
{
    local int i;
	Super.InitComponent(MyOwner);

    for( i = 0; i < MyTabs.Length; i++ )
    {
        MyTabs[i].TabHeader.OnClick = TabHeaderClick;
        MyTabs[i].TabHeader.bNeverFocus = false;
        MyTabs[i].TabHeader.bMaintainFocus = true;
    }
    ActiveTab=InitialTab;
}

////////////////////////////////////////////////////////////////////////
//  Standard Open/Close Event Handling
////////////////////////////////////////////////////////////////////////
event Show()
{
    local int i;
    
    if( bAlwaysUseInitialTabWhenShown )
        ActiveTab=InitialTab;
    
    Super.Show();
    
    for( i = 0; i < MyTabs.Length; i++ )
    {
        MyTabs[i].TabHeader.Show();
    }

    ActiveTab.TabPanel.Show();
}

event Hide()
{
    local int i;
    
    Super.Hide();

    for( i = 0; i < MyTabs.Length; i++ )
    {
        MyTabs[i].TabHeader.Hide();
    }

    ActiveTab.TabPanel.Hide();
}

event Activate()
{
    local int i;
    
    Super.Activate();
    
    for( i = 0; i < MyTabs.Length; i++ )
    {
        MyTabs[i].TabHeader.Activate();
    }

    ActiveTab.TabHeader.Focus();
    ActiveTab.TabPanel.Activate();
}

event DeActivate()
{
    local int i;
    
    Super.DeActivate();

    for( i = 0; i < MyTabs.Length; i++ )
    {
        MyTabs[i].TabHeader.DeActivate();
    }

    ActiveTab.TabHeader.EnableComponent();
    ActiveTab.TabPanel.DeActivate();
}

////////////////////////////////////////////////////////////////////////
//  Tab Header OnClick Delegate
////////////////////////////////////////////////////////////////////////
function TabHeaderClick(GUIComponent Sender)
{
    OpenTab(GUIButton(Sender));
}

////////////////////////////////////////////////////////////////////////
//  Open Tab
////////////////////////////////////////////////////////////////////////
overloaded function OpenTab( int index )
{
    InternalOpenTabPair(GetTab(index));
}

overloaded function OpenTab( GUIPanel Tab )
{
    InternalOpenTabPair(GetTabByPanel(Tab));
}

overloaded function OpenTab( GUIButton Header )
{
    InternalOpenTabPair(GetTabByHeader(Header));
}

function InternalOpenTabPair( sTabButtonPair theTab )
{
    ActiveTab.TabHeader.EnableComponent();
    ActiveTab.TabPanel.DeActivate();
    ActiveTab.TabPanel.Hide();
    
    theTab.TabPanel.Show();
    theTab.TabPanel.Activate();
    theTab.TabHeader.Focus();

    ActiveTab=theTab;
}


//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
// Dynamic Tab management
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

function sTabButtonPair CreateNewPair( string PanelClassName, string PanelName, string ButtonClassName, string ButtonName )
{
    local sTabButtonPair NewPair;
    
    NewPair.TabPanel = GUIPanel( AddComponent( PanelClassName, PanelName, true ) );
    NewPair.TabHeader = GUIButton( AddComponent( ButtonClassName, ButtonName, true ) );
    if( NewPair.TabHeader.Caption == "" )
        NewPair.TabHeader.SetCaption(ButtonName);
    
    return NewPair;
}

////////////////////////////////////////////////////////////////////////
//  Add Tab
////////////////////////////////////////////////////////////////////////
overloaded function AddTab( sTabButtonPair NewPair )
{
    AddTab( MyTabs.Length, NewPair );
}

overloaded function AddTab( int index, sTabButtonPair NewPair )
{
    if( index < 0 )
        return;
    MyTabs[index]=NewPair;
    NewPair.TabHeader.OnClick = TabHeaderClick;
    NewPair.TabHeader.bNeverFocus = false;
    NewPair.TabHeader.bMaintainFocus = true;
    NewPair.TabHeader.Show();
    NewPair.TabHeader.Activate();
}

overloaded function AddTab( string PanelClassName, string PanelName, string ButtonClassName, string ButtonName )
{
    AddTab( MyTabs.Length, PanelClassName, PanelName, ButtonClassName, ButtonName );
}

overloaded function AddTab( int index, string PanelClassName, string PanelName, string ButtonClassName, string ButtonName )
{
    AddTab( index, CreateNewPair( PanelClassName, PanelName, ButtonClassName, ButtonName ) );
}

overloaded function AddTab( GUIPanel Panel, GUIButton Header )
{
    AddTab( MyTabs.Length, Panel, Header );
}

overloaded function AddTab( int index, GUIPanel Panel, GUIButton Header )
{
    InternalAddTab( index, Panel, Header );
}

function InternalAddTab( int index, GUIPanel Panel, GUIButton Header )
{
    local sTabButtonPair NewPair;
    
    if( index < 0 )
        return;

    NewPair.TabPanel = GUIPanel(AppendComponent(Panel));
    NewPair.TabHeader = GUIButton(AppendComponent(Header));

    AddTab( index, NewPair );
}

////////////////////////////////////////////////////////////////////////
//  Remove Tab
////////////////////////////////////////////////////////////////////////
overloaded function RemoveTab( int index )
{
    RemoveComponent( MyTabs[index].TabHeader );
    RemoveComponent( MyTabs[index].TabPanel );
    MyTabs.Remove( index, 1 );
}

overloaded function RemoveTab( GUIPanel Panel )
{
    RemoveTab(GetTabIndexByPanel(Panel));
}

overloaded function RemoveTab( GUIButton Header )
{
    RemoveTab(GetTabIndexByHeader(Header));
}

////////////////////////////////////////////////////////////////////////
//  Get Tab
////////////////////////////////////////////////////////////////////////
function sTabButtonPair GetTab( int index )
{
    return MyTabs[index];
}

function sTabButtonPair GetTabByPanel( GUIPanel Panel )
{
    return MyTabs[GetTabIndexByPanel(Panel)];
}

function sTabButtonPair GetTabByHeader( GUIButton Header )
{
    return MyTabs[GetTabIndexByHeader(Header)];
}

////////////////////////////////////////////////////////////////////////
//  Get Tab Index
////////////////////////////////////////////////////////////////////////
function int GetTabIndexByPanel( GUIPanel Panel )
{
    local int i;
    
    for( i = 0; i < MyTabs.Length; i++ )
    {
        if( Panel == MyTabs[i].TabPanel )
        {
            return i;
        }
    }
}

function int GetTabIndexByHeader( GUIButton Header )
{
    local int i;
    
    for( i = 0; i < MyTabs.Length; i++ )
    {
        if( Header == MyTabs[i].TabHeader )
        {
            return i;
        }
    }
}

////////////////////////////////////////////////////////////////////////
//  Other Utilities
////////////////////////////////////////////////////////////////////////
function Clear()
{
    MyTabs.Remove( 0, MyTabs.Length );
}

function int Num()
{
    return MyTabs.Length;
}

function bool IsEmpty()
{
    return Num() == 0;
}

////////////////////////////////////////////////////////////////////////
//  Tab Alignment
//
//  Params:
//   AlignDirection - Direction to layout the buttons, defined in GUI.uc
//   ButtonsAlignedTopLeft - If true, buttons are aligned to the top or
//      the left of the panel; if false, to the bottom or the right
//   MaxButtonsPerRow - Maximum number of buttons to lay out in a single
//      row.  If there are more buttons than this, they will "wrap" to
//      additional rows as needed.
//   RowSize - Size of a row, in pixels.
//   RowSpacing - Number of pixels between rows of buttons.
//   ButtonSpacing - Number of pixels between buttons on the same row.
////////////////////////////////////////////////////////////////////////
function AlignTabs( eProgressDirection AlignDirection, bool ButtonsAlignedTopLeft, int MaxButtonsPerRow, float RowSize, float RowSpacing, float ButtonSpacing )
{
    local int i, NumRows;
    local float ButtonWidth, PanelWidth;
    local float ButtonHeight, PanelHeight;
    local float PanelTop;
    local float PanelLeft;
    
    if( MyTabs.Length == 0 )
        return;
    
    NumRows = ( (MyTabs.Length - 1) / MaxButtonsPerRow ) + 1;
    
    switch( AlignDirection )
    {
        case DIRECTION_LeftToRight:
        case DIRECTION_RightToLeft:
            PanelWidth=ClientBounds[2]-ClientBounds[0];
            PanelHeight=(ClientBounds[3]-ClientBounds[1]) - (float(NumRows) * RowSize);
            ButtonWidth=PanelWidth / float(MaxButtonsPerRow) - ButtonSpacing;
            ButtonHeight=RowSize-RowSpacing;

            PanelLeft=ClientBounds[0];
            if( ButtonsAlignedTopLeft )
                PanelTop=ClientBounds[1]+(ButtonHeight*NumRows);
            else
                PanelTop=ClientBounds[1];
            break;
        case DIRECTION_TopToBottom:
        case DIRECTION_BottomToTop:
            PanelWidth=ClientBounds[2]-ClientBounds[0] - (float(NumRows) * RowSize);
            PanelHeight=ClientBounds[3]-ClientBounds[1];
            ButtonWidth=RowSize-RowSpacing;
            ButtonHeight=PanelHeight / float(MaxButtonsPerRow) - ButtonSpacing;

            PanelTop=ClientBounds[1];
            if( ButtonsAlignedTopLeft )
                PanelLeft=ClientBounds[0]+(ButtonWidth*NumRows);
            else
                PanelLeft=ClientBounds[0];
            break;
    }
    
    for( i = 0; i < MyTabs.Length; i++ )
    {
        MyTabs[i].TabPanel.bScaled=false;
        MyTabs[i].TabPanel.WinLeft=PanelLeft;
        MyTabs[i].TabPanel.WinTop=PanelTop;
        MyTabs[i].TabPanel.WinWidth=PanelWidth;
        MyTabs[i].TabPanel.WinHeight=PanelHeight;

        MyTabs[i].TabHeader.bScaled=false;
        MyTabs[i].TabHeader.WinWidth=ButtonWidth;
        MyTabs[i].TabHeader.WinHeight=ButtonHeight;
        switch( AlignDirection )
        {
            case DIRECTION_LeftToRight:
                MyTabs[i].TabHeader.WinLeft=ClientBounds[0] + ((i%MaxButtonsPerRow)*(ButtonWidth+ButtonSpacing));
                if( ButtonsAlignedTopLeft )
                    MyTabs[i].TabHeader.WinTop=ClientBounds[1] + ((i/MaxButtonsPerRow)*(ButtonHeight+RowSpacing));
                else
                    MyTabs[i].TabHeader.WinTop=ClientBounds[3] - ((i/MaxButtonsPerRow+1)*(ButtonHeight+RowSpacing));
                break;
            case DIRECTION_RightToLeft:
                MyTabs[i].TabHeader.WinLeft=ClientBounds[0] + ((MaxButtonsPerRow - (i%MaxButtonsPerRow) - 1)*(ButtonWidth+ButtonSpacing));
                if( ButtonsAlignedTopLeft )
                    MyTabs[i].TabHeader.WinTop=ClientBounds[1] + ((i/MaxButtonsPerRow)*(ButtonHeight+RowSpacing));
                else
                    MyTabs[i].TabHeader.WinTop=ClientBounds[3] - ((i/MaxButtonsPerRow+1)*(ButtonHeight+RowSpacing));
                break;
            case DIRECTION_TopToBottom:
                MyTabs[i].TabHeader.WinTop=ClientBounds[1] + ((i%MaxButtonsPerRow)*(ButtonHeight+ButtonSpacing));
                if( ButtonsAlignedTopLeft )
                    MyTabs[i].TabHeader.WinLeft=ClientBounds[0] + ((i/MaxButtonsPerRow)*(ButtonWidth+RowSpacing));
                else
                    MyTabs[i].TabHeader.WinLeft=ClientBounds[2] - ((i/MaxButtonsPerRow+1)*(ButtonWidth+RowSpacing));
                break;
            case DIRECTION_BottomToTop:
                MyTabs[i].TabHeader.WinTop=ClientBounds[1] + ((MaxButtonsPerRow - (i%MaxButtonsPerRow) - 1)*(ButtonHeight+ButtonSpacing));
                if( ButtonsAlignedTopLeft )
                    MyTabs[i].TabHeader.WinLeft=ClientBounds[0] + ((i/MaxButtonsPerRow)*(ButtonWidth+RowSpacing));
                else
                    MyTabs[i].TabHeader.WinLeft=ClientBounds[2] - ((i/MaxButtonsPerRow+1)*(ButtonWidth+RowSpacing));
                break;
        }
    }
}

////////////////////////////////////////////////////////////////////////
//  DefProps
////////////////////////////////////////////////////////////////////////
defaultproperties
{
    PropagateVisibility=false
    PropagateActivity=false
    PropagateState=false
	RenderWeight=0.2
}