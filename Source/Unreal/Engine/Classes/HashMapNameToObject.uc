class HashMapNameToObject extends Core.Object;

var private array<HashMapBucket> Buckets;

const NUM_BUCKETS = 256;

function int HashKey(string inKey)
{
    return abs(Hash(inKey, NUM_BUCKETS));
}

final function Empty()
{
    local int i;

    for (i=0; i<Buckets.length; ++i)
        Buckets[i].Empty();

    Buckets.Remove(0, Buckets.length);
}

final function bool HasKey(string inKey)
{
    local int bucket;

    bucket = HashKey(inKey);

    if (bucket >= Buckets.length)
        return false;
    
    return Buckets[bucket].HasKey(inKey);
}

final function Add(String inKey, Object object)
{
    local int bucket;

    bucket = HashKey(inKey);

    if (bucket >= Buckets.length || Buckets[bucket] == None)
        Buckets[bucket] = new class'HashMapBucket';

    Buckets[bucket].Add(inKey, object);
}

final function Remove(string inKey)
{
    local int bucket;

    bucket = HashKey(inKey);

    Buckets[bucket].Remove(inKey);
}

//returns the first object with key=inKey, or None
final function Object Lookup(string inKey)
{
    local int bucket;

    bucket = HashKey(inKey);

    if (bucket >= Buckets.length || Buckets[bucket] == None)
        return None;

#if IG_SHARED // Ryan: Don't assume there is a valid bucket
	if (Buckets[bucket] == None)
		return None;
#endif // IG

    return Buckets[bucket].Lookup(inKey);
}

final function HashMapBucket GetBucket(string inKey)
{
    local int bucket;

    bucket = HashKey(inKey);

    if (bucket >= Buckets.length)
        return None;
    
    return Buckets[HashKey(inKey)];
}

//for debugging
final function int GetBucketIndex(string inKey)
{
    return HashKey(inKey);
}

final function Profile()
{
    //calculate the bucket size mean and standard deviation
    local float Mean;
    local float Variance;
    local float StandardDeviation;
    local int i;
    local int used;
    local int max;

    //mean
    for (i=0; i<Buckets.length; ++i)
    {
        if (Buckets[i] != None)
        {
            ++used;
            if (Buckets[i].Entries.length > max)
                max = Buckets[i].Entries.length;
            Mean += Buckets[i].Entries.length;
        }
    }
    Mean = Mean / Buckets.length;

    //add squared deviations
    for (i=0; i<Buckets.length; ++i)
        if (Buckets[i] != None)
            Variance += Square(Buckets[i].Entries.length - Mean);
        else
            Variance += Square(Mean);
    Variance = Variance / Buckets.length;

    //standard deviation
    StandardDeviation = Sqrt(Variance);

    log(name$"::Profile(): NUM_BUCKETS="$NUM_BUCKETS$", BucketsAllocated="$Buckets.length$", BucketsUsed="$used$", MaxBucketSize="$max$", MeanBucketSize="$mean$", StandardDeviation="$StandardDeviation);

    /* TMC uncomment for a full dump of each bucket's stats
    for (i=0; i<Buckets.length; ++i)
        if (Buckets[i] != None)
            log("  -> Bucket #"$i$": Size="$Buckets[i].Entries.length$" ("$abs(Buckets[i].Entries.length - Mean) / StandardDeviation$" s.d.(s) from mean)");
        else
            log("  -> Bucket #"$i$": Size=[unallocated:0] ("$Mean / StandardDeviation$" s.d.(s) from mean)");
    */
}
