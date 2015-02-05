interface IInterestedActorDestroyed
    native;

//-------------------------------------------------------------------
// IInterestedActorDestroyed:
// 
// This interface should be implemented by those objects that wish
// to be notified whenever a bStatic=false actor is destroyed during
// normal gameplay. Interested objects can register for such notification
// via the following methods in LevelInfo.uc:
//
//   RegisterNotifyActorDestroyed(IInterestedPawnDied ObjectToNotify)
//   UnRegisterNotifyActorDestroyed(IInterestedPawnDied RegisteredObject)
//
// WARNING: Even if ObjectToNotify is itself an Actor, it will NOT be 
// notified of its own destruction. If it wishes to handle its own 
// destruction, it should override Pawn.Destroyed().
//
//-------------------------------------------------------------------

// Called from within ULevel::DestroyActor(<ActorBeingDestroyed>) 
// *after* ActorBeingDestroyed->Modify() has been called but
// *before* ActorBeingDestroyed->{PostScriptDestroyed/ConditionalDestroy/Destroyed}()
// has been called. 
//
// Therefore it is valid to access methods and data on 
// ActorBeingDestroyed inside of this method. However, after
// this method exits, all references to ActorBeingDestroyed and 
// its data should be considered invalid.
//
// Note: This notification is only sent if ActorBeingDestroyed.bStatic==false.
function OnOtherActorDestroyed(Actor ActorBeingDestroyed);