class AnimNotify_DropWeapon extends Engine.AnimNotify_Scripted;


// MCJ: Chris originally had this at 600, but we were having problems with
// weapons going through walls and floor when they were dropped. He suggested
// reducing the MAX value, so I'm trying 300.
const MAX_MAGNITUDE = 300;
var() rotator   DropDirection "Direction the weapon should fall (based on the the enemy's current rotation) when dropped";
var() float	    Magnitude "Magnitude of impulse to apply to the weapon in the DropDirection, in UnrealUnits/second";
var() float	    RandomDropChance "Enter a value between 0.0 and 1.0 if you want a random drop chance";

// just tells the owner to drop its weapon if it is a SwatEnemy
event Notify( Actor Owner )
{
    local float ClampedMagnitude;

	assert(Owner != None);
    
    if (Owner.IsA('SwatEnemy') && (FRand() <= RandomDropChance))
    {
        // clamp the magnitude so we don't throw the weapon into outer space
        // by accident
        ClampedMagnitude = FClamp(Magnitude, 0, MAX_MAGNITUDE);
        mplog( "AnimNotify_DropWeapon calling DropCurrentWeapon()." );
        SwatEnemy(Owner).DropCurrentWeapon(vector(DropDirection), ClampedMagnitude);
	}
}

defaultproperties
{
	DropDirection=(Pitch=0,Yaw=0,Roll=0)
	Magnitude=275.0
	RandomDropChance=1.0
}
