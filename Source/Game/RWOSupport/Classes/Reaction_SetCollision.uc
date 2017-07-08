class Reaction_SetCollision extends Reaction;

var (Reaction) bool CollideActors;
var (Reaction) bool BlockActors;
var (Reaction) bool BlockPlayers;

protected simulated function Execute(Actor Owner, Actor Other)
{
    Owner.SetCollision(CollideActors, BlockActors, BlockPlayers);
}
