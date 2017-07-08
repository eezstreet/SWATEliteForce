//=============================================================================
// MeshObject
//
// A base class for all Animating-Mesh-editing classes.  Just a convenient place to store
// common elements like enums.
//=============================================================================

class MeshObject extends Core.Object
	abstract
	native;


// Impostor render switches
enum EImpSpaceMode
{
	ISM_Sprite,
	ISM_Fixed,
	ISM_PivotVertical,
	ISM_PivotHorizontal,
};
enum EImpDrawMode
{
	IDM_Normal, 
	IDM_Fading,  
};	
enum EImpLightMode
{
	ILM_Unlit,
	ILM_PseudoShaded,	// Lit by hardware, diverging normals.
	ILM_Uniform,	        // Lit by hardware, all normals pointing faceward.
};	

// Mesh static-section extraction methods
enum EMeshSectionMethod
{
	MSM_SmoothOnly,    // Smooth (software transformed) sections only.
	MSM_RigidOnly,     // Only draw rigid parts, throw away anything that's not rigid.
	MSM_Mixed,         // Convert suitable mesh parts to rigid and draw remaining sections smoothly (software transformation).
	MSM_SinglePiece,   // Freeze all as a single static piece just as in the refpose.
	MSM_ForcedRigid,   // Convert all faces to rigid parts using relaxed criteria ( entire smooth sections forced rigid ).	
};

// Animation (re-)compression methods.
enum EAnimCompressMethod
{
	ACM_Raw,            // Throws away only perfectly interpolatable keys.
	ACM_Classic,        // Throws away keys but don't quantize.
	ACM_Quantized16bit, // Quantized quaternions, taking up 3x16 bits each.	
};

defaultproperties
{
}
