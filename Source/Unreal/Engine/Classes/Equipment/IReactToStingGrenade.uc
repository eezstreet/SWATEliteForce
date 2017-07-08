interface IReactToStingGrenade extends IReactToGrenades;

//damage - Damage should be applied constantly over DamageRadius
//karma impulse - Physics impulse should be applied linearly from PhysicsImpulse.Max to PhysicsImpulse.Min over PhysicsImpulseRadius
function ReactToStingGrenade(   
    SwatProjectile Grenade, 
	Pawn  Instigator,  // who shot the grenade?
    float Damage, 
    float DamageRadius, 
    Range PhysicsImpulse, 
    float PhysicsImpulseRadius, 
    float StingRadius,
    float PlayerStingDuration,
    float HeavilyArmoredPlayerStingDuration,
	float NonArmoredPlayerStingDuration,
    float AIStingDuration,
    float MoraleModifier);
