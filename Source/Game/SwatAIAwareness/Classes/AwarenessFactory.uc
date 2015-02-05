///////////////////////////////////////////////////////////////////////////////
//
// A general-purpose factory, for instantiating any awareness-related object
// that an external package might need to create. The private concrete class
// is returned via its public interface.
//

class AwarenessFactory extends Core.Object;

///////////////////////////////////////////////////////////////////////////////

static function AwarenessProxy CreateAwarenessForPawn(Pawn outerPawn)
{
    local array<Pawn> outerPawns;

    outerPawns[0] = outerPawn;
    return CreateAwarenessForMultiplePawns(outerPawns);
}

///////////////////////////////////////

static function AwarenessProxy CreateAwarenessForMultiplePawns(array<Pawn> outerPawns)
{
    local AwarenessProxy AwarenessProxy;

    AwarenessProxy = new class'AwarenessProxy';
    AwarenessProxy.Init(outerPawns);

    return AwarenessProxy;
}

///////////////////////////////////////////////////////////////////////////////
