class Reaction_DispatchMessage extends Reaction;

var(Reaction) class<Message> DispatchMessage;

protected function Execute(Actor Owner, Actor Other)
{
    Owner.dispatchMessage(new DispatchMessage );
}