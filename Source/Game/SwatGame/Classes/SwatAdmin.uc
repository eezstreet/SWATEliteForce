class SwatAdmin extends Engine.Actor
    ;

var private array<PlayerController> AdminList;
var private string AdminPassword;

function SetAdminPassword( string Password )
{
    AdminPassword = Password;
}

function AdminLogin( PlayerController PC, string Password )
{
    if( Password != AdminPassword )
        return;
    
#if IG_THIS_IS_SHIPPING_VERSION //enable no passwords for dev purposes
    if( AdminPassword == "" && PC != Level.GetLocalPlayerController() )
        return;
#endif
        
    AdminList[ AdminList.Length ] = PC;
    
    if( SwatPlayerReplicationInfo(PC.PlayerReplicationInfo) != None )
        SwatPlayerReplicationInfo(PC.PlayerReplicationInfo).SetAdmin( true );

    if( SwatGamePlayerController(PC) != None )
        SwatGamePlayerController(PC).SwatRepoPlayerItem.LastAdminPassword = Password;
}

function bool IsAdmin( PlayerController PC )
{
    local int i;
    
    for( i = 0; i < AdminList.Length; i++ )
        if( AdminList[i] == PC )
            return true;

    return false;            
}

function Kick( PlayerController PC, String PlayerName )
{
    if( !IsAdmin( PC ) )
        return;
        
    Level.Game.Kick( PC, PlayerName );
}

function KickBan( PlayerController PC, String PlayerName )
{
    if( !IsAdmin( PC ) )
        return;
        
    Level.Game.KickBan( PC, PlayerName );
}

function Switch( PlayerController PC, string URL )
{
    if( !IsAdmin( PC ) )
        return;
        
	Level.ServerTravel( URL, false );
}

function StartGame( PlayerController PC )
{
    if( !IsAdmin( PC ) )
        return;
        
	SwatRepo(Level.GetRepo()).AllPlayersReady();
}

function AbortGame( PlayerController PC )
{
    if( !IsAdmin( PC ) )
        return;
        
	SwatGameInfo(Level.Game).GameAbort();
}

defaultproperties
{	
    bStatic=false
    bStasis=true
    Physics=PHYS_None
    
    bCollideActors=false
    bCollideWorld=false
    bHidden=true
}
