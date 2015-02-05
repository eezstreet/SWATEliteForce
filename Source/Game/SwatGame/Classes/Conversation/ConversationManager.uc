class ConversationManager extends Engine.Actor
    config(Conversations)
    native;

var config float DefaultInterLineDelay;

var private array<Conversation> ActiveConversations;

function StartConversation(name ConversationName)
{
    local SwatGamePlayerController SGPC;
    local Controller current;

    for ( current = Level.ControllerList; current != None; current = current.NextController )
    {
        SGPC = SwatGamePlayerController( current );
        if ( SGPC != None )
        {
            SGPC.ClientStartConversation( ConversationName );
        }
    }
}

simulated function ClientStartConversation(name ConversationName)
{
    local Conversation Conversation;
log( self$"::ClientStartConversation( "$ConversationName$" )" );

    Conversation = new(None, string(ConversationName)) class'Conversation';

    assert(Conversation != None);

    AssertWithDescription(Conversation.Line.length > 0,
        "[tcohen] The ConversationManager was called to start the conversation named "$ConversationName
        $".  But that Conversation doesn't seem to exist (or it is empty) in Conversations.ini.  Please check the name and the config file.");

    //setup a callback for the Conversation to notify the manager when it ends
    Conversation.OnConversationEnded = OnConversationEnded;

    ActiveConversations[ActiveConversations.length] = Conversation;

    Conversation.Start(self);
}

//note that the conversation still needs to do some work
simulated function OnConversationEnded(Conversation Ended, bool Completed)
{
    local int i;

    Label = Ended.Name;  //so that Scripts can be TriggeredBy specific conversations ending
    
    dispatchMessage(new class'MessageConversationEnded'(Completed));

    //remove it from our list of ActiveConversations
    for (i=0; i<ActiveConversations.length; ++i)
    {
        if (ActiveConversations[i] == Ended)
        {
            ActiveConversations[i].OnConversationEnded = None;
            ActiveConversations[i].CleanupActorRefs();
            ActiveConversations.Remove(i, 1);
            return;
        }
    }

    assert(false);  //we should have found the Ended in ActiveConversations
}

simulated event Destroyed()
{
    Super.Destroyed();
    
    while( ActiveConversations.length > 0 )
    {
        ActiveConversations[0].OnConversationEnded = None;
        ActiveConversations[0].CleanupActorRefs();
        ActiveConversations.Remove(0, 1);
    }
}

cpptext
{
    UBOOL Tick(FLOAT DeltaSeconds, enum ELevelTick TickType);
}

defaultproperties
{
    label=ConversationManager
    
    bStatic=false
    Physics=PHYS_None
    bStasis=true
    
    bCollideActors=false
    bCollideWorld=false
    bHidden=true
}
