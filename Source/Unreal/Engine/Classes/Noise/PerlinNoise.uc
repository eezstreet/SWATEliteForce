class PerlinNoise extends Core.DeleteableObject
    native;

var const transient private noexport int Generator;	    //a native FPerlinNoise*

native function float Noise1(float X);
native function float Noise2(float X, float Y);
native function float Noise3(float X, float Y, float Z);

//causes the noise generator to build a new noise function
native function Reinitialize();

cpptext
{
    //Constructor
    UPerlinNoise::UPerlinNoise();

    //Overridden from UObject, called via the destructor implemented in this
    //  class's DECLARE_CLASS macro.
	virtual void Destroy();

    class FPerlinNoise* Generator;
}
