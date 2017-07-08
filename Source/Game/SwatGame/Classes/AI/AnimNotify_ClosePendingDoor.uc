class AnimNotify_ClosePendingDoor extends Engine.AnimNotify_Scripted;

// just tells the owner to close its pending door if the owner is a SwatAI
event Notify( Actor Owner )
{
	assert(Owner != None);
    
    if (Owner.IsA('SwatAI'))
    {
		SwatAI(Owner).InteractWithPendingDoor();
	}
}
