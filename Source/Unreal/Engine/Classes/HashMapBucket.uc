class HashMapBucket extends Core.Object;

var array<HashMapEntry> Entries;

final function Empty()
{
    local int i;

    for (i=0; i<Entries.length; ++i)
        Entries[i].Object = None;

    Entries.Remove(0, Entries.length);
}

final function bool HasKey(string inKey)
{
    local int i;

    for (i=0; i<Entries.length; ++i)
        if (Entries[i].Key == inKey)
            return true;

    return false;
}

final function Add(string inKey, Object object)
{
    local HashMapEntry newEntry;

    newEntry = new class'HashMapEntry';
    newEntry.Key = inKey;
    newEntry.Object = object;

    Entries[Entries.length] = newEntry;
}

final function Remove(string inKey)
{
    local int i;

    for (i=0; i<Entries.length; ++i)
    {
        if (Entries[i].Key == inKey)
        {
            Entries.Remove(i, 1);
            //NOTE: index is no longer valid
            break;
        }
    }
}

//returns the first object with key=inKey, or None
final function Object Lookup(string inKey)
{
    local int i;

    for (i=0; i<Entries.length; ++i)
        if (Entries[i].Key == inKey)
            return Entries[i].Object;

    return None;
}
