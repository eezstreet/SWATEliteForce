class WatcherBase extends Action
	threaded
	abstract;

var() actionnoresolve name watcherName;
var() bool enabled;

defaultproperties
{
	enabled = True
}