class StingGrenadeProjectile extends Engine.SwatGrenadeProjectile
    config(SwatEquipment);

//damage - Damage should be applied constantly over DamageRadius
var config float Damage;
var config float DamageRadius;

//karma impulse - Karma impulse should be applied linearly from KarmaImpulse.Max to KarmaImpulse.Min over KarmaImpulseRadius
var config Range KarmaImpulse;
var config float KarmaImpulseRadius;

//Sting
var config float StingRadius;
var config float PlayerStingDuration;
var config float HeavilyArmoredPlayerStingDuration;
var config float NonArmoredPlayerStingDuration;
var config float AIStingDuration;
var config float MoraleModifier;


simulated function Detonated()
{
    local IReactToStingGrenade Current;
    local ICareAboutGrenadesGoingOff CurrentExtra;
    local float OuterRadius;

    OuterRadius = FMax(FMax(DamageRadius, KarmaImpulseRadius), StingRadius);

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
    if (bRenderDebugInfo)
    {
        // Render a box approximating the radius of effect
        Level.GetLocalPlayerController().myHUD.AddDebugBox(
            Location,
            OuterRadius*2,
            class'Engine.Canvas'.Static.MakeColor(0,255,0),
            5);
    }
#endif

    foreach AllActors(class 'ICareAboutGrenadesGoingOff', CurrentExtra) {
      CurrentExtra.OnStingerWentOff(Pawn(Owner));
    }

    foreach VisibleCollidingActors(class'IReactToStingGrenade', Current, OuterRadius)
    {
        //try to reject the candidate

        if (Actor(Current).Region.ZoneNumber != Region.ZoneNumber)  //in a different zone ...
            if (!FastTrace(Actor(Current).Location))                //  ... and blocked
                continue;

        //can't reject

        Current.ReactToStingGrenade(
            Self,
            Pawn(Owner),
            Damage,
            DamageRadius,
            KarmaImpulse,
            KarmaImpulseRadius,
            StingRadius,
            PlayerStingDuration,
            HeavilyArmoredPlayerStingDuration,
			NonArmoredPlayerStingDuration,
            AIStingDuration,
            MoraleModifier);

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
        if (bRenderDebugInfo)
        {
            // Render line to actors that are affected
            Level.GetLocalPlayerController().myHUD.AddDebugLine(
                Location, Actor(Current).Location,
                class'Engine.Canvas'.Static.MakeColor(0,0,255),
                5);
        }
#endif
    }

    if ( Level.NetMode != NM_Client )
        SwatGameInfo(Level.Game).GameEvents.GrenadeDetonated.Triggered( Pawn(Owner), Self );

    dispatchMessage(new class'MessageStingGrenadeDetonated');
}


simulated latent function DoPostDetonation()
{
    // MCJ: we need keep the projectile around for awhile after it
    // detonates. The problem this addresses is that because of network lag,
    // the clients start their FuseTime sleep a little after the server. If
    // the server's fusetime is up and it detonates the projectile and
    // destroys it, sometimes the clients' projectiles will get destroyed
    // before the fusetime is up on the clients, so they never see the
    // explosion or whatever.
    bHidden = true;

    //log("disabling tick for "$self);
    Disable('Tick');

    Sleep( 3.0 );

    if ( Level.NetMode != NM_Client )
    {
        Destroy();
    }
}



defaultproperties
{
    StaticMesh=StaticMesh'SwatGear_sm.stingGrenadeThrown'
}
