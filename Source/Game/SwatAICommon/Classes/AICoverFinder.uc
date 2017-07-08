///////////////////////////////////////////////////////////////////////////////
//
// AI cover api
//

class AICoverFinder extends Core.Object
    native;

///////////////////////////////////////////////////////////////////////////////

// The outer pawn of this take cover object. Set by constructor.
var private Pawn m_pawn;

///////////////////////////////////////////////////////////////////////////////

// Used by SwatHUD and the cover debug stuff.

enum EShowCoverInfoDetail
{
    // Each higher enum value incorporates the lower detail levels
    kSCID_PlaneAndExtrusionIntersection,
    kSCID_IndividualExtrusions,
    kSCID_IndividualInverseExtrusions,
};

///////////////////////////////////////////////////////////////////////////////

// Allows the client to specify which location in the cover volume it wants.

enum EAICoverLocationType
{
    // Client wants the cover location along the nearest side plane, closest
    // to the pawn.
    kAICLT_NearestSide,
    // Client wants the cover location along the front plane, closest to the
    // pawn.
    kAICLT_NearestFront,
    // Client wants the cover location at the corner of the near and front
    // cover planes.
    kAICLT_NearFrontCorner,
    // Client wants the cover location at the corner of the far and front
    // cover planes.
    kAICLT_FarFrontCorner,
};

///////////////////////////////////////

// Enum used in the AICoverResult structure. See AICoverResult for details.
enum EAICoverLocationInfo
{
    kAICLI_NotInCover,
    kAICLI_InLowCover,
    kAICLI_InCover,
};

///////////////////

// Enum used in the AICoverResult structure. See AICoverResult for details.
enum EAICoverLocationSide
{
    kAICLS_NotApplicable,
    kAICLS_Left,
    kAICLS_Right,
};

///////////////////

// Structure returned by the cover finding functions, that provides the results
// of the cover evaluation.

struct native AICoverResult
{
    // Provides information about the cover location.
    var EAICoverLocationInfo coverLocationInfo;

    // The actor that is providing the cover for our pawn.
    var Actor coverActor;

    // The world-space location the pawn should move to in order to gain
    // cover. Will be (0,0,0) if coverLocationInfo is kAICLI_NotInCover.
    var Vector coverLocation;

    // Enum value indicating which side of the front cover plane's normal this
    // location is on. The front plane's normal points into the cover volume.
    // This value is oriented such that if a pawn is inside the cover volume
    // facing the plane, with the normal pointed toward the pawn, left is to
    // the pawn's left, and right is to the pawn's right.
    var EAICoverLocationSide coverSide;

    // A 0-65536 (0-360 degree) value indicating the yaw of the cover plane,
    // *away* from the cover volume. If a pawn were inside the cover volume,
    // this would be the yaw to face him perpendicular to the plane.
    var int coverYaw;
};

///////////////////////////////////////

// @NOTE: These cover functions operate on cover in the same zone as m_pawn,
// unless otherwise noted.

// Returns true if there are cover actors in the same zone as the pawn
// currently is in.
native function bool IsCoverAvailable();

// Evaluates cover behind every cover actor in the same zone as the pawn
// currently is in. Upon success, returns the desired location within the
// closest cover volume to the pawn. Fails if there is no adequate cover
// available.
native function AICoverResult FindCover(array<Pawn> otherPawns,
    EAICoverLocationType locationType);

// Evaluates cover behind the specified cover actor. Upon success, returns the
// desired location within that cover volume. Fails if cover actor does not
// provide adequate cover.
native function AICoverResult FindCoverBehindActor(array<Pawn> otherPawns,
    Actor coverActor, EAICoverLocationType locationType);

// Evaluates the specified location against all the cover volumes in the same
// zone the pawn currently is in.
native function AICoverResult IsLocationInCover(array<Pawn> otherPawns,
    Vector location);

// Evaluates the specified location behind the specified cover actor.
native function AICoverResult IsLocationInCoverBehindActor(array<Pawn> otherPawns,
    Actor coverActor, Vector location);

///////////////////////////////////////////////////////////////////////////////

overloaded function Construct(Pawn pawn)
{
    m_pawn = pawn;
    assert(m_pawn != none);
}

///////////////////////////////////////

function Pawn GetOuterPawn()
{
    return m_pawn;
}

///////////////////////////////////////////////////////////////////////////////
