class GrenadeDamageType extends DamageType
    implements DamageType
    config(SwatEquipment)
    ;

var config localized   String  FriendlyName;

static function string GetFriendlyName()
{
    return default.FriendlyName;
}

defaultproperties
{
    FriendlyName="Grenade Explosion"
}
