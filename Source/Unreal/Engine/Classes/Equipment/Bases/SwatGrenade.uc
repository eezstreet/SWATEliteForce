class SwatGrenade extends ThrownWeapon;

var() config vector PlayerViewOffset;

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

simulated function vector GetPlayerViewOffset()
{
    return PlayerViewOffset;
}

defaultproperties
{
  PlayerViewOffset = (X=-22,Y=7,Z=-12)
}
