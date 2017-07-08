class ConcussiveDamageType extends Engine.DamageCategory
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
    FriendlyName="C2 Explosion"
}