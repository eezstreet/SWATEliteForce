// rowan: NOTE: This class has been added purely to work around a bug where C++ classes derived from native script classes do not inherit
// the scripted classes default properties. The work around is to add a placeholder noexprt native script class for the C++ class.
class TexCoordMaterial extends RenderedMaterial
	native
	noexport;

var const transient private int Texture;
var const transient private int TextureCoords;
