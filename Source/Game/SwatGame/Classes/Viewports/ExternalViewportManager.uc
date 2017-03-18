class ExternalViewportManager extends Engine.Actor
    implements IInterested_GameEvent_GameStarted,
               IInterested_GameEvent_MissionEnded,
               IControllableViewport
    config(SwatGame);

// =============================================================================
// ExternalVieportManager
//
// The ExternalViewportManager handles managing the external viewports of each of your
// swat members.  Each SWAT team member is equipped with a helmet cam that the player
// can view through the viewport.  The player can also issue commands through the
// viewport...
//
// =============================================================================

// Consts (can be set from a config file though)...
var private config const float kDefaultSizeX;   // Percentage of the screen for the default width of the viewport
var private config const float kDefaultSizeY;   // Percentage of the screen for the default height of the viewport
var private config const float kActiveSizeX;    // Percentage of the screen for the default width of the commanding viewport
var private config const float kActiveSizeY;    // Percentage of the screen for the default height of the commanding viewport
var private config const float kZoomRate ;      // Rate per second for zooming
var private config const float kViewportFOV;    // FOV for this viewport
var private config const float kViewportRightPadding;   // How much to pad the viewport on the right hand side of the screen
var private config const float kViewportTopPadding; // How much to pad the viewport on the top of the screen
var private config const string OfficerFontName; // What font to use for the current resolution
var private config const float kNegativeFontYOffset;
var private config const float kNegativeFontXOffset;
var private int                iCurrentControllable; // Index to the current officer in the AllControllable array
var private array<IControllableThroughViewport> AllControllable;  // List of all controllable objects
var private array<IControllableThroughViewport> CurrentControllables; // List of all controllables in the current filter
var private string             Filter;          // Filter for what type of officer to display in the viewport (red/blue/sniper)
var private string             InitialControllable; // Name of First Controllable actor found when this filter was set.  If cycling every
                                                    // comes back to this Controllable, the viewport will close
var private float CurrentSizeX;                 // In percentage of the screen (0..1)
var private float CurrentSizeY;                 // In percentage of the screen (0..1)
var private float CurrentWidth;                 // In actual screen dimensions (0..SizeX)
var private float CurrentHeight;                // In actual screen dimensions (0..ClipY)

var private float LastDeltaTime;                // Last delta time, for smoothing
var private class<Actor> BaseControllableClass; // Base class for which there could be possible IControllableThroughViewport implementors,
                                                // used as an optimization so we don't have to look through all actors in script.
var private GUIExternalViewport  GUIParent;                // Reference to the GUI component
var private Material  DeadTexture;              // Material to use when the viewport is viewing a dead pawn
var private Rotator   LastViewRotation;
var private Vector    LastViewLocation;
var private Material  ReticleTexture;

var private Vector    MouseAccel;
var private Rotator   OriginalRotation;

const ViewLerpAlpha = 8;
const LocLerpAlpha = 6;

#define DEBUG_OFFICERVIEWPORTS 0

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    //register for notification that the game has started
	// COOP: We'll need to revisit this after we decide what we're doing for
    // replication of game events
	if ( Level.Netmode == NM_Standalone )
    {
    Assert( SwatGameInfo(Level.Game) != None );
    SwatGameInfo(Level.Game).GameEvents.GameStarted.Register(Self);
    SwatGameInfo(Level.Game).GameEvents.MissionEnded.Register(Self);
    } else
    {
		// For now call initialize manually here, normally it's called on GameStarted
        Initialize();
    }
}

simulated function OnGameStarted()
{
    Initialize();
}

simulated function OnMissionEnded()
{
    GUIParent.OnClientDraw = GUIParent.InternalRender;    // reset rendering to the guiComponent, so that this can be GC'd properly
}

simulated function ShowViewport(string inFilter, optional string inSpecificControllableFilter)
{
#if DEBUG_OFFICERVIEWPORTS
	log("[dkaplan] ShowViewport: inFilter = "$inFilter$", inSpecificControllableFilter = "$inSpecificControllableFilter );
#endif
    if ( !SetFilter(inFilter) || inSpecificControllableFilter != "" )
        CycleControllableViewport(inSpecificControllableFilter);
#if DEBUG_OFFICERVIEWPORTS
    mplog( "Showing viewport on controllable: "$GetCurrentControllable().GetViewportName() );
#endif
    if ( GetCurrentControllable() != None )
    {
        OriginalRotation = GetCurrentControllable().GetOriginalDirection();
        LastViewRotation = OriginalRotation;
        LastViewLocation = GetCurrentControllable().GetViewportLocation();
        GUIParent.OnClientDraw = Render;
    }
}

// Returns true if the filter was changed as a result of this call
simulated function bool SetFilter(string inFilter)
{
    local int ct;
#if DEBUG_OFFICERVIEWPORTS
    mplog(" SetFilter: inFilter = "$inFilter );
#endif
    if ( Filter != inFilter )
    {
        Filter = inFilter;

        iCurrentControllable = 0;
        CurrentControllables.Remove( 0, CurrentControllables.Length );
        // Build a list of all the Controllables in this filter
        if ( Filter != "" )
        {
            for ( ct = 0; ct < AllControllable.Length; ++ct )
            {
                if ( ControllableMatchesFilter( AllControllable[ct], Filter ) )
                {
#if DEBUG_OFFICERVIEWPORTS
                    mplog("[dkaplan] ... Adding Controllable: "$AllControllable[ct] );
#endif
                    CurrentControllables.Insert( CurrentControllables.Length, 1 );
                    CurrentControllables[CurrentControllables.Length-1] = AllControllable[ct];
                }
            }
        }
        return true;
    }
    return false;
}

simulated function string GetFilter()
{
    return Filter;
}

simulated function bool ShouldControlViewport()
{
  local SwatGamePlayerController Controller;
  local SwatPlayerReplicationInfo PlayerReplicationInfo;

  if(!GetCurrentControllable().ShouldDrawViewport())
  {
    return false;
  }

  Controller = SwatGamePlayerController(Owner);
  if(Controller == None)
  {
    return false;
  }
  if(Controller.bControlViewport == 0)
  {
    return false;
  }

  if(Level.NetMode != NM_Standalone)
  {
    PlayerReplicationInfo = SwatPlayerReplicationInfo(Controller.PlayerReplicationInfo);
    if(!(Filter ~= "sniper"))
    {
      return false;
    }
    if(!PlayerReplicationInfo.IsLeader)
    {
      return false;
    }
  }

  return true;
}

simulated function Initialize()
{
    local Actor TestControllable;
    local int   NumOfficers;

#if DEBUG_OFFICERVIEWPORTS
    mplog( "searching through all actors of class: "$BaseControllableClass );
#endif
    AllControllable.Length = 0;
    foreach DynamicActors( BaseControllableClass, TestControllable)
    {
#if DEBUG_OFFICERVIEWPORTS
        mplog( "ExternalViewportManager::Initialize() testing: "$TestControllable$" to see if it is a IControllableThroughViewport.  Is it? "$IControllableThroughViewport(TestControllable) );
#endif
        if ( IControllableThroughViewport(TestControllable) != None && IControllableThroughViewport(TestControllable).GetViewportOwner() != Controller(Owner).Pawn )
        {
            AllControllable.Insert(NumOfficers,1);
            AllControllable[NumOfficers] = IControllableThroughViewport(TestControllable);
            NumOfficers++;
        }
    }

    if (0 == NumOfficers) // no officers in game, don't init external viewport
    {
        log("!! No officers in the level, stopping initialization of ExternalViewportManager");
        return;
    }

    if ( Level.NetMode == NM_Standalone || (Level.GetLocalPlayerController() == Owner) )
    {
        // Initialize the HUD GUI component corresponding to this viewport
        GUIParent =  SwatGamePlayerController(Owner).GetHUDPage().ExternalViewport;
        GUIParent.OnClientDraw = Render;    // Rendering will be handled by this class
        GUIParent.Hide();
    }
}

simulated function bool HasOfficers( string ViewportType )
{
    local int ct;

#if DEBUG_OFFICERVIEWPORTS
    mplog( "ExternalViewportManager::HasOfficers(" $ViewportType$ "), AllControllable: "$AllControllable.Length );
#endif
    for ( ct = 0; ct < AllControllable.Length; ++ct )
    {
#if DEBUG_OFFICERVIEWPORTS
        mplog( "Testing "$AllControllable[ct].GetViewportType()$", against type: "$ViewportType );
#endif
        if ( InStr( Caps(AllControllable[ct].GetViewportType()), Caps(ViewportType) ) >= 0 )
        {
            mplog( "ExternalViewportManager::HasOfficers returning true " );
            return true;
        }
    }
    return false;
}

simulated function SetCurrentControllable( IControllableThroughViewport NewControllable )
{
#if DEBUG_OFFICERVIEWPORTS
    mplog( "SetCurrentControllable: "$NewControllable );
#endif
    iCurrentControllable = 0;
    if ( NewControllable != None )
    {
        CurrentControllables.Length = 0;
        CurrentControllables.Insert( 0, 1 );
        CurrentControllables[0] = NewControllable;
    } else
    {
        CurrentControllables.Length = 0;
    }

    if ( GetCurrentControllable() != None )
    {
        OriginalRotation = GetCurrentControllable().GetOriginalDirection();
        LastViewRotation = OriginalRotation;
        LastViewLocation = GetCurrentControllable().GetViewportLocation();
        GUIParent.OnClientDraw = Render;
    }
}

simulated function IControllableThroughViewport GetCurrentControllable()
{
    local IControllableThroughViewport controllable;

    if (iCurrentControllable < CurrentControllables.length)
        controllable = CurrentControllables[iCurrentControllable];
    else
        controllable = None;

    //log( "Current officer returning: "$AllControllable[iCurrentControllable].Officer );
    return controllable;
}

simulated function SetInput(int dMouseX, int dMouseY)
{
    MouseAccel.X = dMouseX;
    MouseAccel.Y = dMouseY;
}

simulated function bool ControllableMatchesFilter( IControllableThroughViewport Controllable, string Filter )
{
    return InStr(Caps(Controllable.GetViewportType()), Caps(Filter)) >= 0;
}

simulated function bool IncrementControllableAndTestValidity()
{
//log("[dkaplan] IncrementControllableAndTestValidity: iCurrentControllable = "$iCurrentControllable );
    ++iCurrentControllable;
    if ( iCurrentControllable >= CurrentControllables.Length )
    {
        SwatGamePlayerController(Owner).HideViewport();
        return false;
    }
    return true;
}

// Handle Cycling through officers in the viewport.  This has to take into account what type of
// officer we're interested in, determined by the filter string.
simulated function CycleControllableViewport( optional string SpecificControllableFilter )
{
#if DEBUG_OFFICERVIEWPORTS
    mplog("CycleControllableViewport: SpecificControllableFilter = "$SpecificControllableFilter );
#endif
    if ( SpecificControllableFilter != "" )
    {
        while ( !ControllableMatchesFilter(GetCurrentControllable(), SpecificControllableFilter) )
        {
            if ( !IncrementControllableAndTestValidity() )
                return;
        }
    }
    else
    {
        if ( !IncrementControllableAndTestValidity() )
            return;
    }
}

// Update the GUI Component to have the same location and dimensions of this viewport
simulated private function UpdateGUIComponent(Canvas inCanvas, int X, int Y, int W, int H)
{
    GUIParent.WinLeft = float(X)/float(inCanvas.SizeX);
    GUIParent.WinTop  = float(Y)/float(inCanvas.SizeY);
    GUIParent.WinWidth = float(W)/float(inCanvas.SizeX);
    GUIParent.WinHeight = float(H)/float(inCanvas.SizeY);
}

simulated function InstantMinimize()
{
    CurrentSizeX = kDefaultSizeX;
    CurrentSizeY = kDefaultSizeY;
}

// Update the geometry of the viewport.  Includes lerping between target positions
simulated private function UpdateGeometry(Canvas inCanvas, float inDeltaTime, out int X, out int Y, out int W, out int H)
{
    // Determine the desired CurrentSizeX/Y for this viewport, still just a percentage of the screen at this point
    if ( ShouldControlViewport() )
    {
        CurrentSizeX = Lerp( inDeltaTime * kZoomRate, CurrentSizeX, kActiveSizeX );
        CurrentSizeY = Lerp( inDeltaTime * kZoomRate, CurrentSizeY, kActiveSizeY );
    } else
    {
        CurrentSizeX = Lerp( inDeltaTime * kZoomRate, CurrentSizeX, kDefaultSizeX );
        CurrentSizeY = Lerp( inDeltaTime * kZoomRate, CurrentSizeY, kDefaultSizeY );
    }

    // Convert from the percentage of the screen, to actual screen dimensions
    CurrentWidth = inCanvas.SizeX * CurrentSizeX;
    CurrentHeight = inCanvas.ClipY * CurrentSizeY;

    // X needs to be offset by the kViewportRightPadding so it's not flush with the right side of the screen
    X = (inCanvas.SizeX - CurrentWidth) - (inCanvas.SizeX * kViewportRightPadding);
    // Y is offset from the top of the screen by the kViewportTopPadding
    Y = inCanvas.ClipY * kViewportTopPadding;
    W = CurrentWidth;
    H = CurrentHeight;

    UpdateGUIComponent(inCanvas, X, Y, W, H);
}

simulated private function DrawOfficerName(Canvas inCanvas)
{
    if (GetCurrentControllable() == None)
        return;

    // Setup the canvas
    if ( CurrentHeight < 100 )
        return;
    inCanvas.SetPos(    int( kNegativeFontXOffset * float( inCanvas.SizeX ) / 800.0 ),
        CurrentHeight - int( kNegativeFontYOffset * float( inCanvas.SizeY ) / 600.0 ) );
    inCanvas.Font = GUIParent.Controller.GetMenuFont(OfficerFontName).GetFont(inCanvas.SizeX);

    // Set draw color based on team affiliation
    if ( InStr(Caps(GetCurrentControllable().GetViewportName()), "BLUE") >= 0 )
    {
        inCanvas.SetDrawColor( 0, 0, 135 );
    }
    else if ( InStr(Caps(GetCurrentControllable().GetViewportName()), "RED") >= 0 )
        inCanvas.SetDrawColor( 175, 0, 0 );
    else
        inCanvas.SetDrawColor( 255, 255, 255 );

    inCanvas.DrawText( Caps(GetCurrentControllable().GetViewportName()) @ GetCurrentControllable().GetViewportDescription() );
}

simulated function Render(Canvas inCanvas)
{
    local int X, Y, W, H;

    // Do any updating...
    UpdateGeometry(inCanvas, FClamp(LastDeltaTime, 0.01, 0.3), X, Y, W, H);

    inCanvas.SetOrigin( X, Y );

    // Render the components
    DrawViewport(inCanvas, X, Y, W, H);
    DrawOfficerName(inCanvas);

    if ( ShouldControlViewport() && GetCurrentControllable().ShouldDrawReticle())
        DrawReticle(inCanvas);

    inCanvas.SetOrigin(0,0);
    inCanvas.ClipX = inCanvas.SizeX;
    inCanvas.ClipY = inCanvas.SizeY;
}


simulated function name   GetControllingStateName()
{
    return 'ControllingViewport';
}

// Return true when this viewport can issue commands
simulated function bool   CanIssueCommands()
{
    return GetCurrentControllable().CanIssueCommands();
}

simulated private function DrawReticle( Canvas inCanvas )
{
    inCanvas.bNoSmooth = False;
    inCanvas.Style = ERenderStyle.STY_Alpha;
    inCanvas.SetDrawColor(255,255,255);

    inCanvas.SetPos( 0.5 * (CurrentWidth - 96), 0.5 * (CurrentHeight - 96));
    inCanvas.DrawTile(ReticleTexture, 96, 96, 0, 0, 256, 256);
}

simulated function int DegreesToUnreal( INT inDegrees )
{
    return (65536*inDegrees)/360;
}

// Can be called in place of PlayerCalcView for the proper
simulated function ViewportCalcView(out Vector CameraLocation, out Rotator CameraRotation )
{
    local Object.Range YawRange, PitchRange;
    local Rotator ViewRotation;

    // Return early if we're not looking through anyone's eyes...
    if ( GetCurrentControllable() == None )
        return;

    if ( ShouldControlViewport() )
    {
        CameraRotation = LastViewRotation;
        GetCurrentControllable().SetRotationToViewport( CameraRotation );
    } else
    {
        CameraRotation = GetCurrentControllable().GetViewportDirection();
    }
    CameraLocation = GetCurrentControllable().GetViewportLocation();

    if ( ShouldControlViewport() )
    {
        if ( VSize(MouseAccel) != 0 )
            GetCurrentControllable().OnMouseAccelerated( MouseAccel );

        if ( VSize(MouseAccel) == 0 )
            GetCurrentControllable().AdjustMouseAcceleration( MouseAccel );
    }
    if ( VSize(MouseAccel) != 0 )
    {
        CameraRotation.Yaw += MouseAccel.X * GetCurrentControllable().GetViewportYawSpeed();
        CameraRotation.Pitch += MouseAccel.Y * GetCurrentControllable().GetViewportPitchSpeed();

        ViewRotation = OriginalRotation;

		// A zero pitch clamp value means no restrictions
        if ( GetCurrentControllable().GetViewportYawClamp() != 0 )
        {
            YawRange.Min = ViewRotation.Yaw     - DegreesToUnreal(GetCurrentControllable().GetViewportYawClamp());
            YawRange.Max = ViewRotation.Yaw     + DegreesToUnreal(GetCurrentControllable().GetViewportYawClamp());
            CameraRotation.Yaw    = Clamp( CameraRotation.Yaw, YawRange.Min, YawRange.Max );
        }

        // A zero pitch clamp value means no restrictions
        if ( GetCurrentControllable().GetViewportPitchClamp() != 0 )
        {
            PitchRange.Min = ViewRotation.Pitch - DegreesToUnreal(GetCurrentControllable().GetViewportPitchClamp());
            PitchRange.Max = ViewRotation.Pitch + DegreesToUnreal(GetCurrentControllable().GetViewportPitchClamp());
            CameraRotation.Pitch  = Clamp( CameraRotation.Pitch, PitchRange.Min, PitchRange.Max );
        }
    }


    if ( ShouldControlViewport() )
        GetCurrentControllable().OffsetViewportRotation( CameraRotation );

    // Lerp to the desired rotation and location
    CameraRotation = RotatorLerp( LastViewRotation, CameraRotation, ViewLerpAlpha * LastDeltaTime );
    CameraLocation = LastViewLocation + (LocLerpAlpha * LastDeltaTime *  (CameraLocation - LastViewLocation));

    LastViewRotation = CameraRotation;
    LastViewLocation = CameraLocation;
}

simulated function OnBeginControlling()
{
    GetCurrentControllable().OnBeginControlling();
}

simulated function OnEndControlling()
{
    GetCurrentControllable().OnEndControlling();
}

simulated function        HandleReload()
{
    GetCurrentControllable().HandleReload();
}

simulated function        HandleFire()
{
    GetCurrentControllable().HandleFire();
}

simulated function        HandleAltFire()
{
    GetCurrentControllable().HandleAltFire();
}

simulated private function DrawViewport( Canvas inCanvas, int X, int Y, int W, int H )
{
    local Rotator ViewRotation;
    local Vector  ViewLocation;
    local float   FOV;

    // Don't render the viewport if the officer has been destroyed
    if ( GetCurrentControllable() != None )
    {
        ViewportCalcView( ViewLocation, ViewRotation );

        FOV = GetCurrentControllable().GetFOV();
        if ( FOV == 0 )
            FOV = kViewportFOV;

        inCanvas.DrawPortal( X, Y, W, H, GetCurrentControllable().GetViewportOwner(), ViewLocation, ViewRotation, FOV, true);

        if ( !GetCurrentControllable().ShouldDrawViewport() )
        {
            // Draw some static on the screen
            inCanvas.SetPos( 0, 0 );
            inCanvas.SetDrawColor( 255, 255, 255, 0.1 );
            inCanvas.DrawTile( DeadTexture, W, H, 0, 0, 256, 256 );
        }
        if ( GetCurrentControllable().GetViewportOverlay() != None )
        {
            inCanvas.SetPos( 0, 0 );
            inCanvas.SetDrawColor( 255, 255, 255, 0.1 );
            inCanvas.DrawTileClipped( GetCurrentControllable().GetViewportOverlay(), W, H, 0, 0, 512, 512);
        }
        inCanvas.SetPos( 0, 0 );
    }
}

simulated function Tick(float DeltaTime)
{
	// cap delta time to 10fps
    LastDeltaTime = fMin( DeltaTime, 0.1 );
}

simulated function HideViewport()
{
}

simulated event Destroyed()
{
    SwatGameInfo(Level.Game).GameEvents.GameStarted.UnRegister(Self);
    SwatGameInfo(Level.Game).GameEvents.MissionEnded.UnRegister(Self);

    Super.Destroyed();
}

defaultproperties
{
    bHidden=true
    bCollideActors=false
    DeadTexture= Shader'HUD.DeadOfficerStaticShader'
    ReticleTexture=Material'HUD.ToolReticle'
    CurrentSizeX=0.3
    CurrentSizeY=0.25
    kDefaultSizeX=0.3
    kDefaultSizeY=0.25
    kActiveSizeX=0.55
    kActiveSizeY=0.5
    kZoomRate=0.7
    kViewportFOV=109
    kViewportRightPadding=0.02
    kViewportTopPadding=0.05
    BaseControllableClass=class'SwatGame.SwatPawn'
    ViewportFont=Font'SwatFonts.Pix800X600'
    RemoteRole=ROLE_None
    kNegativeFontXOffset=8
    kNegativeFontYOffset=18
    OfficerFontName="SwatOSBold"
}
