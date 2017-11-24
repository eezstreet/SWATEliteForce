class SwatAICharacterConfig extends Core.Object
  config(AI);

var public config Mesh OfficerMesh;
var public config Mesh OfficerHeavyMesh;
var public config Mesh OfficerNoArmorMesh;
var public config Material OfficerHeavyDefaultMaterial[4];

static function Mesh GetOfficerHeavyMesh()
{
  return default.OfficerHeavyMesh;
}

static function Mesh GetOfficerNoArmorMesh()
{
  return default.OfficerNoArmorMesh;
}

static function Mesh GetOfficerMesh()
{
  return default.OfficerMesh;
}
