class GUIGraphicCommandInterfaceMenu extends Core.Object
    threaded
    native;

import enum ECommand from CommandInterface;
import enum CommandInterfacePage from CommandInterface;

const MAX_COMMANDS_PER_PAGE = 13;

var GUIGraphicCommandInterface                  GCI;
var CommandInterfacePage                        Page;
var bool                                        IsAMainMenu;

var GUIGraphicCommandInterface.ScreenLocation   Origin;   //the origin is the location of all pads when this menu is closed
var GUIGraphicCommandInterface.ScreenLocation   Root;     //the root is the location of the topmost pad when this menu is open

var GUIGraphicCommandInterfaceMenuPad           MenuPads[MAX_COMMANDS_PER_PAGE];

function Open()
{
    local GUIGraphicCommandInterface.ScreenLocation CurrentLocation;
    local float VerticalSpacing;
    local float HorizontalSpacing;
	local bool CascadeUp;
    local GUIGraphicCommandInterfaceMenuPad CurrentPad;
    local int i;

    GotoState('');  //if we were Closing, then leave that state

    CloseInstantly();   //updates origin and root, and moves to closed positions

    VerticalSpacing = GCI.ActualHeight();
    HorizontalSpacing = GCI.ActualWidth();

    CascadeUp = GCI.GetLogic().MenuInfo[Page].CascadeUp;

    //hide pads with no command
    //show pads with commands
    //move visible pads from root position into open positions
    CurrentLocation = Root;

    for (i=0; i<MAX_COMMANDS_PER_PAGE; ++i)
    {
        CurrentPad = MenuPads[i];

        if (CurrentPad.HideInGCI(GCI))
        {
            CurrentPad.SetVisibility(false);
        }
        else
        {
            CurrentPad.SetVisibility(true);
            CurrentPad.MoveTo(CurrentLocation.X, CurrentLocation.Y, HorizontalSpacing, VerticalSpacing, GCI.OpenCloseTime);

            if (CascadeUp)
                CurrentLocation.Y -= VerticalSpacing;
            else
                CurrentLocation.Y += VerticalSpacing;
        }
    }

    if (IsAMainMenu)
        GCI.TriggerEffectEvent('MainMenuBeganOpening');
    else
        GCI.TriggerEffectEvent('SubMenuBeganOpening');
}

function Close()
{
    local int i;

    //move pads to root position
    for (i=0; i<MAX_COMMANDS_PER_PAGE; ++i)
        MenuPads[i].MoveTo(Origin.X, Origin.Y, 0, 0, GCI.OpenCloseTime);

    if (IsAMainMenu)
        GCI.TriggerEffectEvent('MainMenuBeganClosing');
    else
        GCI.TriggerEffectEvent('SubMenuBeganClosing');

    GotoState('Closing');
}
state Closing
{
    function HidePads()
    {
        local int i;

        for (i=0; i<MAX_COMMANDS_PER_PAGE; ++i)
            MenuPads[i].SetVisibility(false);
    }

Begin:
    Sleep(GCI.OpenCloseTime);
    HidePads();
}

function CloseInstantly()
{
    local int i;

    UpdateOriginAndRoot();

    for (i=0; i<MAX_COMMANDS_PER_PAGE; ++i)
    {
        MenuPads[i].MoveTo(Origin.X, Origin.Y, 0, 0, 0);
        MenuPads[i].OnUnselected();
        MenuPads[i].SetVisibility(false);
    }
}

//update the root location of this menu page
private function UpdateOriginAndRoot()
{
    local ECommand AnchorCommand;
    local Command AnchorCommandRef;
    local GUIGraphicCommandInterfaceMenu AnchorPage;
    local GUIGraphicCommandInterfaceMenuPad Pad;
    local int PadsPrecedingDefault;
    local bool FoundDefault;
    local int i;

    AnchorCommand = GCI.GetLogic().MenuInfo[Page].AnchorCommand;

    if (AnchorCommand == Command_None)  //main page
    {
        Origin.X = GCI.Controller.ResolutionX / 2;
        Origin.Y = GCI.Controller.ResolutionY / 2;

        if (GCI.PlayerOwner().Level.NetMode == NM_Standalone)
        {
            //calculate the number of active menu pads above the default command
            FoundDefault = false;
            for (i=0; i<MAX_COMMANDS_PER_PAGE; ++i)
            {
                if (MenuPads[i].Command == GCI.GetDefaultCommand())
                {
                    FoundDefault = true;
                    break;
                }
                else
                if (MenuPads[i].Command != None)
                    PadsPrecedingDefault++;
            }
        }
        //else: the vertical position of the main menu doesn't change in MP

        if (!FoundDefault)
            //the DefaultCommand is not on this page
            PadsPrecedingDefault = 0;   //root at the first visible pad

        Root.X = Origin.X + GCI.Controller.ResolutionX * GCI.MainPageCenterOffset.X;
        Root.Y = Origin.Y - PadsPrecedingDefault * GCI.ActualHeight();

        return;
    }

    //AnchorPage is the menu page that contains our AnchorCommand
    AnchorCommandRef = GCI.GetCommandRef(AnchorCommand);
    AnchorPage = GCI.MenuPages[int(AnchorCommandRef.Page)];

    //the GCI may not have finished initializing yet, in which case we should just return early here
    if( AnchorPage == None )
        return;

    //find the ScreenLocation of our AnchorCommand on AnchorPage
    for (i=0; i<MAX_COMMANDS_PER_PAGE; ++i)
    {
        Pad = AnchorPage.MenuPads[i];
        if (Pad.Command == AnchorCommandRef)
        {
            if( Pad.bRepositioning )
            {
                Origin.X = Pad.TransitionSpec.NewPos.WinLeft + Pad.TransitionSpec.NewPos.WinWidth + 2;
                Origin.Y = Pad.TransitionSpec.NewPos.WinTop + GCI.ActualHeight() / 2;
            }
            else
            {
                Origin.X = Pad.ActualLeft() + Pad.ActualWidth() + 2;
                Origin.Y = Pad.ActualTop() + GCI.ActualHeight() / 2;
            }

            Root.X = Origin.X;
            Root.Y = Origin.Y;

            return;
        }
    }

//TMC This will happen 1) upon startup, when the main menu is not yet populated
//  and potentially 2) if the anchor of a sub menu is currently disabled.
//
//    assertWithDescription(false,
//        "[tcohen] GUIGraphicCommandInterfaceMenu::UpdateOriginAndRoot() The Menu "$name
//        $" could not locate its AnchorCommand "$GetEnum(ECommand, AnchorCommand)
//        $" on its AnchorPage "$AnchorPage.name
//        $".");
    log("Menu "$name $" could not locate its AnchorCommand "$GetEnum(ECommand, AnchorCommand) $" on its AnchorPage "$AnchorPage.name);
    return;
}

function ClearAllCommands()
{
    local int i;

    for (i=0; i<MAX_COMMANDS_PER_PAGE; ++i)
        MenuPads[i].Command = None;
}

function ClearCommands(bool PageChange)
{
    local int i;

    for (i=0; i<MAX_COMMANDS_PER_PAGE; ++i)
        if (MenuPads[i].Command != None && !MenuPads[i].Command.bStatic)
            MenuPads[i].Command = None;
}

function Command GetNextCommandUp(Command CurrentCommand)
{
    if (GCI.GetLogic().MenuInfo[Page].CascadeUp)
        return GetCommandNextIndex(CurrentCommand);
    else
        return GetCommandPreviousIndex(CurrentCommand);
}

function Command GetNextCommandDown(Command CurrentCommand)
{
    if (!GCI.GetLogic().MenuInfo[Page].CascadeUp)
        return GetCommandNextIndex(CurrentCommand);
    else
        return GetCommandPreviousIndex(CurrentCommand);
}

function Command GetCommandPreviousIndex(Command CurrentCommand)
{
    local int i;

    for (i=CurrentCommand.GCIMenuPad-1; i>=0; --i)
        if (!MenuPads[i].HideInGCI(GCI))
            return MenuPads[i].Command;

    //nothing above
    return CurrentCommand;
}

function Command GetCommandNextIndex(Command CurrentCommand)
{
    local int i;

    for (i=CurrentCommand.GCIMenuPad+1; i<MAX_COMMANDS_PER_PAGE; ++i)
        if (!MenuPads[i].HideInGCI(GCI))
            return MenuPads[i].Command;

    //nothing above
    return CurrentCommand;
}

function Command GetTopCommand()
{
    local int i;

    for (i=0; i<MAX_COMMANDS_PER_PAGE; ++i)
        if (MenuPads[i].Command != None)
            return MenuPads[i].Command;

    assertWithDescription(false,
        "[tcohen] GUIGraphicCommandInterfaceMenu::GetTopCommand() no Commands found.");
}
