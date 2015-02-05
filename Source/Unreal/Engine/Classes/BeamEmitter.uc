//=============================================================================
// BeamEmitter: An Unreal Beam Particle Emitter.
//=============================================================================
class BeamEmitter extends ParticleEmitter
	native;


enum EBeamEndPointType
{
	PTEP_Velocity,
	PTEP_Distance,
	PTEP_Offset,
	PTEP_Actor,
	PTEP_TraceOffset,
	PTEP_OffsetAsAbsolute
};

struct ParticleBeamData
{
	var vector	Location;
	var float	t;
};

struct ParticleBeamEndPoint
{
	var () name			ActorTag;
	var () rangevector	Offset;
	var () float		Weight;
};

struct ParticleBeamScale
{
	var () vector		FrequencyScale;
	var () float		RelativeLength;
};

var (Beam)			range						BeamDistanceRange;	
var (Beam)			array<ParticleBeamEndPoint>	BeamEndPoints;
var (Beam)			EBeamEndPointType			DetermineEndPointBy;		
var (Beam)			float						BeamTextureUScale;
var (Beam)			float						BeamTextureVScale;
var (Beam)			int							RotatingSheets;
var (Beam)			bool						TriggerEndpoint;

var (BeamNoise)		rangevector					LowFrequencyNoiseRange;
var (BeamNoise)		int							LowFrequencyPoints;
var (BeamNoise)		rangevector					HighFrequencyNoiseRange;
var (BeamNoise)		int							HighFrequencyPoints;
var (BeamNoise)		array<ParticleBeamScale>	LFScaleFactors;
var (BeamNoise)		array<ParticleBeamScale>	HFScaleFactors;
var (BeamNoise)		float						LFScaleRepeats;
var (BeamNoise)		float						HFScaleRepeats;
var (BeamNoise)		bool						UseHighFrequencyScale;
var (BeamNoise)		bool						UseLowFrequencyScale;
var (BeamNoise)		bool						NoiseDeterminesEndPoint;
var (BeamNoise)		rangevector					DynamicHFNoiseRange;
var (BeamNoise)		range						DynamicHFNoisePointsRange;
var (BeamNoise)		range						DynamicTimeBetweenNoiseRange;

var (BeamBranching) bool						UseBranching;
var (BeamBranching)	range						BranchProbability;
var	(BeamBranching) range						BranchHFPointsRange;
var (BeamBranching)	int							BranchEmitter;
var (BeamBranching) range						BranchSpawnAmountRange;
var (BeamBranching) bool						LinkupLifetime;

var	transient		int							SheetsUsed;
var transient		int							VerticesPerParticle;
var transient		int							IndicesPerParticle;
var transient		int							PrimitivesPerParticle;
var transient		float						BeamValueSum;
var transient		array<ParticleBeamData>		HFPoints;
var transient		array<vector>				LFPoints;
var transient		array<actor>				HitActors;
var transient		float						TimeSinceLastDynamicNoise;

defaultproperties
{
	HighFrequencyPoints=10
	LowFrequencyPoints=3
	BeamTextureUScale=1
	BeamTextureVScale=1
	BranchEmitter=-1
	BranchHFPointsRange=(Min=0,Max=1000)
}