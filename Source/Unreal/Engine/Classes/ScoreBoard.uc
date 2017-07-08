//=============================================================================
// ScoreBoard
//=============================================================================
class ScoreBoard extends Info;

var() GameReplicationInfo           GRI;
var() class<HUD> HUDClass;
var bool bDisplayMessages;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    InitGRI();
    Init();
}

function Font GetSmallerFontFor(Canvas Canvas, int offset)
{
	local int i;

	for ( i=0; i<8-offset; i++ )
	{
		if ( HUDClass.default.FontScreenWidthMedium[i] <= Canvas.ClipX )
			return HUDClass.static.LoadFontStatic(i+offset);
	}
	return HUDClass.static.LoadFontStatic(8);
}

function bool HaveHalfFont(Canvas Canvas, int Offset)
{
	local int i;

	for ( i=0; i<9-offset; i++ )
		if ( HUDClass.default.FontScreenWidthSmall[i] <= Canvas.ClipX )
			return true;
	return false;
}

function Font GetSmallFontFor(int ScreenWidth, int offset)
{
	local int i;

	for ( i=0; i<8-offset; i++ )
	{
		if ( HUDClass.default.FontScreenWidthSmall[i] <= ScreenWidth )
			return HUDClass.static.LoadFontStatic(i+offset);
	}
	return HUDClass.static.LoadFontStatic(8);
}

simulated function InitGRI()
{
    GRI = PlayerController(Owner).GameReplicationInfo;
}

simulated function string InitTitle()
{
    return Caps(GRI.GameName);
}

simulated function Init();

simulated event DrawScoreboard( Canvas C )
{
	UpdateGRI();
    UpdateScoreBoard(C);
}

function bool UpdateGRI()
{
    if (GRI == None)
    {
        InitGRI();
		if ( GRI == None )
			return false;
	}
    SortPRIArray();
    return true;
}

simulated function String FormatTime( int Seconds )
{
    local int Minutes, Hours;
    local String Time;

    if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

        Time = Hours$":";
	}
	Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    if( Minutes >= 10 )
        Time = Time $ Minutes $ ":";
    else
        Time = Time $ "0" $ Minutes $ ":";

    if( Seconds >= 10 )
        Time = Time $ Seconds;
    else
        Time = Time $ "0" $ Seconds;

    return Time;
}

simulated function UpdateScoreBoard(Canvas Canvas);

simulated function bool InOrder( PlayerReplicationInfo P1, PlayerReplicationInfo P2 )
{
    if( P1.bOnlySpectator )
    {
        if( P2.bOnlySpectator )
            return true;
        else
            return false;
    }
    else if ( P2.bOnlySpectator )
        return true;

    if( P1.Score < P2.Score )
        return false;
    if( P1.Score == P2.Score )
    {
		if ( P1.Deaths > P2.Deaths )
			return false;
		if ( (P1.Deaths == P2.Deaths) && (PlayerController(P2.Owner) != None) && (Viewport(PlayerController(P2.Owner).Player) != None) )
			return false;
	}
    return true;
}

simulated function SortPRIArray()
{
    local int i,j;
    local PlayerReplicationInfo tmp;

    for (i=0; i<GRI.PRIArray.Length-1; i++)
    {
        for (j=i+1; j<GRI.PRIArray.Length; j++)
        {
            if( !InOrder( GRI.PRIArray[i], GRI.PRIArray[j] ) )
            {
                tmp = GRI.PRIArray[i];
                GRI.PRIArray[i] = GRI.PRIArray[j];
                GRI.PRIArray[j] = tmp;
            }
        }
    }
}

function NextStats();

defaultproperties
{
	HUDClass=class'HUD'
}
