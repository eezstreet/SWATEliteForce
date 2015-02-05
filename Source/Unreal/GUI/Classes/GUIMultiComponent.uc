// ====================================================================
//  Class:  GUI.GUIMultiComponent
//
//	GUIMultiComponents are collections of components that work together.
//  When initialized, GUIMultiComponents transfer all of their components
//	to the to the GUIPage that owns them.
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

class GUIMultiComponent extends GUIComponent
        HideCategories(Menu,Object)
		Native;

cpptext
{
		void PreDraw(UCanvas* Canvas);		// Do any size/postitioning
		void Draw(UCanvas* Canvas);			// Draw the component

		virtual void InitializeControls();	// Takes all GUIComponent members and assigns them to the controls array

		UGUIComponent* UnderCursor(FLOAT MouseX, FLOAT MouseY);

		UBOOL NativeKeyType(BYTE& iKey, TCHAR Unicode );					// A Key or Mouse button has pressed
		UBOOL NativeKeyEvent(BYTE& iKey, BYTE& State, FLOAT Delta );		// A Key/Mouse event occured

		UBOOL SpecialHit();

		UBOOL PerformHitTest(INT MouseX, INT MouseY);

		UBOOL MousePressed(UBOOL IsRepeat);					// The left mouse button was pressed
		UBOOL RightMousePressed();							// The right mouse button was pressed
		UBOOL MouseReleased();								// The mouse button was released

		UBOOL XControllerEvent(int Id, eXControllerCodes iCode);

}

var(GUIMultiComponent)	editinline EditConst	array<GUIComponent>		Controls "An Array of Components that make up this Control";
var(GUIMultiComponent)	editinline EditConst 	array<GUIComponent>		Components "An Array of Controls that can be tabbed to";
var(GUIMultiComponent) config bool				PropagateVisibility "Does changes to visibility propagate down the line";
var(GUIMultiComponent) config bool				PropagateActivity "Does changes to activity propagate down the line";
var(GUIMultiComponent) config editinline        array<ControlSpec>      ControlSpecs "Config-ed controls, Please add/remove using Ctrl+N & Ctrl+Delete in the GUI Editor";
var(GUIMultiComponent) config                   bool				    PropagateState "Does changes to MenuState propagate down the line";

////////////////////////////////////////////////////////////////////////////////
// Initialization of Component
////////////////////////////////////////////////////////////////////////////////
function native InitializeControls();

function OnConstruct(GUIController MyController)
{
	local int i;

    Super.OnConstruct(MyController);
    
    // load components from def props first
    InitializeControls();	// Build the Controls array
    
    // then load from ControlSpecs array    
    for(i=0;i<ControlSpecs.length;i++)
    {
        AddComponent( ControlSpecs[i].ClassName, ControlSpecs[i].ObjName );
    }
}


function InitComponent(GUIComponent MyOwner)
{
	local int i;

	Super.InitComponent(MyOwner);

    //double check controls array
	for (i=0;i<Controls.Length;i++)
	{
		if (Controls[i] == None)
		{
			log("Invalid control found in"@string(Class)$"!! (Control"@i$")",'GUI ERROR');
			Controls.Remove(i--,1);
			continue;
		}

        //if this is in fact the active component, ensure that all controls recognize it as their current owner
        Controls[i].MenuOwner=self;

		if( !Controls[i].bInited )
    		Controls[i].InitComponent(Self);
	}

    RemapComponents();
}


////////////////////////////////////////////////////////////////////////////////
// Sub Component Management (Creation, addition, and removal)
////////////////////////////////////////////////////////////////////////////////

// add the control to the dynamic config control array
// theName is the -partial- name for the object
// used by GUI Editor
event GUIComponent CreateControl( string theClass, string theName )
{
    local ControlSpec theSpec;
    local GUIComponent theNewComp;
    theName=self.Name$"_"$theName;
    theSpec.ClassName = theClass;
    theSpec.ObjName = theName;
    ControlSpecs[ControlSpecs.length]=theSpec;
    theNewComp = AddComponent( theClass, theName, true );
    OnChangeLayout();
    return theNewComp;
}


// remove the control from the dynamic config control array
// used by GUI Editor
event bool RemoveControl( GUIComponent Ctrl )
{
    local int i;
    local bool success;
    for( i=0; i<ControlSpecs.length; i++ )
    {
        if( ControlSpecs[i].ObjName == string(Ctrl.Name) )
        {
            ControlSpecs.Remove(i,1); 
            success = RemoveComponent( Ctrl );
            OnChangeLayout();
            return success;
        }
    }
    AssertWithDescription( false, "Could not remove component "$Ctrl );
    return false;
}

// attempts to find the specified component in the controls array of this component
event GUIComponent FindComponent( string theName, optional bool bExact, optional bool bAssert )
{
    local int i;
    for( i=0; i<Controls.length; i++ )
    {
        //disregard case
        if( ( theName ~= string(Controls[i].Name) ) || ( !bExact && InStr(Caps(Controls[i].Name), Caps(theName)) >= 0 ) )
            return( Controls[i] );
    }
    AssertWithDescription( !bAssert || bExact, "Failed to find (GUIComponent) " $ theName $ " in (" $ self.Class $ ") " $ self.Name);
    AssertWithDescription( !bAssert, "Failed to EXACTLY find (GUIComponent) " $ theName $ " in (" $ self.Class $ ") " $ self.Name);
    return None;
}

event GUIComponent AddComponent(string ComponentClass, optional string ComponentName, optional bool bInitNewComponent )
{
    local GUIComponent NewComp;

    //if one already exists with the current name for the current control, return it
    if(ComponentName == "" )
    {
        //no name passed in so construct a default one, based off of the class name
        ComponentName = self.Name$"_"$Right(ComponentClass,Len(ComponentClass)-InStr(ComponentClass,".")-1);
    }
    NewComp = FindComponent(ComponentName,true);
    if( NewComp != None )
        return NewComp;
    
    NewComp = Controller.CreateComponent( ComponentClass, ComponentName );

    if (NewComp!=None)
    {
        if( !NewComp.bInited && bInitNewComponent )
		NewComp.InitComponent(self);
	
        SetDirty();	
   	    return AppendComponent(NewComp);
    }

    log("GUIMultiComponent::AddComponent - Could not create component"@ComponentClass,'GUI');
	return none;
}

event GUIComponent InsertComponent(GUIComponent NewComp, int Index)
{
	if (Index < 0 || Index >= Controls.Length)
		return AppendComponent(NewComp);

	Controls.Insert(Index, 1);
	Controls[Index] = NewComp;
	RemapComponents();
	return NewComp;
}

event GUIComponent AppendComponent(GUIComponent NewComp)
{
	local int index;

    // Attempt to add it sorted in to the array.  The Controls array is sorted by
    // Render Weight.

    while (Index<Controls.Length)
    {
    	if (NewComp.RenderWeight < Controls[Index].RenderWeight)	// We found our spot
        {
			Controls.Insert(Index,1);
			break;
        }
        Index++;
    }

    // Couldn't find a spot, add it at the end
    Controls[Index] = NewComp;
	RemapComponents();
    return NewComp;
}

event bool RemoveComponent(GUIComponent Comp, optional bool bRemap)
{
	local int i;
    for (i=0;i<Controls.Length;i++)
    {
		if (Controls[i] == Comp)
        {
        	Controls.Remove(i,1);
        	Comp.Free();
        	if (bRemap)
	        	RemapComponents();
            return true;
        }
	}
	SetDirty();
    return false;
}


////////////////////////////////////////////////////////////////////////////////
// Radio Groups
////////////////////////////////////////////////////////////////////////////////
function SetRadioGroup( GUIRadioButton group )
{
	local int i;
    for (i=0;i<Controls.Length;i++)
    {
        Controls[i].SetRadioGroup( group );
    }
    Super.SetRadioGroup( group );
}


////////////////////////////////////////////////////////////////////////////////
// Utilities
////////////////////////////////////////////////////////////////////////////////
event int FindComponentIndex(GUIComponent Who)
{
	local int i;

	if (Who != None && Components.Length > 0)
    {
		for (i=0;i<Components.Length;i++)
        {
			if (Who==Components[i])
				return i;
    	}
    }
	return -1;
}

private function int FindControlIndex(GUIComponent Who)
{
	local int i;

	if (Who != None && Controls.Length > 0)
    {
		for (i=0;i<Controls.Length;i++)
        {
			if (Who==Controls[i])
				return i;
    	}
    }
	return -1;
}

//save the layout on this and all subcomponents
function SaveLayout(bool FlushToDisk)
{
    local int i;
    for( i = 0; i < Controls.length; i++ )
    {
        Controls[i].SaveLayout(false); // ckline: pass false to avoid flushing to disk, for speed
    }
    super.SaveLayout(FlushToDisk); 
}

//get the centerpoint of a component
function FindCenterPoint(GUIComponent What, out float X, out float Y)
{
	X = What.ActualLeft() + (What.ActualWidth()/2);
    Y = What.ActualTop() + (What.ActualHeight()/2);
}

//calculate the distance between components
function float FindDist(GUIComponent Source, GUIComponent Target)
{
	local float a,b;
    local float x[2],y[2];

    FindCenterPoint(Source,x[0],y[0]);
    FindCenterPoint(Target,x[1],y[1]);

  	a = abs(x[0]-x[1]);
    a = square(a);
    b = abs(y[0]-y[1]);
    b = square(b);

    return sqrt(a+b);
}

function bool TestControls(int Mode, int SourceIndex, int TargetIndex)
{
	local float sX1,sY1,sX2,sY2;
    local float tX1,tY1,tX2,tY2;

	if (SourceIndex==TargetIndex)
    	return false;

    if (Controls[TargetIndex].bNeverFocus)
    	return false;

	sX1 = Controls[SourceIndex].ActualLeft();
    sX2 = sX1 + Controls[SourceIndex].ActualWidth();
	sY1 = Controls[SourceIndex].ActualTop();
    sY2 = sY1 + Controls[SourceIndex].ActualHeight();

	tX1 = Controls[TargetIndex].ActualLeft();
    tX2 = tX1 + Controls[TargetIndex].ActualWidth();
	tY1 = Controls[TargetIndex].ActualTop();
    tY2 = tY1 + Controls[TargetIndex].ActualHeight();

    switch (mode)
    {
    	case 0 :	// Up
        	return (tY2 <= sY1);
            break;
        case 1 :	// Down
        	return (tY1 >= sY2);
            break;

        case 2 : 	// Left
        	return (tX2 <= sX1);
            break;
        case 3 :	// Right
        	return (tX1 >= sX2);
            break;
	}

    return false;
}

function MapControls()
{
	local int c,i,p;
    local float cd,dist;
    local GUIComponent Closest;

    for (c=0;c<Controls.Length;c++)
    {
    	if (!Controls[c].bNeverFocus)
        {

	        for (p=0;p<4;p++)
	        {
	            Closest = none;
	            if (Controls[c].LinkOverrides[p]!=None)
	                Controls[c].Links[p] = Controls[c].LinkOverrides[p];
	            else
	            {
	                for (i=0;i<Controls.Length;i++)
	                    if ( TestControls(p,c,i) )
	                    {
	                        dist = FindDist(Controls[c],Controls[i]);
	                        if ( (Closest == None) || (dist < cd) )
	                        {
	                            Closest = Controls[i];
	                            cd = dist;
	                        }
	                    }
	                Controls[c].Links[p] = Closest;
	            }
	        }
        }
    }
}


// RemapComponents - This sets the tab order for all the components on this page
event RemapComponents()
{
	local int i,j;

// Remove from 0 instead of 1, in case control was removed, and that control was components[0]
// Otherwise, get access nones
	if (Components.Length>0)
	 	Components.Remove(0,Components.Length);	// Clear the Component Array

	for (i=0;i<Controls.Length;i++)
    {
    	if (Controls[i].bTabStop)
        {
        	for (j=0;j<Components.Length;j++)
            	if ( Controls[i].TabOrder <= Components[j].TabOrder )
                    break;

			if (j < Components.Length)
				Components.Insert(j, 1);

			Components[j] = Controls[i];
         }
    }
    SetDirty();
}

////////////////////////////////////////////////////////////////////////////////
// Focusing 
////////////////////////////////////////////////////////////////////////////////
event TabControl( int offset )
{
	local int Index;
	Index = FindComponentIndex(Controller.FocusedControl);

    Index+=offset;

    // Find the next possible component
    while (Index<Components.Length)
    {
    	if (Components[Index].MenuState!=MSAT_Disabled && Components[Index].bVisible && !Components[Index].bNeverFocus)
    	{
        	Components[Index].Focus();
        	return;
        }
    	Index+=offset;
        if( Index >= Components.Length )
            Index = 0;
        else if( Index < 0 )
            Index = Components.Length-1;
    }
}

////////////////////////////////////////////////////////////////////////////////
// Propogation of state/activity/visibility
////////////////////////////////////////////////////////////////////////////////
event DisableComponent()
{
	local int i;
    Super.DisableComponent();
    if ( PropagateState )
        for (i=0;i<Controls.Length;i++)
    	    Controls[i].DisableComponent();
}

event EnableComponent()
    {
	local int i;
    Super.EnableComponent();
    if ( PropagateState )
	    for (i=0;i<Controls.Length;i++)
    	    Controls[i].EnableComponent();
}

event Show()
{
	local int i;
    Super.Show();
    if ( PropagateVisibility )
        for (i=0;i<Controls.Length;i++)
    	    Controls[i].Show();
}

event Hide()
{
	local int i;
    Super.Hide();
    if ( PropagateVisibility )
        for (i=0;i<Controls.Length;i++)
    	    Controls[i].Hide();
}

event Activate()
{
	local int i;
    Super.Activate();
    if ( PropagateActivity )
        for (i=0;i<Controls.Length;i++)
    	    Controls[i].Activate();
}

event DeActivate()
{
	local int i;
    Super.DeActivate();
    if ( PropagateActivity )
        for (i=0;i<Controls.Length;i++)
    	    Controls[i].DeActivate();
}

// This control is no longer needed
event Free( optional bool bForce ) 			
{
	local int i;
	
	if( bPersistent && !bForce )
	    return;
	    
    for (i=0;i<Controls.Length;i++)
    {
    	Controls[i].Free( bForce );
        Controls[i] = None;
    }
    for (i=0;i<Components.Length;i++)
    	Components[i] = None;

    Controls.Remove(0,Controls.Length);
    Components.Remove(0,Components.Length);

    Super.Free( bForce );
}


////////////////////////////////////////////////////////////////////////////////
// GUI Editor utilities
////////////////////////////////////////////////////////////////////////////////
//Reorder the components in the controls array based on their render weight
event ReorderComponents()
{
    local int i,j;
    
    for( i = 1; i < Controls.Length; i++ )
    {
        for( j = i-1; j >= 0; j-- )
        {
            if( Controls[i].RenderWeight < Controls[j].RenderWeight )
                SwapControlIndicies(i,j);
            else
                break;
        }
    }

    ReweightComponents();
}

//evenly space out the components' render weights
function ReweightComponents()
{
    local int i;

    for( i = 0; i < Controls.Length; i++ )
    {
        Controls[i].RenderWeight = (i+1)*(1.0/(float(Controls.Length+1)));
    }
    SetDirty();
}

//Move this component forward in the controls array 1 spot
event BringForward( GUIComponent Ctrl )
{
//log("[dkaplan] >>> BringForward"$Ctrl);
    //LogControls();
    InternalBringForward( Ctrl );
    ReweightComponents();
}

//Move this component backward in the controls array 1 spot
event BringBackward( GUIComponent Ctrl )
{
//log("[dkaplan] >>> BringBackward"$Ctrl);
    //LogControls();
    InternalBringBackward( Ctrl );
    ReweightComponents();
}

//Move this component to the front of the controls array
event BringToFront( GUIComponent Ctrl )
{
//log("[dkaplan] >>> BringToFront"$Ctrl);
    //LogControls();
    while( FindControlIndex( Ctrl ) < Controls.Length-1 )
    {
        InternalBringForward( Ctrl );
    }
    ReweightComponents();
}

//Move this component to the back of the controls array
event BringToBack( GUIComponent Ctrl )
{
//log("[dkaplan] >>> BringToBack"$Ctrl);
    //LogControls();
    while( FindControlIndex( Ctrl ) > 0 )
    {
        InternalBringBackward( Ctrl );
    }
    ReweightComponents();
}

private function InternalBringForward( GUIComponent Ctrl )
{
    local int index;
    index = FindControlIndex( Ctrl );
    SwapControlIndicies( index, index+1 );
    //LogControls();
}

private function InternalBringBackward( GUIComponent Ctrl )
{
    local int index;
    index = FindControlIndex( Ctrl );
    SwapControlIndicies( index, index-1 );
    //LogControls();
}

//swap the ordering of two components in the controls array
private function SwapControlIndicies( int x, int y )
{
    local GUIComponent temp;
//log("[dkaplan] Swapping Controls at indicies x = " $x$", y = "$y);
    if( x < 0 || y < 0 || x >= Controls.Length || y >= Controls.Length )
        return;
    temp = Controls[x];
    Controls[x] = Controls[y];
    Controls[y] = temp;
}

function LogControls()
{
    local int i;
    log("[dkaplan] Logging controls for "$self);
    for( i = 0; i < Controls.Length; i++ )
    {
        log("[dkaplan] ... Controls["$i$"] = "$Controls[i]);
    }
}

defaultproperties
{
//    bNeverFocus=true
	bTabStop=true
    PropagateVisibility=true
    PropagateActivity=true
    PropagateState=true
}