class DamageRadiusDamageType extends Engine.DamageCategory
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
    FriendlyName="nearby explosion"
}
