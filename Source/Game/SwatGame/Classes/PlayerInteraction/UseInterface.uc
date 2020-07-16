class UseInterface extends PlayerFocusInterface
    Config(PlayerInterface_Use)
    native;

var string UseFeedbackText;        //feedback for use interface
var string OtherFeedbackText;   //other feedback to display in the HUD feedback
var HUDPageBase CachedHUDPage;

var bool LookingThruGlass;

//
// Update Sequence - See documentation above PlayerFocusInterface::PreUpdate()
//

simulated protected function bool PreUpdateHook(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    //we don't update the UseInterface while the player is controlling a viewport (including the Optiwand)
    return (Player.ActiveViewport == None);
}

simulated protected function ResetFocusHook(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    //reset feedback text and update the HUD's Feedback's cache variables
    //
    //TMC Note: there was a tricky bug here.
    //  There are two conflicting goals:
    //  1) Don't do a lot of text processing and GUI interaction unless something has changed.
    //  2) When we lose focus (Use or Fire), update the HUD's Feedback box so it goes away.
    //  The trick is that if the player is looking at something which can be used, and then
    //      looks away quickly, there may not be an update that hits something that _can't_ be used.
    //  So the correct flow looks like this:
    //  - Reset focus of UseInterface [UseInterface::ResetFocusHook()]
    //  - Reset HUD's Feedback's cached feedback variables [UseInterface::PostUpdate()]
    //  - Consider any new focus (there may be none), and potentially update object variables [UseInterface::ConsiderNewFocus()]
    //  - Update the HUD's Feedback's cached feedback variables again [UseInterface::PostUpdate()]
    //  - Update HUD's Feedback's Caption from cached feedback variables [GUIFeedback::UpdateCaption()]

    UseFeedbackText = "";
    OtherFeedbackText = "";
    CachedHUDPage = HUDPage;

    LookingThruGlass = false;

    PostUpdate(Player);
}

simulated protected event PostContextMatched(PlayerInterfaceContext Context, Actor Target)
{
    local string localUseFeedbackText, localOtherFeedbackText;
    local SwatHostage Hostage;
    local UseInterfaceContext UseContext;

    UseContext = UseInterfaceContext(Context);

    if (UseInterfaceContext(Context).IsGlass)
        LookingThruGlass = true;

    localUseFeedbackText = UseContext.UseFeedbackText;
    localOtherFeedbackText = UseContext.OtherFeedbackText;

    if(localUseFeedbackText ~= "Report Dead Hostage") {
      // EXTREME HACK
      Hostage = SwatHostage(Target);
      if(Hostage.IsDOA()) {
        localUseFeedbackText = "Report DOA";
      }
    }

    if (localUseFeedbackText != "")
        UseFeedbackText = localUseFeedbackText;
    if (localOtherFeedbackText != "")
        OtherFeedbackText = localOtherFeedbackText;
}

simulated protected event PostDoorRelatedFocusAdded(PlayerInterfaceDoorRelatedContext inContext, Actor Target, ESkeletalRegion SkeletalRegionHit)
{
    local UseInterfaceDoorRelatedContext Context;

    Context = UseInterfaceDoorRelatedContext(inContext);

    UseFeedbackText = Context.UseFeedbackText;
    OtherFeedbackText = Context.OtherFeedbackText;
}

simulated function PostUpdate(SwatGamePlayerController Player)
{
    local GUIFeedback Feedback;

    Feedback = CachedHUDPage.Feedback;

    //in ConsiderNewFocus(), we already computed the feedback text to display on the HUD
    Feedback.UseText = UseFeedbackText;
    Feedback.OtherText = OtherFeedbackText;
}

//
// (End of Update Sequence)
//

simulated function Interact()
{
    local ICanBeUsed Target;
    local SwatGamePlayerController PC;

    log( "---UseInterface::Interact()." );

    if (FociLength > 0)
    {
        Target = ICanBeUsed(Foci[0].Actor);

        log( "...Target="$Target );

        //there are occasions that a Focus of the UseInterface is not an ICanBeUsed,
        //  for example, another player in MP is a UseInterface Focus (so that we can
        //  report, "Equip Zipcuffs to Restrain"), but it can not be used.
        if (Target == None)
            return;         //nothing to use

        PC = SwatGamePlayerController(Level.GetLocalPlayerController());
        if (Target.CanBeUsedNow())
        {
            log( "...UniqueID="$Target.UniqueID() );
            PC.ServerRequestInteract( Target, Target.UniqueID() );
        }
    }
//  else
//      TMC TODO need feedback "nothing to use here"

}

// Use interface has a few extra considerations with regards to context
function bool ContextMatches(SwatPlayer Player, Actor Target, PlayerInterfaceContext Context, float Distance, bool Transparent)
{
	local UseInterfaceContext UseContext;
	local ICanBeUsed UsedItem;
	local SwatPawn SwatPawn;

	UseContext = UseInterfaceContext(Context);
	UsedItem = ICanBeUsed(Target);
	SwatPawn = SwatPawn(Target);
	if(UsedItem == None)
	{
		return false; // this thing can't be used (?)
	}

	if(UseContext.CaresAboutCanBeUsedNow)
	{
		if(UsedItem.CanBeUsedNow() ^^ UseContext.CanBeUsedNow)
		{
			return false; // this thing can't be used now
		}
	}

	if(UseContext.CaresAboutRestrained)
	{
		if(SwatPawn == None || SwatPawn.IsArrested() ^^ UseContext.IsRestrained)
		{
			return false;
		}
	}

	if(UseContext.CaresAboutIncapacitated)
	{
		if(SwatPawn == None || SwatPawn.IsIncapacitated() ^^ UseContext.IsIncapacitated)
		{
			return false;
		}
	}

	if(UseContext.CaresAboutCanBeArrestedNow)
	{
		if(SwatPawn == None || SwatPawn.CanBeArrestedNow() ^^ UseContext.CanBeArrestedNow)
		{
			return false;
		}
	}

	if(UseContext.CaresAboutDead)
	{
		if(SwatPawn == None || SwatPawn.IsDead() ^^ UseContext.IsDead)
		{
			return false;
		}
	}

	if(UseContext.CaresAboutLookingThruGlass)
	{
		if(UseContext.IsLookingThruGlass ^^ Transparent)
		{
			return false;
		}
	}

	return Super.ContextMatches(Player, Target, Context, Distance, Transparent);
}

function bool DoorRelatedContextMatches(SwatPlayer Player, SwatDoor Door, PlayerInterfaceDoorRelatedContext Context,
	float Distance, bool Transparent, bool HitTransparent, DoorPart CandidateDoorPart, ESkeletalRegion CandidateSkeletalRegion)
{
	local UseInterfaceDoorRelatedContext UseContext;
	UseContext = UseInterfaceDoorRelatedContext(Context);

	if(UseContext.CaresAboutLookingThruGlass)
	{
		// HOL UP
		// If the door we are hitting is itself the transparency (ie, St. Micheal's Medical Center doors)
		// then we should *absolutely* allow this context to go through
		if(UseContext.IsLookingThruGlass ^^ HitTransparent)
		{
			return false;
		}
	}

	return Super.DoorRelatedContextMatches(Player, Door, Context, Distance, Transparent, HitTransparent, CandidateDoorPart, CandidateSkeletalRegion);
}

cpptext
{
    virtual UBOOL DoorRelatedContextMatches(UPlayerInterfaceDoorRelatedContext* DoorRelatedContext, ASwatDoor* Door);
    virtual UBOOL ContextMatches(UPlayerInterfaceContext* inContext, AActor* Candidate);
}

defaultproperties
{
    DoorRelatedContextClass=class'SwatGame.UseInterfaceDoorRelatedContext'
    ContextClass=class'SwatGame.UseInterfaceContext'
}
