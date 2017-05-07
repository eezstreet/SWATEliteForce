class SwatAICharacterConfig extends Core.Object
  config(AI);

var public config Mesh OfficerMesh;
var public config Mesh OfficerHeavyMesh;

static function Mesh GetOfficerHeavyMesh()
{
  return default.OfficerHeavyMesh;
}

static function Mesh GetOfficerMesh()
{
  return default.OfficerMesh;
}
