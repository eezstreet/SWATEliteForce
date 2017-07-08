class CSGasGrenadeProjectile extends Engine.SwatGrenadeProjectile;

var config float UpdatePeriod;  //how often to check who I'm affecting
var config float GasEmissionDuration; // how long the gas grenade continues to "emit" gas (not related to the visual effect, only the logic)
var config float ReactionDuration; // how long a gassed pawn reacts to the gas, ie. how long it takes for a pawn to recover after leaving the gas
var config float ExpansionTime; // how long it takes for the radius of effect to go from min to max
var config Range Radius; // the radius of effect, both min and max, that expands over ExpansionTime

// When a Player (non-AI) being gassed has protective
// equipment that protects him from gas, then the duration of
// effect will be scaled by this value.
// I.e., Duration *= <XXX>PlayerProtectiveEquipmentDurationScaleFactor
// Where XXX is SP or MP depending on whether it's a single-player or
// multiplayer game
var config float SPPlayerProtectiveEquipmentDurationScaleFactor;
var config float MPPlayerProtectiveEquipmentDurationScaleFactor;

var float DetonatedTime;

///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
simulated function Detonated()
{
    local ICareAboutGrenadesGoingOff CurrentExtra;
    DetonatedTime = Level.TimeSeconds;
    GotoState('Active');

    foreach AllActors(class'ICareAboutGrenadesGoingOff', CurrentExtra) {
      CurrentExtra.OnCSGasWentOff(Pawn(Owner));
    }

    dispatchMessage(new class'MessageCSGasGrenadeDetonated');
}

///////////////////////////////////////////////////////////////////////////////

protected function float GetRadiusOfEffect()
{
    local float FractionOfMaxRadius;
    local float ElapsedTime;

    ElapsedTime = Level.TimeSeconds - DetonatedTime;
    FractionOfMaxRadius = FClamp(ElapsedTime / ExpansionTime, 0.0, 1.0);
    return Lerp(FractionOfMaxRadius, Radius.Min, Radius.Max);
}

simulated state Active
{
    simulated event Timer()
    {
        local float Now;
        local Engine.IReactToCSGas Current;
        local float EffectRadius;

        Now = Level.TimeSeconds;

        if (Now > DetonatedTime + GasEmissionDuration)
        {
            SetTimer(0, false);     //stop the timer
            GotoState('Dead');
        }
        else
        {
            //update the effect radius
            EffectRadius = GetRadiusOfEffect();

            //tell all affected IReactToCSGas to ReactToCSGas()

            foreach RadiusActors(class'Engine.IReactToCSGas', Current, EffectRadius)
            {
                if  (                                                   // (it's within range, and
                        Actor(Current).Region.Zone == Region.Zone       //  AND it's in the same zone),
                    ||  FastTrace(Location, Actor(Current).Location)    // OR it's unblocked
                    )
                {
                    Current.ReactToCSGas(
                        self,
                        ReactionDuration,
                        SPPlayerProtectiveEquipmentDurationScaleFactor,
                        MPPlayerProtectiveEquipmentDurationScaleFactor);

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
                    if (bRenderDebugInfo)
                    {
                        // Render line to actors that are affected
                        Level.GetLocalPlayerController().myHUD.AddDebugLine(
                            Location, Actor(Current).Location,
                            class'Engine.Canvas'.Static.MakeColor(0,0,255),
                            UpdatePeriod);
                    }
#endif
                }
            }
        }

    }

    event Tick(float dTime)
    {
#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
        local float EffectRadius;
#endif
        Super.Tick(dTime);

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
        if (bRenderDebugInfo)
        {
            EffectRadius = GetRadiusOfEffect();
            log("RAD="$EffectRadius);
//#if 0
//        // ckline: Draw3DCylinder seems to be busted
//            // Render a cylinder approximating the radius of effect
//            Level.GetLocalPlayerController().myHUD.Draw3DCylinder(
//                Location,
//                Vect(1,0,0), Vect(0,1,0), Vect(0,0,1),
//                EffectRadius, EffectRadius,
//                class'Engine.Canvas'.Static.MakeColor(0,255,0),
//                20);
//#else
            // Render a box approximating the radius of effect
            Level.GetLocalPlayerController().myHUD.AddDebugBox(
                Location,
                EffectRadius*2, // pass the diameter to addDebugBox
                class'Engine.Canvas'.Static.MakeColor(0,255,0),
                UpdatePeriod);
//#endif
       }
#endif
    }

    simulated function Detonated()
    {
        assertWithDescription(false,
            "[tcohen] "$name$" Detonated(), but it is already Active.");
    }

Begin:

    SetTimer(UpdatePeriod, true);   //loop
}


///////////////////////////////////////////////////////////////////////////////
simulated state Dead
{
    simulated event Timer()
    {
        assertWithDescription(false,
            "[tcohen] "$name$" is Dead, but it is still getting Timer() events.");
    }

    simulated function Detonated()
    {
        assertWithDescription(false,
            "[tcohen] "$name$" Detonated, but it is Dead.");
    }

Begin:

    bBlockNonZeroExtentTraces=false; // optimization

    bStasis = true; // optimization

    //log("disabling tick for "$self);
    Disable('Tick');

    if (Level.DetailMode == DM_Low)
        LifeSpan = 30; // destroy self after 30 seconds, for optimization
    else
        LifeSpan = 180; // destroy self after 3 minutes, for optimization
}


defaultproperties
{
    StaticMesh=StaticMesh'SwatGear_sm.CSgasGrenadeThrown'
    bBlockNonZeroExtentTraces=true
    ExpansionTime=2
	GasEmissionDuration=12
	Radius=(Min=20.0,Max=400.0)
	UpdatePeriod=0.5
    SPPlayerProtectiveEquipmentDurationScaleFactor=0
    MPPlayerProtectiveEquipmentDurationScaleFactor=0
}
