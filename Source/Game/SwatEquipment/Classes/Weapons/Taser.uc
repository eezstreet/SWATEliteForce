class Taser extends RoundBasedWeapon
	implements Engine.IInterestedPawnDied;

const MAX_PROBES = 4;	// maximum number of probes (not truly changeable - below code assumes in a few places there will be at most 4)

// NOTE: there is currently a bug where sometimes the probes will stick in BSP
// even though they shouldn't (e.g., when set to STICK_Actors or lower enum).
// I think this is due to collision resolution issues in the engine.
enum EStickPolicy
{
	STICK_Nothing,
	STICK_TaseablePawns,  // only stick to things that can be tased
	STICK_SkeletalMeshes, // stick to any skeletal mesh
	STICK_Actors,         // stick to any actor but bsp walls
	STICK_AllGeometry,    // stick to everything and bsp walls too
	STICK_Always,		  // stick to the empty location of the wire's full extent even if you completely miss
};

enum EProbeState
{
	PROBE_Traveling,			// Moving from the taser gun to the target
	PROBE_AfterHit,				// Falling or Sticking after reaching the target
	PROBE_Slacking,
};

enum EWireState
{
	WIRE_AttachedToGun,			// Wire is attached to the taser
	WIRE_Falling				// Wire is Falling from the taser after too much motion
};

// configurable parameters for how long AIs and Players are affected when hit
var config float         PlayerTasedDuration;
var config float         AITasedDuration;

// configurable parameters for the taser probe models
var config class<TaserProbeBase> ProbeClass;
var config int			 NProbes;			 // number of probes (2 for Taser, 4 for Stingray)
var config float         TaserAimSpread;     // the spread in degrees between the two probes
var config float		 VerticalSpread;     // the spread in degrees (vertical) between the two sets of probes
var config EStickPolicy  StickToWhat;        // What substances can the probes stick to
var config name          FirstPersonProbeBones[MAX_PROBES];
var config name          ThirdPersonProbeBones[MAX_PROBES];
var config Vector        FirstPersonProbeOffset[MAX_PROBES];
var config Vector        ThirdPersonProbeOffset[MAX_PROBES];
var config float         ProbeStickTime;    //  time for the probes to stick in the victim, in seconds
var config float         ProbeFallDuration; // time to fall if the probe misses
var config float         FadeDuration;      // time to fade out the wires and probes
var config float         ProbeVisualSpeed;   //in units per second, how fast do the probes *appear* to fly.  Note that the target point has *already been determined*.
var config float         ProbeRecoilTime;   // seconds for probes to recoil back to their maximum extention if they hit nothing
var config float         ProbeFinalRecoilSpeed;   // seconds for probes to recoil back to their maximum extention if they hit nothing

// configurable parameters for the taser wire animated models
var config class<TaserWire>      TaserWireClass;
var config name  WireZapAnimation[2];   // the name of the animation to play on the wires as they shoot out
var config name  WireSlackAnimation[2]; // the name of the animation to play on the wires after they attach
var config float WireForceSlackTimeFraction; // force the slack to start after this fraction of the zap animation
var config float WireSlackAnimRate;   // the speed of the slack animation
var config float WireSlackTweenTime;  // how much time to fade in the slack animation
var config float WireSlackStartSpeed; // The speed at which slacking starts during the physics bouncing slowing down
var config float WireMinYZScale;     // the minimum scaling in the yz plane
var config float WireMaxYZScale;     // the maximum scaling in the yz plane
var config float WireAnimRate;       // the speed of the animation
var config float WireMaxHeightFraction; // the height of the parabola as a fraction of the distance
var config float WireMaxHeight; // the abolute maximum height of the parabola, if the shot is really far
var config name  WireEndEffectorName;  // the end bone in the wire's mesh (used to determine end point location)
var config float WireDetachDistance; // distance at which the wire will detach from the taser gun (if the gun moves or rotates too far)

var private Name ProbePartNames[MAX_PROBES]; // Names of the spawned probes
var private Name WirePartNames[MAX_PROBES];  // Names of the spawned wires

// This structure encapuslates the state of of each probe and wire that is
// shot out of the Taser.
struct TaserProbeShot {
	var vector         TargetLocation;  // where the probe should hit
	var Actor          Victim;          // what was hit
	var Name           VictimBone;      // which bone was it hit on

	var TaserProbeBase Probe;           // the probe object (like a bullet)

	var TaserWire      TaserWire;       // the wire between the probe and the taser gun
	var Vector         TargetBoneOffset; // the offset, in local bone coords of the hit point from the bone origin

    var Vector         ProbeInitialLocation;

    var Vector         ProbeOriginLocation;
    var Rotator        ProbeOriginRotation;
	var float          CurrentTravelTime;   // current time (decrementing to 0 by dTime)
	var float          TravelTime;          // how long it will take for the probes to reach the target
	var float          PostTravelTime;      // time for sticking or falling
	var EProbeState    ProbeState;
	var EWireState     WireState;
	var Material       HitMaterial;
	var bool           StickToTarget;       // probe should stick to what it hits (depending on the type of geometry)
	var bool           TaserHit;            // did this taser probe hit a Taseable Pawn or not?
	var bool           Active;              // probe is active after firing and before hiding
	var bool			DidDamageAlready;
};

struct ProbeRecoilState {
	var float  recoilTime;
	var Vector initialVelocity;
	var float  initialSpeed;
};

var private TaserProbeShot probes[MAX_PROBES];           // all the info for each probe/wire combination
var private ProbeRecoilState probeRecoils[MAX_PROBES];   // info required during the probe recoil
var private float  ActualTasedDuration; // calculated depending on if a Player or AI was hit
var private float  MinTravelTime; // the minumum travel time between the two probes, so that they will fade out at the same time
var private bool   TaserHit;      // did either taser probe hit a Taseable Pawn or not?
var private bool   ShouldTick;

function PostBeginPlay()
{
    Super.PostBeginPlay();

	// register to find out when the owner pawn dies or is destroyed
	Level.RegisterNotifyPawnDied(self);

    assertWithDescription(ProbeClass != None,
        "[tcohen] The TaserProbeClass for the Taser/Stingray is invalid.  Please set this in SwatEquipment.ini, [SwatEquipment.Taser]/[SwatEquipment.Stingray].");
    assertWithDescription(TaserWireClass != None,
        "[henry] The TaserWireClass for the Taser/Stingray is invalid.  Please set this in SwatEquipment.ini, [SwatEquipment.Taser]/[SwatEquipment.Stingray].");
}

/////////////////////////////////////////////////
/// Death / Destruction Notifications
/////////////////////////////////////////////////
// This is called when any pawn dies, so that we can make sure there are no
// dangling taser probes in a multiplayer game
simulated function OnOtherPawnDied(Pawn DeadPawn)
{
	if (DeadPawn == Owner || DeadPawn == probes[0].Victim || DeadPawn == probes[1].Victim || DeadPawn == probes[2].Victim || DeadPawn == probes[3].Victim)
	{
		if (probes[0].Active || probes[1].Active || probes[2].Active || probes[3].Active)
		{
			log("Taser owner or victim was killed while the tasers were shot");
		}
		EndAllProbes();
		if (DeadPawn == Owner)
		{
			// don't bother listening for deaths any more
			Level.UnRegisterNotifyPawnDied(self);
		}
	}
}

simulated function Destroyed()
{
	//log("Taser "$name$" is being destroyed!!");
	Super.Destroyed();
	DestroyAllProbes();
}

// cartridge is the number of the cartridge (always 0 for Tasers)
simulated function ApplyTaserAimError(int cartridge, rotator CenterFireDirection, out rotator FireDirection1, out rotator FireDirection2)
{
    local float Rho, Theta;
	local float xScale, yScale;
	local vector xPlanarVec, yPlanarVec, zPlanarVec, spherePoint;
	local vector diff, randPoint2, randPoint1;
	local float planarAimError, boundaryDist;
	local Rotator downtilt;

	assert(cartridge == 0 || cartridge == 1);

    //pick a random point in in a 2D circle using polar coordinates, with a maximum distance from the center relative to AimError
    //by setting Rho=Sqrt(FRand())*AimError, the points are evenly distributed, whereas
    //	Rho=FRand()*AimError would produce center-biased points (because polar coordinates are more dense closer to
    //	the origin).
    //TMC TODO consider using center-biased accuracy for an easier difficulty setting

	planarAimError = Tan(GetAimError() * DEGREES_TO_RADIANS);
    Rho = Sqrt(FRand()) * planarAimError;
    Theta = FRand() * 360.0;

	//log("Taser aim error: "$ GetAimError()$", planar error" $ planarAimError);
	//log("rho: "$ Rho $", Theta" $ Theta);

	xScale = Rho * Cos(Theta * DEGREES_TO_RADIANS);
	yScale = Rho * Sin(Theta * DEGREES_TO_RADIANS);

	// To make this random circle point appear as a random point within a
	// circle on the sphere, create a plane tangent to the perfect aim
	// direction on the unit sphere.  Define "up" and "left" directions on
	// that plane and project the point in the 2d circle to a point in the
	// circle on the tangent plane.  Then normalize the point to project
	// it back to the sphere, and figure out what rotator angle it is.

	// This method does not introduce errors as the aim is pointed toward
	// the north or south poles.

	// for GetAxes, X points out of the sphere, Y points right (like the
	// x-axis of the tangent plane), and Z points up (in the tangent plane)
	GetAxes(CenterFireDirection, xPlanarVec, yPlanarVec, zPlanarVec);
	spherePoint = Vector(CenterFireDirection);

	randPoint1 = spherePoint + (xScale * yPlanarVec) + (yScale * zPlanarVec);

	//log("Fired Taser rnd 2d point: "$xScale$","$yScale);
	//log("axes: "$ xPlanarVec $",  "$ yPlanarVec $", " $ zPlanarVec);


	// to make the second point, move from the first point towards the center
	// of the circle by the taserAimSpread amount, but clip the max distance
	// to stay within the aimError circle, so that both points end up in the reticle.

	// The max dist to stay in the reticle is the distance to the circle
	// origin plus 1 radius (this total is the distance to the opposite point
	// on the circle's diameter)

	diff = spherePoint - randPoint1;
	boundaryDist = VSize(diff) + planarAimError; // dist to circle center plus radius
	diff = Normal(diff);

	randPoint2 = randPoint1 + diff *
		FMin(Tan(TaserAimSpread * DEGREES_TO_RADIANS), boundaryDist);

	// project back onto the unit sphere
	randPoint1 = Normal(randPoint1);
	randPoint2 = Normal(randPoint2);

	FireDirection1 = Rotator(randPoint1);
	FireDirection2 = Rotator(randPoint2);
    //FireDirection.Pitch += Rho * Sin(Theta * DEGREES_TO_RADIANS) * DEGREES_TO_TWOBYTE;
    //FireDirection.Yaw += Rho * Cos(Theta * DEGREES_TO_RADIANS) * DEGREES_TO_TWOBYTE;

	// add vertical displacement for 2nd cartridge on Stingray
	if (cartridge == 0 && VerticalSpread != 0 && CurrentFireMode == FireMode_DoubleTaser)
	{
		downtilt.Pitch = 65536.0f * VerticalSpread / 360.0f;
		FireDirection1 += downtilt;
		FireDirection2 += downtilt;
	}
}

simulated function TraceFire()
{
	// taser only has one cartridge
	TraceFireInternal(0);
}

simulated function TraceFireInternal(int cartridge)
{
    local vector StartLocation;
    local rotator StartDirection;
    local rotator FireDirection1, FireDirection2;
	local vector StartTrace, EndTrace;
    local Material MaterialHit;
	local vector HitLocation, HitNormal, HitDiff;
    local Actor LocalVictim;
    local ESkeletalRegion HitRegion;
	local int i;
	local float spread;
	local Actor ActualTasedVictim;
	local int probe1, probe2;

	log("Fired Taser owner: '"$owner$"'");

	probe1 = 2*cartridge;
	probe2 = 2*cartridge+1;

    GetPerfectFireStart(StartLocation, StartDirection);

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
    if (DebugDrawAccuracyCone)
        Level.GetLocalPlayerController().myHUD.AddDebugCone(
            StartLocation, vector(StartDirection),
            Range, GetAimError(),              //half angle in degrees
            class'Engine.Canvas'.Static.MakeColor(0,0,255),
            5);                         //lifespan
#endif

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
    if (!DebugPerfectAim)
#else
    if (true)
#endif
	{
        //ApplyAimError(StartDirection);
        ApplyTaserAimError(cartridge, StartDirection, FireDirection1, FireDirection2);
		StartDirection = FireDirection1;
	}
	else
	{
		FireDirection1 = StartDirection;
		FireDirection2 = StartDirection;
	}

    StartTrace = StartLocation;
    EndTrace   = StartLocation + vector(StartDirection) * Range;

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
    if (DebugDrawTraceFire)
	{
		EndTrace   = StartLocation + vector(FireDirection1) * Range;
		Level.GetLocalPlayerController().myHUD.AddDebugLine(StartTrace, EndTrace, class'Engine.Canvas'.Static.MakeColor(255,0,0));

		EndTrace   = StartLocation + vector(FireDirection2) * Range;
        Level.GetLocalPlayerController().myHUD.AddDebugLine(StartTrace, EndTrace, class'Engine.Canvas'.Static.MakeColor(255,0,0));
	}
#endif

	for (i = probe1; i <= probe2; i++) {
		probes[i].Victim     = None;
		probes[i].VictimBone = '';
		probes[i].HitMaterial = None;
		probes[i].DidDamageAlready = false;

		spread = 0;
		if (i == probe1)
		{
			EndTrace = StartLocation + vector(FireDirection1) * Range;
		}
		else
		{
			EndTrace = StartLocation + vector(FireDirection2) * Range;
		}

		//spread = ((TaserAimSpread * i) - TaserAimSpread*0.5) * DEGREES_TO_TWOBYTE;
		//StartDirection.Yaw += spread;
		//EndTrace = StartLocation + vector(StartDirection) * Range;
		//StartDirection.Yaw -= spread;

		foreach TraceActors(
			class'Actor',
			LocalVictim,
			HitLocation,
			HitNormal,
			MaterialHit,
			EndTrace,
			StartTrace,,
			true, HitRegion)
			{
				// You shouldn't be able to hit hidden actors that block zero-extent traces (i.e., projectors, blocking volumes).
				// However, the 'LocalVictim' when you hit BSP is LevelInfo, which is hidden, so we have to handle that as a special case.
				if ((LocalVictim.bHidden || LocalVictim.DrawType == DT_None) && !(LocalVictim.IsA('LevelInfo')))
					continue;

                //SwatDoors (the animations) must be drawn, and their SkeletalRegions must block traces, but shots should ignore them
                if (LocalVictim.IsA('SwatDoor'))
                    continue;

				// If the nearest hit is too far, then consider it a miss, and make
				// the taser Wire shoot out to the max distance and then fall.
				if (VDistSquared(HitLocation, StartLocation) > Square(Range))
				{
					HitDiff = Normal(HitLocation - StartLocation);
					HitDiff *= Range;
					EndTrace = StartLocation + HitDiff;
					probes[i].Victim         = None;
					probes[i].VictimBone     = '';
					probes[i].TargetLocation = EndTrace;
					probes[i].TaserHit       = false;
					probes[i].DidDamageAlready = false;
					break;
				}

				probes[i].Victim         = LocalVictim;
				probes[i].VictimBone     = GetLastTracedBone();
				probes[i].TargetLocation = HitLocation;
				probes[i].HitMaterial    = MaterialHit;

				//if (probes[i].Victim.IsA('ICanBeTased'))
				//	ICanBeTased(probes[i]Victim).ReactToBeingTased(self, PlayerTasedDuration, AITasedDuration);

				break;
			}

		//if we didn't hit anything, then the extent of the probes is the end of the trace
		if (probes[i].Victim == None)
		{
			probes[i].TargetLocation = EndTrace;
			probes[i].TaserHit = false;
			probes[i].DidDamageAlready = false;
		}
		else
		{
			probes[i].TaserHit = probes[i].Victim.IsA('ICanBeTased');
		}
	}

	ActualTasedDuration = ProbeFallDuration;
	TaserHit = (probes[probe1].TaserHit || probes[probe2].TaserHit);
	ActualTasedVictim = None;

	// if both hit, but they hit different Pawns, then choose the closest one
	if (probes[probe1].TaserHit && probes[probe2].TaserHit && probes[probe1].Victim != probes[probe2].Victim)
	{
		if (VDistSquared(probes[probe1].TargetLocation, probes[probe1].ProbeOriginLocation) <
			VDistSquared(probes[probe2].TargetLocation, probes[probe2].ProbeOriginLocation))
		{
			ActualTasedVictim = probes[probe1].Victim;
		}
		else
		{
			ActualTasedVictim = probes[probe2].Victim;
		}
	}
	else
	{
		// Else, choose the first probe (in probe order, not in distance) that hits something tases it
		if (probes[probe1].TaserHit)
		{
			ActualTasedVictim = probes[probe1].Victim;
		}
		else if (probes[probe2].TaserHit)
		{
			ActualTasedVictim = probes[probe2].Victim;
		}
	}

	if (ActualTasedVictim != None)
	{
		ICanBeTased(ActualTasedVictim).ReactToBeingTased(self, PlayerTasedDuration, AITasedDuration);
		if (ClassIsChildOf(ActualTasedVictim.Class, class'SwatPlayer'))
		{
			ActualTasedDuration = PlayerTasedDuration;
		}
		else
		{
			ActualTasedDuration = AITasedDuration;
		}
	}

    InitializeProbes(cartridge);

	// for debugging, to see which probe is which
	//probes[0].Probe.SetDrawScale(5.0);
}

simulated function InitializeProbes(int cartridge)
{
	local vector targetOffset;
	local coords boneCoords;
	local float travelDistance, heightPeak;
	local int i;
	local int probe1, probe2;

    ShouldTick = true;
	probe1 = 2*cartridge;
	probe2 = 2*cartridge+1;

	for (i = probe1; i <= probe2; i++)
    {
		//log("Taser fire victim: " $ probes[i].Victim @ probes[i].VictimBone @ probes[i].TargetLocation);

		probes[i].Active     = true;
		probes[i].ProbeState = PROBE_Traveling;
		probes[i].WireState  = WIRE_AttachedToGun;
		probes[i].DidDamageAlready = false;

		// Make the TargetBoneOffset be in local coordinates of the bone,
		// so that the target will move correctly with the bone
		if (probes[i].Victim != None)
        {
			if (probes[i].VictimBone != '')
            {
				boneCoords = probes[i].Victim.GetBoneCoords(probes[i].VictimBone, true);
				targetOffset = probes[i].TargetLocation - boneCoords.Origin;
				probes[i].TargetBoneOffset.X = targetOffset Dot boneCoords.XAxis;
				probes[i].TargetBoneOffset.Y = targetOffset Dot boneCoords.YAxis;
				probes[i].TargetBoneOffset.Z = targetOffset Dot boneCoords.ZAxis;
			}
            else
            {
				probes[i].TargetBoneOffset = probes[i].TargetLocation - probes[i].Victim.Location;
			}
		}
        else
        {
			probes[i].TargetBoneOffset.X = 0.0;
			probes[i].TargetBoneOffset.Y = 0.0;
			probes[i].TargetBoneOffset.Z = 0.0;
		}

		GetProbeOriginFrame(i);

		probes[i].ProbeInitialLocation = probes[i].ProbeOriginLocation;

		if (probes[i].Probe == None)
		{
			probes[i].Probe = Spawn(ProbeClass, self, ProbePartNames[i],
									probes[i].ProbeOriginLocation,
                                    probes[i].ProbeOriginRotation,
                                    true // bNoCollisionFail
                                    );
		}
        else
        {
			probes[i].Probe.SetLocation(probes[i].ProbeOriginLocation);
			probes[i].Probe.SetRotation(probes[i].ProbeOriginRotation);
		}
		assert(probes[i].Probe != None);

		probes[i].Probe.ResetState();
		probes[i].Probe.OptimizeIn();
		probes[i].Probe.Show();

		if (probes[i].TaserWire == None)
		{
			probes[i].TaserWire = Spawn(TaserWireClass, self, WirePartNames[i],
                                        probes[i].ProbeOriginLocation,
                                        probes[i].ProbeOriginRotation,
                                        true // bNoCollisionFail
                                        );
		}
        else
        {
			probes[i].TaserWire.SetLocation(probes[i].ProbeOriginLocation);
			probes[i].TaserWire.SetRotation(probes[i].ProbeOriginRotation);
		}
		assert(probes[i].TaserWire != None);

		probes[i].TaserWire.OptimizeIn();
		probes[i].TaserWire.Show();

		probes[i].TaserWire.SetPhysics(PHYS_None);

		probes[i].TaserWire.minYZScale      = WireMinYZScale;
		probes[i].TaserWire.maxYZScale      = WireMaxYZScale;
		probes[i].TaserWire.endEffectorName = WireEndEffectorName;

		travelDistance = VSize(probes[i].Probe.Location - probes[i].TargetLocation);
		travelDistance = FMax(travelDistance, 0.01);

		probes[i].TravelTime = travelDistance / ProbeVisualSpeed;
		probes[i].CurrentTravelTime = 0;

		heightPeak = FMin(WireMaxHeightFraction * travelDistance, WireMaxHeight);

		// Set the velocity so that the physics system has an initial velocity
		// at the end of the travel time to use when switching to PHYS_Falling
		probes[i].Probe.Velocity    = (probes[i].TargetLocation - probes[i].ProbeOriginLocation) / probes[i].TravelTime;
		probes[i].Probe.Velocity.Z -= 4.0*heightPeak; // add in the derivative of the vertical parabolic motion component

		probes[i].TaserWire.PlayAnim(WireZapAnimation[i], WireAnimRate);

		probes[i].StickToTarget = false;
        //log("Victim = "$probes[i].Victim.Name$" VictimBones = "$probes[i].VictimBone$" StickPolicy = "$StickToWhat$" = "$GetEnum(EStickPolicy, StickToWhat));
		if (probes[i].VictimBone != '')
        {
            // Check if the victim is both taseable in theory (ICanBeTased) AND
            // is *currently* taseable (e.g., not wearing armor that blocks tasing,
            // etc)
			if  (probes[i].Victim.IsA('ICanBeTased') &&
                 ICanBeTased(probes[i].Victim).IsVulnerableToTaser())
            {
				//log("hit Taseable");
				if (StickToWhat >= STICK_TaseablePawns)
                {
					probes[i].StickToTarget = true;
				}
			}
            else
            {
				//log("hit HasBones");
				if (StickToWhat >= STICK_SkeletalMeshes)
                {
					probes[i].StickToTarget = true;
				}
			}
		}
        else if (probes[i].Victim != None)
        {
			if (probes[i].Victim.IsA('LevelInfo'))
            {
				//log("hit LevelInfo");
				if (StickToWhat >= STICK_AllGeometry)
                {
					probes[i].StickToTarget = true;
				}
			}
            else
            {
				//log("hit noBones");
				if (StickToWhat >= STICK_Actors)
                {
					probes[i].StickToTarget = true;
				}
			}
		}
        else // taser hit nothing
        {
			//log("hit nothing");
			if (StickToWhat >= STICK_Always)
            {
				probes[i].StickToTarget = true;
			}
		}

		if (probes[i].StickToTarget == true && TaserHit)
		{
			probes[i].PostTravelTime = ProbeStickTime;
		}
		else
		{
			probes[i].PostTravelTime = ProbeFallDuration;
		}

		//log("stick to target = " $ probes[i].StickToTarget @
		//	" should stick to: " $ GetEnum(EStickPolicy, StickToWhat) $ " ("$StickToWhat$")");
 	}

	if (TaserHit)
	{
		// make the post travel time the same because it looks weird if one
		// probe lasts longer than the other.
		probes[probe1].PostTravelTime = FMax(probes[probe1].PostTravelTime, probes[probe2].PostTravelTime);
		probes[probe2].PostTravelTime = probes[probe1].PostTravelTime;
	}
	MinTravelTime = FMin(probes[probe1].TravelTime, probes[probe2].TravelTime);

    Tick(0);    //set effects' initial values
}

simulated function GetProbeOriginFrame(int probeInd)
{
    local coords ProbeBoneCoords;

    //taser-end
    if (InFirstPersonView())
    {
        ProbeBoneCoords = GetFirstPersonModel().GetBoneCoords(FirstPersonProbeBones[probeInd], true);    //use socket
		probes[probeInd].ProbeOriginLocation = ProbeBoneCoords.Origin;
		probes[probeInd].ProbeOriginRotation = Rotator(ProbeBoneCoords.XAxis);

		//log("probe bone Origin frame (1st person): " $ string(FirstPersonProbeBones[probeInd]) $ " coords: " $ string(ProbeBoneCoords.Origin));
    }
    else
    {
#if 0 // Disabled because the weapon is currently static mesh, not skeletal mesh with bones
        //ProbeBoneCoords = GetThirdPersonModel().GetBoneCoords(ThirdPersonProbeBones[probeInd], true);    //use socket
#else
		// Use the taser's origin and add the offset in the taser's coordinate system
		probes[probeInd].ProbeOriginLocation = GetThirdPersonModel().Location;
		GetAxes(GetThirdPersonModel().Rotation, ProbeBoneCoords.XAxis,	ProbeBoneCoords.YAxis, ProbeBoneCoords.ZAxis);
		probes[probeInd].ProbeOriginLocation +=
			ThirdPersonProbeOffset[probeInd].X * ProbeBoneCoords.XAxis +
			ThirdPersonProbeOffset[probeInd].Y * ProbeBoneCoords.YAxis +
			ThirdPersonProbeOffset[probeInd].Z * ProbeBoneCoords.ZAxis;
		probes[probeInd].ProbeOriginRotation = SwatPawn(GetThirdPersonModel().owner).GetAimRotation();
#endif
		//log("probe bone Origin frame (3rd person) coords: " $ string(GetThirdPersonModel().Location));
		//log("probe bone Origin frame (3rd person) Rotation: " $ string(SwatPawn(GetThirdPersonModel().owner).GetAimRotation()));
    }


}

simulated function GetProbeOrigin(int probeInd)
{
    local coords ProbeBoneCoords;

    //taser-end
    if (InFirstPersonView())
    {
        ProbeBoneCoords = GetFirstPersonModel().GetBoneCoords(FirstPersonProbeBones[probeInd], true);    //use socket
		probes[probeInd].ProbeOriginLocation = ProbeBoneCoords.Origin;
		//log("probe bone Origin (1st person): " $ string(FirstPersonProbeBones[probeInd]) $ " coords: " $ string(ProbeBoneCoords.Origin));
    }
    else
    {
#if 0 // Disabled because the weapon is currently static mesh, not skeletal mesh with bones
        //ProbeBoneCoords = GetThirdPersonModel().GetBoneCoords(ThirdPersonProbeBones[probeInd], true);    //use socket
#else
		// Use the taser's origin and add the offset in the taser's coordinate system
		probes[probeInd].ProbeOriginLocation = GetThirdPersonModel().Location;
		GetAxes(GetThirdPersonModel().Rotation, ProbeBoneCoords.XAxis,	ProbeBoneCoords.YAxis, ProbeBoneCoords.ZAxis);
		probes[probeInd].ProbeOriginLocation +=
			ThirdPersonProbeOffset[probeInd].X * ProbeBoneCoords.XAxis +
			ThirdPersonProbeOffset[probeInd].Y * ProbeBoneCoords.YAxis +
			ThirdPersonProbeOffset[probeInd].Z * ProbeBoneCoords.ZAxis;
		//log("probe bone Origin (3rd person) coords: " $ string(GetThirdPersonModel().Location));
#endif
    }

}

// This called when the actors owned by the Taser are destroyed
event LostChild( Actor Other )
{
    local TaserProbeBase deadProbe;
    local TaserWire deadWire;
	local int i;

    Super.LostChild(Other);

    // Sometimes probes and wires can slip through corners in bsp and fall
    // out of the world, so we need to clean up properly in this case
    deadProbe = TaserProbeBase(Other);
    deadWire = TaserWire(Other);

    if (deadProbe != None)
    {
        //log("TaserProbe "$deadProbe.Name$" destroyed; cleaning up the Taser references");
		for (i = 0; i < NProbes; ++i)
		    if (probes[i].Probe == deadProbe)
			    probes[i].Probe = None;
    }
    else if (deadWire != None)
    {
        //log("TaserWire "$deadWire.Name$" destroyed; cleaning up the Taser references");
		for (i = 0; i < NProbes; ++i)
			if (probes[i].TaserWire == deadWire)
				probes[i].TaserWire = None;
    }
}


simulated function Tick(float dTime)
{
	local Vector diff;
	local float  timeFraction, timeScale;
	local float diffSize, heightPeak;
	local Coords boneCoords;
	local int i;
	local name currentAnimation;
	local float rawTime, actualAnimRate, recoilSpeedFade;
	local SwatAICharacter ptCharacter;

	super.Tick(dTime);

    if (!ShouldTick) return;

	for (i = 0; i < NProbes; i++) {

		if (probes[i].Active == false) {
			continue;
		}

		// In case the physics engine decided to destroy one of the probes or
		// wires for some reason, end the effect right now
		if (probes[i].Probe == None || probes[i].TaserWire == None) {
			EndAllProbes();		// todo: think about just ending the corresponding pair
			return;
		}

		// update the start locations so the gun can move and have the Wires stay
		// attached
		GetProbeOrigin(i);

		// update the target position if the hit point is an actor
		if (probes[i].Victim != None) {
			if (probes[i].VictimBone != '') {
				boneCoords = probes[i].Victim.GetBoneCoords(probes[i].VictimBone, true);
				probes[i].TargetLocation = boneCoords.Origin +
					probes[i].TargetBoneOffset.X * boneCoords.XAxis +
					probes[i].TargetBoneOffset.Y * boneCoords.YAxis +
					probes[i].TargetBoneOffset.Z * boneCoords.ZAxis;
			} else {
				probes[i].TargetLocation = probes[i].Victim.Location + probes[i].TargetBoneOffset;
			}
		}

		//log("Taser fire victim: " $ Victim @ VictimBone @ TargetLocation);

		probes[i].CurrentTravelTime += dTime;

		timeFraction = probes[i].CurrentTravelTime / probes[i].TravelTime;
		timeFraction = FMin(timeFraction, 1.0);
		timeFraction = FMax(0.01, timeFraction);
		// square the time scale to make it decelerate to simulate slowing
		// down as the wires are being streched
		timeScale    = 1.0 - Square(timeFraction - 1.0);

		//log("Time: " $ CurrentTravelTime @ TravelTime @ timeFraction);
		//log("New Target: " $ TargetLocation);

		diff = probes[i].TargetLocation - probes[i].ProbeOriginLocation;
		diffSize = VSize(diff);
		diff *= timeScale;
		if (WireMaxHeightFraction > 0) {
			heightPeak = FMin(WireMaxHeightFraction * diffSize, WireMaxHeight);
			diff.Z    += heightPeak * (1.0 - 4.0*Square(timeFraction - 0.5));
		}

		if (probes[i].CurrentTravelTime <= probes[i].TravelTime)
		{
			//advance positions
			probes[i].Probe.SetLocation(probes[i].ProbeOriginLocation + diff);
			// use the original probe delta because once the Wires leave, the probes
			// shouldn't be affected by the updated delta
			probes[i].TaserWire.GetAnimParams(0, currentAnimation, rawTime, actualAnimRate);
			if (currentAnimation == '' || rawTime > WireForceSlackTimeFraction) {
				//log("Taser Start slack during travel time: "$ rawTime$", slackTime" $ WireForceSlackTimeFraction);
				probes[i].TaserWire.LoopAnim(WireSlackAnimation[i],
										     WireSlackAnimRate, 0.0, 1);
				// Note: the BlendToAlpha needs to be after the loopAnim so
				// that the channel is properly set up for blending, otherwise
				// the first time the taser is show, the slack doesn't show up
				// because the alpha stays at 0.
				probes[i].TaserWire.AnimBlendToAlpha(1, 1.0, WireSlackTweenTime);
			}

		}
		else // else done moving to target
		{
			// Check for cardiac arrest -- eez
			if(probes[i].Victim != None && probes[i].Victim.IsA('SwatAICharacter') && !probes[i].Victim.IsA('SwatOfficer')) {
				ptCharacter = SwatAICharacter(probes[i].Victim);
				if(ptCharacter.TaserKillsMe() && !probes[i].DidDamageAlready) {
					// Do damage to them.
					probes[i].Victim.TakeDamage(50, Pawn(owner), probes[i].ProbeOriginLocation, diff, None);
					probes[i].DidDamageAlready = true;
				}
			}
			// Check for unauthorized tasering
			if(probes[i].Victim != None && (probes[i].Victim.IsA('SwatOfficer') || probes[i].Victim.IsA('SwatPlayer')) && !probes[0].DidDamageAlready) {
				SwatGameInfo(Level.Game).GameEvents.PawnTased.Triggered(Pawn(probes[i].Victim), owner);
				probes[0].DidDamageAlready = true;
			}

			if (probes[i].StickToTarget)
			{
                //log("Probe["$i$"] sticking to target "$(probes[i].Victim.Name));
				// stay attached to target
				probes[i].Probe.SetLocation(probes[i].ProbeOriginLocation + diff);
				if (probes[i].ProbeState < PROBE_AfterHit)
				{
					if (probes[i].Victim  != None)
					{
						probes[i].Probe.TriggerEffectEvent('BulletHit', ,probes[i].HitMaterial);
					}
					probes[i].ProbeState = PROBE_AfterHit;
					//log("Taser Start slack at hit event, anim: "$WireSlackAnimation[i]$" tween time: "$ WireSlackTweenTime$" rate: "$ WireSlackAnimRate);
					probes[i].TaserWire.LoopAnim(WireSlackAnimation[i],
												 WireSlackAnimRate, 0.0, 1);
					// Note: the BlendToAlpha needs to be after the loopAnim so
					// that the channel is properly set up for blending, otherwise
					// the first time the taser is show, the slack doesn't show up
					// because the alpha stays at 0.
					probes[i].TaserWire.AnimBlendToAlpha(1, 1.0, WireSlackTweenTime);
				}
			}
			else
			{
				//they should start falling
                //log("Probe["$i$"] falling probestate="$GetEnum(EProbeState, probes[i].ProbeState)$" ProbeRecoilTime="$probeRecoils[i].recoilTime);
				if (probes[i].ProbeState < PROBE_AfterHit) {
					if (probes[i].Victim  != None)
					{
						probes[i].Probe.TriggerEffectEvent('BulletHit', ,probes[i].HitMaterial);
					}
					probeRecoils[i].recoilTime = 0;
					diff = Normal(probes[i].Probe.Location - probes[i].ProbeOriginLocation);
					// get the component along the wire direction
					probeRecoils[i].initialVelocity = (probes[i].Probe.Velocity	Dot diff) * diff;
					probeRecoils[i].initialSpeed = VSize(probeRecoils[i].initialVelocity);
                    probes[i].Probe.StartPhysics();
					probes[i].ProbeState = PROBE_AfterHit;
				} else {
					if (probes[i].ProbeState < PROBE_Slacking) {
						if (VSizeSquared(probes[i].Probe.Velocity) < Square(WireSlackStartSpeed)) {
							//log("Taser Start slack at at falling event, when speed slows down enough:"$ VSize(probes[i].Probe.Velocity)$" min speed: "$ WireSlackStartSpeed);
							probes[i].ProbeState = PROBE_Slacking;
							probes[i].TaserWire.LoopAnim(WireSlackAnimation[i],
														 WireSlackAnimRate, 0.0, 1);
							// Note: the BlendToAlpha needs to be after the loopAnim so
							// that the channel is properly set up for blending, otherwise
							// the first time the taser is show, the slack doesn't show up
							// because the alpha stays at 0.
							probes[i].TaserWire.AnimBlendToAlpha(1, 1.0, WireSlackTweenTime);
						}
					}
				}
				// perform the recoil action by putting the velocity component
				// along the wire on a cos, and fading from the initial
				// speed to the final recoil speed
				if (probeRecoils[i].recoilTime <= ProbeRecoilTime)
				{
					diff = Normal(probes[i].Probe.Location - probes[i].ProbeOriginLocation);
					// subtract out the component along the wire direction
					probes[i].Probe.Velocity -= (probes[i].Probe.Velocity Dot diff) * diff;

					if (ProbeRecoilTime > 0)
					{

						timeFraction = probeRecoils[i].recoilTime / ProbeRecoilTime;
						recoilSpeedFade    = probeRecoils[i].initialSpeed +
							timeFraction * (ProbeFinalRecoilSpeed -	probeRecoils[i].initialSpeed);
						// add back in the oscillated velocity along the wire direction
						probes[i].Probe.Velocity +=	(recoilSpeedFade * Cos(Pi * timeFraction)) * diff;
                        //log("Probe["$i$"] Recoil velocity = "$probes[i].Probe.Velocity);
					}
					else
					{
						probes[i].Probe.Velocity -=	ProbeFinalRecoilSpeed * diff;
                        //log("Probe["$i$"] regular velocity = "$probes[i].Probe.Velocity);
					}
					probeRecoils[i].recoilTime += dTime;
				}
			}

			if (probes[i].WireState == WIRE_AttachedToGun)
			{
				// If the Taser gun moves more than a distance threshold, then
				// detach the wire from it, and accelerate the fade out time,
				// so it initiates fadeout right away
				if (VDistSquared(probes[i].ProbeInitialLocation,probes[i].ProbeOriginLocation) >
					Square(WireDetachDistance))
				{
					probes[i].WireState = WIRE_Falling;
					probes[i].TaserWire.SetPhysics(PHYS_Falling);
					probes[i].CurrentTravelTime =
						FMax(probes[i].CurrentTravelTime, MinTravelTime + probes[i].PostTravelTime);
				}
			}

			// Make sure both wires fade out at the same time, even if they
			// travel different distances
			if (probes[i].CurrentTravelTime > (MinTravelTime + probes[i].PostTravelTime + FadeDuration))
			{
				//we're done with this probe
				EndProbe(i);
			}
			else if (probes[i].CurrentTravelTime > (MinTravelTime + probes[i].PostTravelTime))
			{
				//TMC TODO age transparency of Wires
			}
		}

		if (probes[i].WireState == WIRE_AttachedToGun)
		{
			probes[i].TaserWire.SetStartLocation(probes[i].ProbeOriginLocation);
		}
		probes[i].TaserWire.SetEndLocation(probes[i].Probe.Location);
		probes[i].TaserWire.updateSpan();

		//log("TaserWireA Pos: " $ string(ProbeAOriginLocation)  @ string(ProbeA.Location));
	}


	// If they are all done, don't bother ticking any more
	if (probes[0].Active == false && probes[1].Active == false && probes[2].Active == false && probes[3].Active == false) {
		ShouldTick = false;
	}

}

simulated function EndAllProbes()
{
	local int i;

	for (i = 0; i < NProbes; ++i)
		EndProbe(i);

	ShouldTick = false;
}

// Make the probe and wire inactive, but don't destroy it so that it
// can be reused the next time the taser is shot.
simulated function EndProbe(int probeInd)
{
	if (probes[probeInd].Active == false) {
		return;
	}

	//log("Setting to PHYS_None");
	if (probes[probeInd].Probe != None) {
		probes[probeInd].Probe.SetPhysics(PHYS_None);
		probes[probeInd].Probe.OptimizeOut(); // hide and disable tick
	}

	if (probes[probeInd].TaserWire != None) {
		probes[probeInd].TaserWire.SetPhysics(PHYS_None);
		probes[probeInd].TaserWire.AnimBlendToAlpha(1, 0.0, 0.0);
		probes[probeInd].TaserWire.StopAnimating();
		probes[probeInd].TaserWire.OptimizeOut(); // hide and disable tick
	}

	probes[probeInd].Active     = false;
	probes[probeInd].Victim     = None;
	probes[probeInd].VictimBone = '';
}

simulated function DestroyAllProbes()
{
	local int i;

	for (i = 0; i < NProbes; ++i)
		DestroyProbe(i);

	ShouldTick = false;
}

// Completely destroy the probe and wire -
// This is only done when the taser itself gets destroyed.
simulated function DestroyProbe(int probeInd)
{
	if (probes[probeInd].Probe != None) {
		probes[probeInd].Probe.Destroy();
		probes[probeInd].Probe = None;
	}

	if (probes[probeInd].TaserWire != None) {
		probes[probeInd].TaserWire.Destroy();
		probes[probeInd].TaserWire = None;
	}

	probes[probeInd].Active     = false;
	probes[probeInd].Victim     = None;
	probes[probeInd].VictimBone = '';
}

//tcohen 5/8/2004: We used to override FiredWeapon::IsFiredWeaponIdleHook()
//  to return !ShouldTick, ie. the Taser is busy while the
//  probes are visible.
//But that caused problems with AIs, who (reasonably) expect that
//  when HandheldEquipment::LatentUse() returns,
//  the HandheldEquipment should be idle.
//So instead, we override FiredWeapon::PostRoundUsed() to sleep
//  until the probes are done, thereby returning from
//  HandheldEquipment::LatentUse() only after the Taser is idle.
simulated latent function PostRoundUsed()
{
    while (ShouldTick)
        Sleep(0);
}

defaultproperties
{
    Slot=Slot_Invalid
    PlayerTasedDuration=10.0
    AITasedDuration=10.0
	WireZapAnimation[0]=Fire1
	WireZapAnimation[1]=Fire2
	WireSlackAnimation[0]=Slack1
	WireSlackAnimation[1]=Slack2
	WireForceSlackTimeFraction=0.7
	WireSlackAnimRate=2.5
	WireSlackTweenTime=.5
	WireSlackStartSpeed=100
	WireEndEffectorName=TaserProng
	WireMinYZScale=0.1
	WireMaxYZScale=1.0
	WireAnimRate=1.0
	WireMaxHeightFraction=.12
	WireMaxHeight=15
	WireDetachDistance=40
	TaserAimSpread=3.0
	VerticalSpread=0.0
	StickToWhat=STICK_Actors
	ProbeStickTime=1
	ProbeFallDuration=1
	FadeDuration=0.5
    ProbeVisualSpeed=450
	ProbeRecoilTime=0.3
    ProbeFinalRecoilSpeed=120
    ProbePartNames[0]='ProbeA'
    ProbePartNames[1]='ProbeB'
 	WirePartNames[0]='TaserWireA'
 	WirePartNames[1]='TaserWireB'
    FirstPersonProbeBones[0]=TaserProng1
    FirstPersonProbeBones[1]=TaserProng2
    ThirdPersonProbeBones[0]=TaserProng1
    ThirdPersonProbeBones[1]=TaserProng2
    FirstPersonProbeOffset[0]=(X=0,Y=-11,Z=5)
    FirstPersonProbeOffset[1]=(X=0,Y=-11,Z=3.8)
    ThirdPersonProbeOffset[0]=(X=0,Y=-11,Z=4.5)
    ThirdPersonProbeOffset[1]=(X=0,Y=-11,Z=5.5)

	bIsLessLethal=true
}
