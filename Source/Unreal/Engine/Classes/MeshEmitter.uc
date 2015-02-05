//=============================================================================
// Emitter: An Unreal Mesh Particle Emitter.
//=============================================================================
class MeshEmitter extends ParticleEmitter
	native;


var (Mesh)		staticmesh		StaticMesh;
var (Mesh)		bool			UseMeshBlendMode;
var (Mesh)		bool			RenderTwoSided;
var (Mesh)		bool			UseParticleColor;

var	transient	vector			MeshExtent;

defaultproperties
{
	UseMeshBlendMode=True
	StartSizeRange=(X=(Min=1,Max=1),Y=(Min=1,Max=1),Z=(Min=1,Max=1))
    StaticMesh=None
}