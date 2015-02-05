//=====================================================================
// AI_Controller
// Dummy controller class to make Unreal happy
// - used to replicate data
// - stores frag statistics etc
// - contains interface to movement physics system
// - used as parameter to hearing related functions
//=====================================================================

class AI_Controller extends Engine.Controller
	native;

// debug stuff
const DEBUGAI_X = 20;					// where debugai info will display on screen
const DEBUGAI_Y = 100;

//---------------------------------------------------------------------

event OnHearSound(Actor SoundMaker, vector SoundOrigin, Name SoundCategory)
{
#if IG_TRIBES3
	// temporary (probably want to catch this case earlier)
	if (Rook(pawn).hearing != None)
		Rook(pawn).hearing.OnHearSound(SoundMaker, SoundOrigin, SoundCategory);
#elif IG_SWAT
    // do nothing; this is overridden in SwatGame.SwatAIController
#else
    // by default, do nothing
#endif    
}

//---------------------------------------------------------------------
// Display AI Debug Info

function drawDebug( Canvas canvas, HUD hud )
{
#if 0
	local array<String> debugAIText;
	local int i;
	local float strX;
	local float strY;
	local float debugAIX;
	local float debugAIY;
	local AI_Resource r;
	local Gameplay.DefaultHUD dhud;

	// construct debug text
	dhud = Gameplay.DefaultHUD( hud );
	if ( Pawn != None )
	{
		debugAIText.length = 4;
		debugAIText[0] = String( Pawn.name ) $ ":";
		r = AI_Resource( Pawn.characterAI );

		debugAIText[1] = " Goals:";
		for ( i = 0; i < r.goals.length; i++ )
			debugAIText[1] = debugAIText[1] $ " " $ r.goals[i].name;

		debugAIText[2] = " Running Actions:";
		for ( i = 0; i < r.runningActions.length; i++ )
			debugAIText[2] = debugAIText[2] $ " " $ r.runningActions[i].name;

		debugAIText[3] = " Idle Actions:";
		for ( i = 0; i < r.idleActions.length; i++ )
			debugAIText[3] = debugAIText[3] $ " " $ r.idleActions[i].name;

		// render text
		Canvas.SetDrawColor(255, 0, 0, 255);
		debugAIX = /*Scale * */ DEBUGAI_X;
		debugAIY = /*Scale * */ DEBUGAI_Y;
		Canvas.Font = dhud.smallFont; //MyFont.GetSmallFont(Canvas.ClipX);
		for (i = 0; i < debugAIText.length; i++)
		{
			Canvas.StrLen(debugAIText[i], strX, strY);
			Canvas.SetPos(debugAIX /*- strX / 2*/, debugAIY + i * strY - strY / 2);	
			Canvas.DrawText(debugAIText[i], false);		
		}
	}
#endif
}

//=============================================================================

defaultProperties
{
}
