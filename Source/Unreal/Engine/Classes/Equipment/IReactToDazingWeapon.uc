interface IReactToDazingWeapon;

function ReactToLessLeathalShotgun(
  Pawn Instigator,
    float Damage,
    Vector MomentumVector,
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration,
	class<DamageType> DamageType);

// Triple baton rounds are launched from the grenade launcher but are handle differently than a direct hit from a launched grenade
function ReactToGLTripleBaton(
	Pawn  Instigator,
    float Damage,
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration,
	class<DamageType> DamageType);

// React to a direct hit from a grenade launched from the grenade launcher
function ReactToGLDirectGrenadeHit(
	Pawn  Instigator,
    float Damage,
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration,
	class<DamageType> DamageType);

function ReactToMeleeAttack(
	class<DamageType> MeleeDamageType,
	Pawn  Instigator,
    float Damage,
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration);
