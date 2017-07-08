class ActionCinematicFadeView extends Action;

var() actionnoresolve color fadeStart;
var() actionnoresolve color fadeEnd;
var() actionnoresolve float fadeAlphaStart	"The start alpha value of the fade, between 0 and 1";
var() actionnoresolve float fadeAlphaEnd	"The end alpha value of the fade, between 0 and 1";
var() float duration						"Duration of fade in seconds. Set to zero for an instant adjustment";
var() float holdDuration					"Time in seconds to hold the fade after the duration is over.";
var() bool bRestoreFadeControl				"If false, then fade control is not restored to the game after the action is finished. When you are finished with this behaviour, you will need to trigger a 'zero duration' fade action with this variable set to false. If you do not do this, the screen may remain black and pain flashes will not work.";

var float startTime;

// execute
latent function Variable execute()
{
	local PlayerController pc;
	local Vector fadeDiff;
	local float alpha;

	Super.execute();

	pc = parentScript.Level.GetLocalPlayerController();
	
	if( pc == None )
	    return None;
	    
	pc.bManualFogUpdate = true;

	if (duration != 0)
	{
		fadeDiff.X = fadeEnd.R - fadeStart.R;
		fadeDiff.Y = fadeEnd.G - fadeStart.G;
		fadeDiff.Z = fadeEnd.B - fadeStart.B;

		startTime = parentScript.Level.TimeSeconds;
		while (parentScript.Level.TimeSeconds - startTime < duration)
		{
			alpha = (parentScript.Level.TimeSeconds - startTime) / duration;

			pc.FlashFog.X = (float(fadeStart.R) + fadeDiff.X * alpha) / 255;
			pc.FlashFog.Y = (float(fadeStart.G) + fadeDiff.Y * alpha) / 255;
			pc.FlashFog.Z = (float(fadeStart.B) + fadeDiff.Z * alpha) / 255;
			pc.FlashScale.X = 1.0f - (fadeAlphaStart + (fadeAlphaEnd - fadeAlphaStart) * alpha); // for some reason, flashscale 0 means full alpha
			pc.FlashScale.Y = pc.FlashScale.X;
			pc.FlashScale.Z = pc.FlashScale.X;
			Sleep(0);

			log(pc.FlashFog.X@pc.FlashScale.X);
		}
	}
	else
	{
		pc.FlashFog.X = fadeEnd.R / 255;
		pc.FlashFog.Y = fadeEnd.G / 255;
		pc.FlashFog.Z = fadeEnd.B / 255;
		pc.FlashScale.X = fadeAlphaEnd;
		pc.FlashScale.Y = pc.FlashScale.X;
		pc.FlashScale.Z = pc.FlashScale.X;
	}

	if (holdDuration > 0)
		Sleep(holdDuration);

	if (bRestoreFadeControl)
		pc.bManualFogUpdate = false;

	pc.FlashScale.X = 1;
	pc.FlashScale.Y = 1;
	pc.FlashScale.Z = 1;

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Fade view";
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Fade View"
	actionHelp			= "Fades the view. Does not finish until the fade is completed."
	category			= "Cinematic"

	duration			= 2
	fadeStart			= (R=0,G=0,B=0)
	fadeEnd				= (R=0,G=0,B=0)
	fadeAlphaStart		= 0
	fadeAlphaEnd		= 1
	bRestoreFadeControl = true
}