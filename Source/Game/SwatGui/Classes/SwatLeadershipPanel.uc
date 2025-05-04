// ====================================================================
//  Class:  SwatGui.SwatLeadershipPanel
//  Parent: GUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatLeadershipPanel extends SwatGUIPanel
     ;

var(SWATGui) private EditInline Config GUIMultiColumnListBox MyLeadershipBonusBox;
var(SWATGui) private EditInline Config GUIMultiColumnListBox MyLeadershipPenaltyBox;
var(SWATGui) private EditInline Config GUILabel MyLeadershipBonusTotal;
var(SWATGui) private EditInline Config GUILabel MyLeadershipPenaltyTotal;
var(SWATGui) private EditInline Config GUILabel MyLeadershipTotal;
var(SWATGui) private EditInline Config GUILabel MyLeadershipRanking;
var(SWATGui) private EditInline Config GUILabel MyDifficultyLabel;

var(SWATGui) private config bool bInGame "If true, this is an in-game implementation";

var() private config localized string BonusFormatString;
var() private config localized string PenaltyFormatStringx;
var() private config localized string TotalString;
var() private config string TotalFormatString;
var() private config string NotMetDifficultyRequirementTotalFormatString;
var() private config localized string RankingFormatString;
var() private config localized string NoPenaltiesDeducted;
var() private config localized string MissionFailedRanking;
var() private config localized string DifficultyLabelString;

var() private config localized array<String> RankingStrings;
var() private config array<int>              RankingLevels;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

function InternalOnShow()
{
    UpdateProcedures();
    SetTimer( GC.MPPollingDelay, true );
}

event Timer()
{
    UpdateProcedures();
}

function UpdateProcedures()
{
    local Procedures theProcedures;
    local int i, score, bonusScore, penaltyScore, curValue;
    local string Rank;
    local SwatGameReplicationInfo SGRI;

    SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );
    
    theProcedures = SwatGuiController(Controller).Repo.Procedures;

    if( theProcedures == None )
        return;

    score = 0;
    bonusScore = 0;
    penaltyScore = 0;
    MyLeadershipBonusBox.Clear();
    if( MyLeadershipPenaltyBox != None )
        MyLeadershipPenaltyBox.Clear();

    if( SGRI == None )
        return;

    for( i = 0; i < theProcedures.Procedures.length; i++ )
    {
        if( bInGame && !theProcedures.Procedures[i].IsShownInObjectivesPanel )
            continue;
            
        curValue = SGRI.ProcedureValue[i];
        score += curValue;
        
// dkaplan - we want to show 0 score bonuses
//        if( ( theProcedures.Procedures[i].IsABonus && 
//              (curValue != 0 || theProcedures.Procedures[i].IsNeverHidden) ) ||
//              ( bInGame && theProcedures.Procedures[i].IsShownInObjectivesPanel ) )

        if( theProcedures.Procedures[i].IsABonus )
        {
            MyLeadershipBonusBox.AddNewRowElement( "Description",, theProcedures.Procedures[i].Description );    
            MyLeadershipBonusBox.AddNewRowElement( "Calculation",, SGRI.ProcedureCalculations[i] );  
            if( !bInGame )
                MyLeadershipBonusBox.AddNewRowElement( "Score",, curValue$"/"$SGRI.ProcedurePossible[i] );    
			MyLeadershipBonusBox.PopulateRow();
    
            bonusScore += curValue;
        }
        else if( (curValue != 0 || theProcedures.Procedures[i].IsNeverHidden) && MyLeadershipPenaltyBox != None)
        {
            MyLeadershipPenaltyBox.AddNewRowElement( "Description",, theProcedures.Procedures[i].Description );    
            MyLeadershipPenaltyBox.AddNewRowElement( "Calculation",, SGRI.ProcedureCalculations[i] );    
            if( !bInGame )
                MyLeadershipPenaltyBox.AddNewRowElement( "Score",,, curValue );    
			MyLeadershipPenaltyBox.PopulateRow();
    
            penaltyScore += curValue;
        }
    }

    if( bInGame )
    {
        if( MyLeadershipPenaltyBox != None )
            MyLeadershipPenaltyBox.Hide();
        if( MyLeadershipBonusTotal != None )
            MyLeadershipBonusTotal.Hide();
        if( MyLeadershipPenaltyTotal != None )
            MyLeadershipPenaltyTotal.Hide();
        if( MyLeadershipTotal != None )
            MyLeadershipTotal.Hide();
        if( MyLeadershipRanking != None )
            MyLeadershipRanking.Hide();
    }
    else
    {
        if( MyLeadershipPenaltyBox.Num() == 0 )
        {
            MyLeadershipPenaltyBox.AddNewRowElement( "Description",, NoPenaltiesDeducted );    
			MyLeadershipPenaltyBox.PopulateRow();
        }
        
        score = Max( score, 0 );
    
        MyLeadershipBonusTotal.SetCaption( FormatTextString( BonusFormatString, bonusScore ) );
        MyLeadershipPenaltyTotal.SetCaption( FormatTextString( PenaltyFormatStringx, penaltyScore ) );

        if( GC.CurrentMission.HasMetDifficultyRequirement() )
            MyLeadershipTotal.SetCaption( FormatTextString( TotalFormatString, TotalString, score ) );
        else
            MyLeadershipTotal.SetCaption( FormatTextString( NotMetDifficultyRequirementTotalFormatString, TotalString, score ) );

        if( GC.CurrentMission.IsMissionFailed() )
        {
            Rank = MissionFailedRanking;
        }
        else
        {
            for( i = 0; i < RankingStrings.Length; i++ )
            {
                if( score >= RankingLevels[i] )
                {
                    Rank = RankingStrings[i];
                    break;
                }
            }
        }
        
        MyLeadershipRanking.SetCaption( FormatTextString( RankingFormatString, Rank ) );
    }
    
    if( MyDifficultyLabel != None )
        MyDifficultyLabel.SetCaption( FormatTextString( DifficultyLabelString, GC.DifficultyScoreRequirement[int(GC.CurrentDifficulty)] ) );
}

defaultproperties
{
    OnShow=InternalOnShow
    
    TotalString="Total"
    BonusFormatString="%1"
    PenaltyFormatStringx="%1"
    TotalFormatString="[c=ffffff]%1: [c=00ff00]%2[c=ffffff]/100"
    NotMetDifficultyRequirementTotalFormatString="[c=ffffff]%1: [c=ff0000]%2[c=ffffff]/100"
    RankingFormatString="Ranking: %1"

    NoPenaltiesDeducted="No Penalties Deducted!"
    MissionFailedRanking="Failure!"
    DifficultyLabelString="Required score: %1"
}