//=============================================================================
// An object taht can be deleted with an explicit cal to "delete" 
//
// (for those cases where you know for sure when an object's life ends
// and don't want to refcount)
//=============================================================================
class DeleteableObject extends Object
	noexport
	native;

#if IG_UC_LATENT_STACK_CLEANUP // Ryan: Latent stack cleanup
var transient private const Array<INT> LatentStackLocations;
#endif

// increment reference count, return new value
native(200) final function Delete();
