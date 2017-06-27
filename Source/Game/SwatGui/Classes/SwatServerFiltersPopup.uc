// ====================================================================
//  Class:  SwatGui.SwatServerFiltersPopup
//  Parent: SwatGuiPopup
//
//  Popup to select server filters.
// ====================================================================

class SwatServerFiltersPopup extends SwatGuiPopup
     ;

import enum EMPMode from Engine.Repo;

var(SWATGui) private EditInline Config GUICheckBoxButton	MyPingCheck;
var(SWATGui) private EditInline Config GUINumericEdit	    MyPingEdit;

var(SWATGui) private EditInline Config GUIComboBox	        MyGameTypeCombo;
var(SWATGui) private EditInline Config GUICheckBoxButton	MyGameTypeCheck;
var(SWATGui) private EditInline Config GUICheckBoxButton	MyPasswordedCheck;
var(SWATGui) private EditInline Config GUICheckBoxButton	MyFullCheck;
var(SWATGui) private EditInline Config GUICheckBoxButton	MyEmptyCheck;

var(SWATGui) private EditInline Config GUICheckBoxButton	MyHideIncompatibleVersionsCheck;
var(SWATGui) private EditInline Config GUICheckBoxButton	MyHideIncompatibleModsCheck;

function InitComponent(GUIComponent MyOwner)
{
	  Super.InitComponent(MyOwner);

    MyPingCheck.OnChange=InternalOnChange;
    MyGameTypeCheck.OnChange=InternalOnChange;

    MyGameTypeCombo.AddItem(GC.GetGameModeName(MPM_COOP));
    MyGameTypeCombo.AddItem(GC.GetGameModeName(MPM_COOPQMM));
}

function InternalOnActivate()
{
    MyPingEdit.SetValue( GC.theServerFilters.MaxPing, true );
    MyPingCheck.bForceUpdate = true;
    MyPingCheck.SetChecked( GC.theServerFilters.MaxPing >= 0 );

    MyGameTypeCombo.List.SetIndex( GC.theServerFilters.GameType );
    MyGameTypeCheck.bForceUpdate = true;
    MyGameTypeCheck.SetChecked( GC.theServerFilters.bFilterGametype );
    MyPasswordedCheck.SetChecked( GC.theServerFilters.bPassworded );
    MyFullCheck.SetChecked( GC.theServerFilters.bFull );
	MyEmptyCheck.SetChecked( GC.theServerFilters.bEmpty );

    MyHideIncompatibleVersionsCheck.SetChecked( GC.theServerFilters.bHideIncompatibleVersions );
    MyHideIncompatibleModsCheck.SetChecked( GC.theServerFilters.bHideIncompatibleMods );

#if IG_SWAT_MP_DEMO
    MyGameTypeCombo.DisableComponent();
    MyGameTypeCheck.DisableComponent();
#endif
}

protected function Confirm()
{
    if( MyPingCheck.bChecked )
        GC.theServerFilters.MaxPing = MyPingEdit.Value;
    else
        GC.theServerFilters.MaxPing = -1;

    GC.theServerFilters.GameType = EMPMode(MyGameTypeCombo.GetIndex());

    GC.theServerFilters.bFilterGametype = MyGameTypeCheck.bChecked;
    GC.theServerFilters.bPassworded = MyPasswordedCheck.bChecked;
    GC.theServerFilters.bFull = MyFullCheck.bChecked;
	GC.theServerFilters.bEmpty = MyEmptyCheck.bChecked;

    GC.theServerFilters.bHideIncompatibleVersions = MyHideIncompatibleVersionsCheck.bChecked;
    GC.theServerFilters.bHideIncompatibleMods = MyHideIncompatibleModsCheck.bChecked;

    GC.SaveConfig();
}

function InternalOnChange(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyPingCheck:
		    MyPingEdit.SetEnabled(MyPingCheck.bChecked);
            break;
		case MyGameTypeCheck:
		    MyGameTypeCombo.SetEnabled(MyGameTypeCheck.bChecked);
            break;
	}
}

defaultproperties
{
    OnActivate=InternalOnActivate
    Passback="Filters"
}
