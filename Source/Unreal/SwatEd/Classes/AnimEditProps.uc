//=============================================================================
// Object to facilitate properties editing
//=============================================================================
//  Animation / Mesh editor object to expose/shuttle only selected editable 
//  parameters from UMeshAnim/ UMesh objects back and forth in the editor.
//  

class AnimEditProps extends Engine.MeshObject
	hidecategories(Object)
	native;	

cpptext
{
	void PostEditChange();
}

var const int WBrowserAnimationPtr;
var(Compression) float   GlobalCompression;
var(Compression) EAnimCompressMethod CompressionMethod;

defaultproperties
{	
	GlobalCompression=1.0
}
