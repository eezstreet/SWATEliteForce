interface IInterestedPawnDied
    native;

//-------------------------------------------------------------------
// IInterestedPawnDied:
// 
// This interface should be implemented by those objects that wish
// to be notified whenever a Pawn dies. Interested objects can 
// register for such notification via the following methods in 
// LevelInfo.uc:
//
//   RegisterNotifyPawnDied(IInterestedPawnDied ObjectToNotify)
//   UnRegisterNotifyPawnDied(IInterestedPawnDied RegisteredObject)
//
// Note: If the ObjectToNotify is itself a pawn, it *will* receive 
// notification of its own death.
//
//-------------------------------------------------------------------

// Called immediately after a Engine.Pawn.Died() is called on a Pawn,
// or Engine.Controller.PawnDied() is called on the pawn's Controller 
// (whichever comes first; only one notification will be sent).
function OnOtherPawnDied(Pawn DeadPawn);