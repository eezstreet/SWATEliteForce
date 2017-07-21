class ShotgunAmmo extends RoundBasedAmmo;

var private config bool bPenetratesDoor;

final function bool WillPenetrateDoor()
{
  return bPenetratesDoor;
}

defaultproperties
{
    bPenetratesDoor=true
    StaticMesh=StaticMesh'Hotel_sm.hot_bath_prodbot2'
}
