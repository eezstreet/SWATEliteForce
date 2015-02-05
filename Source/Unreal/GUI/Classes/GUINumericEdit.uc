// ====================================================================
//	Class: GUI. UT2NumericEdit
//
//  A Combination of an EditBox and 2 spinners
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

class GUINumericEdit extends GUIMultiComponent
        HideCategories(Menu,Object)
	Native;

cpptext
{
		void UpdateComponent(UCanvas* Canvas);
}

var   GUIEditBox MyEditBox;
var   GUISpinnerButton MyPlus;
var   GUISpinnerButton MyMinus;

var(GUINumericEdit) config  int 				Value "Value of this edit box";
var(GUINumericEdit) config  bool				bLeftJustified "Is the text left justified";
//TMC TODO make these 2 private
var(GUINumericEdit) config  int					MinValue "Minimum value allowed";
var(GUINumericEdit) config  int					MaxValue "Maximum value allowed";
var(GUINumericEdit) config  int					Step "Step to use for additive/subtractive increments";
var(GUINumericEdit) config  bool                bDisplayAsTime "If true, will convert the display string to a time display (assumes time entered in seconds)";
var(GUINumericEdit) config  bool                bReadOnly "If true, will not allow the user to edit this box";
var(GUINumericEdit) config  bool                bAlwaysShowMins "If true, will always display times less than a minute in the format 0:SS";
var(GUINumericEdit) config  bool                bAlwaysShowHours "If true, will always display times less than an hour in the format 0:MM:SS";

function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

	MyEditBox=GUIEditBox(AddComponent( "GUI.GUIEditBox" , self.Name$"_EditBox"));
	if( !bReadOnly )
	{
	    MyPlus=GUISpinnerButton(AddComponent( "GUI.GUISpinnerButton" , self.Name$"_Plus"));
	    MyMinus=GUISpinnerButton(AddComponent( "GUI.GUISpinnerButton" , self.Name$"_Minus"));
	}
}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	MyEditBox.SetText("");
	MyEditBox.bIntOnly=true;
	
	if( !bReadOnly )
	{
	    MyPlus.PlusButton=true;
	    MyMinus.PlusButton=false;
    }

	MyEditBox.OnChange = EditOnChange;
    if( bDisplayAsTime || bReadOnly )
        MyEditBox.bReadOnly = true;
	SetValue(Value);
	MyEditBox.OnKeyEvent = EditKeyEvent;

	CalcMaxLen();

	if( !bReadOnly )
	{
	    MyPlus.OnClick = SpinnerPlusClick;
	    MyPlus.SetFocusInstead(MyEditBox);
	    MyMinus.OnClick = SpinnerMinusClick;
	    MyMinus.SetFocusInstead(MyEditBox);
    }
}

function CalcMaxLen()
{
	local int digitcount,x;

	digitcount=1;
	x=10;
	while (x<=MaxValue)
	{
		digitcount++;
		x*=10;
	}

	MyEditBox.MaxWidth = DigitCount;
}

function SetMinValue(int inMin)
{
    MinValue = inMin;

    //change Value if it is no longer in [MinValue, MaxValue]
    SetValue(Value);
}

function SetMaxValue(int inMax)
{
    MaxValue = inMax;

    CalcMaxLen();

    //change Value if it is no longer in [MinValue, MaxValue]
    SetValue(Value);
}

function SetValue(int V, optional bool bForceCallbacks)
{
    local String TimeStr;
    local int hours, mins, secs;
    
	if (V<MinValue)
		V=MinValue;

	if (V>MaxValue)
		V=MaxValue;

    if (!bForceCallbacks && Value == V) return;

    Value = V;
    
    if( bDisplayAsTime )
    {
        hours = V/3600;
        mins = (V%3600)/60;
        secs = V%60;

        TimeStr = "" $ secs;

        if( bAlwaysShowMins || bAlwaysShowHours || mins > 0 || hours > 0 )
        {
            if( secs < 10 )
                TimeStr = "0" $ TimeStr;
            TimeStr = mins $ ":" $ TimeStr;
        }

        if( bAlwaysShowHours || hours > 0 )
        {
            if( mins < 10 )
                TimeStr = "0" $ TimeStr;
            TimeStr = hours $ ":" $ TimeStr;
        }
        
        MyEditBox.MaxWidth = Len(TimeStr);
        
        MyEditBox.SetText(TimeStr);
    }
    else
    	MyEditBox.SetText(""$V);
    	
    SetDirty();
    
    OnChange(self);
}

function SpinnerPlusClick(GUIComponent Sender)
{
	SetValue(Value + Step);
}

function SpinnerMinusClick(GUIComponent Sender)
{
	SetValue(Value - Step);
}

function bool EditKeyEvent(out byte Key, out byte State, float delta)
{
	if ( (key==0xEC) && (State==3) )
	{
		SpinnerPlusClick(none);
		return true;
	}

	if ( (key==0xED) && (State==3) )
	{
		SpinnerMinusClick(none);
		return true;
	}

	return MyEditBox.InternalOnKeyEvent(Key,State,Delta);
}

function EditOnChange(GUIComponent Sender)
{
    if( !bDisplayAsTime )
    	SetValue( int(MyEditBox.GetText()) );
}


defaultproperties
{
	Value=0
	Step=1
	bAcceptsInput=true;
	bLeftJustified=false;
	WinHeight=0.027344
	PropagateVisibility=true
    MaxValue=9999
    bAlwaysShowMins=true
}