class PlayerFocusInterface extends Engine.Actor
    Config(PlayerFocusInterface)
    native
    abstract;

//This is the base of classes which encapsulate player interface elements
//  controlled with player focus, ie. with the reticle.
//Subclasses include UseInterface, FireInterface, and CommandInterface.

import enum ESkeletalRegion from Engine.Actor;
import enum EMaterialVisualType from Engine.Material;

var const config float                              Range;

struct native Focus
{
    var protected name Context;
    var protected Actor Actor;
    var protected vector Location;
    var protected vector Normal;
    var protected Material Material;
    var protected ESkeletalRegion Region;
};
//because of the allocation garbage associated with resizing dynamic script arrays,
//  we'll just use a small fixed array here.
var protected array<Focus>                          Foci;                       //NOTE: Using this as a static array, so don't resize!  (Static arrays of structs are still broken)
var protected int                                   FociLength;
var protected bool                                  FocusIsBlocked;             //shouldn't bother testing trace anymore because its already blocked by something

var config array<name>                              DoorRelatedContext;
var class<PlayerInterfaceDoorRelatedContext>        DoorRelatedContextClass;
var config array<PlayerInterfaceDoorRelatedContext> DoorRelatedContexts;

var config array<name>                              Context;
var class<PlayerInterfaceContext>                   ContextClass;
var config array<PlayerInterfaceContext>            Contexts;

//logic control
var bool AlwaysAddDoor;     //if true, and a DoorRelatedContext matches, then the SwatDoor will always be added, rather than the door part that was hit
var bool											AlwaysPostUpdate;

var protected SwatGamePlayerController              PlayerController;
var protected SwatPlayer                            PlayerPawn;

var protected Name                                  FocusInterfaceType;


enum DoorPart
{
    DoorPart_Animation,
    DoorPart_Model,
    DoorPart_Way,
    DoorPart_Any
};

const MAX_FOCI = 3;     //I'm hoping and guessing that we don't care about any more than the first 4 foci

simulated function PostBeginPlay()
{
    local Focus junk;
    local int i;

    Super.PostBeginPlay();

    SetFocusInterfaceType();

    //just grow the dynamic array
    //  We're using this dynamic array as if it were a static array
    //  to avoid reallocation every update.
    //  So it should never be grown or shrunk after this
    Foci[MAX_FOCI] = junk;

    //create contexts
    for (i=0; i<Context.length; ++i)
    {
        Contexts[i] = new (None, string(Context[i])) ContextClass;
        assert(Contexts[i] != None);
    }
    for (i=0; i<DoorRelatedContext.length; ++i)
    {
        DoorRelatedContexts[DoorRelatedContexts.length] = new (None, string(DoorRelatedContext[i])) DoorRelatedContextClass;
        assert(DoorRelatedContexts[i] != None);
    }
}

//used to test if Contexts meets special conditions for this type of PlayerFocusInterface
simulated function SetFocusInterfaceType()
{
    FocusInterfaceType = class.name;
}

//
// PlayerFocusInterface Update Sequence
//
// SwatGamePlayerController::UpdateFocus() calls the following functions on each PlayerFocusInterface in the following order:
//
//      (final) PreUpdate   -> (protected)  PreUpdateHook   - returns true if the PlayerFocusInterface wants to be updated & gives subclasses a chance too
//                                                          [if PreUpdate returns false, then updating of this PlayerFocusInterface ends here]
//      (final) ResetFocus  -> (protected)  ResetFocusHook  - resets base focus tracking & gives subclasses a chance to do more work
//      [for each focus candidate]
//          (static)    StaticRejectFocus                   - returns true if all PlyaerFocusInterfaces will always reject a focus candidate
//                                                            (static, so called once for each focus candidate, not once per-PlayerFocusInterface)
//                      RejectFocus                         - returns true if this PlayerFocusInterfaces wants to reject the focus candidate
//          (native)    ConsiderNewFocus                    - considers adding a candidate as a focus
//          (protected) Post{DoorRelated}ContextMatched     - called when the current focus candidate matches a context
//          (final)     AddFocus                            - adds a qualified focus
//          (protected) Post{DoorRelated}FocusAdded         - called after a candidate is added to the focus
//                      PostUpdate                          - called after an update is complete
//

//return true if the PlayerFocusInterface wants to be updated
simulated final function bool PreUpdate(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    PlayerController = SwatGamePlayerController(Level.GetLocalPlayerController());
    PlayerPawn = SwatPlayer(SwatGamePlayerController(Level.GetLocalPlayerController()).Pawn);

    return PreUpdateHook(Player, HUDPage);
}
simulated protected function bool PreUpdateHook(SwatGamePlayerController Player, HUDPageBase HUDPage) { return true; }   //for subclasses

simulated final function ResetFocus(SwatGamePlayerController Player, HUDPageBase HUDPage)
{
    FociLength = 0;             //clear foci
    FocusIsBlocked = false;

    ResetFocusHook(Player, HUDPage);
}
simulated protected function ResetFocusHook(SwatGamePlayerController Player, HUDPageBase HUDPage);  //for subclasses

//returns true if all PlayerFocusInterfaces will always reject this focus candidate
//TMC TODO OPTIMIZATION this function is called fairly often.  It might be worth moving native.
simulated static final function bool StaticRejectFocus(
        SwatGamePlayerController Player,
        Actor CandidateActor,
        vector CandidateLocation,
        vector CandidateNormal,
        Material CandidateMaterial,
        ESkeletalRegion CandidateSkeletalRegion,
        float Distance,
        bool Transparent,
        bool bAuditFocus)
{
    local IControllableThroughViewport CurrentControllable;

    // We don't want any focus traces to hit hidden actors that block zero-extent traces (i.e., projectors, blocking volumes).
    // However, the 'Victim' when you hit BSP is LevelInfo, which is hidden, so we have to handle that as a special case.
    if  (
            (
                CandidateActor.bHidden
            ||  CandidateActor.DrawType == DT_None
            )
        //these are things that are bHidden=true but we do want to consider for focus
        &&  !(CandidateActor.IsA('LevelInfo'))
        &&  !(CandidateActor.IsA('DoorWay'))
        &&  !(CandidateActor.IsA('MirrorPoint'))
        &&  !(CandidateActor.IsA('DoorBufferVolume'))
        )
    {
#if IG_SWAT_AUDIT_FOCUS
        if (bAuditFocus) log("[FOCUS] ... ... PlayerFocusInterface::StaticRejectFocus() "$CandidateActor.class.name$" was rejected because it is Invisible.");
#endif

        return true;
    }

    // Focus interfaces should always ignore fluid surfaces.
    if (CandidateActor.IsA('FluidSurfaceInfo'))
    {
        return true;
    }

    if( Player.ActiveViewport != None && Player.ActiveViewport.CanIssueCommands() )
    {
        //focus traces should ignore the actor at the source of the trace
        //this should be either the player or an officer that the player is currently controlling
        CurrentControllable = Player.GetExternalViewportManager().GetCurrentControllable();

        //ignore the actor that the player is controlling
        if (CandidateActor == CurrentControllable)
            return true;
    }
    else    //not controlling a viewport
    {
        //ignore the player pawn
        if (CandidateActor == Player.Pawn)
        return true;
    }

    return false;
}

native function bool RejectFocus(
        PlayerController Player,
        Actor CandidateActor,
        vector CandidateLocation,
        vector CandidateNormal,
        Material CandidateMaterial,
        ESkeletalRegion CandidateSkeletalRegion,
        float Distance,
        bool Transparent);

/*native function ConsiderNewFocus(
        SwatPlayer Player,
        Actor CandidateActor,
        float Distance,
        vector CandidateLocation,
        vector CandidateNormal,
        Material CandidateMaterial,
        ESkeletalRegion CandidateSkeletalRegion,
        bool Transparent);*/

// Meant to be subclassed.
simulated function bool SpecialCondition_Zulu() { return false; }
simulated function bool SpecialCondition_CanBeArrested(Actor Target) { return false; }
simulated function bool SpecialCondition_LowReadyPawn(SwatPlayer Player, Actor Target) { return false; }


// This function also got rewritten from native code
function bool DoorRelatedContextMatches(SwatPlayer Player, SwatDoor Door, PlayerInterfaceDoorRelatedContext Context,
	float Distance, bool Transparent, bool HitTransparent, DoorPart CandidateDoorPart, ESkeletalRegion CandidateSkeletalRegion)
{
	local int i;
	local HandheldEquipment ActiveItem;

	if(Context.SkeletalRegion != REGION_None && Context.SkeletalRegion != CandidateSkeletalRegion)
	{
		// Not touching the right part of the door
		return false;
	}

	if(Context.DoorPart != DoorPart.DoorPart_Any && Context.DoorPart != CandidateDoorPart)
	{
		// Not touching the right part of the door
		return false;
	}

	if(Distance >= Context.Range)
	{
		// Not in range
		return false;
	}

	ActiveItem = Player.GetActiveItem();
	if(Context.ActiveItem != '' && !ActiveItem.IsA(Context.ActiveItem))
	{
		// The context demands that we have a certain item active and we don't have said item active
		return false;
	}

	for(i = 0; i < Context.ExceptActiveItem.Length; i++)
	{
		if(Context.ExceptActiveItem[i] != '' && ActiveItem.IsA(Context.ExceptActiveItem[i]))
		{
			// The context does not allow us to have a certain item active
			return false;
		}
	}

	if(Context.CaresAboutTransparent)
	{
		// If we care about transparency, Context.IsTransparent should match Transparent
		if(Context.IsTransparent ^^ Transparent)
		{
			return false;
		}
	}

	if(Context.CaresAboutOpen)
	{
		// If we care about whether the door is open, Context.IsOpen should match Door.IsOpen
		if(Context.IsOpen ^^ Door.IsOpen())
		{
			return false;
		}
	}

	if(Context.CaresAboutLocked)
	{
		// If we care about whether the door is locked, Context.IsLocked should match Door.IsLocked
		if(Context.IsLocked ^^ Door.IsLocked())
		{
			return false;
		}
	}

	if(Context.CaresAboutPlayerBelief)
	{
		// FIXME: we should probably deviate from the base behavior somehow here?
		// If we care about whether the player knows the door is locked, Context.PlayerBelievesLocked should match Door.PawnBelievesDoorLocked
		if(Context.PlayerBelievesLocked ^^ Door.PawnBelievesDoorLocked(Player))
		{
			return false;
		}
	}

	if(Context.CaresAboutWedged)
	{
		// If we care about whether the door is wedged, Context.IsWedged should match Door.IsWedged
		if(Context.IsWedged ^^ Door.IsWedged())
		{
			return false;
		}
	}

	if(Context.CaresAboutBroken)
	{
		// If we care about whether the door is broken, Context.IsBroken should match Door.IsBroken
		if(Context.IsBroken ^^ Door.IsBroken())
		{
			return false;
		}
	}

	if(Context.CaresAboutMissionExit)
	{
		// If we care about whether the door is a mission exit, Context.IsMissionExit should match Door.IsMissionExit
		if(Context.IsMissionExit ^^ Door.IsMissionExit())
		{
			return false;
		}
	}

	if(Context.HasA != '' && !Player.HasA(Context.HasA))
	{
		return false;
	}

	if(Context.DoesntHaveA != '' && Player.HasA(Context.DoesntHaveA))
	{
		return false;
	}

	// This context is acceptable
	return true;
}

// This function also got rewritten from native code
function bool ContextMatches(SwatPlayer Player, Actor Target, PlayerInterfaceContext Context, float Distance, bool Transparent)
{
	local int i;

	if(Distance >= Context.Range)
	{
		// Not in range
		return false;
	}

	if(Context.Type != '' && !Target.IsA(Context.Type))
	{
		// Not the right type of actor
		return false;
	}

	for(i = 0; i < Context.Except.Length; i++)
	{
		if(Target.IsA(Context.Except[i]))
		{
			// It's the right type, but we excluded this type specifically
			return false;
		}
	}

	if(Context.HasA != '' && !Player.HasA(Context.HasA))
	{
		// The context requires something that we don't have
		return false;
	}

	if(Context.DoesntHaveA != '' && Player.HasA(Context.DoesntHaveA))
	{
		// The context requires us to not have something which we have
		return false;
	}

	if(Context.CaresAboutTransparent)
	{
		if(Context.IsTransparent ^^ Transparent)
		{
			return false;
		}
	}

	if(Context.ActiveItem != '' && !Player.GetActiveItem().IsA(Context.ActiveItem))
	{
		// The context requires us to be holding something which we aren't holding
		return false;
	}

	if(Context.HasA != '' && !Player.HasA(Context.HasA))
	{
		// The context requires us to have something which we don't have
		return false;
	}

	if(Context.DoesntHaveA != '' && Player.HasA(Context.DoesntHaveA))
	{
		// The context requires us to not have something, and we have it
		return false;
	}

	if(Context.HasSpecialConditions)
	{
		// There are some special conditions related to this context which are hardcoded for the context.
		switch(Context.Name)
		{
			case 'Zulu':
				// False if we don't have a held command
				if(!SpecialCondition_Zulu())
				{
					return false;
				}
				break;
			case 'CanBeArrested':
				if(!SpecialCondition_CanBeArrested(Target))
				{
					return false;
				}
				break;
			case 'LowReadyPawn':
				if(!SpecialCondition_LowReadyPawn(Player, Target))
				{
					return false;
				}
				break;
			case 'MirrorPoint':
				return true; // I'm not sure what the special condition is supposed to be.
				break;
			case 'ToolkitOnBomb':
				return true; // PvP FIXME
				break;
			case 'CuffsOnVIP':
				return false; // PvP FIXME
				break;
			case 'CuffsOnPlayer':
				return false; // PvP FIXME
				break;
			case 'ToolkitOnArrestedVIP':
				return false; // PvP FIXME
				break;
			case 'ArrestablePlayer':
				return false; // PvP FIXME
				break;
		}
	}

	// This context is acceptable
	return true;
}

// This function got rewritten from native code, so we can do more with it.
// HasA() crashes with our new LoadOut changes so we need to rewrite the only function which uses it (this one)
function ConsiderNewFocus(SwatPlayer Player, Actor CandidateActor, float Distance, vector CandidateLocation, vector CandidateNormal,
	Material CandidateMaterial, ESkeletalRegion CandidateSkeletalRegion, bool Transparent, bool HitTransparent)
{
	local bool bDoorRelated;
	local int i;
	local SwatDoor Door;
	local DoorPart DoorPart;

	if(CandidateActor.IsA('SwatDoor') || CandidateActor.IsA('DoorModel') || CandidateActor.IsA('DoorWay'))
	{
		bDoorRelated = true;

		if(CandidateActor.IsA('SwatDoor'))
		{
			Door = SwatDoor(CandidateActor);
			DoorPart = DoorPart_Animation;
		}
		else if(CandidateActor.IsA('DoorModel'))
		{
			Door = DoorModel(CandidateActor).Door;
			DoorPart = DoorPart_Model;
		}
		else
		{
			Door = DoorWay(CandidateActor).GetDoor();
			DoorPart = DoorPart_Way;
		}
	}

	if(bDoorRelated)
	{
		for(i = 0; i < DoorRelatedContexts.Length; i++)
		{
			// Detect if the context matches
			if(DoorRelatedContextMatches(Player, Door, DoorRelatedContexts[i], Distance, Transparent, HitTransparent, DoorPart, CandidateSkeletalRegion))
			{
				PostDoorRelatedContextMatched(DoorRelatedContexts[i], Door);

				if(DoorRelatedContexts[i].BlockTraceIfOpaque && !Transparent)
				{
					FocusIsBlocked = true;
				}
				else if(DoorRelatedContexts[i].BlockTrace)
				{
					FocusIsBlocked = true;
				}

				if(DoorRelatedContexts[i].AddFocus)
				{
					if(DoorRelatedContexts[i].IsA('UseInterfaceDoorRelatedContext'))
					{
						// HACK here to replicate Irrational behavior...
						// With UseInterface, we use the thing itself instead of the door it's attached to
						AddFocus(DoorRelatedContexts[i].Name, CandidateActor, CandidateLocation,
							CandidateNormal, CandidateMaterial, CandidateSkeletalRegion);
					}
					else
					{
						AddFocus(DoorRelatedContexts[i].Name, Door, CandidateLocation,
							CandidateNormal, CandidateMaterial, CandidateSkeletalRegion);
					}
					PostDoorRelatedFocusAdded(DoorRelatedContexts[i], CandidateActor, CandidateSkeletalRegion);
				}

				if(DoorRelatedContexts[i].BreakIfMatch)
				{
					break;
				}
			}
		}
	}
	else
	{
		for(i = 0; i < Contexts.Length; i++)
		{
			// Detect if the context matches
			if(ContextMatches(Player, CandidateActor, Contexts[i], Distance, Transparent))
			{
				PostContextMatched(Contexts[i], CandidateActor);

				if(Contexts[i].BlockTraceIfOpaque && !Transparent)
				{
					FocusIsBlocked = true;
				}
				else if(Contexts[i].BlockTrace)
				{
					FocusIsBlocked = true;
				}

				if(Contexts[i].AddFocus)
				{
					AddFocus(Contexts[i].Name, CandidateActor, CandidateLocation,
						CandidateNormal, CandidateMaterial, CandidateSkeletalRegion);
					PostFocusAdded(Contexts[i], CandidateActor, CandidateSkeletalRegion);
				}

				if(Contexts[i].BreakIfMatch)
				{
					break;
				}
			}
		}
	}
}

simulated protected event PostContextMatched(PlayerInterfaceContext Context, Actor Target);
simulated protected event PostDoorRelatedContextMatched(PlayerInterfaceDoorRelatedContext Context, Actor Target);

simulated event AddFocus(name Context, Actor Actor, vector Location, vector Normal, Material Material, optional ESkeletalRegion Region)
{
    assertWithDescription(Actor != None,
        "[tcohen] "$class.name$" attempted to AddFocus() with Actor=None");

    if (FociLength >= MAX_FOCI)
        return;     //ignore any foci after the MAX_FOCI'th focus

    Foci[FociLength].Context = Context;
    Foci[FociLength].Actor = Actor;
    Foci[FociLength].Location = Location;
    Foci[FociLength].Normal = Normal;
    Foci[FociLength].Material = Material;
    Foci[FociLength].Region = Region;

    FociLength++;
}

simulated protected event PostFocusAdded(PlayerInterfaceContext Context, Actor Target, ESkeletalRegion SkeletalRegionHit);
simulated protected event PostDoorRelatedFocusAdded(PlayerInterfaceDoorRelatedContext Context, Actor Target, ESkeletalRegion SkeletalRegionHit);

simulated function PostUpdate(SwatGamePlayerController Player);

//
// Accessors
//

simulated final function Actor GetDefaultFocusActor()
{
    if (FociLength > 0)
        return Foci[0].Actor;
    else
        return None;
}

simulated final function vector GetDefaultFocusLocation()
{
    if (FociLength > 0)
        return Foci[0].Location;
    else
        return vect(0,0,0);
}

//returns the first Focus Actor (if any) in Foci that IsA(ClassName)
simulated final protected function Actor GetFocusOfClass(name ClassName)
{
    local int i;

    for (i=0; i<FociLength; ++i)
        if (Foci[i].Actor != None && Foci[i].Actor.IsA(ClassName))
            return Foci[i].Actor;

    return None;
}

simulated final private function int GetFociLength()
{
    return FociLength;
}

simulated final function bool HasContext(name Context)
{
    local int i;

    for (i=0; i<FociLength; ++i)
        if (Foci[i].Context == Context)
            return true;

    return false;
}

//
// Debug
//

function DrawDebugText(vector CameraLocation, Canvas Canvas, out int X, out int Y)
{
    local int i;
    local Name MaterialName;
    local EMaterialVisualType MVT;
    local float MTP;

    Canvas.SetPos(X, Y);

    if (FociLength > 0)
    {
        Canvas.DrawText(Class.Name$":");

        Y += 15;

        for (i=0; i<FociLength; ++i)
        {
            if (Foci[i].Region != REGION_None)
            {
                Canvas.SetPos(X + 5, Y);
                Canvas.DrawText(i+1$": "$Foci[i].Context);
                Y += 10; Canvas.SetPos(X + 5, Y);
                Canvas.DrawText("   Actor    = "$Foci[i].Actor.class.name);
                Y += 10; Canvas.SetPos(X + 5, Y);
                Canvas.DrawText("   Distance = "$VSize(Foci[i].Location - CameraLocation));
                Y += 10; Canvas.SetPos(X + 5, Y);
                Canvas.DrawText("   Region   = "$GetEnum(ESkeletalRegion, Foci[i].Region));
                Y += 10; Canvas.SetPos(X + 5, Y);
                Canvas.DrawText("   Location = "$Foci[i].Location);
            }
            else
            {
                Canvas.SetPos(X + 5, Y);
                Canvas.DrawText(i+1$": "$Foci[i].Context);
                Y += 10; Canvas.SetPos(X + 5, Y);
                Canvas.DrawText("   Actor      = "$Foci[i].Actor.class.name);
                Y += 10; Canvas.SetPos(X + 5, Y);
                Canvas.DrawText("   Distance   = "$VSize(Foci[i].Location - CameraLocation));
                Y += 10; Canvas.SetPos(X + 5, Y);
                if (Foci[i].Material == None)
                {
                    MaterialName = 'None';
                    MVT = MVT_Default;
                    MTP = 0;
                }
                else
                {
                    MaterialName = Foci[i].Material.name;
                    MVT = Foci[i].Material.MaterialVisualType;
                    MTP = Foci[i].Actor.GetMomentumToPenetrate(vect(0,0,0), vect(0,0,0), Foci[i].Material);
                }
                Canvas.DrawText("   Material   = "$MaterialName$", MVT = "$GetEnum(EMaterialVisualType, MVT)$", MtP = "$MTP);
                Y += 10; Canvas.SetPos(X + 5, Y);
                if (Foci[i].Actor.StaticMesh != None)
                {
                    Canvas.DrawText("   StaticMesh = "$Foci[i].Actor.StaticMesh.name);
                    Y += 10; Canvas.SetPos(X + 5, Y);
                }
                Canvas.DrawText("   Location   = "$Foci[i].Location);
            }

            Y += 15;
        }
    }
    else
    {
        Canvas.DrawText(Class.Name$": (No Focus)");

        Y += 15;
    }

    Y += 5;
}

cpptext
{
    virtual UBOOL DoorRelatedContextMatches(UPlayerInterfaceDoorRelatedContext* DoorRelatedContext, ASwatDoor* Door) { return false; }
    virtual UBOOL ContextMatches(UPlayerInterfaceContext* inContext, AActor* Candidate) { return false; }
}

defaultproperties
{
    bHidden=true
    RemoteRole=ROLE_None
}
