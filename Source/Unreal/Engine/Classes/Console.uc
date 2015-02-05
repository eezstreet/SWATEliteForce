//=============================================================================
// Console - A quick little command line console that accepts most commands.

//=============================================================================
class Console extends Interaction;

// Constants.
const MaxHistory=16;		// # of command histroy to remember.

// Variables

var globalconfig byte ConsoleKey;			// Key used to bring up the console

var int HistoryTop, HistoryBot, HistoryCur;
var string TypedStr, History[MaxHistory]; 	// Holds the current command, and the history
var bool bTyping;							// Turn when someone is typing on the console
var bool bIgnoreKeys;						// Ignore Key presses until a new KeyDown is received							
var font ConsoleFont;
var Texture BackgroundTexture;

function Initialize()
{
	Super.Initialize();
	ConsoleFont = Font(DynamicLoadObject("Engine_res.ConsoleFont", class'Font'));
	BackgroundTexture = Texture(DynamicLoadObject("Engine_res.MenuBlack", class'Texture'));
}

event NativeConsoleOpen()
{
}


//-----------------------------------------------------------------------------
// Exec functions accessible from the console and key bindings.

// Begin typing a command on the console.
exec function Type()
{
	TypedStr="";
	GotoState( 'Typing' );
}

exec function Talk()
{
	TypedStr="Say ";
	GotoState( 'Typing' );
}

exec function TeamTalk()
{
	TypedStr="TeamSay ";
	GotoState( 'Typing' );
}

event NotifyLevelChange()
{
}

//-----------------------------------------------------------------------------
// Message - By default, the console ignores all output.
//-----------------------------------------------------------------------------

event Message( coerce string Msg, float MsgLife);

//-----------------------------------------------------------------------------
// Check for the console key.

function bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
{
	if( Action!=IST_Press )
		return false;
	else if( Key==ConsoleKey )
	{
		GotoState('Typing');
		return true;
	}
	else
		return false;

}

//-----------------------------------------------------------------------------
// State used while typing a command on the console.

state Typing
{
	exec function Type()
	{
		TypedStr="";
		gotoState( '' );
	}
#if IG_SHARED // hkaufman: Prevent the addition of repeated consecutive commands to the console history list
	function int GetPrevHistoryIndex( int Cur )
	{
		local int Prev;
		Prev = -1;
		if ( HistoryBot >= 0 )
		{
			if (Cur == HistoryBot)
				Prev = HistoryTop;
			else
			{
				Prev = Cur - 1;
				if (Prev<0)
					Prev = MaxHistory-1;
			}
		}
		return Prev;
	}
#endif

	function bool KeyType( EInputKey Key, optional string Unicode )
	{
		if (bIgnoreKeys)
			return true;

		if( Key>=0x20 && Key<0x100 && Key!=Asc("~") && Key!=Asc("`") )
		{
			if( Unicode != "" )
				TypedStr = TypedStr $ Unicode;
			else
				TypedStr = TypedStr $ Chr(Key);
			return true;
		}
	}
	function bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
	{
		local string Temp;
#if IG_SHARED // hkaufman: Prevent the addition of repeated consecutive commands to the console history list
		local int PrevInd;
#endif
		if (Action== IST_Press)
		{
			bIgnoreKeys=false;
		}

		if( Key==IK_Escape )
		{
			if( TypedStr!="" )
			{
				TypedStr="";
				HistoryCur = HistoryTop;
				return true;
			}
			else
			{
				GotoState( '' );
			}
		}
		else if( global.KeyEvent( Key, Action, Delta ) )
		{
			return true;
		}
		else if( Action != IST_Press )
		{
			return false;
		}
		else if( Key==IK_Enter )
		{
			if( TypedStr!="" )
			{
				// Print to console.
				Message( TypedStr, 6.0 );

#if IG_SHARED // hkaufman: Prevent the addition of repeated consecutive commands to the console history list
				PrevInd = GetPrevHistoryIndex( HistoryTop );
				// don't advance the history if the command was a repeat.
				if (PrevInd < 0 || TypedStr != History[PrevInd])
				{
#endif
				    History[HistoryTop] = TypedStr;
				    HistoryTop = (HistoryTop+1) % MaxHistory;
    
				    if ( ( HistoryBot == -1) || ( HistoryBot == HistoryTop ) )
					    HistoryBot = (HistoryBot+1) % MaxHistory;
    
				    HistoryCur = HistoryTop;
#if IG_SHARED // hkaufman: Prevent the addition of repeated consecutive commands to the console history list
				}
#endif
				// Make a local copy of the string.
				Temp=TypedStr;
				TypedStr="";

				if( !ConsoleCommand( Temp ) )
					Message( Localize("Errors","Exec","Core"), 6.0 );

				Message( "", 6.0 );
				GotoState('');
			}
			else
				GotoState('');

			return true;
		}
		else if( Key==IK_Up )
		{
#if IG_SHARED // hkaufman: Prevent the addition of repeated consecutive commands to the console history list
			PrevInd = GetPrevHistoryIndex( HistoryCur );
			if (PrevInd >= 0)
			{
				HistoryCur = PrevInd;
				TypedStr = History[HistoryCur];
			}
#else
			if ( HistoryBot >= 0 )
			{
				if (HistoryCur == HistoryBot)
					HistoryCur = HistoryTop;
				else
				{
					HistoryCur--;
					if (HistoryCur<0)
						HistoryCur = MaxHistory-1;
				}
				TypedStr = History[HistoryCur];
			}
#endif
			return True;
		}
		else if( Key==IK_Down )
		{
			if ( HistoryBot >= 0 )
			{
				if (HistoryCur == HistoryTop)
					HistoryCur = HistoryBot;
				else
					HistoryCur = (HistoryCur+1) % MaxHistory;

				TypedStr = History[HistoryCur];
			}

		}
		else if( Key==IK_Backspace || Key==IK_Left )
		{
			if( Len(TypedStr)>0 )
				TypedStr = Left(TypedStr,Len(TypedStr)-1);
			return true;
		}
		return true;
	}

	function PostRender(Canvas Canvas)
	{
		local float xl,yl;
		local string OutStr;

		// Blank out a space

		Canvas.Style = 1;

		Canvas.Font	 = ConsoleFont;
		OutStr = "(>"@TypedStr$"_";
		Canvas.Strlen(OutStr,xl,yl);

		Canvas.SetPos(0,Canvas.ClipY-6-yl);
		Canvas.DrawTile( BackgroundTexture, Canvas.ClipX, yl+6,0,0,32,32);

		Canvas.SetPos(0,Canvas.ClipY-8-yl);
		Canvas.SetDrawColor(0,255,0);
//		Canvas.DrawTile( texture 'Engine_res.ConsoleBdr', Canvas.ClipX, 2,0,0,32,32);

		Canvas.SetPos(0,Canvas.ClipY-3-yl);
		Canvas.bCenter = False;
		Canvas.DrawText( OutStr, false );
	}

	function BeginState()
	{
		bTyping = true;
		bVisible= true;
		bIgnoreKeys = true;
		HistoryCur = HistoryTop;
	}
	function EndState()
	{
		bTyping = false;
		bVisible = false;
	}
}


defaultproperties
{
	bActive=True
	bVisible=False
	bRequiresTick=True
	HistoryBot=-1
}