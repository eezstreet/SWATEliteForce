// ====================================================================
//  Class:  SwatGui.SwatCreditsMenu
//  Parent: SwatGUIPage
//
//  Menu to display SWAT4 Credits.
// ====================================================================

class SwatCreditsMenu extends SwatGUIPage
     ;

var(SWATGui) private EditInline Config GUIButton		MyEscapeButton;

var(SWATGui) private EditInline Editconst array<GUILabel>  Credits;

var(CREDITS) private config float ScrollDelay;
var(CREDITS) private config float InitialDelay;
var(CREDITS) private config float RepeatDelay;
var(CREDITS) private config sDynamicPositionSpec InitialPlacement;
var(CREDITS) private config sDynamicPositionSpec FinalPlacement;

var(CREDITS) private int NextToStartScrolling;
var(CREDITS) private bool bTriggeredCreditsMusic;

function InitComponent(GUIComponent MyOwner)
{
    local int i;
    local Swat4Credits CreditObj;
        
    Super.InitComponent(MyOwner);

    MyEscapeButton.OnClick=InternalOnClick;
    
    CreditObj = new() class'Swat4Credits';

    assertWithDescription( CreditObj.CreditLines.Length == CreditObj.CreditLineStyles.Length, "The number of lines of credits specified in SwatCredits.ini does not match the number of styles!" );

    for( i = 0; i < CreditObj.CreditLines.Length; i++ )
    {
        Credits[i] = GUILabel(AddComponent("GUI.GUILabel",self.Name$"_"$i$"_Label",true));
        Assert( Credits[i] != None );
        Credits[i].SetCaption( CreditObj.CreditLines[i] );
        Credits[i].StyleName = CreditObj.CreditLineStyles[i];
        Credits[i].Style = Controller.GetStyle( CreditObj.CreditLineStyles[i] );

        Credits[i].MovePositions[0] = FinalPlacement;
        Credits[i].MovePositions[1] = InitialPlacement;
        Credits[i].RePosition( InitialPlacement.KeyName, true );
        Credits[i].OnRePositionCompleted = InternalOnRePositionCompleted;

        Credits[i].TextAlign = TXTA_Center;
        Credits[i].bAllowHTMLTextFormatting=true;
    }
}


private function InternalOnShow()
{
    if( Credits.Length < 1 )
        return;
    NextToStartScrolling = 0;
    bTriggeredCreditsMusic = false;
    SetTimer( InitialDelay );
}

private function InternalOnHide()
{
    local int i;
    
    for( i = 0; i < Credits.Length; i++ )
    {
        Credits[i].RePosition( InitialPlacement.KeyName, true );
    }
}

event Timer()
{
    if( !bTriggeredCreditsMusic && !bNeverTriggerEffectEvents && Style != None )
    {
        bTriggeredCreditsMusic = true;
        PlayerOwner().TriggerEffectEvent('UIMenuLoop',,,,,,,,Style.EffectCategory);
    }
    
    ScrollNext();
}

private function ScrollNext()
{
//log("ScrollingNext: " $ NextToStartScrolling);
    if( NextToStartScrolling >= Credits.Length )
    {
        ScrollingCompleted();
        return;
    }
    Credits[NextToStartScrolling].RePosition( FinalPlacement.KeyName );
    NextToStartScrolling++;
    SetTimer( ScrollDelay );
}

private function InternalOnRePositionCompleted( GUIComponent Sender, name NewPosLabel )
{
    if( NewPosLabel == FinalPlacement.KeyName )
        Sender.RePosition( InitialPlacement.KeyName, true );
}

private function ScrollingCompleted()
{
//log("ScrollingCompleted");
    NextToStartScrolling = 0;
    SetTimer( RepeatDelay );
}

////////////////////////////////////////////////////////////////////////////////////
// Component Management
////////////////////////////////////////////////////////////////////////////////////
private function InternalOnClick(GUIComponent Sender)
{
    Close();
}

private function Close()
{
    Controller.CloseMenu();
    Free( true );
}

////////////////////////////////////////////////////////////////////////////////////
// Component Cleanup
////////////////////////////////////////////////////////////////////////////////////
event Free( optional bool bForce ) 			
{
	local int i;
	
    for (i=0;i<Credits.Length;i++)
        Credits[i] = None;
    Credits.Remove(0,Credits.Length);

    MyEscapeButton=None;

    Super.Free( bForce );
}


defaultproperties
{
	OnShow=InternalOnShow
	OnHide=InternalOnHide
	
	ScrollDelay=1
	InitialDelay=1
	RepeatDelay=1

	StyleName="STY_CreditsMenu"
}