// ====================================================================
//  Class:  SwatGui.SwatTimelinePanel
//  Parent: GUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatTimelinePanel extends SwatGUIPanel
     ;

//var(SWATGui) private EditInline Config array<GUIButton> MyTimeSelectors;
var(SWATGui) private EditInline Config GUITimeline Timeline;
var(SWATGui) private EditInline Config GUIListBox MyTimeline;
var(SWATGui) private EditInline Config GUIScrollTextBox MyExtendedTimeline;
var(SWATGui) private EditInline Config GUIImage     		MyInvalidImage;

var private bool bloading;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	
	MyTimeline.OnChange=TimeSelected;
}

function InternalOnShow()
{
    local int i;
    
    bloading=true;
    MyTimeline.Clear();
    Timeline.ClearPlot();
    
    for( i = 0; i < GC.CurrentMission.TimeLineTime.Length; i++ )
    {
        //add a line to serve as hotlink destination & long entry
        MyTimeline.List.Add(GC.CurrentMission.TimeLineTime[i] @ GC.CurrentMission.TimelineShortDescription[i],,GC.CurrentMission.TimeLineTime[i] @ GC.CurrentMission.TimelineLongDescription[i],i);
        Timeline.AddTimePlot(GC.CurrentMission.TimeLinePlot[i]);
    }
    
    bloading=false;
    MyTimeline.List.SetIndex(0);
}

event Show()
{
    Super.Show();
    MyInvalidImage.SetVisibility( GC.CurrentMission.CustomScenario != None );
}

function TimeSelected(GUIComponent Sender)
{
    if( bloading )
        return;

    MyExtendedTimeline.SetContent( MyTimeline.List.GetExtra() );
    Timeline.SelectPlot( MyTimeline.List.GetExtraIntData() );
}

defaultproperties
{
    OnShow=InternalOnShow
    
    WinLeft=0.05
    WinTop=0.21333
    WinHeight=0.66666
    WinWidth=0.875
}