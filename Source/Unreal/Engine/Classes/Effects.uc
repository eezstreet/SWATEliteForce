//=============================================================================
// Effects, the base class of all gratuitous special effects.
// 
//=============================================================================
class Effects extends Actor;

defaultproperties
{
     DrawType=DT_Sprite
     Physics=PHYS_None
     bUnlit=True
	 bNetTemporary=true
	 bGameRelevant=true
	 CollisionRadius=+0.00000
	 CollisionHeight=+0.00000
     RemoteRole=ROLE_None
     bNetInitialRotation=true
}
