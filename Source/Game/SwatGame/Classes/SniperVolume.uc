class SniperVolume extends HighGroundVolume
    config(HighGround);

// NOTE: this class uses the default highgroundvolume code.  It only really cares about a couple of
// conditions which the designers can specify.

var() name          AssociatedSniperTag "The tag of the sniper pawn that is linked with this volume";
var   SniperPawn    AssociatedSniper;

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
    if(AssociatedSniper == None)
    {
      // Always reject if we don't have a sniper.
      return true;
    }

    // Always reject in MP...
    if ( Level.NetMode != NM_Standalone && !(ServerSettings(Level.CurrentServerSettings).bShowEnemyNames))
        return true;

    // Fixing TSS bug ...
    // FunTime Amusements and Drug Lab have two SniperVolumes...so we hear the effect twice, potentially.
    // Instead we're going to store this as a property of the sniper pawn itself
    if ( inCondition.Subject == 'SwatPlayer' || inCondition.Subject == 'SwatOfficer' )
    {
      if(inCondition.Action == 'Left')
      {
        if ( AssociatedSniper.bAlreadyPlayedEntryTeamLeaving )
            return true;
        AssociatedSniper.bAlreadyPlayedEntryTeamLeaving = true;
      }
      else
      {
        if ( AssociatedSniper.bAlreadyPlayedEntryTeam )
            return true;
        AssociatedSniper.bAlreadyPlayedEntryTeam = true;
      }

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
