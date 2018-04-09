// ====================================================================
//  Class:  SwatGui.SwatObjBriefingPanel
//  Parent: SwatGUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatObjBriefingPanel extends SwatGUIPanel
     ;

var(SWATGui) private EditInline Config GUIScrollTextBox		MyObjectivesBox;
var(SWATGui) private EditInline Config GUIScrollTextBox		MyBriefingBox;
var(SWATGui) private EditInline Config GUIImage     		MyInvalidImage;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

function InternalOnShow()
{
    local MissionObjectives theObjectives;
    local int i;
    local string displayString;

    // display objectives
    theObjectives = GC.CurrentMission.Objectives;

    displayString = "";
    for( i = 0; i < theObjectives.Objectives.length; i++ )
    {
        if( theObjectives.Objectives[i].IsHidden )
            continue;

        displayString = displayString $ ">" $ theObjectives.Objectives[i].Description $ "||";
    }

    MyObjectivesBox.SetContent( displayString );


    // display briefing
    displayString = "";
	if(GC.CurrentMission.CustomScenario != None && GC.CurrentMission.CustomScenario.UseCustomBriefing)
	{
		displayString = GC.CurrentMission.CustomScenario.GetCustomScenarioBriefing();
	}
	else
	{
		for( i = 0; i < GC.CurrentMission.BriefingText.Length; i++ )
	    {
	        displayString = displayString $ GC.CurrentMission.BriefingText[i] $ "|";
	    }
	}

    MyBriefingBox.SetContent( displayString );
}

event Show()
{
    Super.Show();

	MyInvalidImage.SetVisibility(GC.CurrentMission.CustomScenario != None && !GC.CurrentMission.CustomScenario.UseCustomBriefing && !GC.CurrentMission.CustomScenario.UseCampaignObjectives);
}

defaultproperties
{
    WinLeft=0.05
    WinTop=0.21333
    WinHeight=0.66666
    WinWidth=0.875
    OnShow=InternalOnShow
}
