// ====================================================================
//  Class:  SwatGui.SwatTestMenu
//  Parent: SwatCustomScenarioPageBase
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatTestMenu extends GUI.GUIPage
     ;

var(SWATGui) private EditInline GUITabControl		    TabControl;
var int Number;

function InitComponent(GUIComponent MyOwner)
{
 	Super.InitComponent(MyOwner);

    TabControl = GUITabControl(AddComponent("GUI.GUITabControl", self.Name$"_GUITabControl", true ));

    TabControl.WinLeft = 0.0;
    TabControl.WinTop = 0.0;
    TabControl.WinWidth = 1.0;
    TabControl.WinHeight = 1.0;
}

////////////////////////////////////////////////////////////////////////////////////
// Component Management
////////////////////////////////////////////////////////////////////////////////////
private function InternalOnActivate()
{
    SetTimer( 2.0, true );
}

event Timer()
{
    local bool bAddOne;
    local int i;

    bAddOne = FRand() > 0.5;

    for(i = Rand(10); i > 0; i-- )
    {
        if( TabControl.IsEmpty() || bAddOne )
            AddTab();
        else
            RemoveTab();
    }
    ReAlign();
}

function AddTab()
{
log( self$"::AddTab()" );
    TabControl.AddTab( "GUI.GUIPanel", "Tab"$Number$"Panel", "GUI.GUIButton", "Tab"$Number$"Header" );
    Number++;
}

function RemoveTab()
{
log( self$"::RemoveTab()" );
    TabControl.RemoveTab( Rand( TabControl.Num()-1 ) );
}

function ReAlign()
{
    local int dir, numPerRow;
    local float RowSpacing;
    local bool ButtonsAlignedTopLeft;
    
    dir = Rand( eProgressDirection.EnumCount - 1 );
    if( dir < 2 )
    {
        RowSpacing = 20.0;
        numPerRow = 10;
    }
    else
    {
        RowSpacing = 80.0;
        numPerRow = 30;
    }
    ButtonsAlignedTopLeft = FRand() > 0.5;
log( self$"::ReAlign() ... Dir = "$GetEnum(eProgressDirection,dir)$", ButtonsAlignedTopLeft = "$ButtonsAlignedTopLeft );
    TabControl.AlignTabs( eProgressDirection( dir ), ButtonsAlignedTopLeft, numPerRow, RowSpacing, 1.0, 2.0 );
}

defaultproperties
{
	OnActivate=InternalOnActivate
}