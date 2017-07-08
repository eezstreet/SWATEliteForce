//=============================================================================
// Keypoint, the base class of invisible actors which mark things.
//=============================================================================
class Keypoint extends Actor
	abstract
	placeable
	native;

defaultproperties
{
     bStatic=True
     bHidden=True
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications 
//     SoundVolume=0
//#endif
     CollisionRadius=+00010.000000
     CollisionHeight=+00010.000000
	 Texture=Texture'Engine_res.S_Keypoint'
}
