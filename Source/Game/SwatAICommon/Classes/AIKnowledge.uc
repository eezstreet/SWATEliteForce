///////////////////////////////////////////////////////////////////////////////

class AIKnowledge extends Core.Object
    implements IVisionNotification
    native
    noexport;

///////////////////////////////////////////////////////////////////////////////

struct native KnowledgeAboutPawn
{
    var vector location;
	var bool   bHasEverSeenPawn;
    // @TODO: Expand data as-needed
};

///////////////////////////////////////////////////////////////////////////////

// Allocate 4 bytes for pointer to a TMap<const APawn *, FKnowledgeAboutPawn *>
// object.
var private int m_knowledgeMap;

var private Pawn m_thisPawn;
var private VisionNotifier m_visionNotifier;

///////////////////////////////////////////////////////////////////////////////

function Init(Pawn thisPawn, VisionNotifier visionNotifier)
{
    assert(thisPawn != none);
    assert(m_visionNotifier == none);

    m_thisPawn = thisPawn;

    if (visionNotifier != none)
    {
        m_visionNotifier = visionNotifier;
        m_visionNotifier.RegisterVisionNotification(self);
    }
}

///////////////////////////////////////

function Term()
{
    m_thisPawn = none;
    if (m_visionNotifier != none)
    {
        m_visionNotifier.UnregisterVisionNotification(self);
        m_visionNotifier = none;
    }
}

///////////////////////////////////////

// Returns false if nothing is known about the other pawn
native function bool GetLastKnownKnowledgeAboutPawn(Pawn otherPawn, out KnowledgeAboutPawn outKnowledge);
native function bool HasKnownKnowledgeAboutPawn(Pawn otherPawn);

native function UpdateKnowledgeAboutPawn(Pawn otherPawn);

///////////////////////////////////////////////////////////////////////////////

// IVisionNotification functions

native function OnViewerSawPawn(Pawn viewer, Pawn seen);
native function OnViewerLostPawn(Pawn viewer, Pawn seen);

///////////////////////////////////////////////////////////////////////////////
