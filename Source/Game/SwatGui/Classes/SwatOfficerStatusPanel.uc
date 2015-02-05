// ====================================================================
//  Class:  SwatGui.SwatOfficerStatusPanel
//  Parent: GUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatOfficerStatusPanel extends SwatGUIPanel
     ;

var(SWATGui) private EditInline Config GUILabel ReynoldsStatusLabel;
var(SWATGui) private EditInline Config GUILabel GirardStatusLabel;
var(SWATGui) private EditInline Config GUILabel FieldsStatusLabel;
var(SWATGui) private EditInline Config GUILabel JacksonStatusLabel;

var() private config localized string IncapacitatedString;
var() private config localized string InjuredString;
var() private config localized string HealthyString;
var() private config localized string NotAvailable;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

function InternalOnShow()
{
	local Pawn OfficerIter;
    local string status;

    ReynoldsStatusLabel.SetCaption( NotAvailable );
    GirardStatusLabel.SetCaption( NotAvailable );
    FieldsStatusLabel.SetCaption( NotAvailable );
    JacksonStatusLabel.SetCaption( NotAvailable );

	// notify all of the AI Officers.
	for(OfficerIter = PlayerOwner().Level.pawnList; OfficerIter != None; OfficerIter = OfficerIter.nextPawn)
	{
	    if (OfficerIter.IsA('SwatOfficer'))
	    {  
		    status = GetStatusString( OfficerIter );

		    if( OfficerIter.IsA( 'OfficerRedOne' ) )
		    {
                ReynoldsStatusLabel.SetCaption( status );
		    }
		    else if( OfficerIter.IsA( 'OfficerRedTwo' ) )
		    {
                GirardStatusLabel.SetCaption( status );
		    }
		    else if( OfficerIter.IsA( 'OfficerBlueOne' ) )
		    {
                FieldsStatusLabel.SetCaption( status );
		    }
		    else if( OfficerIter.IsA( 'OfficerBlueTwo' ) )
		    {
                JacksonStatusLabel.SetCaption( status );
		    }
		    else
		        Assert( false );
        }
	}
}

private function string GetStatusString( Pawn officer )
{
    if( !officer.IsConscious() )
        return IncapacitatedString;
        
    if( officer.IsInjured() )
        return InjuredString;

    return HealthyString;
}

defaultproperties
{
    OnShow=InternalOnShow
    
    HealthyString="Healthy"
    InjuredString="[c=ff0000]Injured"
    IncapacitatedString="[c=ff0000][b]Incapacitated"
    NotAvailable="[c=ffffff][b]Not Available"
}