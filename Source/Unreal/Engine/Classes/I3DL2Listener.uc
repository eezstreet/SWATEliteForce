//=============================================================================
// I3DL2Listener: Base class for I3DL2 room effects.
//=============================================================================

class I3DL2Listener extends Core.Object
	abstract
	editinlinenew
	native;


var()			float		EnvironmentSize;
var()			float		EnvironmentDiffusion;
var()			int			Room;
var()			int			RoomHF;
var()			int			RoomLF;
var()			float		DecayTime;
var()			float		DecayHFRatio;
var()			float		DecayLFRatio;
var()			int			Reflections;
var()			float		ReflectionsDelay;
var()			vector		ReflectionsPan;
var()			int			Reverb;
var()			float		ReverbDelay;
var()			vector		ReverbPan;
var()			float		EchoTime;
var()			float		EchoDepth;
var()			float		ModulationTime;
var()			float		ModulationDepth;
var()			float		RoomRolloffFactor;
var()			float		AirAbsorptionHF;
var()			float		HFReference;
var()			float		LFReference;
var()			bool		bDecayTimeScale;
var()			bool		bReflectionsScale;
var()			bool		bReflectionsDelayScale;
var()			bool		bReverbScale;
var()			bool		bReverbDelayScale;
var()			bool		bEchoTimeScale;
var()			bool		bModulationTimeScale;
var()			bool		bDecayHFLimit;

var	transient	int			Environment;
var transient	int			Updated;

defaultproperties
{
//	Texture=S_Emitter
	EnvironmentSize=7.5
	EnvironmentDiffusion=1.0
	Room=-1000
	RoomHF=-100
	RoomLF=0
	DecayTime=1.49
	DecayHFRatio=0.83
	DecayLFRatio=1.00
	Reflections=-2602
	ReflectionsDelay=0.007
	Reverb=200
	ReverbDelay=0.011
	EchoTime=0.25
	EchoDepth=0.0
	ModulationTime=0.25
	ModulationDepth=0.0
	RoomRolloffFactor=0.0
	AirAbsorptionHF=-5
	HFReference=5000
	LFReference=250
	bDecayTimeScale=true
	bReflectionsScale=true
	bReflectionsDelayScale=true
	bReverbScale=true
	bReverbDelayScale=true
	bEchoTimeScale=true
	bDecayHFLimit=true
}