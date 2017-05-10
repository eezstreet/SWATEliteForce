class FlashbangGrenadeProjectile extends Engine.SwatGrenadeProjectile
    config(SwatEquipment);

//damage - Damage should be applied constantly over DamageRadius
var config float Damage;
var config float DamageRadius;

//karma impulse - Karma impulse should be applied linearly from KarmaImpulse.Max to KarmaImpulse.Min over KarmaImpulseRadius
var config Range KarmaImpulse;
var config float KarmaImpulseRadius;

//stun
var config float StunRadius;
var config float PlayerStunDuration;
var config float AIStunDuration;
var config float MoraleModifier;


simulated function Detonated()
{
    local IReactToFlashbangGrenade Current;
    local ICareAboutGrenadesGoingOff CurrentExtra;
    local float OuterRadius;
	local vector vCeilingChkr;

    OuterRadius = FMax(FMax(DamageRadius, KarmaImpulseRadius), StunRadius);
	vCeilingChkr = Location;
	vCeilingChkr.Z = Location.Z + 246;

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
    if (bRenderDebugInfo)
    {
        // Render a box approximating the radius of affect
        Level.GetLocalPlayerController().myHUD.AddDebugBox(
            Location,
            StunRadius*2,
            class'Engine.Canvas'.Static.MakeColor(0,255,0),
            5);
    }
#endif

    foreach AllActors(class'ICareAboutGrenadesGoingOff', CurrentExtra) 
	{
      CurrentExtra.OnFlashbangWentOff(Pawn(Owner));
    }
	
  if(FastTrace(Location, vCeilingChkr))
{	
    foreach RadiusActors(class'IReactToFlashbangGrenade', Current, OuterRadius)
    {
        //try to reject the candidate

        if  (
                Actor(Current).Region.ZoneNumber != Region.ZoneNumber   //in a different zone
            )
            continue;

        //can't reject

        Current.ReactToFlashbangGrenade(
            Self,
            Pawn(Owner),
            Damage,
            DamageRadius,
            KarmaImpulse,
            KarmaImpulseRadius,
            StunRadius,
            PlayerStunDuration,
            AIStunDuration,
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
}	
  else
{	  
    foreach VisibleCollidingActors(class'IReactToFlashbangGrenade', Current, OuterRadius)
    {
        //try to reject the candidate

        if  (
                Actor(Current).Region.ZoneNumber != Region.ZoneNumber   //in a different zone
            &&  !FastTrace(Actor(Current).Location)                     //and blocked
            &&  GetLastTracedActor().class.name != 'DoorWay'            //but not by a DoorWay
            )
            continue;

        //can't reject

        Current.ReactToFlashbangGrenade(
            Self,
            Pawn(Owner),
            Damage,
            DamageRadius,
            KarmaImpulse,
            KarmaImpulseRadius,
            StunRadius,
            PlayerStunDuration,
            AIStunDuration,
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
}	

    if ( Level.NetMode != NM_Client )
        SwatGameInfo(Level.Game).GameEvents.GrenadeDetonated.Triggered( Pawn(Owner), Self );
    dispatchMessage(new class'MessageFlashbangGrenadeDetonated');

    bStasis = true; // optimization

    if (Level.DetailMode == DM_Low)
        LifeSpan = 30; // destroy self after 30 seconds, for optimization
    else
        LifeSpan = 180; // destroy self after 3 minutes, for optimization
}

simulated latent function DoPostDetonation()
{
    //log("disabling tick for "$self);
    Disable('Tick');
}


defaultproperties
{
    StaticMesh=StaticMesh'SwatGear_sm.FlashbangThrown'
}
