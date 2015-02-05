//=============================================================================
// SpawnableEmitter:
//   If you want to be able to spawn an emitter at runtime, use this class
//   and not the base Emitter class. However, if you need a placeable
//   emitter that will appear on clients in MP games, you must use the
//   base emitter (SpawnableEmitters that are placed in the level instead of
//   being spawned will NOT show up on MP clients!). 
//   
//   So, in general, use this class for your weapon effects, and Emitter.uc
//   for atmospheric effects.
//   
//=============================================================================
class SpawnableEmitter extends Emitter
    native;

cpptext
{
    void CheckForErrors();
}

defaultproperties
{
    RemoteRole=ROLE_None
    bNoDelete=false
//#if IG_SWAT // ckline: generally a good idea to make transient emitters AutoDestroy
	AutoDestroy=true 
//#endif
}

