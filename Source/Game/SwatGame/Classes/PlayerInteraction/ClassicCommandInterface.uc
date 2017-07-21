class ClassicCommandInterface extends CommandInterface
    abstract;

import enum EquipmentSlot from Engine.HandheldEquipment;

var config localized string ElementString;
var config localized string RedTeamString;
var config localized string BlueTeamString;
var config localized string BackString;
var config localized string DeployMenuKeyString;
var config localized string TwelveMenuKeyString;

var private config array<ECommand> ReverseCommands; // These commands will trigger a Back()

const MAX_COMMANDS          = 13;

struct MenuPad
{
    var Command Command;
    var MenuPadStatus Status;
};
var MenuPad CurrentMenuPads[MAX_COMMANDS];

var HUDPageBase HUDPage;

var protected GUIClassicCommandInterfaceContainer View;

const ROW_SPACING = 14.0;

simulated function Initialize()
{
    local SwatGamePlayerController Player;

    Player = SwatGamePlayerController(Level.GetLocalPlayerController());
    assert(Player != None);

    HUDPage = Player.GetHUDPage();
    assert(HUDPage != None);

    View = HUDPage.ClassicCommandInterface;
    assertWithDescription(View != None,
        "[tcohen] ClassicCommandInterface::OnGameStarted() HUDPage.ClassicCommandInterface is None.");

    View.SetCCIStyle('Element');            //in the case of MP, we never change this

    Super.Initialize();
}

//
// Update Sequence - See documentation above PlayerFocusInterface::PreUpdate()
//

simulated function PostUpdate(SwatGamePlayerController Player)
{
    Super.PostUpdate(Player);

    UpdateView();
}

//
// (End of Update Sequence)
//

simulated function SetCommand(Command Command, MenuPadStatus Status)
{
    if (Command.Page == CurrentPage)
    {
        CurrentMenuPads[Command.CCIMenuPad].Command    = Command;
        CurrentMenuPads[Command.CCIMenuPad].Status     = Status;
    }
}

simulated function SetCurrentPage(CommandInterfacePage NewPage, optional bool Force)
{
    if (CurrentPage != NewPage || Force)
    {
        CurrentPage = NewPage;
        ClearCommands(true);        //changing pages
        ActivateStaticCommands();
        UpdateFocus();
    }
}

//called from final function CommandInterface::SetMainPage(), usually as a result of CommandInterface::NextMainPage()
simulated protected function PostMainPageChanged()
{
    SetCurrentPage(CurrentMainPage);
}

simulated function GiveCommandIndex(int CommandIndex, optional bool bHoldCommand)
{
    local SwatGamePlayerController Player;

    assertWithDescription(CommandIndex <= MAX_COMMANDS,
        "[tcohen] CommandInterface::GiveCommand() was called with CommandIndex="$CommandIndex
        $", but MAX_COMMANDS="$MAX_COMMANDS
        $".");

    Player = SwatGamePlayerController(Level.GetLocalPlayerController());

    switch (CurrentMenuPads[CommandIndex].Status)
    {
    case Pad_Disabled:
        return;     //that command is unavailable

    case Pad_GreyedOut:
        Player.TriggerEffectEvent('GreyedOutCommandGiven');
        break;

    case Pad_Normal:
        Player.TriggerEffectEvent('NormalCommandGiven');
        break;

    default:
        assert(false);  //unexpected pad status
        break;
    }

    GiveCommand(CurrentMenuPads[CommandIndex].Command, bHoldCommand);
}

simulated function UpdateView()
{
    local int i;
    local string DrawnIndex;
    local string Text;

#if IG_SWAT_TESTING_MP_CI_IN_SP //tcohen: testing MP CommandInterface behavior in SP
    if (false)
#else
    if (Level.NetMode == NM_Standalone)
#endif
    {
        //in SP, the first line of the CCI indicates the current team

        if (CurrentCommandTeam == Element)
        {
            View.SetCCIStyle('Element');
            Text = "[c=ffffff]" $ ElementString $ "[\\c]" $ "|";
        }
        else
        if (CurrentCommandTeam == RedTeam)
        {
            View.SetCCIStyle('Red');
            Text = "[c=ffffff]" $ RedTeamString $ "[\\c]" $ "|";
        }
        else
        if (CurrentCommandTeam == BlueTeam)
        {
            View.SetCCIStyle('Blue');
            Text = "[c=ffffff]" $ BlueTeamString $ "[\\c]" $ "|";
        }
        else
            assertWithDescription(false,
                "[tcohen] ClassicCommandInterface::UpdateView() CurrentCommandTeam doesn't match any of the known teams.");
    }
    else    //playing MP
    {
        //in MP, the first line of the CCI indicates the current main menu page

        Text = MenuInfo[int(CurrentMainPage)].Text $ "|";
    }

    for (i=1; i<MAX_COMMANDS; ++i)
    {
        //set the string to display for each index
        switch (i)
        {
        case 10:
            DrawnIndex = "0";
            break;

        case 11:
            DrawnIndex = DeployMenuKeyString;
            break;

		case 12:
            DrawnIndex = TwelveMenuKeyString;
            break;

        default:
            DrawnIndex = string(i);
            break;
        }

        switch (CurrentMenuPads[i].Status)
        {
        case Pad_Normal:
            Text = Text $ "|" $ "[c=000000]" $ DrawnIndex $ "   " $ "[c=ffffff]" $ CurrentMenuPads[i].Command.Text $ "[\\c]";
            break;

        case Pad_GreyedOut:
            Text = Text $ "|" $ "[c=000000]" $ DrawnIndex $ "   " $ "[c=808080]" $ CurrentMenuPads[i].Command.Text $ "[\\c]";
            break;

        case Pad_Disabled:
            Text = Text $ "|";
            break;

        default:
            assert(false);  //unexpected PadStatus
            break;
        }
    }

    if (MenuInfo[GetCurrentPage()].AnchorCommand != Command_None)
        //current page is a sub menu
        Text = Text $ "||     " $ BackString;

    View.SetContent(Text);
}

simulated protected function PostDeactivated()
{
    if (View != None)
        View.Hide();
}

//
//PlayerFocusInterface overrides
//

simulated function ClearCommands(bool PageChange)
{
    local int i;

    for (i=0; i<MAX_COMMANDS; ++i)
    {
        if  (
                PageChange
            ||  CurrentMenuPads[i].Command == None
            ||  !CurrentMenuPads[i].Command.bStatic
            )
            CurrentMenuPads[i].Status = Pad_Disabled;
    }
}

function bool CommandTriggersBack(ECommand Command)
{
  local int i;

  for(i = 0; i < ReverseCommands.Length; i++)
  {
    if(ReverseCommands[i] == Command)
    {
      return true;
    }
  }
  return false;
}

defaultproperties
{
    DeployMenuKeyString="-"
	TwelveMenuKeyString="="
}
