class SniperVolume extends HighGroundVolume
    config(HighGround);

// NOTE: this class uses the default highgroundvolume code.  It only really cares about a couple of 
// conditions which the designers can specify.  

var() name          AssociatedSniperTag "The tag of the sniper pawn that is linked with this volume";
var   SniperPawn    AssociatedSniper;
var   bool          bAlreadyPlayedEntryTeam;

function PostBeginPlay()
{
    local SniperPawn Sniper;

    Super.PostBeginPlay();

    // Find the sniperpawn associated with this volume...
    foreach DynamicActors( class'SniperPawn', Sniper, AssociatedSniperTag )
    {
        AssociatedSniper = Sniper;
        AssociatedSniper.SniperName = string(RoomName);
        break;
    }
}

function bool ShouldRejectCondition(HighGroundCondition inCondition)
{
    // Always reject in MP...
    /*if ( Level.NetMode != NM_Standalone )
        return true;*/

    if ( inCondition.Subject == 'SwatPlayer' || inCondition.Subject == 'SwatOfficer' )
    {
        if ( bAlreadyPlayedEntryTeam )
            return true;
        bAlreadyPlayedEntryTeam = true;
    }
    return false;
}

function OnConditionPlayed()
{
    // Only alert the player for certain conditions
    if ( Level.GetLocalPlayerController() != None 
         && Level.GetLocalPlayerController().IsA( 'SwatGamePlayerController' ) 
         && PlayingCondition.Subject != 'SwatPlayer'                    // Don't warn for the swat team
         && PlayingCondition.Subject != 'SwatOfficer' 
         && PlayingCondition.Action != 'Left'                           // Don't warn when guys leave the area
        )
    {
        SwatGamePlayerController(Level.GetLocalPlayerController()).OnSniperAlerted(AssociatedSniper);
    } 
}

defaultproperties
{
    bOccludedByGeometryInEditor=true
}
