interface IReactToDazingWeapon;

function ReactToLessLeathalShotgun(
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration);

// Triple baton rounds are launched from the grenade launcher but are handle differently than a direct hit from a launched grenade
function ReactToGLTripleBaton(
	Pawn  Instigator,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration);

// React to a direct hit from a grenade launched from the grenade launcher
function ReactToGLDirectGrenadeHit(
	Pawn  Instigator,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration);

function ReactToMeleeAttack(
	class<DamageType> MeleeDamageType,
	Pawn  Instigator,
    float Damage, 
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration);