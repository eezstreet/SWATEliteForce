///////////////////////////////////////////////////////////////////////////////
//
// Proxy class for forwarding script calls to the actual native implementation
// object.
//

class AwarenessProxy extends Core.Object
    implements IVisionNotification, IHearingNotification,
               IInterestedActorDestroyed, IInterestedPawnDied
    native
    noexport;

///////////////////////////////////////////////////////////////////////////////

struct native AwarenessKnowledge
{
    // Reference to the awareness point that this piece of knowledge is about.
    var AwarenessPoint aboutAwarenessPoint;

    // The confidence is a factor of when the AI has last seen the awareness
    // point, combined with influence from the confidence of nearby awareness
    // points.
    var float confidence;

    // @TODO: Document
    var float threat;
};

///////////////////////////////////////////////////////////////////////////////

// The native version will use these 4 bytes as a pointer to the
// implementation class
var private int m_implPadding;

///////////////////////////////////////////////////////////////////////////////

native function Init(array<Pawn> outerPawns);

///////////////////////////////////////////////////////////////////////////////

// IAwareness functions

native function Term();
native function ForceViewerSawPawn(Pawn viewer, Pawn Seen);
native function AwarenessKnowledge        GetKnowledge(AwarenessPoint aboutAwarenessPoint);
native function array<AwarenessKnowledge> GetPotentiallyVisibleKnowledge(optional Pawn visibilityFromPawn);
native function array<AwarenessKnowledge> GetVisibleKnowledge(optional Pawn visibilityFromPawn);
native function DrawDebugInfo(HUD hud);

///////////////////////////////////////

// IVisionNotification functions

native function OnViewerSawPawn(Pawn viewer, Pawn seen);
native function OnViewerLostPawn(Pawn viewer, Pawn seen);

///////////////////////////////////////

// IHearingNotification functions

native function OnListenerHeardNoise(Pawn listener, Actor soundMaker, vector soundOrigin, Name soundCategory);

///////////////////////////////////////

// IInterestedActorDestroyed functions

native function OnOtherActorDestroyed(Actor actorBeingDestroyed);

///////////////////////////////////////

// IInterestedPawnDied functions

native function OnOtherPawnDied(Pawn deadPawn);

///////////////////////////////////////////////////////////////////////////////
