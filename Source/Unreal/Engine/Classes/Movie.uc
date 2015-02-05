//=============================================================================
// Movie.uc: A movie that plays on a surface be that a texture or the canvas
//
// Created by Demiurge Studios 2002
//
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class Movie extends Core.Object
	native
	noexport;

var const transient int FMovie; //this is really an FMovie*

// native functions.
native final function Play( String MovieFilename, bool UseSound, bool LoopMovie);
native final function Pause( bool Pause );
native final function bool IsPaused();
native final function StopNow();
native final function StopAtEnd();
native final function bool IsPlaying();
native final function int GetWidth();
native final function int GetHeight();

