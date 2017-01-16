class QualifiedTacticalAid extends HandheldEquipment;

////////////////////////////////////////////////////////////////////////////////
//
// IHaveWeight implementation
var() public config float Weight;
var() public config float Bulk;

simulated function float GetWeight() {
  return Weight;
}

simulated function float GetBulk() {
  return Bulk;
}
