class GUIDefaultCommandIndicator extends GUI.GUILabel;

var(CommandInterface) config string RedTeamStyleName "The Syle to use when displaying a command for the RED team.";
var(CommandInterface) config string BlueTeamStyleName "The Syle to use when displaying a command for the BLUE team.";
var(CommandInterface) config string AsAnElementStyleName "The Syle to use when displaying a command for the entire ELEMENT.";

function OnCurrentTeamChanged(SwatAICommon.OfficerTeamInfo NewTeam)
{
    if( NewTeam == None )
    {
        Style = Controller.GetStyle(AsAnElementStyleName);
    }
    else
    {
        switch (NewTeam.Label)
        {
            case 'Element':
                Style = Controller.GetStyle(AsAnElementStyleName);
                break;

            case 'RedTeam':
                Style = Controller.GetStyle(RedTeamStyleName);
                break;

            case 'BlueTeam':
                Style = Controller.GetStyle(BlueTeamStyleName);
                break;

            default:
                //Should only be the case in multplayer
                Style = Controller.GetStyle(AsAnElementStyleName);
        }
    }
}

defaultproperties
{
    bPersistent=True
}