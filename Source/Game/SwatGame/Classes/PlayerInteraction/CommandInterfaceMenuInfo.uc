class CommandInterfaceMenuInfo extends Core.Object
    PerObjectConfig
    abstract;

var config CommandInterface.ECommand            AnchorCommand;
var config bool                                 CascadeUp;
var config localized string                     Text;
var config name                                 OverrideDefaultCommand;

var Command                                     OverrideDefaultCommandObject;

function bool IsAvailable(LevelInfo Level, CommandInterface CI)
{
    return true;
}
