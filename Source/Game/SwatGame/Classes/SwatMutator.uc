class SwatMutator extends Engine.Mutator;

function bool MutatorIsAllowed()
{
    return !Level.IsDemoBuild() || Class==class'SwatMutator' || Super.MutatorIsAllowed();
}
