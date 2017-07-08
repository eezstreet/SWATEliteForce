class AnimNotify_Trigger extends AnimNotify_Scripted;

var() name EventName;

event Notify( Actor Owner )
{
	Owner.TriggerEvent( EventName, Owner, Pawn(Owner) );
}

