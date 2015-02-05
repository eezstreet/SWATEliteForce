class HUDPageBase extends GUI.GUIPage
    implements IEffectObserver
    abstract;

import enum ENetMode from Engine.LevelInfo;
import enum FireMode from Engine.FiredWeapon;
import enum ESkeletalRegion from Engine.Actor;

const NVOIPSPEAKERS = 4;

//This class represents the GUIPage that is displayed in-game while playing SWAT,
//  and contains the SWAT HUD elements.

//generic hud components
var(HUD) EditInline GUIFeedback                         Feedback                    "Test that displays feedback to the user if they can 'Use' or 'Fire' at something under the Reticle.";
var(HUD) EditInline GUIFireMode                         FireMode                    "An image that indicates the current fired weapon's fire mode, eg. 3-round burst.";
var(HUD) EditInline GUIDamageIndicator                  DamageIndicator             "An image that indicates the current damage state of the player.";
var(HUD) EditInline GUIAmmoStatusBase                   AmmoStatus                  "Displays the current ammunition situation for the current weapon.";
var(HUD) EditInline GUIOverlay                          Overlay                     "An image that should be the size of the screen, and obstructs the view for sniper scope, gas mask, etc.";
var(HUD) EditInline GUIProgressBar                      Progress                    "A multi-purpose progress bar.";
var(HUD) EditInline GUIReticle                          Reticle                     "The reticle.";

//sp only hud components
var(HUD) EditInline GUIDefaultCommandIndicator          DefaultCommand              "Text that displays the Command that will be given if the player presses the button to give the Default Command (right-mouse by default).";
var(HUD) Editinline GUIClassicCommandInterfaceContainer ClassicCommandInterface     "A GUI component which contains the Classic Command Interface.";
var(HUD) Editinline GUIGraphicCommandInterface          GraphicCommandInterface     "A GUI component which contains the Graphic Command Interface.";
var(HUD) Editinline GUILabel							RedHeldCommand				"Text that displays the Command that is currently held for the red team.";
var(HUD) Editinline GUILabel							BlueHeldCommand				"Text that displays the Command that is currently held for the blue team.";
var(HUD) Editinline GUILabel							ElementHeldCommand			"Text that displays the Command that is currently held for the element.";
var(HUD) EditInline GUIExternalViewport                 ExternalViewport            "The gui component which contains the external viewport for team/sniper management.";
var(HUD) EditInline GUIScrollText                       TrainingText                "A Text Box that displays the current information during Training.";
#if IG_BATTLEROOM
var(HUD) EditInline GUIBattleRoom                       BattleRoom                  "The gui component which contains the battle room hud";
#endif

//mp only hud components
var(HUD) EditInline GUILabel                            PlayerTag                   "The text that pops up on top of players in multiplayer games.";
var(HUD) EditInline GUILabel                            CommandInterfaceMenuPage    "Text that displays the currently selected CommandInterface menu page.";
var(HUD) config EditInline GUIImage						SmashAndGrabItemImage;
var(HUD) config EditInline GUILabel						SmashAndGrabItemOwnerLabel;
var(HUD) config EditInline GUIImage						NVGogglesTransitionOverlay;
var(HUD) EditInline GUILabel							VOIPSpeakers[NVOIPSPEAKERS]	"Name of player who is speaking";

//speech recognition
var(HUD) config EditInline GUIImage						SpeechRecStatus;
var(HUD) config EditInline Material						SpeechRecStart;
var(HUD) config EditInline Material						SpeechRecProcessing;
var(HUD) config EditInline Material						SpeechRecBad;
var(HUD) config EditInline Material						SpeechRecRecognized;

//cinematic components
var(SWATGui) private EditInline Config array<GUIComponent>  SequenceComponents;

var(PREGAME) protected config Name PreGamePlacementName;
var(PREGAME) protected config Name MidGamePlacementName;
var(PREGAME) protected config Name PostGamePlacementName;

var(PREGAME) protected config Name MissionEndSequenceAName;
var(PREGAME) protected config Name MissionEndSequenceBName;

var(PREGAME) protected config Name MissionStartSequenceAName;
var(PREGAME) protected config Name MissionStartSequenceBName;

var(PREGAME) protected bool bInCinematic; //true while doing a cinematic repositioning
var() int NumTicks;

function OnConstruct(GUIController MyController)
{
	local int i;

    Super.OnConstruct(MyController);
    
    Feedback = GUIFeedback(AddComponent("SwatGame.GUIFeedback", "HUDPage_feedback"));
    AmmoStatus = GUIAmmoStatusBase(AddComponent("SwatGUI.GUIAmmoStatus", "HUDPage_ammostatus"));
    FireMode = GUIFireMode(AddComponent("SwatGame.GUIFireMode", "HUDPage_FireMode"));
    DamageIndicator = GUIDamageIndicator(AddComponent("SwatGame.GUIDamageIndicator", "HUD_page_DamageIndicator"));
    Overlay = GUIOverlay(AddComponent("SwatGame.GUIOverlay", "HUDPage_overlay"));
    Progress = GUIProgressBar(AddComponent("GUI.GUIProgressBar", "HUDPage_Progress"));
    Reticle = GUIReticle(AddComponent("SwatGame.GUIReticle", "HudReticle"));
    ClassicCommandInterface = GUIClassicCommandInterfaceContainer(AddComponent("SwatGame.GUIClassicCommandInterfaceContainer", "HUDPage_ClassicCommandInterface"));
    GraphicCommandInterface = GUIGraphicCommandInterface(AddComponent("SwatGame.GUIGraphicCommandInterface", "HUDPage_GraphicCommandInterface"));
    DefaultCommand = GUIDefaultCommandIndicator(AddComponent("SwatGame.GUIDefaultCommandIndicator", "HUDPage_defaultcommand"));
	RedHeldCommand = GUILabel(AddComponent("GUI.GUILabel", "HUDPage_redheldcommand"));
	BlueHeldCommand = GUILabel(AddComponent("GUI.GUILabel", "HUDPage_blueheldcommand"));
	ElementHeldCommand = GUILabel(AddComponent("GUI.GUILabel", "HUDPage_elementheldcommand"));
    CommandInterfaceMenuPage = GUILabel(AddComponent("GUI.GUILabel", "HUDPage_CommandInterfaceMenuPage"));
    ExternalViewport = GUIExternalViewport(AddComponent("SwatGame.GUIExternalViewport", "HUDPAGE_ExternalViewport"));
    BattleRoom = GUIBattleRoom(AddComponent("SwatGame.GUIBattleRoom", "HUDPage_BattleRoom"));
    PlayerTag = GUILabel(AddComponent("GUI.GUILabel", "HUDPage_playertag"));
    TrainingText = GUIScrollText(AddComponent("GUI.GUIScrollText", "HUDPage_TrainingText"));
    TrainingText.CharDelay=0.001;

	for (i = 0; i < NVOIPSPEAKERS; i++)
	{
		VOIPSpeakers[i] = GUILabel(AddComponent("GUI.GUILabel", "HUDPage_VOIPSpeaker"$i));
	}
}


function InitComponent(GUIComponent MyOwner)
{
    local int i;

    Super.InitComponent(MyOwner);
    
    for( i = 0; i < SequenceComponents.Length; i++ )
    {
        SequenceComponents[i].bRepeatCycling = false;
    }

    OnKeyEvent=InternalOnKeyEvent;
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// HUD Component Management
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//dkaplan - (1/23/04) ovverride default activation/deactivation of this GUIPage for the HUD
event Activate()
{
    Super(GUIComponent).Activate();
	NVGogglesTransitionOverlay.WinTop = -1.0;
}

event DeActivate()
{
    Super(GUIComponent).DeActivate();
}

event Show()
{
    UpdateCIVisibility();
    Super.Show();
}

event Hide()
{
    Super.Hide();
}

function PreLevelChangeCleanup()
{
    GraphicCommandInterface.SetLogic( None );    
}

function OnGameInit()
{
    RepositionComponents( PreGamePlacementName, true );
}

function OnGameStarted()
{
    RepositionComponents( MidGamePlacementName );

    CloseComponents();
    OpenCinematicComponents();
    // Set this to true early, to make sure we block out input during the
    // first 3 ticks.
    bInCinematic=true;
    
    NumTicks = 0;
}

function OnTick( float Delta )
{
	if (NumTicks >= 0)
	{
		NumTicks++;

		if (NumTicks > 25/* && Controller.TopPage() == self*/)
		{
			if( SwatGUIControllerBase(Controller).GuiConfig.CurrentMission == None ||
				SwatGUIControllerBase(Controller).GuiConfig.CurrentMission.CustomScenario != None )
				FinishStartRoundSequence();
			else
			{
				if( !PlayerOwner().TriggerEffectEvent( 'UIMissionDispatcher',,,,,,,self ) )
					FinishStartRoundSequence();
				else
					StartStartRoundSequence();
			}

			NumTicks = -1;
		}
	}
}

function OnGameOver()
{
    CloseComponents();
    RepositionComponents( PostGamePlacementName );
}

function OnPlayerRespawned()
{
    OpenComponents();
}

function OnPlayerDied()
{
    CloseComponents();
}

function StartStartRoundSequence()
{
    bInCinematic=true;
    RepositionComponents( MissionStartSequenceAName );
}

function FinishStartRoundSequence()
{
    OpenComponents();
    bInCinematic=false;
    RepositionComponents( MissionStartSequenceBName );
    SwatGamePlayerController(PlayerOwner()).PostGameStarted();
}

function StartEndRoundSequence()
{
    bInCinematic=true;
    CloseComponents();
    RepositionComponents( MissionEndSequenceAName );
}

function FinishEndRoundSequence() 
{
    bInCinematic=false;
    RepositionComponents( MissionEndSequenceBName );
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
// IEffectObserver implementation
function OnEffectInitialized(Actor inInitializedEffect);
function OnEffectStarted(Actor inStartedEffect);

function OnEffectStopped(Actor inStoppedEffect, bool Completed)
{
    FinishStartRoundSequence();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////

protected function OpenComponents()
{
    switch (SwatGUIControllerBase(Controller).GuiConfig.SwatGameRole)
    {
        case GAMEROLE_None:
        case GAMEROLE_SP_Campaign:
        case GAMEROLE_SP_Custom:
        case GAMEROLE_SP_Other:
            OpenSPComponents();
            break;

        case GAMEROLE_MP_Host:
        case GAMEROLE_MP_Client:
            OpenMPComponents();
            break;

        default:
            assert(false);  //unexpected SwatGameRole
            break;
    }
    
    OpenGenericComponents();
}

protected function CloseComponents()
{
    switch (SwatGUIControllerBase(Controller).GuiConfig.SwatGameRole)
    {
        case GAMEROLE_None:
        case GAMEROLE_SP_Campaign:
        case GAMEROLE_SP_Custom:
        case GAMEROLE_SP_Other:
            CloseSPComponents();
            break;

        case GAMEROLE_MP_Host:
        case GAMEROLE_MP_Client:
            CloseMPComponents();
            break;

        default:
            assert(false);  //unexpected SwatGameRole
            break;
    }
    
    CloseGenericComponents();
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////

function OpenCinematicComponents()
{    
    local int i;

    for( i = 0; i < SequenceComponents.Length; i++ )
    {
        SequenceComponents[i].Show();
    }
}

function CloseCinematicComponents()
{    
    local int i;
    
    for( i = 0; i < SequenceComponents.Length; i++ )
    {
        SequenceComponents[i].Hide();
    }
}


function CloseGenericComponents()
{
    assert( ClassicCommandInterface != None );
    ClassicCommandInterface.Hide();
    assert( GraphicCommandInterface != None );
    GraphicCommandInterface.Hide();
    assert( DefaultCommand != None );
    DefaultCommand.Hide();
    assert( CommandInterfaceMenuPage != None );
    CommandInterfaceMenuPage.Hide();
    assert( ExternalViewport != None );
    ExternalViewport.Hide();

    assert( Feedback != None );
    Feedback.Hide();
    Feedback.RePosition('down', true); //ensure feedback always starts from down position

    assert( FireMode != None );
    FireMode.Hide();
    assert( DamageIndicator != None );
    DamageIndicator.Hide();
    assert( AmmoStatus != None );
    AmmoStatus.Hide();
    assert( Overlay != None );
    Overlay.Hide();
    assert( Progress != None );
    Progress.Hide();
    Progress.Value = 0;
    Progress.Reposition('down');
    assert( Reticle != None );
    Reticle.Hide();
}

function CloseSPComponents()
{
    assert( TrainingText != None );
    TrainingText.Hide();
#if IG_BATTLEROOM
    assert( BattleRoom != None );
    BattleRoom.Hide();
#endif

	SpeechRecStatus.Hide();
}

function CloseMPComponents()
{
    assert( PlayerTag != None );
    PlayerTag.Hide();
	SmashAndGrabItemImage.Hide();
	SmashAndGrabItemOwnerLabel.Hide();
}

function OpenGenericComponents()
{
    assert(ExternalViewport != None);
    ExternalViewport.Hide();

    UpdateCIVisibility();

    assert( Feedback != None );
    Feedback.Show();
    Feedback.RePosition('down', true); //ensure feedback always starts from down position
    
    assert( AmmoStatus != None );
    //updated in UpdateFireMode, below
    
    assert( FireMode != None );
    UpdateFireMode();
    
    assert( DamageIndicator != None );
    DamageIndicator.Reset();
    DamageIndicator.Show();
    
    assert( Overlay != None );
    Overlay.Show();
    
    assert( Progress != None );
    Progress.Show();
    
    assert( Reticle != None );
    Reticle.Show();

	NVGogglesTransitionOverlay.Show();
	NVGogglesTransitionOverlay.WinTop = -NVGogglesTransitionOverlay.WinHeight;
}

function OpenSPComponents()
{
    assert(TrainingText != None);
    TrainingText.Hide();

#if IG_BATTLEROOM
    assert(BattleRoom != None);
    BattleRoom.Hide();
#endif // IG_BATTLROOM

	SpeechRecStatus.Show();
}

function OpenMPComponents()
{
    assert(PlayerTag != None);
    PlayerTag.Hide();
}

function UpdateCIVisibility()
{
    local bool CurrentInterfaceIsEnabled, CCIShown;
    local CommandInterface CurrentCommandInterface;

    CurrentCommandInterface = SwatGamePlayerController(PlayerOwner()).GetCommandInterface();
    CurrentInterfaceIsEnabled = CurrentCommandInterface != None && CurrentCommandInterface.Enabled;
    
    CCIShown = SwatGUIControllerBase(Controller).GuiConfig.CurrentCommandInterfaceStyle == CommandInterface_Classic;
//log( self$"::UpdateCIVisibility() ... CCIShown = "$CCIShown$", CurrentCommandInterface = "$CurrentCommandInterface$", CurrentInterfaceIsEnabled = "$CurrentInterfaceIsEnabled );
                 
    assertWithDescription(CurrentCommandInterface == None || CurrentCommandInterface.IsA('ClassicCommandInterface') == CCIShown,
        "[tcohen] HUDPageBase::UpdateCIVisibility() the GUIConfig and the GamePlayerController disagree about which CommandInterface is current.");
    
    assert(ClassicCommandInterface != None);
    ClassicCommandInterface.SetVisibility( CCIShown && CurrentInterfaceIsEnabled );

    assert(GraphicCommandInterface != None);
    GraphicCommandInterface.SetVisibility( !CCIShown && CurrentInterfaceIsEnabled );
    GraphicCommandInterface.bUseExitPad = SwatGUIControllerBase(Controller).GuiConfig.bUseExitMenu;

    assert(DefaultCommand != None);
    DefaultCommand.SetVisibility(CurrentInterfaceIsEnabled);

    assert(CommandInterfaceMenuPage != None);
    CommandInterfaceMenuPage.SetVisibility(
            CurrentInterfaceIsEnabled 
        &&  !CCIShown 
        &&  (
                SwatGUIControllerBase(Controller).GuiConfig.SwatGameRole == GAMEROLE_MP_Host
            ||  SwatGUIControllerBase(Controller).GuiConfig.SwatGameRole == GAMEROLE_MP_Client
#if IG_SWAT_TESTING_MP_CI_IN_SP //tcohen: testing MP CommandInterface behavior in SP
            ||  true
#endif
            )
        );
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// HUD Input capture
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    return bInCinematic;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// HUD Update utilities
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


function GUIScrollText GetTrainingTextControl()
{
    assert(TrainingText != None);
    TrainingText.Show();

    return TrainingText;
}

simulated function UpdateProtectiveEquipmentOverlay()
{
    Overlay.UpdateImage();
}

simulated function UpdateFireMode()
{
    local FiredWeapon FiredWeapon;
    local FiredWeapon.FireMode CurrentFireMode;
//    local int i;

    if( PlayerOwner().Pawn != None )
        FiredWeapon = FiredWeapon(PlayerOwner().Pawn.GetActiveItem());

    if (FiredWeapon == None)
    {
        //Hide the fire mode indicator && AmmoStatus HERE.
        if( AmmoStatus.bVisible )
            AmmoStatus.Hide();

        if( FireMode.bVisible )
            FireMode.Hide();

        //log("[FIRE MODE] ActiveItem is not a FiredWeapon.");
    }
    else
    {
        //Update available fire modes display HERE (if such a display exists).
        if( !AmmoStatus.bVisible )
            AmmoStatus.Show();

        if( !FireMode.bVisible )
            FireMode.Show();

        if( FiredWeapon.AvailableFireMode.length < 2 )
            FireMode.Hide();

        //Available fire modes are FiredWeapon.AvailableFireMode.
        //  See declaration in Unreal/Engine/Classes/Equipment/FiredWeapon.uc:
        //      var private config array<FireMode> AvailableFireMode;       //named in singular for simplicity of config file
        //
        //log("[FIRE MODE] The following FireModes are available for "$FiredWeapon.class.name$":");
        
        CurrentFireMode = FiredWeapon.CurrentFireMode;

        //FireMode.HideFireModes();
        //for (i=0; i<FiredWeapon.AvailableFireMode.length; ++i)
        //{
        //    FireMode.ShowFireMode(FiredWeapon.AvailableFireMode[i]);
        //}

        FireMode.SelectFireMode( CurrentFireMode );
                                     
        //log("[FIRE MODE] FireMode for "$FiredWeapon.class.name$" is now "$GetEnum(FiredWeapon.FireMode, CurrentFireMode));
    }
}

function SkeletalRegionHit(ESkeletalRegion RegionHit, int damage)
{
    DamageIndicator.SkeletalRegionHit(RegionHit, damage);
}

function SetCrouched( bool bCrouching )
{
    if( bCrouching )
        DamageIndicator.Crouch();
    else
        DamageIndicator.Stand();
}

function ResetDamageIndicator()
{
    DamageIndicator.Reset();
}

protected function RepositionComponents( name ToPos, optional bool Immediate )
{
    local int i;
        
    for( i = 0; i < Controls.Length; i++ )
    {
        Controls[i].RePosition( ToPos, Immediate );
    }
}

function OnSmashAndGrabItemOwnerChange(PlayerReplicationInfo NewOwner)
{
	if (NewOwner != None)
	{
		SmashAndGrabItemImage.Show();
		SmashAndGrabItemOwnerLabel.Show();
		SmashAndGrabItemOwnerLabel.Caption = NewOwner.PlayerName;
	}
	else
	{
		SmashAndGrabItemImage.Hide();
		SmashAndGrabItemOwnerLabel.Hide();
	}
}

function UpdateVOIPSpeakers(array<string> Speakers, array<int> TeamNumbers)
{
	local int i;
	local string style;

	while ( i < min(Speakers.length, NVOIPSPEAKERS) )
	{
		if (TeamNumbers[i] == 0)
			style = "sty_VOIPblue";
		else
			style = "sty_VOIPred";

		if (VOIPSpeakers[i].StyleName != style)
			VOIPSpeakers[i].ChangeStyle(style);
		VOIPSpeakers[i].SetCaption(Speakers[i]);
		VOIPSpeakers[i].Show();
		i++;
	}

	while ( i < NVOIPSPEAKERS )
	{
		VOIPSpeakers[i].Hide();
		i++;
	}
}

defaultproperties
{
    bIsHUD=true
    bNeverFocus=true
    PropagateVisibility=false
    PropagateActivity=false
    PropagateState=false
    bCaptureMouse=false
	NumTicks=-1
}
