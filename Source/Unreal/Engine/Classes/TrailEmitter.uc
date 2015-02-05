//=============================================================================
// Emitter: An Unreal Trail Particle Emitter.
//=============================================================================
class TrailEmitter extends ParticleEmitter
	abstract
	native;

struct ParticleTrailData
{
	var vector	Location;
	var color	Color;
	var float	Size;
	var int		DoubleDummy1;
	var int		DoubleDummy2;
};

struct ParticleTrailInfo
{
	var int		TrailIndex;
	var int		NumPoints;
	var vector	LastLocation;
};

var (Trail)			int							MaxPointsPerTrail;
var (Trail)			float						DistanceThreshold;
var (Trail)			bool						UseCrossedSheets;
var (Trail)			int							MaxTrailTwistAngle;

var transient		array<ParticleTrailData>	TrailData;
var transient		array<ParticleTrailInfo>	TrailInfo;
var transient		vertexbuffer				VertexBuffer;
var transient		indexbuffer					IndexBuffer;
var transient		int							VerticesPerParticle;
var transient		int							IndicesPerParticle;
var transient		int							PrimitivesPerParticle;


defaultproperties
{
	MaxPointsPerTrail=50
	DistanceThreshold=1
	MaxTrailTwistAngle=16384
}