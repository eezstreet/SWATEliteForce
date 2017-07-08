class CSBallBase extends Engine.SwatProjectile
    config(SwatEquipment)
    abstract;

var config float CloudRadius;
var config float CloudDuration;
var config float AIGassedDuration;
var config float PlayerGassedDuration;
var config float UpdatePeriod;

// When a Player (non-AI) being gassed has protective 
// equipment that protects him from gas, then the duration of 
// effect will be scaled by this value. 
// I.e., PlayerDuration *= <XXX>PlayerProtectiveEquipmentDurationScaleFactor
// Where XXX is SP or MP depending on whether it's a single-player or
// multiplayer game

var config float SPPlayerProtectiveEquipmentDurationScaleFactor;
var config float MPPlayerProtectiveEquipmentDurationScaleFactor;

var vector PreviousLocation;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    PreviousLocation = Location;
}

simulated function PostBump(actor Other)
{
    // Don't play effects on invisible objects, other paintballs, and our owner
    if ( !Other.IsA( 'Door' ) && !Other.bHidden && !Other.IsA('CSBallBase') && Other != Owner )
    {
        TriggerEffectEvent('BulletHit');
        GotoState('Hit');
    }
}

simulated event HitWall(vector HitNormal, actor HitWall)
{
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games 
    if (Level.AnalyzeBallistics)
        //draw a BLUE box at the current Location when HitWall
        Level.GetLocalPlayerController().myHUD.AddDebugBox(Location, 3, class'Engine.Canvas'.Static.MakeColor(0,0,255), 7);
#endif

    TriggerEffectEvent(
        'BulletHit', 
        HitWall,            //Other
        None,               //TargetMaterial
        Location,           //HitLocation
        Rotator(HitNormal)  //HitNormal
        );

    GotoState('Hit');
}

simulated event Touch(Actor Other)
{
    local Actor HitActor;
    local vector TraceEnd, HitLocation, HitNormal;

    TraceEnd = PreviousLocation + 2 * (Location - PreviousLocation);

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games 
    if (Level.AnalyzeBallistics)
    {
        log("CSBallBase::Touch() Other="$Other.class.name$", PreviousLocation="$PreviousLocation$", Location="$Location);
        //draw a RED line along the trace vector (starting at PreviousLocation)
        Level.GetLocalPlayerController().myHUD.AddDebugLine(PreviousLocation, TraceEnd, class'Engine.Canvas'.Static.MakeColor(255,0,0), 5);
        ////draw a RED box at the current Location when Touch
        //Level.GetLocalPlayerController().myHUD.AddDebugBox(Location, 3, class'Engine.Canvas'.Static.MakeColor(255,0,0), 7);
    }
#endif

	HitActor = Trace(
        HitLocation,        // out vector      HitLocation,
        HitNormal,          // out vector      HitNormal,
        TraceEnd,           // vector          TraceEnd,
        PreviousLocation,   // optional vector TraceStart,
        true,               // optional bool   bTraceActors,
        ,                   // optional vector Extent,
        ,                   // optional out material Material,
        false,              // optional bool   bWeaponFireTest,
        false,              // optional bool   bTraceThroughSeeThroughMaterials,
        true);              // optional bool   bSkeletalBoxTest,

    if (Level.AnalyzeBallistics)
    {
        if (HitActor != None)
            log("... HitActor="$HitActor);
        else
            log("... HitActor=None");
    }

    if (HitActor != None)
    {
        if (HitActor.bHidden && HitActor.class.name != 'LevelInfo')
        {
            log("... invisible & !BSP: returning");
            return;             //ignore invisible and not BSP
        }

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games 
        if (Level.AnalyzeBallistics)
		{
        	log("... backing-off to HitLocation="$HitLocation);
            //draw a GREEN box at the HitLocation
            Level.GetLocalPlayerController().myHUD.AddDebugBox(HitLocation, 3, class'Engine.Canvas'.Static.MakeColor(0,255,0), 7);
		}
#endif

        SetCollision(false, false, false);
        SetLocation(HitLocation);
        GotoState('Hit');           //clears collision

        TriggerEffectEvent('BulletHit');
    }
}

function Tick(float dTime)
{
    PreviousLocation = Location;
}

#define DEBUG_CSBALLBASETIMER 0

simulated state Hit
{
    simulated event Timer()
    {
        local Pawn Pawn;
        local vector ViewPoint;
        local Actor HitActor;
        local vector HitLocation, HitNormal;
        local Material HitMaterial;
//      local SwatDoor HitDoor;
        local bool PawnShouldBeAffected;

#if DEBUG_CSBALLBASETIMER
log("TMC CSBallBase::Timer()");
#endif
        //update victims
        for (Pawn = Level.pawnList; Pawn != None; Pawn = Pawn.nextPawn)
        {
#if DEBUG_CSBALLBASETIMER
log("TMC ... considering Pawn="$Pawn.name$" at Location="$Pawn.Location);
#endif
            if (Pawn.IsA('SwatAI'))
                ViewPoint = SwatAI(Pawn).GetViewPoint();
            else
            if (Pawn.IsA('SwatPlayer'))
                ViewPoint = SwatPlayer(Pawn).GetThirdPersonEyesLocation();
            else
				ViewPoint = Pawn.GetAimOrigin();

            if (VSize(ViewPoint - Location) > CloudRadius)
            {
#if DEBUG_CSBALLBASETIMER
log("TMC ... too far away, skipping.  ViewPoint=("$ViewPoint$"), Location=("$Location$"), distance="$VSize(ViewPoint - Location));
#endif
                continue;           //too far away
            }

#if DEBUG_CSBALLBASETIMER
log("TMC ... close enough.  ViewPoint=("$ViewPoint$"), Location=("$Location$"), distance="$VSize(ViewPoint - Location));
#endif

            PawnShouldBeAffected=true;
            
            //only affect the Pawn if a trace can get to them
#if DEBUG_CSBALLBASETIMER
log("TMC ... tracing from Location="$Location$" to ViewPoint="$ViewPoint);
#endif
            foreach TraceActors(
                class'Actor',
                HitActor,
                HitLocation,
                HitNormal,
                HitMaterial,
                ViewPoint,
                Location)
            {
#if DEBUG_CSBALLBASETIMER
log("TMC ... ... trace hit "$HitActor);
#endif
                if (HitActor.class.name == 'LevelInfo')
                {
#if DEBUG_CSBALLBASETIMER
log("TMC ... ... NOT calling ReactToCSGas(): HitActor="$HitActor$" of class "$HitActor.class.name$" and BLOCKED by BSP.");
#endif
                    PawnShouldBeAffected = false;                              //trace is blocked by BSP
                    break;
                }

                if (HitActor.DrawType == DT_None || HitActor.bHidden)
                {
#if DEBUG_CSBALLBASETIMER
log("TMC ... ... ignoring invisible actor "$HitActor$" of class "$HitActor.class.name);
#endif
                    continue;                           //ignore invisible actors
                }
                
                
                if( HitActor.IsA( 'SwatDoor' ) )
                {
#if DEBUG_CSBALLBASETIMER
log("TMC ... ... ignoring door animation "$HitActor$" of class "$HitActor.class.name);
#endif
                    continue;                           //ignore SwatDoors
                }
                
                
                if( HitActor.IsA( 'DoorModel' ) )
                {
#if DEBUG_CSBALLBASETIMER
log("TMC ... ... NOT calling ReactToCSGas(): HitActor="$HitActor$" of class "$HitActor.class.name$" and BLOCKED by a DoorModel.");
#endif
                    PawnShouldBeAffected = false;                              //trace is blocked by a DoorModel
                    break;
                }
            }// forEach TraceActors
            
            if( PawnShouldBeAffected )
            {
#if DEBUG_CSBALLBASETIMER
log("TMC ... calling ReactToCSGas() on Pawn="$Pawn$" of class "$Pawn.class.name);
#endif
                if (Pawn.IsA('SwatPlayer'))
                {
                    IReactToCSGas(Pawn).ReactToCSGas(
                        self, 
                        PlayerGassedDuration, 
                        SPPlayerProtectiveEquipmentDurationScaleFactor,
                        MPPlayerProtectiveEquipmentDurationScaleFactor);

						if (Level.GetEngine().EnableDevTools)
						{
                            mplog("CSBallBase::Timer() calling ReactToCSGas() on: "$Pawn
                                    $", PlayerGassedDuration is: "$PlayerGassedDuration
                                    $", SP/MP duration scale factor is "$SPPlayerProtectiveEquipmentDurationScaleFactor
                                    $"/"$MPPlayerProtectiveEquipmentDurationScaleFactor
                                    $" for protective equipment" );
                        }
                }
                else
                {
                    IReactToCSGas(Pawn).ReactToCSGas(
                        self, 
                        AIGassedDuration,
                        1, 1                // AI is always fully protected if it has protective equipment that protects it from gas
                        );

					if (Level.GetEngine().EnableDevTools)
					{
                        mplog( "CSBallBase::Timer() calling ReactToCSGas() on: "$Pawn
                                $", AIGassedDuration is: "$AIGassedDuration
                                $", SP/MP duration scale factor is 1/1 for protective equipment" );
					}
                }
            }   //if( PawnShouldBeAffected )
        }   //foreach Pawn
    }

    function BeginState()
    {
		if (Level.GetEngine().EnableDevTools)
		{
        	mplog( "CSBallBase::Hit state beginning" );
		}

        SetPhysics(PHYS_None);
        SetDrawType(DT_None);
        SetCollision(false, false, false);
        Velocity = vect(0,0,0);
        if (Level.NetMode != NM_Client)
        {
            SetTimer(UpdatePeriod, true);   //loop

		    if (Level.GetEngine().EnableDevTools)
		    {
                mplog( "CSBallBase::Hit state calling timer" );
		    }

            Timer();
        }
    }

Begin:

    Sleep(CloudDuration);
    Destroy();
}

defaultproperties
{
    DrawType=DT_Sprite
    Texture=Material'Engine_res.SunIcon'
    CollisionRadius=5
    CollisionHeight=5
    RemoteRole=ROLE_None 
    SPPlayerProtectiveEquipmentDurationScaleFactor=0
    MPPlayerProtectiveEquipmentDurationScaleFactor=0
    bBlockActors=false
    bBlockPlayers=false
}
