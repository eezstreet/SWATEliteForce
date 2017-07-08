class Handler extends Core.Object
    hideCategories(Object)
    collapsecategories
    editinlinenew
    native
    abstract;

// These Reactions need to have their references nulled in CleanupRefs
var (Handler) editinline deepcopy private array<Reaction> Reactions;

//should only be called by subclasses
final protected simulated function DoReactions(Actor Owner, Actor Other)
{
    local int i;
    //log(self$"::DoReactions( "$Owner$", "$Other$" )");
    for (i=0; i<Reactions.length; ++i)
        Reactions[i].InternalExecute(Owner, Other); // note: may not really execute if it's exhausted
}

cpptext
{
    void CleanupRefs();
    void DetachReactions();
    void CheckForErrors(const TCHAR* RWOName, const TCHAR* HandlersName);
}
