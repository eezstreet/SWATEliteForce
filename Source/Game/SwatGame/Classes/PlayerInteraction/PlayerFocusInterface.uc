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

native function ConsiderNewFocus(
        SwatPlayer Player, 
        Actor CandidateActor, 
        float Distance, 
        vector CandidateLocation, 
        vector CandidateNormal, 
        Material CandidateMaterial, 
        ESkeletalRegion CandidateSkeletalRegion,
        bool Transparent);

simulated protected event PostContextMatched(PlayerInterfaceContext Context, Actor Target);
simulated protected event PostDoorRelatedContextMatched(PlayerInterfaceDoorRelatedContext Context, Actor Target);

simulated final event AddFocus(name Context, Actor Actor, vector Location, vector Normal, Material Material, optional ESkeletalRegion Region)
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
