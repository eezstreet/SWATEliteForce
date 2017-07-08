// ====================================================================
//  Class:  SwatGui.SwatIntroMenu
//  Parent: SwatGUIPage
//
//  Menu to display SWAT4 Credits.
// ====================================================================

class SwatIntroMenu extends SwatGUIPage
     ;

var(SWATGui) private EditInline Config GUIButton		MyEscapeButton;

// GuiComponents do not properly fade generic Materials, only Textures. 
// What this hack does is prevent the GuiImages from being rendered at
// all when they are not visible (instead of being rendered at alpha 0)
// so that the GuiImages using Materials don't bleed over top of the 
// other materials in the sequence.
#define HACK_SUPPORT_MATERIALS_IN_GUIIMAGES 1

struct IntroComponent
{
    var() config GUIComponent Component;
    var() config string MovieName;
    var() config int MovieWidth;
    var() config int MovieHeight;
    var() config bool bCanNotBeSkipped;
};

var(SWATGui) private EditInline Config array<IntroComponent>  IntroComponents;

var private int CurrentComponentIndex;
var private bool bWaitForMovieCompletion;
var private int numTicksElapsed;
var private int OldResX, OldResY;

function InitComponent(GUIComponent MyOwner)
{
 	Super.InitComponent(MyOwner);

    MyEscapeButton.OnClick=InternalOnClick;
}

function SetupComponents()
{
    local int i;
        
    for( i = 0; i < IntroComponents.Length; i++ )
    {
        if( IntroComponents[i].Component == None )
            continue;
            
        IntroComponents[i].Component.bRepeatCycling = false;
        IntroComponents[i].Component.CyclePosition = -1;
        IntroComponents[i].Component.RePosition( 'Initial', true );
        IntroComponents[i].Component.OnRePositionCompleted = InternalOnRePositionCompleted;
        IntroComponents[i].Component.bHideMouseCursor=true;

#if HACK_SUPPORT_MATERIALS_IN_GUIIMAGES
        //log("SetupComponents: Changing "$IntroComponents[i].Component.Name$".bCanBeShown from "$IntroComponents[i].Component.bCanBeShown);
        IntroComponents[i].Component.bCanBeShown=false;
        IntroComponents[i].Component.Hide();
        //log("        to "$IntroComponents[i].Component.bCanBeShown);
#endif
    }

    CurrentComponentIndex = -1;
}


private function InternalOnShow()
{
    SetupComponents();

    numTicksElapsed = 0;
    SetTimer( 0.01, true );
}

function StartNextComponent()
{
    StopComponent( CurrentComponentIndex );
    
    CurrentComponentIndex++;
    
    if( CurrentComponentIndex == IntroComponents.Length )
        Close();

    StartComponent( CurrentComponentIndex );
}

function StartComponent( int index )
{
    if( index < 0 || index > IntroComponents.Length )
        return;
        
    if( IntroComponents[index].Component != None )
    {
#if HACK_SUPPORT_MATERIALS_IN_GUIIMAGES
        //log("StartComponent: Changing "$IntroComponents[index].Component.Name$".bCanBeShown from "$IntroComponents[index].Component.bCanBeShown);
        IntroComponents[index].Component.bCanBeShown=true;
        IntroComponents[index].Component.Show();
        //log("        to "$IntroComponents[index].Component.bCanBeShown);
#endif

        IntroComponents[index].Component.Reposition( 'Show' );
    }
        
    if( IntroComponents[index].MovieName != "" )
    {
        log("Starting movie '"$IntroComponents[index].MovieName$"', WinWidth: "$Controller.ResolutionX$", WinHeight: "$Controller.ResolutionY);
        PlayerOwner().MyHud.PlayMovieDirect( IntroComponents[index].MovieName, 
                                             (400) - (IntroComponents[index].MovieWidth/2), 
                                             (300) - (IntroComponents[index].MovieHeight/2), 
                                             true, false );
        WaitForMovieCompletion();
    }
}

function StopComponent( int index )
{
    if( index < 0 || index > IntroComponents.Length )
        return;
    
    if( IntroComponents[index].Component != None )
    {
        IntroComponents[index].Component.Reposition( 'Final' );

#if HACK_SUPPORT_MATERIALS_IN_GUIIMAGES
        //log("StopComponent: Changing "$IntroComponents[index].Component.Name$".bCanBeShown from "$IntroComponents[index].Component.bCanBeShown);
        IntroComponents[index].Component.bCanBeShown=false;
        IntroComponents[index].Component.Hide();

        // This hack makes the baby Jesus cry.
        if (IntroComponents[index].Component.Name == 'SwatIntroMenu_IGIntro')
        {
			// Prevent this image from rendering any more, in any possible way!
            //log("    ***Hiding the image for "$IntroComponents[index].Component.Name$" altogether");
            GuiImage(IntroComponents[index].Component).Image=None;
            IntroComponents[index].Component=None;
        }

        //log("        to "$IntroComponents[index].Component.bCanBeShown);
#endif
    }

    if( IntroComponents[index].MovieName != "" )
    {
        log ( "Stopping movie '"$IntroComponents[index].MovieName$"'" );
        PlayerOwner().MyHud.StopMovie();
    }

    bWaitForMovieCompletion = false;    
    KillTimer();
}

private function InternalOnRePositionCompleted( GUIComponent Sender, name NewPosLabel )
{
    if( NewPosLabel == 'Show' )
    {
        Sender.Reposition( 'Wait' );
    }
    else if( NewPosLabel == 'Wait' )
    {
        StartNextComponent();
    }
}

function WaitForMovieCompletion()
{
    bWaitForMovieCompletion = true;
    SetTimer( 0.5, true );
}

event Timer()
{
    //If one is playing, See if the current movie has finished
    if( bWaitForMovieCompletion && !PlayerOwner().MyHud.IsMoviePlaying() )
    {
        StartNextComponent();
    }
    //wait a few ticks before starting
    else if( NumTicksElapsed < 6 ) 
    {
        NumTicksElapsed++;
        
        if( NumTicksElapsed > 5 )
        {
            StartNextComponent();
        
            Controller.GetGuiResolution();
            OldResX = Controller.ResolutionX;
            OldResY = Controller.ResolutionY;

            Controller.ConsoleCommand( "rmode 1" );
            Controller.ConsoleCommand( "setres 800x600" );
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////
// Component Management
////////////////////////////////////////////////////////////////////////////////////
private function InternalOnClick(GUIComponent Sender)
{
    if( !IntroComponents[CurrentComponentIndex].bCanNotBeSkipped )
        StartNextComponent();
}

function PerformClose()
{
    if( !IntroComponents[CurrentComponentIndex].bCanNotBeSkipped )
        StartNextComponent();
}

private function Close()
{
    if ( PlayerOwner().MyHud.IsMoviePlaying() )
    {
       log ( "Stopping intro movie!!" );
       PlayerOwner().MyHud.StopMovie();
    }

    Controller.ConsoleCommand( "setres "$OldResX$"x"$OldResY );
    Controller.ConsoleCommand( "rmode 5" );

    Controller.CloseMenu();
    Free( true );
}

////////////////////////////////////////////////////////////////////////////////////
// Component Cleanup
////////////////////////////////////////////////////////////////////////////////////
event Free( optional bool bForce ) 			
{
	local int i;
	
    for (i=0;i<IntroComponents.Length;i++)
        IntroComponents[i].Component = None;
    IntroComponents.Remove(0,IntroComponents.Length);

    MyEscapeButton=None;

    Super.Free( bForce );
}

defaultproperties
{
	OnShow=InternalOnShow
	OnHide=InternalOnHide
	bHideMouseCursor=true
}