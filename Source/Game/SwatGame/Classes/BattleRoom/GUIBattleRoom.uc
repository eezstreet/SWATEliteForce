class GUIBattleRoom extends GUI.GUIMultiComponent;

#if IG_BATTLEROOM

const MAX_MENU_ITEMS = 5;

const MENU_GOD = 0;
const MENU_DEBUG = 1;
const MENU_HEALTH = 2;
const MENU_MORALE = 3;
const MENU_CANCEL = 4;

var GUIButton BattleRoomMenu[MAX_MENU_ITEMS];
var string    MenuOptions[MAX_MENU_ITEMS];
var GUIImage  ScreenCanvas;
var Pawn      MenuPawn;
var bool      bMenuOpen;
var bool      bSavedMenuPause;

function OnConstruct(GUIController MyController)
{
    local int ct;

    Super.OnConstruct(MyController);
    ScreenCanvas = GUIImage(AddComponent("GUI.GUIImage", "HUDPage_BattleRoomScreen"));

    for (ct=0; ct<MAX_MENU_ITEMS; ++ct)
    {
        BattleRoomMenu[ct] = GUIButton(AddComponent("GUI.GUIButton", class.name$"_Button"$ct));

    }
}

function InitComponent(GUIComponent Owner)
{
    local int ct;
    log("init component!");
    Super.InitComponent(Owner);

    log("menu owner="$MenuOwner);
    for (ct=0; ct<MAX_MENU_ITEMS; ++ct)
    {
        BattleRoomMenu[ct].Style = Style;
        BattleRoomMenu[ct].bBoundToParent = false;
        BattleRoomMenu[ct].bScaleToParent = false;
        BattleRoomMenu[ct].WinWidth = 0.1;
        BattleRoomMenu[ct].WinHeight = 0.01;
        BattleRoomMenu[ct].SetCaption( MenuOptions[ct] );
        BattleRoomMenu[ct].Hide();
    }
}

function CommandClicked(GUIComponent Component)
{
    local int ct;

    for ( ct = 0; ct < MAX_MENU_ITEMS; ++ct )
    {
        if ( Component == BattleRoomMenu[ct] )
        {
            switch (ct)
            {
                case MENU_GOD:
                    MenuPawn.Controller.bGodMode = !MenuPawn.Controller.bGodMode;
                    break;
                case MENU_DEBUG:
                    MenuPawn.bDisplayBattleDebug = !MenuPawn.bDisplayBattleDebug;
                    break;
                case MENU_MORALE:
                    if ( MenuPawn.IsA('SwatAI') )
                    {
                        SwatAI(MenuPawn).GetCommanderAction().ChangeMorale( 0.4, "Battle Room Morale Boost!" );                      
                    }
                    break;
                case MENU_HEALTH:
                    MenuPawn.Health = 1000;
                    MenuPawn.Default.Health = 1000;
                    break;
            }
        }
    }
    CloseMenu();
}

function Open()
{
	Style = Controller.GetStyle("STY_lunarblue");
    Show();
    ScreenCanvas.FillOwner();
    ScreenCanvas.Show();
}

function OpenMenu(Pawn inPawn)
{
    local int ct;

    Activate();   //activate the HUDPage (accept input)
    ScreenCanvas.bActiveInput = false;
    ScreenCanvas.bAcceptsInput = false;

    MenuPawn = inPawn;
    
    Focus();  //set focus to the GUIGraphicCommandInterface
    Press();  //capture the mouse

    MenuReposition();

    for (ct=0; ct<MAX_MENU_ITEMS; ++ct)
    {
        BattleRoomMenu[ct].SetCaption( MenuOptions[ct] );
        BattleRoomMenu[ct].Style = Style;
        BattleRoomMenu[ct].OnMouseRelease = CommandClicked;
        BattleRoomMenu[ct].Show();
     }

    bMenuOpen = true;
    Controller.ActiveControl = self;
    bSavedMenuPause = Controller.ViewportOwner.Actor.Level.bPlayersOnly;
    Controller.ViewportOwner.Actor.Level.bPlayersOnly = true;
}

function MenuReposition()
{
    local int ct;
    local sDynamicPositionSpec Position;
    local Vector Screen;

    Screen = Controller.WorldToScreen( (MenuPawn.Location) );

    for (ct=0; ct<MAX_MENU_ITEMS; ++ct)
    {
        Controller.GetGuiResolution();        
        Position.WinLeft = ((Screen.X+50)/Controller.ResolutionX);
        Position.WinTop = ((Screen.Y-(20*MAX_MENU_ITEMS))/Controller.ResolutionY) + (0.05*ct);  
        Position.WinWidth = 0.11;
        Position.WinHeight = 0.05;
        Position.TransitionTime = 0;
        Position.KeyName = 'Temp';

        BattleRoomMenu[ct].bBoundToParent = false;
        BattleRoomMenu[ct].bScaleToParent = false;
        BattleRoomMenu[ct].WinWidth = 0.11;
        BattleRoomMenu[ct].WinHeight = 0.05;

        BattleRoomMenu[ct].RepositionTo(Position);
     }
}


function CloseMenu()
{
    local int ct;

    ScreenCanvas.Show();
    ScreenCanvas.bActiveInput = true;
    ScreenCanvas.bAcceptsInput = true;

    //initialize the selected pad index
    //SelectPad(DefaultPadIndex, MoveTime);
    for (ct=0; ct<MAX_MENU_ITEMS; ++ct)
    {
        BattleRoomMenu[ct].Hide();
    }

    Controller.ActiveControl = self;
    bMenuOpen = false;
    if ( !bSavedMenuPause )
        Controller.ViewportOwner.Actor.Level.bPlayersOnly = false;
}

function Close()
{
    Hide();
    Deactivate();
}

defaultproperties
{
    MenuOptions(0)="Toggle god."
    MenuOptions(1)="Toggle Debug."
    MenuOptions(2)="1000 Health."
    MenuOptions(3)="Boost Morale."
    MenuOptions(4)="Cancel."
}
#endif // IG_BATTLEROOM