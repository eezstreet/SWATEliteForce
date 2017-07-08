class Command_MP extends Command
    config(PlayerInterface_Command_MP);

//Commands are normally played on the listener, ie. as if coming from your comm. radio,
//  and they are only played on friendlies and not on opponents.
//If a Command IsTaunt, then it is played on the speaker, ie. as if you are hearing them directly,
//  and they are played on every client, not just friendlies.
var config bool IsTaunt;

//certain commands refer to the speaker as the target of the command (ex. "Fall In", "Cover Me")
var config bool TargetIsSelf;

//the length of time (in seconds) to display the command arrow for this command
//  if <= 0.0, will not display an arrow for this command
var config float ArrowLifetime;

defaultproperties
{
    ArrowLifetime=8.0
}