// ====================================================================
//  Class:  GUI.GUILabel
//
//	GUIButton - The basic button class
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================
/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIButton extends GUITextComponent
        HideCategories(Menu,Object)
        Native;

var(GUIButton) config int Value "A value associated to this button";
		
function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	OnKeyEvent=InternalOnKeyEvent;
    OnXControllerEvent=InternalOnXControllerEvent;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
#if !IG_SWAT //swat does not want to process keyboard events on buttons
	if (key==0x0D && State==3)	// ENTER Pressed
	{
	    //dont use this button if in edit mode
	    if( !Controller.bDesignMode && MenuState != MSAT_Disabled ) 
		    OnClick(self);
		return true;
	}
#endif	
	return false;
}

function bool InternalOnXControllerEvent(byte Id, eXControllerCodes iCode)
{
	if (iCode==XC_Start)
    {
    	OnClick(Self);
        return true;
    }
    return false;
}

defaultproperties
{
	StyleName="STY_RoundButton"	
	bCaptureMouse=True
	bNeverFocus=true
	bTabStop=true
	WinHeight=0.04
	bMouseOverSound=true
	OnClickSound=CS_Click
	bDrawStyle=true
	TextAlign=TXTA_Center
}
