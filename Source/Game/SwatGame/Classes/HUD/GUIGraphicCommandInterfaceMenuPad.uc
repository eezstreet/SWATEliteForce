class GUIGraphicCommandInterfaceMenuPad extends GUI.GUIButton
    native;

var Command Command;
var eMenuState UnselectedState;

function MoveTo(float X, float Y, float W, float H, float Time)
{
    local sDynamicPositionSpec Position;

    Position.WinTop = Y - H / 2.0;  //center left side at (X,Y)
    Position.WinLeft = X;
    Position.WinWidth = W;
    Position.WinHeight = H;
    Position.TransitionTime = Time;
    Position.KeyName = 'Temp';
    Position.Transparency = 1.0;

    RepositionTo(Position);
}

function OnSelected()
{
    Watched();
}

function OnUnselected()
{
    //note this still isn't quite up to par, but it works for now and is better than before
    Switch(UnselectedState)
    {
        case MSAT_Blurry:
            EnableComponent();
            break;
        case MSAT_Disabled:
            DisableComponent();
            break;
    }
}

function bool HideInGCI(GUIGraphicCommandInterface GCI)
{
    return  (
                Command == None     //no command set on this pad
            ||  (
                    Command.IsCancel
                &&  !GCI.bUseExitPad
                )                   //not displaying the cancel pad
            );
}

defaultproperties
{
    bAllowHTMLTextFormatting=true
}
