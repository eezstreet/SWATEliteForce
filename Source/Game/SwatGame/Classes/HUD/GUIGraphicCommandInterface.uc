class GUIGraphicCommandInterface extends GUI.GUIMultiComponent
    threaded
    native;

import enum MenuPadStatus from CommandInterface;
import enum CommandInterfacePage from CommandInterface;
import enum EInputKey from Engine.Interactions;
import enum EInputAction from Engine.Interactions;

const MAX_COMMANDS_PER_PAGE = 20;

var GUIGraphicCommandInterfaceMenu MenuPages[CommandInterfacePage.EnumCount];
var Command CurrentCommand;

struct native ScreenLocation
{
    var private float X;
    var private float Y;
};

var protected GraphicCommandInterface Logic;    //represents the logic for managing the graphic command interface

var(GraphicCommandInterface) config float OpenCloseTime;   //how long to open/close

var(GraphicCommandInterface) config float MouseGestureTime "A break in mouse movement longer than this time is considered a new mouse gesture.";
var private float MouseSensitivity;
var private float LastMouseMoveTime;
var private float GestureDistanceX, GestureDistanceY;      //how far the mouse has moved in the current gesture.
var(GraphicCommandInterface) config float ScrollTime;           //in seconds, the time it takes to scroll the menu from one entry to the next
var(GraphicCommandInterface) config float MouseDistanceBetweenMenus "How far the mouse needs to move (horizontally, within a gesture) to select the sub/parent menu.";
var(GraphicCommandInterface) config float MouseDistanceBetweenMenuPads "How far the mouse needs to move (vertically, within a gesture) to select the next/previous menu pad.";
var(GraphicCommandInterface) config string RedTeamStyleName "The Syle to use when displaying a command menu for the RED team.";
var(GraphicCommandInterface) config string BlueTeamStyleName "The Syle to use when displaying a command menu for the BLUE team.";
var(GraphicCommandInterface) config string AsAnElementStyleName "The Syle to use when displaying a command menu for the entire ELEMENT.";
var(GraphicCommandInterface) config ScreenLocation MainPageCenterOffset;
var(DEBUG) bool bUseExitPad;

function OnConstruct(GUIController MyController)
{
    local int i, j;

    Super.OnConstruct(MyController);

    bUseExitPad = SwatGuiControllerBase(Controller).GuiConfig.bUseExitMenu;

    for (i=0; i<CommandInterfacePage.EnumCount; ++i)
    {
        MenuPages[i] = new (self, string(GetEnum(CommandInterfacePage, i))) class'GUIGraphicCommandInterfaceMenu';
        assert(MenuPages[i] != None);
        MenuPages[i].GCI = self;
        MenuPages[i].Page = CommandInterfacePage(i);

        for (j=0; j<MAX_COMMANDS_PER_PAGE; ++j)
            MenuPages[i].MenuPads[j] = GUIGraphicCommandInterfaceMenuPad(AddComponent("SwatGame.GUIGraphicCommandInterfaceMenuPad", MenuPages[i].name$"_MenuPad"$j));
    }
}

function InitComponent(GUIComponent Owner)
{
    local int i, j;
    local GUIStyles InitialStyle;

    Super.InitComponent(Owner);

    InitialStyle = Controller.GetStyle(AsAnElementStyleName);

    for (i=0; i<CommandInterfacePage.EnumCount; ++i)
    {
        for (j=0; j<MAX_COMMANDS_PER_PAGE; ++j)
        {
            MenuPages[i].MenuPads[j].Style = InitialStyle;
            MenuPages[i].MenuPads[j].bBoundToParent = false;
            MenuPages[i].MenuPads[j].bScaleToParent = false;
            MenuPages[i].MenuPads[j].bScaled=false;
            MenuPages[i].MenuPads[j].TextAlign=TXTA_Left;
        }
    }
}

function SetLogic(GraphicCommandInterface inLogic)
{
    local int i;

    Logic = inLogic;

    if( Logic == None )
        return;

    for (i=0; i<CommandInterfacePage.EnumCount; ++i)
        if( MenuPages[i] != None && Logic.MenuInfo[i] != None )
            MenuPages[i].IsAMainMenu = (Logic.MenuInfo[i].AnchorCommand == Command_None);
}

function GraphicCommandInterface GetLogic()
{
    return Logic;
}

//returns the abcissa at which a menu pad should be located to appear centered at RawPadY, ie. Center a pad vertically at RawPadY.
function float CenteredPadY(float RawPadY)
{
    return RawPadY - ActualHeight() / 2;
}

simulated function ClearAllCommands()
{
    local int i;

    for (i=1; i<CommandInterfacePage.EnumCount; ++i)
        MenuPages[i].ClearAllCommands();
}

simulated function ClearCommands(bool PageChange)
{
    local int i;
    local bool IsMP;

    IsMP = (Logic.Level.NetMode != NM_Standalone);

    for (i=1; i<CommandInterfacePage.EnumCount; ++i)    //skip Page_None enum value 0
        //TMC TODO don't need to ClearCommands() on a page that isn't used in the current NetMode
        MenuPages[i].ClearCommands(PageChange);
}

function OnCurrentTeamChanged(SwatAICommon.OfficerTeamInfo NewTeam)
{
    local GUIStyles NewStyle;
    local int i, j;

	Logic.RestoreHeldCommandCaptions();

    if (Logic.CurrentCommandTeam == Logic.Element)
        NewStyle = Controller.GetStyle(AsAnElementStyleName);
    else
    if (Logic.CurrentCommandTeam == Logic.RedTeam)
        NewStyle = Controller.GetStyle(RedTeamStyleName);
    else
    if (Logic.CurrentCommandTeam == Logic.BlueTeam)
        NewStyle = Controller.GetStyle(BlueTeamStyleName);
    else
        assertWithDescription(false,
            "[tcohen] GUIGraphicCommandInterface::OnCurrentTeamChanged() Logic.CurrentCommandTeam isn't Red, Blue, or Element.");

    for (i=0; i<CommandInterfacePage.EnumCount; ++i)
    {
        for (j=0; j<MAX_COMMANDS_PER_PAGE; ++j)
        {
            MenuPages[i].MenuPads[j].Style = NewStyle;
            Logic.SetCommandStatus(MenuPages[i].MenuPads[j].Command, true);
            MenuPages[i].MenuPads[j].OnUnSelected();    //update GUI state of the component
        }
    }
    //reselect any current command
    if (CurrentCommand != None)
	{
        MenuPages[int(CurrentCommand.Page)].MenuPads[CurrentCommand.GCIMenuPad].OnSelected();
		if (SwatGamePlayerController(Logic.Level.GetLocalPlayerController()).bHoldCommand > 0 &&
			IsCurrentCommandHoldable())
			Logic.SetHeldCommandCaptions(CurrentCommand, Logic.CurrentCommandTeam);
	}
}

native function SetCommand(Command Command, CommandInterface.MenuPadStatus Status);

function SelectCommand(Command NewSelection, optional bool LateralMove)
{
    local GUIGraphicCommandInterfaceMenuPad Pad;

    //if LateralMove==true, then we are selecting the command in response to
    //  a lateral move of the mouse, ie. left or right.
    //Lateral moves don't cause menus to open or close.

    if (NewSelection == None) return;   //this can happen if a command is given before the CommandInterface is updated

    //out with the old ...

    if (CurrentCommand != None)
    {
        //restore the current command's pad to its saved state
        Pad = MenuPages[int(CurrentCommand.Page)].MenuPads[CurrentCommand.GCIMenuPad];
        Pad.OnUnselected();

        //if the command had a sub page, and we're moving vertically (ie. no onto the subpage), then close the subpage
        if (CurrentCommand.SubPage != Page_None && !LateralMove)
            MenuPages[int(CurrentCommand.SubPage)].Close();
    }

    CurrentCommand = NewSelection;

    //in with the new ...

    //save the new command's state and then "watch" it
    Pad = MenuPages[int(CurrentCommand.Page)].MenuPads[CurrentCommand.GCIMenuPad];
    Pad.OnSelected();

    //if the command has a sub page then open it
    if (CurrentCommand.SubPage != Page_None && !LateralMove)
        MenuPages[int(CurrentCommand.SubPage)].Open();

	// update "held command" display
	if (SwatGamePlayerController(Logic.Level.GetLocalPlayerController()).bHoldCommand > 0)
	{
		if (IsCurrentCommandHoldable())
			Logic.SetHeldCommandCaptions(CurrentCommand, Logic.CurrentCommandTeam);
		else
			Logic.RestoreHeldCommandCaptions();
	}
}

// is current command "holdable"? (for a later zulu)
function bool IsCurrentCommandHoldable()
{
    local GUIGraphicCommandInterfaceMenuPad Pad;

	Pad = MenuPages[int(CurrentCommand.Page)].MenuPads[CurrentCommand.GCIMenuPad];

	return !CurrentCommand.IsCancel &&			// not the "exit" command
		CurrentCommand.SubPage == Page_None &&	// not a sub-page header
		Pad.UnselectedState != MSAT_Disabled;	// not grayed out
}

final function Open()
{
    GotoState('');          //if we were Closing, then leave that state

    Show();                 //show the GUIGraphicCommandInterface
    MenuOwner.Activate();   //activate the HUDPage (accept input)
    Activate();

    Focus();  //set focus to the GUIGraphicCommandInterface
    Press();  //capture the mouse

    Controller.ActiveControl = self;

    //open the main menu
    MenuPages[Logic.GetCurrentMainPage()].Open();

    //select the default command
    //if (SwatGUIControllerBase(Controller).GuiConfig.bUseExitMenu)
        SelectCommand(MenuPages[Logic.GetCurrentMainPage()].MenuPads[0].Command);
    //else
    //    SelectCommand(Logic.GetDefaultCommand());
}

final function Close()
{
    local int i;
    local GUIGraphicCommandInterfaceMenuPad Pad;

    //unselect the current command
    if (CurrentCommand != None)
    {
        Pad = MenuPages[int(CurrentCommand.Page)].MenuPads[CurrentCommand.GCIMenuPad];
        Pad.OnUnselected();
    }

    CurrentCommand = None;

    //close all menus
    for (i=0; i<CommandInterfacePage.EnumCount; ++i)
        MenuPages[i].Close();

    GotoState('Closing');
}
state Closing
{
Begin:
    Sleep(OpenCloseTime);

    Hide();
    MenuOwner.Deactivate();
    DeActivate();
}

final function CloseInstantly()
{
    local int i;

    //close all menus
    for (i=0; i<CommandInterfacePage.EnumCount; ++i)
        MenuPages[i].CloseInstantly();
}

Delegate bool OnCapturedMouseMove(float dX, float dY)
{
    local float Now;
    local float dTime;

    Now = Logic.Level.TimeSeconds;
    dTime = Now - LastMouseMoveTime;
    LastMouseMoveTime = Now;

    //reset the gesture if too much time has elapsed
    if (dTime > MouseGestureTime)
    {
        GestureDistanceX = 0;
        GestureDistanceY = 0;
    }

    GestureDistanceX += dX;
    GestureDistanceY += dY;

    while (GestureDistanceX >= MouseDistanceBetweenMenus)
    {
        OnMouseMovedRight();
        GestureDistanceX -= MouseDistanceBetweenMenus;
    }

    while (GestureDistanceX <= -MouseDistanceBetweenMenus)
    {
        OnMouseMovedLeft();
        GestureDistanceX += MouseDistanceBetweenMenus;
    }

    while (GestureDistanceY >= MouseDistanceBetweenMenuPads)
    {
        OnMouseMovedUp();
        GestureDistanceY -= MouseDistanceBetweenMenuPads;
    }

    while (GestureDistanceY <= -MouseDistanceBetweenMenuPads)
    {
        OnMouseMovedDown();
        GestureDistanceY += MouseDistanceBetweenMenuPads;
    }

    return true;    //mouse movement was consumed
}

Delegate bool OnKeyEvent(out byte Key, out byte State, float delta)
{
    if( KeyMatchesBinding( Key, "OpenGraphicCommandInterface | RightMouseAlias" ) )
    {
        if( State==EInputAction.IST_Press)
            return OnRightMousePressed();

        if( State==EInputAction.IST_Release)
            return OnRightMouseReleased();
    }

    if( KeyMatchesBinding( Key, "Fire" ) )
    {
        if( State==EInputAction.IST_Press)
            return OnLeftMousePressed();
    }

    if( KeyMatchesBinding( Key, "CommandInterfaceNextGroup" ) )
    {
        if( State==EInputAction.IST_Press )
            return false;
    }

    if  (
            KeyMatchesBinding( Key, "ScrollCommand Up")
        &&  State == EInputAction.IST_Press
        )
        Scroll('Up');

    if  (
            KeyMatchesBinding( Key, "ScrollCommand Down")
        &&  State == EInputAction.IST_Press
        )
        Scroll('Down');

    if( State==EInputAction.IST_Release || KeyMatchesBinding( Key, "HoldCommandForZulu" ))
        return false;

    return true;
}

function bool OnRightMousePressed()
{
    local int ButtonMode;

    ButtonMode = SwatGUIControllerBase(Controller).GuiConfig.GCIButtonMode;

    Switch (ButtonMode)
    {
    case 1:                         //!Modal, !LMBCancel
    case 2:                         //!Modal, LMBCancel
        return false;

    case 3:                         //Modal, !LMBCancel
        Logic.Close();
        return true;

    case 4:                         //Modal, LMBCancel
        GiveCommand();
        Logic.Close();
        return true;
    }

    assert(false);
}

function bool OnRightMouseReleased()
{
    local int ButtonMode;

    ButtonMode = SwatGUIControllerBase(Controller).GuiConfig.GCIButtonMode;

    Switch (ButtonMode)
    {
    case 1:                         //!Modal, !LMBCancel
        Logic.Close();

        //Note: Don't consume this input because the game needs to notice that the
        //  right-mouse is released.
        return false;

    case 2:                         //!Modal, LMBCancel
        GiveCommand();
        Logic.Close();
        return true;

    case 3:                         //Modal, !LMBCancel
    case 4:                         //Modal, LMBCancel
        return true;
    }

    assert(false);
}

function bool OnLeftMousePressed()
{
    local int ButtonMode;

    ButtonMode = SwatGUIControllerBase(Controller).GuiConfig.GCIButtonMode;

    Switch (ButtonMode)
    {
    case 1:                         //!Modal, !LMBCancel
        GiveCommand();
        Logic.Close();
        return true;

    case 2:                         //!Modal, LMBCancel
        Logic.Close();
        return true;

    case 3:                         //Modal, !LMBCancel
        GiveCommand();
        Logic.Close();
        return true;

    case 4:                         //Modal, LMBCancel
        Logic.Close();
        return true;
    }

    assert(false);
}

function bool SelectCommandTeam()
{
    Logic.NextTeam();
    return true;
}

protected function OnMouseMovedUp()
{
    local Command NewCommand;

    if (CurrentCommand == None) return;     //this can happen if the interface is closing

    NewCommand = MenuPages[int(CurrentCommand.Page)].GetNextCommandUp(CurrentCommand);

    if (NewCommand != CurrentCommand)
    {
        SelectCommand(NewCommand);
        TriggerEffectEvent('SelectionChanged');
    }
}

protected function OnMouseMovedDown()
{
    local Command NewCommand;

    if (CurrentCommand == None) return;     //this can happen if the interface is closing

    NewCommand = MenuPages[int(CurrentCommand.Page)].GetNextCommandDown(CurrentCommand);

    if (NewCommand != CurrentCommand)
    {
        SelectCommand(NewCommand);
        TriggerEffectEvent('SelectionChanged');
    }
}

protected function OnMouseMovedRight()
{
    if (CurrentCommand == None) return;     //this can happen if the interface is closing

    if ( CurrentCommand.SubPage != Page_None)
    {
        SelectCommand(MenuPages[int(CurrentCommand.SubPage)].GetTopCommand(), true);    //LateralMove
        TriggerEffectEvent('MenuChanged');
    }
}

protected function OnMouseMovedLeft()
{
    if (CurrentCommand == None) return;     //this can happen if the interface is closing

    if (Logic.MenuInfo[int(CurrentCommand.Page)].AnchorCommand != Command_None)
    {
        SelectCommand(Logic.Commands[int(Logic.MenuInfo[int(CurrentCommand.Page)].AnchorCommand)], true);    //LateralMove
        TriggerEffectEvent('MenuChanged');
    }
}

function Scroll(name UpOrDown)
{
    if (!MenuOwner.bActiveInput)
        return;                 //GCI isn't active (visible)

    //scrolling represents a complete gesture; reset the mouse gesture
    LastMouseMoveTime = Logic.Level.TimeSeconds;
    GestureDistanceX = 0;
    GestureDistanceY = 0;

    switch (UpOrDown)
    {
        case 'Up':
            OnMouseMovedUp();
            break;

        case 'Down':
            OnMouseMovedDown();
            break;

        default:
            assertWithDescription(false,
                "[tcohen] GUIGraphicCommandInterface::Scroll() UpOrDown is not 'Up' or 'Down'.  Check keybindings.");
            break;
    }
}

//issue the currently selected command
protected function GiveCommand()
{
    if (CurrentCommand == None) return;     //this can happen if the interface is closing

    Logic.GiveCommand(CurrentCommand, Logic.Level.GetLocalPlayerController().bHoldCommand > 0);

    TriggerEffectEvent('GaveCommand');
}

function Command GetCommandRef(CommandInterface.ECommand Command)
{
    return Logic.Commands[int(Command)];
}

function Command GetDefaultCommand()
{
    return Logic.GetDefaultCommand();
}

//utility

//pad string out to Length characters - for output formatting
//SLOW
//TMC TODO consider moving Pad() into Object
final function string Pad(int Length, coerce string S)
{
    while (Len(S) < Length)
        S = S $ " ";

    return S;
}

//GUIComponent changes the MenuState in MousePressed/Released()... we don't want that behavior
event MousePressed() {}
event MouseReleased() {}

function TriggerEffectEvent(name EffectEvent)
{
    Logic.TriggerEffectEvent(EffectEvent);
}

defaultproperties
{
    OpenCloseTime=0.200000
    MouseSensitivity=1.0
    MouseGestureTime=0.5
    MouseDistanceBetweenMenuPads=8.0
    MouseDistanceBetweenMenus=10.0
    bNeverFocus=false
    bCaptureMouse=true

    //we want to manage the visibility of all subcomponents
    PropagateVisibility=false
    PropagateState=false
    ScrollTime=0.0

    bPersistent=True
    MainPageCenterOffset=(X=0.025)
}
