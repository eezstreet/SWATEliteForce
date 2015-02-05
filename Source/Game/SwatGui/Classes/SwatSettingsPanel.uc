// ====================================================================
//  Class:  SwatGui.SwatSettingsPanel
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatSettingsPanel extends SwatGUIPanel
     Abstract;

var(SWATGui) protected EditInline Config GUIButton                MyResetToDefaultsButton;

var protected bool bLoadingSettings;

var() protected config localized string ConfirmResetString;

var() private config localized string ConfirmationTextSettingsChange;
var() private config int ConfirmationDialogDelayBeforeRevert "If the user does not confirm the change in settings within this amount of time, the settings will be reverted to their previous values.";

function LoadSettings();
function SaveSettings();

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	MyResetToDefaultsButton.OnClick=ConfirmReset;

    OnActivate=InternalOnActivate;
    OnDeActivate=InternalOnDeActivate;
}

function InternalOnActivate()
{
    bLoadingSettings=true;
    LoadSettings();
    bLoadingSettings=false;
    Controller.TopPage().OnPopupReturned=InternalOnPopupReturned;
}

function InternalOnDeActivate()
{
    SaveSettings();
}

final function ApplySetting( String Setting )
{
    InternalApplySetting( Setting );
    SaveSettings();
}

// Apply a potentially dangerous setting change (like screen resolution)
// that requires confirmation and/or auto-restoration of previous setting
// after a timeout or cancellation
final function ApplyDangerousSetting( String Passback, String Caption )
{
log("dkaplan >>> ApplyDangerousSetting( "$Passback$", "$Caption$")");

    // Open the confirmation dialog, passing the string that will restore the 
    // current settings if necessary (in the Passback string)
    Controller.TopPage().OnDlgReturned=InternalDlgReturned;
    Controller.TopPage().OpenDlg( Caption, QBTN_YesNo, "Confirm"$Passback );
}

// This is called whenever returning from a dialog that pops up as the result
// of pre- or post-confirming (or timing out of) a "dangerous" setting
final function InternalDlgReturned( int returnButton, optional string Passback )
{
log("dkaplan >>> InternalDlgReturned( "$returnButton$", "$Passback$")");
    if( (returnButton & QBTN_Cancel) != 0 ||
        (returnButton & QBTN_No) != 0 ||
        (returnButton & QBTN_TimeOut) != 0 )
    {
        // Re-load the saved settings and re-apply them to the GUI
        bLoadingSettings=true;
        LoadSettings();
        bLoadingSettings=false; 

        // If you're returning to this dialog because you hit cancel or the
        // dialog timed out, apply the "passback" string, which is the
        // string that will apply the previous settings
        if( InStr( Passback, "Test" ) >= 0 )
        {
            Passback = Right(Passback, ( Len(Passback) - 4 ) );
            InternalApplySetting( Passback, true );
        }
    }
    else // user clicked "ok" at confirmation dialog
    {
        AssertWithDescription( returnButton == QBTN_OK || returnButton == QBTN_Yes, "Return value "$returnButton$" from confirmation dialog was not valid in SwatVideoSettingsPanel.");
        
        // If "Confirm" is in the passback string, then we just came back from the 
        // Confirmation dialog as the result of clicking OK
        if( InStr( Passback, "Confirm" ) >= 0 )
        {
            // Apply the settings change that the user just confirmed
            Passback = Right(Passback, ( Len(Passback) - 7 ) );
            InternalApplySetting( Passback );
            Controller.TopPage().OnDlgReturned=InternalDlgReturned;
            Controller.TopPage().OpenDlg( ConfirmationTextSettingsChange, QBTN_YesNo, "Test"$Passback, ConfirmationDialogDelayBeforeRevert );
            return;
        }
        SaveSettings();
    }
}

function InternalOnPopupReturned( GUIListElem returnObj, optional string Passback );
function InternalApplySetting( string Setting, optional bool bDontSave );

private function ConfirmReset( GUIComponent Sender )
{
	Controller.TopPage().OnDlgReturned=InternalOnDlgReturned;
    Controller.TopPage().OpenDlg( ConfirmResetString, QBTN_YesNo, "" );
}

private function InternalOnDlgReturned( int Selection, String passback )
{
    if( Selection == QBTN_Yes )
    {
        ResetToDefaults();
    }
}

protected function ResetToDefaults();

defaultproperties
{
    WinLeft=0.05
    WinTop=0.21333
    WinHeight=0.66666
    WinWidth=0.875
    
    ConfirmResetString="Are you sure that you wish to reset these settings to their defaults? This may take a few moments."

    ConfirmationTextSettingsChange="Do you wish to keep these new settings?"
    ConfirmationDialogDelayBeforeRevert=10
}