class Reaction_RunScript extends Reaction;

var (Reaction) name Script  "The Label of the Script to execute";

protected function Execute(Actor Owner, Actor Other)
{
    Owner.dispatchMessage(new class'MessageRWOReacted'(Owner.label, ''));
}
