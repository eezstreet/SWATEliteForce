//=============================================================================
// Emitter: An Unreal Sprite Particle Emitter.
//=============================================================================
class SpriteEmitter extends ParticleEmitter
	native;


enum EParticleDirectionUsage
{
	PTDU_None,
	PTDU_Up,
	PTDU_Right,
	PTDU_Forward,
	PTDU_Normal,
	PTDU_UpAndNormal,
	PTDU_RightAndNormal,
	PTDU_Scale
};


var (Sprite)		EParticleDirectionUsage		UseDirectionAs;
var (Sprite)		vector						ProjectionNormal;

var transient		vector						RealProjectionNormal;

defaultproperties
{
	UseDirectionAs=PTDU_None
	ProjectionNormal=(X=0,Y=0,Z=1)
}