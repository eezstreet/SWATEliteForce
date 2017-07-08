///////////////////////////////////////////////////////////////////////////////
class SwatRagdollPawn extends SwatPawn
    native 
    placeable
    config(SwatPawn);

// define this to log messages about what pawns do when BecomeRagdoll is called on them
#define DEBUG_RAGDOLL_TRANSITIONS 0

// ckline: Enable this to draw lines when the player walks in/near an open doorway, 
// showing what direction he would be pushed if he were to go ragdoll at that moment.
#define DEBUG_PUSHAWAY 0

// We expand the pawn's collision radius when he becomes ragdoll, to a value that should
// encompass any extremely sprawled out ragdoll character. This prevents a ragdoll
// from being culled because his collision cylinder is outside the view frustum.
const kRagdollCollisionRadius = 72;

// Has the pawn ragdolled at all?
var private bool bHasRagdolledLocally;
// This is replicated to clients when the server ragdolls a pawn. The client
// should in turn use this make the pawn become ragdoll.
var private bool bHasRagdolledOnServer;
// This is set to true when the client has determined that it is "safe" to
// check for transitions in the bHasRagdolledOnServer variable. Otherwise,
// the pawn might go ragdoll before the client has initialized the pawn
// from the replicated data (for example, if the network pawn was crouching,
// but the client hasnt yet updated to the crouching collision cylinder, and
// thus the pawn is considered halfway in the floor).
var private bool bShouldCheckHasRagdolledOnServer;

// To handle the problem where a server ragdolls a pawn who is not yet relevant
// to a client. The client will have no way of knowing where the ragdoll pawn
// was when the server changed the pawn to a ragdoll.
var private vector LocationAtRagdollStartOnServer;

// Server-only timer that is started when a pawn dies. When the timer fires,
// the dead pawn is torn off. This delay allows clients to get the now-
// always-replicated ragdolled pawn locally spawned on their machines, so that
// they have the dead body present before its finally torn off.
const kDeadPawnTearOffDelaySeconds = 5.0;
var private Timer DeadPawnTearOffTimer;


// Tragically, we need this replicated boolean so that clients know to
// call PlayDying. Previously, PlayDying was called on clients as a result
// of bTearOff changing. But now, since we dont tear off until a few seconds
// after death (see comments above kDeadPawnTearOffDelaySeconds), we need to
// trigger this differently.
var private bool bClientsShouldCallPlayDying;

// Has the pawn died AND did it do ragdoll when it died?
var private bool bIsDisabledRagdoll; // has pawn finished a ragdoll death and been disabled?

// If true, some approximation (or exaggeration) of the killing blow's impact
// momentum will be applied to the ragdoll. If false, the ragdoll will have no
// initial forces applied to it except gravity.
var config private bool bRagdollDeathUsesImpactMomentum;

// If true, this pawn will try and push away from nearby doors' sweeps when killed.  
var config private bool bRagdollDeathPushesAwayFromDoor;
var config private float RagdollPushAwayFromDoorVelocityMagnitude;

// If non-zero, the ragdoll simulation will stop the specified number of
// seconds after the pawn dies (i.e., it will stop being ragdoll and stay
// frozen). If zero, it stays ragdoll forever.
var config protected float RagdollSimulationTimeout;

var protected Timer LimbTwitchTimer;		   // Timer for how long limbs will twitch while this pawn is incapacitated
var config protected float LimbTwitchTime;	   // Length of time for the LimbTwitchTimer

var protected Timer LimbIdleTimer;			   // Timer for how long limbs are idle after beting twitched
var config protected float LimbIdleTime;	   // Length of time for the LimbIdleTimer
var protected bool   bLimbsAreIdle;			   // True while limbs are idling

var private bool bRagdollingOnReplication;     // True if this pawn is ragdolling the instant it is replicated (in PostNetBeginPlay)
var private float FirstRagdollRenderTime;      // The first time this Ragdoll was rendered while ragdolling

enum ETwitchType
{
    ETWITCH_Torque,
    ETWITCH_LinearVelocity,
    ETWITCH_Force,
    ETWITCH_Impulse,
};

struct native TwitchingBoneInfo
{
    var config Name     BoneName;
    var config Range    ForceMagnitude;
    var        Vector   ForceVector;
    var config Name     TargetBoneName;
    var config Vector   TargetForceNormal;
    var ETwitchType     TwitchType;
};

var config protected array<TwitchingBoneInfo> TwitchInfos;
var config protected float RenderTimeout;

//initial timeout for ragdoll rendering
var config protected float InitialRagdollRenderTimeout;

struct native BoneDampingSetting 
{
    var Name BoneName;
    var Float Damping;
};

var config array<BoneDampingSetting> BoneLinearDamping;
var config array<BoneDampingSetting> BoneAngularDamping;

replication
{
    reliable if ( Role == ROLE_Authority )
        bHasRagdolledOnServer, LocationAtRagdollStartOnServer, bClientsShouldCallPlayDying;
}

///////////////////////////////////////////////////////////////////////////////

simulated event PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    // At this point, we hope that the pawn has been initialized enough on the
    // client to properly ragdoll. If it has ragdolled on the server, but not
    // locally, call BecomeRagdoll().
    if (bHasRagdolledOnServer && !bHasRagdolledLocally)
    {
        bRagdollingOnReplication=true;
        BecomeRagdoll();
    }
    // Otherwise, set the bShouldCheckHasRagdolledOnServer to true, so that
    // PostNetReceive can monitor changes in the bHasRagdolledOnServer
    // variable.
    else
    {
        bShouldCheckHasRagdolledOnServer = true;
    }
}

simulated function OnMeshChanged()
{
    Super.OnMeshChanged();
    if (Physics == PHYS_HavokSkeletal)
    {
        SetPhysics(PHYS_None);
        BecomeRagdoll();
    }
}

// Accessor for Incapacitated AI behavior
simulated function float GetRagdollSimulationTimeout()
{
	return RagdollSimulationTimeout;
}

native function StartTwitchingLimbs();
native function StopTwitchingLimbs();

simulated function StartTwitching()
{
    //log ( "Incapacitated twitching limbs for pawn: "$Name$", TimeSeconds: "$Level.TimeSeconds );
    if ( IsIncapacitated() )
    {   
        if (LimbTwitchTimer == None) // lazy create
        {
            LimbTwitchTimer = new class'Timer';
            LimbTwitchTimer.TimerDelegate = StartIdling;     // We start idling after we've been twitching
        }
        bLimbsAreIdle = false;
        StartTwitchingLimbs();
        LimbTwitchTimer.StartTimer( LimbTwitchTime, false );
    }
}

simulated function StartIdling()
{
    //log ( "Incapacitated idling limbs for pawn: "$Name$", TimeSeconds: "$Level.TimeSeconds );
    if ( IsIncapacitated() )
    {
        if (LimbIdleTimer == None) // lazy create
        {
            LimbIdleTimer = new class'Timer';
            LimbIdleTimer.TimerDelegate = StartTwitching;    // We start twitching after we've been idling
        }
        bLimbsAreIdle = true;
        StopTwitchingLimbs();
        LimbIdleTimer.StartTimer( LimbIdleTime, false );
    }    
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

}

simulated event Destroyed()
{
    if (LimbIdleTimer != None)
    {
        LimbIdleTimer.Destroy();
        LimbIdleTimer = None;
    }

    if (LimbTwitchTimer != None)
    {
        LimbTwitchTimer.Destroy();
        LimbTwitchTimer = None;
    } 

    if (DeadPawnTearOffTimer != None)
    {
        DeadPawnTearOffTimer.Destroy();
        DeadPawnTearOffTimer= None;
    }

    Super.Destroyed();
}

///////////////////////////////////////
// This is called when the pawn is killed, at the start of the death animation
// or ragdoll death (the Pawn::Died() calls PlayDying, which initiates
// ragdoll). 
function Died(Controller Killer, class<DamageType> damageType, vector HitLocation, vector HitMomentum)
{
    mplog( self$"---SwatRagdollPawn::Died(). HitLocation="$HitLocation$", HitMomentum="$HitMomentum$", DamageType "$DamageType );

    //log("PHYSICS IS "$GetEnum(EPhysics,Physics));

    // Super.Died will eventually cause PlayDying() to be called, switching us to ragdoll
    super.Died(Killer, DamageType, HitLocation, HitMomentum);

    // Some pawns tell themselves to be deleted when they die.  Must check for
    // this and exit early in this case before running any additional code.
	if ( bDeleteMe || Level.bLevelChange )
		return; // already destroyed, or level is being cleaned up

    //stop all sounds being played on this pawn
    BroadcastStopAllSounds();

    // Now is the time to play the 'dying' sound - this will be the only sound played on this pawn during the dying sequence
    BroadcastEffectEvent('Died', Killer, None, HitLocation,,,,,GetPlayerTag());
}


simulated function Tick(float DeltaTime)
{
#if DEBUG_PUSHAWAY // ckline
    local Vector PushAwayVelocity;
    if (!IsDead() && PlayerController(Controller) != None)
    {
        // Show where the ragdoll would be pushed if the pawn were to die right now
        // and was near doors. Won't show anything if not in the sweep of any doors.
        PushAwayVelocity = GetBestVelocityToApplyToPushRagdollAwayFromDoors();

        // Only set velocity if we need to avoid doors; otherwise let the pawn
        // ragoll keep its velocity at time of death.
        if (VSizeSquared(PushAwayVelocity) > 0)
        {
            // Draw vector from Pawn in PushAwayVelocity in Red, with length scaled by 100 so we can see it
            Level.GetLocalPlayerController().myHUD.AddDebugLine(Location, Location + (PushAwayVelocity * 100), class'Engine.Canvas'.Static.MakeColor(255,0,0), 0.01);
            //Log("  -> CUMULATIVE PUSH: Pushing "$Name$" away from door(s) in direction "$Normal(PushAwayVelocity)$" with Mag "$VSize(PushAwayVelocity)); 
        }
    }
#endif

    if ( Level.NetMode == NM_DedicatedServer )
        return;

    // assume dead if bTearOff - for remote clients unfff unfff
    if ( bTearOff )
    {
        if ( !bPlayedDeath )
            PlayDying(DeathHitDamageType, DeathHitLocation, DeathHitMomentum, KillerLocation);
        return;
    }
}


///////////////////////////////////////

// ChunkUp is called whenever the player should be totally destroyed. The
// superclass method destroy()s the Pawn. 
//
// We're overriding this so that pawns aren't destroyed when they're already
// dead (otherwise they would disappear if you shot them after they went
// ragdoll). 
simulated function ChunkUp( Rotator HitRotation, class<DamageType> TheDamageType ) 
{
    // do nothing
}

simulated function Vector GetBestVelocityToApplyToPushRagdollAwayFromDoors()
{
    local Vector            PushAwayDirection;
    local Vector            CumulativePushAwayDirection;
    local SwatDoor          NearbyDoor;

	ForEach TouchingActors(class'SwatDoor', NearbyDoor)
    {
        if (NearbyDoor != None &&   // sometimes iterator returns None ?!?
            !NearbyDoor.IsClosed()) // ignore closed doors
        {
            // Get best direction to push the ragdoll away from this
            // door. 
            PushAwayDirection = NearbyDoor.GetPushAwayDirection(self);
 
            //Log("Pushing "$Name$" ("$VSize2D(DirTo2D)$" units from door "$NearbyDoor.Name$" in XY plane) in direction "$Normal(PushAwayDirection)); 

            // Accumulate the push-away velocity vectors, in case
            // we're near two doors (imagine a corner where there's 
            // doors on two adjacent walls... we should push away in
            // the direction of the diagonal so that we don't accidentally
            // push away from one door into the path of another.
            //
            // NOTE: assumes PushAwayDirection is normalized!
            CumulativePushAwayDirection += PushAwayDirection;
        }
    }

    if (VSizeSquared(CumulativePushAwayDirection) > 0)
    {
        // Scale the velocity vector by the appropriate magnitude. Re-normalize
        // first because the accumulation phase above may have de-normalized it.
        CumulativePushAwayDirection = Normal(CumulativePushAwayDirection) * RagdollPushAwayFromDoorVelocityMagnitude;
    }

    return CumulativePushAwayDirection;
}

// Carlos/ckline: 
// PushAwayFromDoors() will push away this ragdoll from every door that it is inside the total sweep of
simulated function PushAwayFromDoors()
{
    local Vector PushAwayVelocity;
    PushAwayVelocity = GetBestVelocityToApplyToPushRagdollAwayFromDoors();
	
    // Only set velocity if we need to avoid doors; otherwise let the pawn
    // ragoll keep its velocity at time of death.
    if (VSizeSquared(PushAwayVelocity) > 0)
    {
        HavokSetLinearVelocityAll( PushAwayVelocity );
    }
}

///////////////////////////////////////

// Helper function for BecomeRagdoll(). Applies the momentum of the 
// killing blow to the ragdoll. Not intended to be called outside of
// BecomeRagdoll().
protected simulated function ApplyDeathHitMomentumToRagdoll()
{
    local name TakeHitBone;
    local ESkeletalRegion HitRegion;
    local vector TraceStart, TraceEnd;
	local vector DummyTraceLoc, DummyTraceNormal;
	local vector HitDir;
	local SwatRagdollPawn DummyTraceActor;
    local Material DummyTraceMaterial;
    local vector ScaledMomentum;
    local bool bLogDebugInfo;

    bLogDebugInfo = Level.AnalyzeBallistics || Level.GetEngine().EnableDevTools;

    if (bLogDebugInfo) // debug ragdoll death impulse
    {
        if (DeathHitDamageType != None)
            Log("DeathHitDamageType = "$DeathHitDamageType.static.GetFriendlyName());
        else
            Log("DeathHitDamageType = None");
        Log("  DeathHitMomentum = "$DeathHitMomentum$" Normalized = "$Normal(DeathHitMomentum));
        Log("  DeathHitLocation = "$DeathHitLocation);
        Log("    KillerLocation = "$KillerLocation);
    }

    // If we're on the client, we need to re-trace from the shot direction
    // to find the havok bone that got hit (if we're on the server or standalone,
    // the last trace was the trace that killed the character, so the last 
    // traced bone is the bone that got hit by the killing shot)
    if (Level.NetMode == NM_Client)
    {
        // Do a trace through the hitlocation in the direction of the 
        // DeathHitMomentum, to get the bone hit by the blow that killed
        // this pawn
        HitDir = Normal(DeathHitMomentum);
        TraceStart = DeathHitLocation - 200*HitDir;
        TraceEnd = DeathHitLocation + 200*HitDir;
        foreach TraceActors(
            class'SwatRagdollPawn', 
            DummyTraceActor, 
            DummyTraceLoc, 
            DummyTraceNormal, 
            DummyTraceMaterial,
            TraceEnd, 
            TraceStart,
            ,     // use default extent == zero extent trace
            true, // Get skeletal region hit
            HitRegion)
        {
            // Only care about intersection with self
            if (DummyTraceActor == self)
            {
                if ( HitRegion != REGION_None )
                {
                    TakeHitBone = GetLastTracedBone(); 

                    if (bLogDebugInfo) // debug ragdoll death impulse
                    {
                        log(" BecomeRagdoll: HIT PAWN   = "$DummyTraceActor);
                        log(" HIT REGION = "$GetEnum(ESkeletalRegion, HitRegion)$" was hit.");
                        if (TakeHitBone != '')
                            Log("  HIT BONE  = "$TakeHitBone$" (from re-calculated trace)");
                        else
                            Log("  HIT BONE  = UNKNOWN (from re-calculated trace)");
                        //Level.GetLocalPlayerController().myHUD.AddDebugLine(TraceStart, TraceEnd, class'Engine.Canvas'.Static.MakeColor(221,221,28,255),5); // yellow
                    }
                }
                break;
            }
        }
    }
    else
    {
        // On server/standalone, the shot trace happens locally so we can
        // just get the cached hit bone
        //
        // Call GetLastTracedBone() rather than HavokGetLastTracedBone() 
        // because the pawn wasn't havok when the killing shot was fired.
        // HavokGetLastTracedBone is only valid when pawn is PHYS_HavokSkeletal.
        TakeHitBone = GetLastTracedBone(); 

        if (bLogDebugInfo) // debug ragdoll death impulse
        {
            if (TakeHitBone != '')
                Log("   TakeHitBone = "$TakeHitBone$" (from cached trace)");
        }
    }

    // Sometimes the trace on the MP client might not hit a bone, but 
    // we know some bone was hit because otherwise the ragdoll wouldn't
    // have died. So we pick the upper spine as the bone to push so he
    // falls in a reasonable direction.
    if (TakeHitBone == '') 
    {
        TakeHitBone = 'Bip01_Spine2';

        if (bLogDebugInfo) // debug ragdoll death impulse
        {
            Log("   Applying hit impulse to Bip01_Spine2 because hit bone is unknown");
        }
    }

    if (bLogDebugInfo) // debug ragdoll death impulse
    {
        Log("   Applying hit impulse dir = "$Normal(DeathHitMomentum)$", base magnitude = "$VSize(DeathHitMomentum)$", multiplier = "$DeathHitDamageType.static.GetRagdollDeathImpactMomentumMultiplier()$" to bone = "$TakeHitBone);
    
        // scale it for effect
        Log( "...DeathHitMomentum before scaling="$DeathHitMomentum );
        Log( "...multiplier="$DeathHitDamageType.static.GetRagdollDeathImpactMomentumMultiplier() );
        ScaledMomentum = DeathHitMomentum * DeathHitDamageType.static.GetRagdollDeathImpactMomentumMultiplier();
        Log( "...DeathHitMomentum after scaling="$ScaledMomentum );
    }

    // Apply impact impulse to impact bone
    HavokImpartCOMImpulse(ScaledMomentum, TakeHitBone);
}

///////////////////////////////////////

simulated event BecomeRagdoll()
{
    local int i;

#if DEBUG_RAGDOLL_TRANSITIONS
    Log("RAGDOLL["$self$"]: BecomeRagdoll() called");
#endif

    // Set some flags if this is our first local ragdoll.
    if (!bHasRagdolledLocally)
    {
        bHasRagdolledLocally = true;
        bReplicateMovement = false;
        // Contrary to the obvious, the bUseCompressedPosition flag is what
        // actually stops the replication of the pawn's movement. [darren]
        bUseCompressedPosition = false;
        // Make sure ragdoll doesn't block players
        bBlockPlayers = false;
        // Clients should no longer locally simulate this pawn. Change the net
        // role to dumb proxy.
        if (Level.NetMode == NM_Client)
        {
            Role = ROLE_DumbProxy;

            // If the LocationAtRagdollStartOnServer vector is all zeros, that
            // would indicate it hasn't been received from the server yet.
            // Therefore we shouldn't use it.
            if( bRagdollingOnReplication &&
               (LocationAtRagdollStartOnServer.X != 0.0 ||
                LocationAtRagdollStartOnServer.Y != 0.0 ||
                LocationAtRagdollStartOnServer.Z != 0.0)
              )
            {
                SetLocation(LocationAtRagdollStartOnServer);
            }
        }
        else
        {
            RemoteRole = ROLE_DumbProxy;
            bHasRagdolledOnServer = true;
            LocationAtRagdollStartOnServer = Location;
        }
        // Make this pawn always relevant, so that all clients will create the
        // pawn and perform the ragdoll.
        bAlwaysRelevant = true;
    }
    
    if (Physics == PHYS_HavokSkeletal)
    {
#if DEBUG_RAGDOLL_TRANSITIONS
        Log("Skipping call to BecomeRagdoll() because "$self$" is already PHYS_HavokSkeletal");
#endif
        return;
    }

    // notify subclasses that we're about to go ragdoll
    NotifyReadyToRagdoll();

    // Locally become ragdoll if this is not a dedicated server.
	if (Level.NetMode != NM_DedicatedServer)
	{
        // Freeze anim on this pawn.
        // We pass false because we want to freeze anims where they are, not reset them 
        // to frame 0 before freezing (which will cause a 1-frame pop in the animation).
        StopAnimating(false); 

        // turn of physics-based anim; otherwise the ragdoll skeleton
	    // will become detached from the mesh, and the mesh will not
	    // animate with the ragdoll.
	    bPhysicsAnimUpdate = false;
        // Turn off animation replication too
        bReplicateAnimations = false;

        // Stop the first person hands from animating
        if ( GetHands() != None )
	    {
            GetHands().StopAnimating();
	    }

        // Have to turn off character collisions when going ragdoll, or else
        // ragdoll rigid bodies will sometimes collide with the collision proxy 
        // and cause weird ragdoll behavior (getting 'stuck', or flailing around)
        // I think this is a temporary problem -- when I last spoke to the havok 
        // engineers about this (4/5/04) they said I had to turn it off before 
        // going ragdoll. And I trust 'em, cause them is smart people.
        bHavokCharacterCollisions = false;

        // SetPhysics will initialize havok for this pawn and create its havokdata
        //
        // NOTE: Setting physics to PHYS_HavokSkeletal will cause the pawn's velocity to
        // be applied to the ragdoll -- so if you want a special velocity on the ragdoll,
        // apply it after changing to PHYS_HavokSkeletal!
        SetPhysics(PHYS_HavokSkeletal);

        // Apply any specified damping settings
        for (i = 0; i < BoneLinearDamping.length; ++i)
        {
            //log("Applying Linear Damping "$BoneLinearDamping[i].Damping$" to Bone "$BoneLinearDamping[i].BoneName);
            HavokSetLinearDamping(BoneLinearDamping[i].Damping, BoneLinearDamping[i].BoneName);
        }

        for (i = 0; i < BoneAngularDamping.length; ++i)
        {
            //log("Applying Angular Damping "$BoneAngularDamping[i].Damping$" to Bone "$BoneAngularDamping[i].BoneName);
            HavokSetAngularDamping(BoneAngularDamping[i].Damping, BoneAngularDamping[i].BoneName);
        }
        
        // Don't apply death momentum if is incapacitated, because the incapacitated
        // pawns might have played a pre-incapacitation animation prior to going ragdoll,
        // and we don't want to apply impact momentum unless it happens immediately.
        if (bRagdollDeathUsesImpactMomentum && !IsIncapacitated())
            ApplyDeathHitMomentumToRagdoll();

        // Push away from doors last, so any shot velocity doesn't cause the pawn
        // to fall into the door
        if (bRagdollDeathPushesAwayFromDoor)
        {
            PushAwayFromDoors();
        }

        if ( IsIncapacitated() )
            StartTwitching();
    }
	// Dedicated server "ragdoll":
	else
	{
		//Velocity += DeathHitMomentum;
		//BaseEyeHeight = Default.BaseEyeHeight;
		
		// You can't see 'em, and he doesn't block anything
		SetPhysics(PHYS_None);
	    SetCollision(false,false,false); 
	}

    // See comment above kRagdollCollisionRadius for an explanation of the
    // collision size change.
    SetCollisionSize(kRagdollCollisionRadius, CollisionHeight);
}

// allows subclasses to do things before we go ragdoll
// subclasses SHOULD call down the chain
simulated function NotifyReadyToRagdoll();

// This is played when the pawn is killed but not gibbed. Called by
// Pawn.Died(). It handles switching to RagDoll, among other things.
simulated function PlayDying( class<DamageType> DamageType, vector HitLoc, vector HitMomentum, vector inKillerLocation )
{
    local SwatGamePlayerController LocalPlayerController;
    local HandheldEquipment theActiveItem;
    local HandheldEquipmentModel theThirdPersonModel;

    // If we are in Coop, and the pawn is a SwatAI, and that AI is arrested,
    // and the activeitem is the IAmCuffed, then make the IAmCuffed's
    // ThirdPersonModel bTearOff=true, since we no longer want to replicate
    // it. We have to tear it off so it will follow the ragdoll's wrists
    // correctly on each client.
    if ( Level.IsCOOPServer )
    {
        if ( IsA( 'SwatAI' ) && IsArrested() )
        {
            theActiveItem = GetActiveItem();
            if ( theActiveItem != None )
            {
                theThirdPersonModel = theActiveItem.GetThirdPersonModel();
                if ( theThirdPersonModel != None )
                {
                    theThirdPersonModel.bTearOff = true;
                }
            }
        }
    }

    bPlayedDeath = true;

    // Set 'death info' variables here that will be replicated, so that 
    // remote clients can play ragdoll deaths using server-calculated 
    // parameters:
    //   DeathHitLocation - where the pawn was shot
    //   DeathHitDamageType   - what thing killed the pawn
    //   DeathHitMomentum - momentum of the shot
    //   KillerLocation  - where the killer was

    DeathHitLocation     = HitLoc;
    DeathHitDamageType   = DamageType;
	DeathHitMomentum     = HitMomentum;
    KillerLocation       = inKillerLocation;

    // See comments above this variable's declaration for an explanation.
    bClientsShouldCallPlayDying = true;

    //log( "...aaa DeathHitMomentum="$DeathHitMomentum );

//    Log("RAGDOLL["$self$"]: PlayDying() called");
//    if (DeathHitDamageType != None)
//        Log("    DeathHitDamageType = "$DeathHitDamageType.static.GetFriendlyName());
//    else
//        Log("    DeathHitDamageType = None");
//    Log("  DeathHitMomentum = "$DeathHitMomentum$" Normalized = "$Normal(DeathHitMomentum));
//    Log("  DeathHitLocation = "$DeathHitLocation);
//    Log("   KillerLocation = "$KillerLocation);

    // If the local player controller is viewing this pawn, let it know about
    // the KillerLocation, for death cam
    LocalPlayerController = SwatGamePlayerController(Level.GetLocalPlayerController());
    if (LocalPlayerController != None && LocalPlayerController.ViewTarget == self)
    {
        if (KillerLocation.Z != kInvalidKillerLocationZ)
        {
            LocalPlayerController.SetKillerLocation(inKillerLocation);
        }

        LocalPlayerController.StartDeathCam();
    }

#if IG_SWAT_INTERRUPT_STATE_SUPPORT //tcohen: support for notifying states before they are interrupted
    mplog( "...calling InterruptState()." );
    InterruptState('Dying');
    if ( Controller != None )
    {
        //mplog( "...calling Controller.InterruptState()." );
        Controller.InterruptState('Dying');
    }
    else if ( CachedPlayerControllerForOptiwand != None )
    {
        //mplog( "...calling CachedPlayerControllerForOptiwand.InterruptState()." );
        CachedPlayerControllerForOptiwand.InterruptState('Dying');
    }
#endif

    GotoState('Dying');
    // MCJ: When we start a ragdoll death, we want to stop coughing, etc.
    ResetNonlethalEffects();
    BecomeRagdoll();

    // If we're in standalone, or we're the server, start the timer for
    // tearing this pawn off.
    if (Level.NetMode != NM_Client)
    {
        // We expect this never to be called before
        if (DeadPawnTearOffTimer == None)
        {
            DeadPawnTearOffTimer = new class'Timer';
            DeadPawnTearOffTimer.TimerDelegate = TearOffPawn;
            DeadPawnTearOffTimer.StartTimer(kDeadPawnTearOffDelaySeconds, false);
        }
    }
}

// * SERVER ONLY
// Called by the DeadPawnTearOffTimer when the timer fires.
function TearOffPawn()
{
    bTearOff = true;
}

simulated event DisableRagdoll(optional bool bKeepHavokPhysics)
{
	if (Physics == PHYS_HavokSkeletal)
	{
#if DEBUG_RAGDOLL_TRANSITIONS
		log(self$"...Stopping ragdoll simulation." );
#endif
		if ( !bKeepHavokPhysics )
        {
            if (LimbIdleTimer != None)
            {
                LimbIdleTimer.Destroy();
                LimbIdleTimer = None;
            }

            if (LimbTwitchTimer != None)
            {
                LimbTwitchTimer.Destroy();
                LimbTwitchTimer = None;
            } 

            SetPhysics(PHYS_None);
        }
		HavokActivate(false); // deactivate ragdoll
		bIsDisabledRagdoll = true;
	}
}

simulated State Dying
{
    ignores Trigger, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling;
    
	simulated function BeginState()
	{
        mplog( self$" entering state 'Dying'." );
        super.BeginState();
	}
	simulated function EndState()
	{
        mplog( self$" leaving state 'Dying'." );
	}

	simulated function Timer()
	{
        if ( !IsIncapacitated() )
            DisableRagdoll();
        else  // If incapacitated, they could possibly get killed at some point, so make sure and check again
            SetTimer(RagdollSimulationTimeout, false);

	}
    
	simulated function PostTakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation, 
                                       Vector momentum, class<DamageType> damageType)
	{
        // Note: Don't call superclass method. Superclass sets physics to
        // PHYS_Falling, which would cause the ragdoll to fall through the
        // world
        
#if 0 // ckline: commented out until I confirm it works in Havok
        // Restart ragdoll if it was shut off in the timer
        if (Physics == PHYS_None && bIsDisabledRagdoll)
        {
#if DEBUG_RAGDOLL_TRANSITIONS
            Log("RAGDOLL["$self$"]: Re-starting ragdoll simulation on ragdoll in state Dying");        
#endif
            BecomeRagdoll();
            SetTimer(RagdollSimulationTimeout, false);
        }
#endif

        // apply impulses when you shoot a ragdoll
        if (Physics == PHYS_HavokSkeletal)
        {
#if DEBUG_RAGDOLL_TRANSITIONS
            Log("RAGDOLL["$self$"]: Ragdoll is taking damage in state Dying");        
#endif
#if 0//!IG_SWAT    //tcohen: we may want to do this later, but DamageType is now an interface, so the code would need to change
            if(VSize(momentum) > 0.001)
            {
                HavokImpartImpulse( Normal(momentum), hitlocation);
            }
#endif
        }
    }

	event FellOutOfWorld(eKillZType KillType)
	{
		if(KillType == KILLZ_Suicide )
			return;

#if IG_THIS_IS_SHIPPING_VERSION
        log(
#else
        AssertWithDescription(false, 
#endif
            "[ckline]: !!!! WARNING !!!!! Pawn "$self$" in state SwatRagdollPawn.Dying and Physics="$GetEnum(EPhysics,Physics)$" fell out of the world and had Super::FellOutOfWorld() called on it! Contact a programmer -- This shouldn't happen, and it might screw up objectives, leadership scores, etc. ");
        
        Super.FellOutOfWorld(KillType);
	}
    
Begin:
	
        mplog( self$" Begin: of state 'Dying'." );

		bInvulnerableBody = false;
		SetTimer(RagdollSimulationTimeout, false);
        if ( Level.NetMode != NM_Standalone )
        {
			// this code should be in NetPlayer (i didn't write it though). [crombie]
            if ( IsA('NetPlayer') && !NetPlayer(self).IsTheVIP() )
                NetPlayer(self).GetNetTeam().AddNetPlayerToDestroy( NetPlayer(self) );
        }
	}	


///////////////////////////////////////

cpptext
{
    virtual UBOOL Tick( FLOAT DeltaTime, ELevelTick TickType );
	virtual void PostNetReceive();
}

defaultproperties
{    
    bCollideActors              = true
    bCollideWorld               = true
    bBlockPlayers               = true

    HavokDataClass=class'SwatOfficerRagdollParams'

    bIsDisabledRagdoll = false
	bRagdollDeathUsesImpactMomentum = true

    RagdollSimulationTimeout=10

    bRagdollDeathPushesAwayFromDoor=true
    RagdollPushAwayFromDoorVelocityMagnitude=85

    // .... These are set in SwatPawn.ini
    //LimbTwitchTime=5
    //LimbIdleTime=3
    //TwitchInfos(0)=(BoneName=Bip01_Head,ForceMagnitude=(Min=-1900,Max=1900),TargetBoneName=Bip01_Spine,TwitchType=ETWITCH_Force)
    //TwitchInfos(1)=(BoneName=Bip01_L_Forearm,ForceMagnitude=(Min=-700,Max=700),TargetBoneName=Bip01_Spine,TwitchType=ETWITCH_Torque)
    //TwitchInfos(2)=(BoneName=Bip01_R_Forearm,ForceMagnitude=(Min=-700,Max=700),TargetBoneName=Bip01_Spine,TwitchType=ETWITCH_Torque)
    //TwitchInfos(3)=(BoneName=Bip01_R_UpperArm,ForceMagnitude=(Min=-700,Max=700),TargetBoneName=Bip01_Spine,TwitchType=ETWITCH_Torque)
    //TwitchInfos(4)=(BoneName=Bip01_L_UpperArm,ForceMagnitude=(Min=-700,Max=700),TargetBoneName=Bip01_Spine,TwitchType=ETWITCH_Torque)
    //TwitchInfos(5)=(BoneName=Bip01_R_Calf,ForceMagnitude=(Min=-300,Max=3000),TargetBoneName=Bip01_Spine,TwitchType=ETWITCH_Torque)
    //TwitchInfos(6)=(BoneName=Bip01_L_Calf,ForceMagnitude=(Min=-300,Max=3000),TargetBoneName=Bip01_Spine,TwitchType=ETWITCH_Torque)
    //RenderTimeout=1.5
}
