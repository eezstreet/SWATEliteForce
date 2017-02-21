class LessLethalSG extends Shotgun
    config(SwatEquipment);

var config float Damage;

var config float PlayerStingDuration;
var config float HeavilyArmoredPlayerStingDuration;
var config float NonArmoredPlayerStingDuration;
var config float AIStingDuration;

simulated function DealDamage(Actor Victim, int Damage, Pawn Instigator, Vector HitLocation, Vector MomentumVector, class<DamageType> DamageType )
{
    // Don't deal damage for pawns, instead make them effected by the sting grenade
    if ( Victim.IsA( 'Pawn' ) )
    {
        IReactToDazingWeapon(Victim).ReactToLessLeathalShotgun(
			PlayerStingDuration,
			HeavilyArmoredPlayerStingDuration,
			NonArmoredPlayerStingDuration,
			AIStingDuration);

      log("Called ReactToLessLeathalShotgun on: "$Victim$", Damage="$Damage$"" );

      Super.DealDamage( Victim, Damage, Instigator, HitLocation, MomentumVector, DamageType );
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


defaultproperties
{
    Slot=Slot_Invalid
	bIsLessLethal=true
	WoodBreachingChance = 0;
	MetalBreachingChance = 0;
	bPenetratesDoors=false
}
