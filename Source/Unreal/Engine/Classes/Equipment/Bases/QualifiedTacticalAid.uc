class QualifiedTacticalAid extends HandheldEquipment;

////////////////////////////////////////////////////////////////////////////////
//
// IHaveWeight implementation
var() public config float Weight;
var() public config float Bulk;
var() public config int StartCount;
var() public config bool PlayerUsable;

static function float GetInitialWeight()
{
  return default.StartCount * default.Weight;
}

static function float GetInitialBulk()
{
  return default.StartCount * default.Bulk;
}

simulated function float GetItemWeight() {
  return Weight;
}

simulated function float GetItemBulk() {
  return Bulk;
}

simulated function int GetDefaultAvailableCount()
{
  return StartCount;
}

static function bool IsUsableByPlayer()
{
	return default.PlayerUsable;
}

defaultproperties
{
  StartCount=1
}
