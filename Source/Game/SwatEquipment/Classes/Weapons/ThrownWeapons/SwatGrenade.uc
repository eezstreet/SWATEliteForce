class SwatGrenade extends Engine.ThrownWeapon;

////////////////////////////////////////////////////////////////////////////////
//
// IHaveWeight implementation

var() protected config float Weight;
var() protected config float Bulk;

simulated function float GetWeight() {
  return Weight;
}

simulated function float GetBulk() {
  return Bulk;
}
