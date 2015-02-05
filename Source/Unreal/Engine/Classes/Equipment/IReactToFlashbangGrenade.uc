interface IReactToFlashbangGrenade extends IReactToGrenades;

//damage - Damage should be applied constantly over DamageRadius
//physics impulse - Physics impulse should be applied linearly from PhysicsImpulse.Max to PhysicsImpulse.Min over PhysicsImpulseRadius
function ReactToFlashbangGrenade(   
    SwatGrenadeProjectile Grenade, 
	Pawn  Instigator,
    float Damage, 
    float DamageRadius, 
    Range PhysicsImpulse, 
    float PhysicsImpulseRadius, 
    float StunRadius,
    float PlayerStunDuration,
    float AIStunDuration,
    float MoraleModifier);
