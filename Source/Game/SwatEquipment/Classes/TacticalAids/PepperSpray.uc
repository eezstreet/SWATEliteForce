class PepperSpray extends RoundBasedWeapon
    implements ITacticalAid;

//when deciding who is affected by pepper spray, the trace is not blocked by anything with MtP less than this
var config float MomentumToPenetrateThreshold;

var config float PlayerPepperSprayedDuration;
var config float AIPepperSprayedDuration;

// When a Player (non-AI) being peppered has protective
// equipment that protects him from pepper, then the duration of
// effect will be scaled by this value.
// I.e., PlayerDuration *= <XXX>PlayerProtectiveEquipmentDurationScaleFactor
// Where XXX is SP or MP depending on whether it's a single-player or
// multiplayer game
var config float SPPlayerProtectiveEquipmentDurationScaleFactor;
var config float MPPlayerProtectiveEquipmentDurationScaleFactor;

const kDistanceToAIToIgnoreFOV = 16.0;

simulated function TraceFire()
{
    local vector StartLocation;
    local rotator StartDirection;
    local ICanBePepperSprayed Candidate;
    local Actor HitActor;
    local vector HitLocation, HitNormal;
    local Material HitMaterial;
    local bool TraceBlocked;
    local vector CandidateViewPoint;

    GetPerfectFireStart(StartLocation, StartDirection);

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
    if (DebugDrawAccuracyCone)
    {
        Level.GetLocalPlayerController().myHUD.AddDebugCone(
            StartLocation, vector(StartDirection),
            Range, GetAimError(),              //half angle in degrees
            class'Engine.Canvas'.Static.MakeColor(0,0,255),
            8);                         //lifespan
    }
#endif

    if ( Level.NetMode == NM_Client )
        return;

    //find all things implementing 'ICanBePepperSprayed' that are within Range
    foreach RadiusActors(class'ICanBePepperSprayed', Candidate, Range, StartLocation)
    {
        assert(Candidate.IsA('Pawn'));
        CandidateViewPoint = SwatPawn(Candidate).GetViewPoint();
//        log("PepperSpray testing sprayable actor within radius: "$Candidate.Name);

        //disqualify if Candidate is not within the spray "cone",
		// but if the candidate is a SwatAI, and the distance between the view point and the origin of the pepper spray is small, do not disqualify

        if  (
                !PointWithinInfiniteCone(
                    StartLocation,
                    Vector(StartDirection),
                    CandidateViewPoint,
                    2 * (GetAimError() * DEGREES_TO_RADIANS))
            &&  (
                    !Candidate.IsA('SwatAI')
                ||  (VSize(CandidateViewPoint - StartLocation) > kDistanceToAIToIgnoreFOV)
                )
            )
        {
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
            if (DebugDrawAccuracyCone)
            {
                // draw misses (outside cone) in red
                Level.GetLocalPlayerController().myHUD.AddDebugLine(
                        StartLocation,
                        CandidateViewPoint,
                        class'Engine.Canvas'.Static.MakeColor(255,0,0),
                        8);
                Level.GetLocalPlayerController().myHUD.AddDebugBox(
                        CandidateViewPoint,
                        3,
                        class'Engine.Canvas'.Static.MakeColor(255,0,0),
                        8);
            }
#endif

//            log("   Candidate viewpoint is not within the player's FOV!; rejecting (target viewpoint="
//                $CandidateViewPoint
//                $", location="
//                $SwatPawn(Candidate).Location
//                $", eyeposition="
//                $SwatPawn(Candidate).EyePosition()
//                $")");

            continue;
        }

        if (Candidate == Owner)
        {
//            log("   Candidate is the person doing the spraying!; rejecting");
            continue;
        }

        //disqualify if trace is blocked by someting with adequate momentum to penetrate
        TraceBlocked = false;
        foreach TraceActors(
            class'Actor',
            HitActor,
            HitLocation,
            HitNormal,
            HitMaterial,
            CandidateViewPoint,
            StartLocation,
            ,       //extent=0
            true)   //skeletal box test
        {
            if (HitActor == Actor(Candidate))
            {
//                log("   PepperSpray hit target before anything else");
                break;
            }
            else
            if  (
                    HitActor.class.name != 'LevelInfo'
                &&  (HitActor.DrawType == DT_None || HitActor.bHidden)
                )
            {
//                log("   PepperSpray trace hit invisible Actor "$HitActor.Name$"... ignoring that.");
                continue;
            }
            else
            if (HitActor.GetMomentumToPenetrate(HitLocation, HitNormal, HitMaterial) > MomentumToPenetrateThreshold)
            {
//                log("   PepperSpray trace is blocked by: "$HitActor.Name$" with MTP"$HitActor.GetMomentumToPenetrate(HitLocation, HitNormal, HitMaterial)$" > "$MomentumToPenetrateThreshold);
                TraceBlocked = true;
                break;
            }
        }

        if (!TraceBlocked)
        {
//            log("   Calling ReactToBeingPepperSprayed on "$Candidate);

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
            if (DebugDrawAccuracyCone)
            {
                // draw hits in green
                Level.GetLocalPlayerController().myHUD.AddDebugLine(
                        StartLocation,
                        CandidateViewPoint,
                        class'Engine.Canvas'.Static.MakeColor(0,255,0),
                        8);
                Level.GetLocalPlayerController().myHUD.AddDebugBox(
                        CandidateViewPoint,
                        3,
                        class'Engine.Canvas'.Static.MakeColor(0,255,0),
                        8);
            }
#endif
            //okay, Candidate is a qualified victim
            Candidate.ReactToBeingPepperSprayed(
                self,
                PlayerPepperSprayedDuration,
                AIPepperSprayedDuration,
                SPPlayerProtectiveEquipmentDurationScaleFactor,
                MPPlayerProtectiveEquipmentDurationScaleFactor);
        }
        else
        {
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
            if (DebugDrawAccuracyCone)
            {
                // draw blocked shots (inside cone but trace was blocked) in aquamarine
                Level.GetLocalPlayerController().myHUD.AddDebugLine(
                        StartLocation,
                        CandidateViewPoint,
                        class'Engine.Canvas'.Static.MakeColor(0,255,255),
                        8);
                Level.GetLocalPlayerController().myHUD.AddDebugBox(
                        CandidateViewPoint,
                        3,
                        class'Engine.Canvas'.Static.MakeColor(0,255,255),
                        8);
            }
#endif
        }
    }
}

simulated latent function EndFiring()
{
    Super.EndFiring();

    if (NeedsReload())
    {
        EquipOtherAfterUsed = true;

        if (Owner.IsA('SwatPlayer'))
            SwatPlayer(Owner).SetupReequip();
    }
}

// Sticky selection: if this item is equipped, then we switch to a grenade, then use a grenade, it switches to this item
simulated function bool HasStickySelection()
{
  return false;
}

function OnGivenToOwner()
{
  // Need to override this, because otherwise we get problems
  Super.OnGivenToOwner();

  Ammo.InitializeAmmo(10);
}

//which slot should be equipped after this item becomes unavailable
simulated function EquipmentSlot GetSlotForReequip()
{
    return Slot_Invalid;    //this means do default equip, ie. primary if available, backup otherwise
}

defaultproperties
{
    Slot=Slot_PepperSpray
    SPPlayerProtectiveEquipmentDurationScaleFactor=0
    MPPlayerProtectiveEquipmentDurationScaleFactor=0
    bIsLessLethal=true
}
