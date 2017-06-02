class GraphicCommandInterface extends CommandInterface
    native
    abstract;

var protected GUIGraphicCommandInterface View;

var private bool bIsClosed;
var private bool bWasClosedBeforePageChange;


simulated function Initialize()
{
    local SwatGamePlayerController Player;

    Player = SwatGamePlayerController(Level.GetLocalPlayerController());

    View = Player.GetHUDPage().GraphicCommandInterface;
    assert(View != None);
log( self$"::Initialize() ... Setting the Logic to self!" );
    View.SetLogic(self);

    View.ClearAllCommands();

    Super.Initialize();

    View.OnCurrentTeamChanged(CurrentCommandTeam);

    SetCurrentPage(CurrentMainPage, true);    //force update

    View.CloseInstantly();
}

//
// Update Sequence - See documentation above PlayerFocusInterface::PreUpdate()
//

simulated protected function bool PreUpdateHook(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    return Super.PreUpdateHook(Player, HUDPage) && bIsClosed;
}

//
// (End of Update Sequence)
//

simulated function CancelGivingCommand()
{
    Close();
}

simulated function Open()
{
    if (!Enabled || !SwatGamePlayerController(Level.GetLocalPlayerController()).CanOpenGCI())
    {
        TriggerEffectEvent('Denied');
        return;
    }

	EnsureMenuPageValid();

	SwatGamePlayerController(Level.GetLocalPlayerController()).UpdateFocus();
    View.Open();

    bIsClosed = false;
}

simulated protected function PostDeactivated()
{
    View.Hide();
}

//
// forward calls to the view
//

simulated function Close()
{
    View.Close();

    bIsClosed = true;
}

simulated protected function OnCurrentTeamChanged(SwatAICommon.OfficerTeamInfo NewTeam)
{
    if (View != None)
        View.OnCurrentTeamChanged(NewTeam);
}

simulated function ClearCommands(bool PageChange)
{
    if (View != None)
        View.ClearCommands(PageChange);
}

simulated function SetCommand(Command Command, MenuPadStatus Status)
{
    if (View != None)
        View.SetCommand(Command, Status);
}

simulated event Destroyed()
{
    View = None;

    Super.Destroyed();
}

//called from CommandInterface::SetMainPage(), usually as a result of NextMainPage()
simulated protected function PreMainPageChanged()
{
    bWasClosedBeforePageChange = bIsClosed;
    bIsClosed=true;

    if (View != None)
        View.CloseInstantly();
}

//called from CommandInterface::SetMainPage(), usually as a result of NextMainPage()
simulated protected function PostMainPageChanged()
{
	//restore bIsClosed from before the page change
    bIsClosed = bWasClosedBeforePageChange;

	//if we are not closed, open the view.
    if (View != None && !bIsClosed)
        View.Open();
}

// added by Marc (19-Apr-2005)
simulated function Command GetCurrentCommand()
{
	if (View != None)
		return View.CurrentCommand;
}

simulated function bool IsOpen()
{
	return !bIsClosed;
}

// is current command "holdable"? (for a later zulu)
simulated function bool IsCurrentCommandHoldable()
{
	if (View != None)
		return View.IsCurrentCommandHoldable();
	else
		return false;
}

cpptext
{
    UBOOL Tick(FLOAT DeltaSeconds, enum ELevelTick TickType);
}

defaultproperties
{
    bStatic=false
    Physics=PHYS_None
    bStasis=true
    bIsClosed=true
}
