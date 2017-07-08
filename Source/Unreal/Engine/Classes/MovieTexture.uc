//=============================================================================
// MovieTexture: A movie that plays on a texture
//
// Created by Demiurge Studios 2002
//
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class MovieTexture extends Texture
	native;

// TODO Al: Make this extend UBitmapMaterial, if possible

var const transient Movie Movie;

var() String MovieFilename;
var() int FrameRate;

// native functions.
native final function InitializeMovie();

defaultproperties
{
	FrameRate = 30
}