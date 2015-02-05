class PlayerTagInterface extends PlayerFocusInterface
    Config(PlayerInterface_PlayerTags)
    native;

var HUDPageBase         CachedHUDPage;             
var SwatPawn            CachedPlayerTarget;
var SwatPawn            PlayerTargetDuringUpdate;

var Timer               TagTimeoutTimer;            // Timer for how long the tag remains on the screen after a player's reticle leaves a target.  
var Timer               HoverTimer;                 // Timer for how long it takes for a tag to initially be shown when the player puts their reticle over the target.

var bool                bShowEnemyTags;             // If true, will show enemy tags
var bool                bShowFriendlyTags;          // If true, will show friendly tags

// Hover timer's control how long it takes for the playertag to initially pop up once the cursor is over a pawn.
var config float        FriendlyHoverDuration;      // For pawns on your team
var config float        EnemyHoverDuration;         // For pawns on the other team

var config float        TagTimeoutDuration;         // How long the Timeout timer is
var config string       FriendlyTagStyle;           // The style for the HUDPage's PlayerTag when over a friendly player
var config string       EnemyTagStyle;              // Style for the HUDPage's PlayerTag when over an enemy player
var config string       LeaderTagStyle;             // The style for the HUDPage's PlayerTag when over a coop element leader

var SwatGameReplicationInfo CachedRep;              // Cached replication info
var bool                    bLoadedFromRepo;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    TagTimeoutTimer = Spawn(class'Timer');
    HoverTimer = Spawn(class'Timer');
    
    TagTimeoutTimer.TimerDelegate = OnTagTimeoutTimer;
    HoverTimer.TimerDelegate = OnHoverTimer;
}

//
// Update Sequence - See documentation above PlayerFocusInterface::PreUpdate()
//

native function bool RejectFocus(
        PlayerController Player,
        Actor CandidateActor, 
        vector CandidateLocation, 
        vector CandidateNormal, 
        Material CandidateMaterial, 
        ESkeletalRegion CandidateSkeletalRegion, 
        float Distance, 
        bool Transparent);

simulated protected function bool PreUpdateHook(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    if ( CachedHUDPage == None && HUDPage != None )
        HudPage.PlayerTag.SetVisibility(false);

    CachedHUDPage = HUDPage;

    if ( !bLoadedFromRepo )
    {
        CachedRep = SwatGameReplicationInfo(PlayerController(Owner).GameReplicationInfo);
        mplog( "Testing repo initialization! CachedRep: "$CachedRep$", ShowFriendlyTags: "$CachedRep.ShowTeammateNames$", EnemyTags: "$CachedRep.ShowEnemyNames );           
        if ( CachedRep != None && CachedRep.ShowTeammateNames > 0 && CachedRep.ShowEnemyNames > 0 )
        {
            bLoadedFromRepo = true;
            bShowFriendlyTags = CachedRep.ShowTeammateNames == 2;
            bShowEnemyTags = CachedRep.ShowEnemyNames == 2;
            mplog( "Repo_Loaded! ShowFriendlyTags: "$bShowFriendlyTags$", EnemyTags: "$bShowEnemyTags );           
        }
    }

    // don't want update if no tags are requested in the server options
    return (bShowEnemyTags || bShowFriendlyTags);
}

simulated protected function ResetFocusHook(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    PlayerTargetDuringUpdate = None;
}

simulated protected event PostFocusAdded(PlayerInterfaceContext Context, Actor Target, ESkeletalRegion SkeletalRegionHit)
{
    local SwatPawn PawnTarget;
    PawnTarget = SwatPawn(Target);

    if ( PawnTarget != None && !class'Pawn'.static.checkDead(PawnTarget) )
        PlayerTargetDuringUpdate = SwatPawn(Target);

}

simulated function PostUpdate(SwatGamePlayerController Player)
{
    local SwatPlayer LocalPlayer;
    local bool bIsSWAT;
    local bool bIsFriendly;

    LocalPlayer = SwatPlayer(SwatGamePlayerController(Owner).Pawn);

    // PlayerTargets have changed...
    if ( CachedPlayerTarget != PlayerTargetDuringUpdate )
    {
        if ( PlayerTargetDuringUpdate == None )
        {
            // Stop the HoverTimer and start the TimeoutTimer
            HoverTimer.StopTimer();
            TagTimeoutTimer.StartTimer( TagTimeoutDuration, true );
        }
        else
        {  
            // MCJ: Kluge alert (but it's a good one). We are testing out new
            // ways of increasing friendly recognition and reducing friendly
            // fire. Instead of showing blue tags for teammates and red for
            // enemies, we need to try blue for SWAT and red for
            // Suspects. Since we're not sure if we will want to keep this
            // change permanently, Carlos and I decided to just alter how we
            // set bIsFriendly here and leave all the rest of the code the
            // same. So for now, bIsFriendly will be set to true for SWAT and
            // false for Suspects. If we decide to keep this change, we should
            // rename the variables here and in the relevant ini files.
            bIsSWAT = PlayerTargetDuringUpdate.GetTeamNumber() == 0;
            bIsFriendly = PlayerTargetDuringUpdate.GetTeamNumber() == LocalPlayer.GetTeamNumber() ||
							(PlayerTargetDuringUpdate.GetTeamNumber() == 0 && LocalPlayer.GetTeamNumber() == 2) ||
							(PlayerTargetDuringUpdate.GetTeamNumber() == 2 && LocalPlayer.GetTeamNumber() == 0); // dbeswick: hack for coop
            if ( (bShowFriendlyTags && bIsFriendly) || (bShowEnemyTags && !bIsFriendly) )
            {
				if (SwatPlayerReplicationInfo(PlayerTargetDuringUpdate.PlayerReplicationInfo) != None && 
					SwatPlayerReplicationInfo(PlayerTargetDuringUpdate.PlayerReplicationInfo).IsLeader)
					StartTag(bIsFriendly, CachedHUDPage.Controller.GetStyle(LeaderTagStyle));
				else if (bIsSWAT)
					StartTag(bIsFriendly, CachedHUDPage.Controller.GetStyle(FriendlyTagStyle));
				else
					StartTag(bIsFriendly, CachedHUDPage.Controller.GetStyle(EnemyTagStyle));
            }

            // old code
            //bIsFriendly = PlayerTargetDuringUpdate.GetHumanReadableTeamName() == LocalPlayer.GetHumanReadableTeamName();
            //if ( (bShowFriendlyTags && bIsFriendly) || (bShowEnemyTags && !bIsFriendly) )
            //{
            //    StartTag(bIsFriendly);
            //}
        }
    } 
    PlayerTargetDuringUpdate = None;
}

//
// (End of Update Sequence)
//

simulated function StartTag( bool bFriendly, GUIStyles Style )
{
    local float HoverDuration;

    // Stop updating for timeouts, we found a new focus
    TagTimeoutTimer.StopTimer();

    // Update CachedPlayerTarget 
    CachedPlayerTarget = PlayerTargetDuringUpdate;

    // Set the hover duration
    if ( bFriendly )
        HoverDuration = FriendlyHoverDuration;
    else
        HoverDuration = EnemyHoverDuration;

    // Start the hover timer, if it's already started this will have no effect as it's passing false as the "reset" parameter
    HoverTimer.StartTimer( HoverDuration, false, false );

    // Determine style...
    CachedHUDPage.PlayerTag.Style = Style;

    // Update the caption
    CachedHUDPage.PlayerTag.SetCaption( CachedPlayerTarget.GetHumanReadableName() );
}

simulated function OnHoverTimer()
{
    CachedHUDPage.PlayerTag.SetVisibility( true );
    CachedHUDPage.PlayerTag.bDrawStyle=true;
}


simulated function OnTagTimeoutTimer()
{
    CachedPlayerTarget = None;
    TagTimeoutTimer.StopTimer();
    CachedHUDPage.PlayerTag.SetCaption( "" );
    CachedHUDPage.PlayerTag.SetVisibility( false );
}

cpptext
{
    virtual UBOOL DoorRelatedContextMatches(UPlayerInterfaceDoorRelatedContext* DoorRelatedContext, ASwatDoor* Door) {return true; }
    virtual UBOOL ContextMatches(UPlayerInterfaceContext* inContext, AActor* Candidate);
}

defaultproperties
{
    DoorRelatedContextClass=class'SwatGame.PlayerTagInterfaceDoorRelatedContext'
    ContextClass=class'SwatGame.PlayerTagInterfaceContext'
}
