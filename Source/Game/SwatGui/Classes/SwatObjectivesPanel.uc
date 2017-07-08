// ====================================================================
//  Class:  SwatGui.SwatObjectivesPanel
//  Parent: GUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatObjectivesPanel extends SwatGUIPanel
     ;

import enum ObjectiveStatus from SwatGame.Objective;

var(SWATGui) private EditInline Config GUIMultiColumnListBox		MyObjectivesBox;

var(SWATGui) private config localized string     InProgressString;
var(SWATGui) private config localized string     CompletedString;
var(SWATGui) private config localized string     FailedString;

var(SWATGui) private config Color InProgressColor;
var(SWATGui) private config Color CompletedColor;
var(SWATGui) private config Color FailedColor;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

function InternalOnShow()
{
    UpdateObjectives();
    
    if( PlayerOwner().Level.NetMode != NM_Standalone )
        SetTimer( GC.MPPollingDelay, true );
}

event Timer()
{
    UpdateObjectives();
}

function UpdateObjectives()
{
    local MissionObjectives theObjectives;
    local int i;
    local SwatGameReplicationInfo SGRI;
	local class<Objective> ObjectiveClass;

    if( GC.CurrentMission == None )
        return;

    SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );
    
    // display objectives
    theObjectives = GC.CurrentMission.Objectives;

    MyObjectivesBox.Clear();
    
    if( SGRI == None )
        return;

	for( i = 0; i < SGRI.class.const.MAX_OBJECTIVES; ++i)
	{
		if( SGRI.ObjectiveNames[i] == "" )
			break;

		if( SGRI.ObjectiveHidden[i] == 1 )
			continue;

		MyObjectivesBox.AddNewRowElement( "Objective",, Localize( SGRI.ObjectiveNames[i], "Description", "Transient" ) ); 
        MyObjectivesBox.AddNewRowElement( "Status",, ObjectiveStatusToString(SGRI.ObjectiveStatus[i]) ); 
		MyObjectivesBox.PopulateRow();
	}
}

private function string ObjectiveStatusToString(ObjectiveStatus Status)
{
    switch Status
    {
        case ObjectiveStatus_InProgress:
            return MakeColorCode( InProgressColor ) $ InProgressString;

        case ObjectiveStatus_Completed:
            return MakeColorCode( CompletedColor ) $ CompletedString;

        case ObjectiveStatus_Failed:
            return MakeColorCode( FailedColor ) $ FailedString;

        default:
            assert(false);  //unexpected ObjectiveStatus
    }
}

defaultproperties
{
    WinLeft=0.05
    WinTop=0.21333
    WinHeight=0.66666
    WinWidth=0.875
    OnShow=InternalOnShow
    
    InProgressString="In Progress"
    CompletedString="Completed"
    FailedString="Failed"

	InProgressColor=(R=151,G=151,B=151,A=255)
	CompletedColor=(R=0,G=255,B=0,A=255)
	FailedColor=(R=255,G=0,B=0,A=255)
}