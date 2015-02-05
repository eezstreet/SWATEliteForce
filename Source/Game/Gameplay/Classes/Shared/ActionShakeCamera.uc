class ActionShakeCamera extends Scripting.Action;

var() float rollMagnitude "How far to roll the view";
var() float rollRate "How fast to roll the view";
var() float rollTime "How long to roll the view";

var() actionnoresolve Vector offsetMagnitude "How far to offset the view";
var() actionnoresolve Vector offsetRate "How fast to offset the view";
var() float offsetTime "How long to offset the view";

latent function Variable execute()
{
	local PlayerController pcc;

	Super.execute();

	pcc = parentScript.Level.GetLocalPlayerController();

	if (pcc != None)
	{
		pcc.ShakeView(rollTime, rollMagnitude, offsetMagnitude, rollRate, offsetRate, offsetTime);
	}
	else
	{
		SLog("Couldn't get the players controller");
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Shake the players view";
}

defaultproperties
{
	rollMagnitude		= 400.0
	rollRate			= 12000.0
	rollTime			= 25.0

	offsetMagnitude		= (X=5.0,Y=0.0,Z=10.0)
	offsetRate			= (X=250.0,Y=250.0,Z=250.0)
	offsetTime			= 10.0

	returnType			= None
	actionDisplayName	= "Shake Camera"
	actionHelp			= "Sakes the players view"
	category			= "AudioVisual"
}
