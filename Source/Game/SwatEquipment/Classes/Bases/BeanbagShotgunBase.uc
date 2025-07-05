class BeanbagShotgunBase extends RoundBasedWeapon
  config(SwatEquipment);

var config float Damage;

var config float PlayerStingDuration;
var config float HeavilyArmoredPlayerStingDuration;
var config float NonArmoredPlayerStingDuration;
var config float AIStingDuration;
var config float OfficerUseRangeMin;
var config float OfficerUseRangeMax;
var config int OfficerUseTargetMinHealth;
var config int OfficerUseMaxShotsWhenStung;

simulated function DealDamage(Actor Victim, int Damage, Pawn Instigator, Vector HitLocation, Vector MomentumVector, class<DamageType> DamageType )
{
    // Don't deal damage for pawns, instead make them effected by the sting grenade
    if ( Victim.IsA( 'Pawn' ) )
    {
      IReactToDazingWeapon(Victim).ReactToLessLeathalShotgun(Pawn(Owner), Damage, MomentumVector, PlayerStingDuration, HeavilyArmoredPlayerStingDuration, NonArmoredPlayerStingDuration, AIStingDuration, DamageType);

      log("Called ReactToLessLeathalShotgun on: "$Victim$", Damage="$Damage$"" );

      // This is now handled in ReactToLessLeathalShotgun
      //Super.DealDamage( Victim, Damage, Instigator, HitLocation, MomentumVector, DamageType );
    }
    // Otherwise deal damage, cept for ExplodingStaticMesh that is....
    else if ( !Victim.IsA('ExplodingStaticMesh') )
    {
        Super.DealDamage( Victim, Damage, Instigator, HitLocation, MomentumVector, DamageType );
    }
}

// Less-lethal should never spawn blood effects
simulated function bool  ShouldSpawnBloodForVictim( Pawn PawnVictim, int Damage )
{
    return false;
}

simulated function bool ShouldOfficerUseAgainst(Pawn OtherActor, int ShotsFired)
{
    local SwatPawn SwatPawn;
    local float Distance;

    SwatPawn = SwatPawn(OtherActor);
    if (SwatPawn == None)
    {
        return false;
    }

    // Don't use them -at all- against hostages
    if (SwatPawn.IsA('SwatHostage'))
    {
        return false;
    }

    // Don't shoot the target if lower than X health
    if (SwatPawn.Health < OfficerUseTargetMinHealth)
    {
        return false;
    }

    if (SwatPawn.IsStung() && ShotsFired >= OfficerUseMaxShotsWhenStung)
    {   
        // Don't shoot more than 3 times if the target is stunned
        return false;
    }

    Distance = VSize(Owner.Location - OtherActor.Location);
    if (Distance < OfficerUseRangeMin || Distance > OfficerUseRangeMax)
    {   
        // Outside of the range
        log (Name$"::ShouldOfficerUseAgainst("$OtherActor.Name$") for "$Owner.Name$": not using the LL now because Distance of "$Distance$" falls outside the range.");
        return false;
    }

    return super.ShouldOfficerUseAgainst(OtherActor, ShotsFired);
}


defaultproperties
{
    Slot=Slot_Invalid
	bIsLessLethal=true
	WoodBreachingChance = 0;
	MetalBreachingChance = 0;
	bPenetratesDoors=false
    OfficerUseRangeMin=256
    OfficerUseRangeMax=1024
    OfficerUseMaxShotsWhenStung=3
    OfficerUseTargetMinHealth=80
}
