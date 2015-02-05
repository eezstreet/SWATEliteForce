//=============================================================================
// A reference counted object
//	-	You have to explicitly AddRef and Release() the object
//		Just like using COM or DirectX 
//	-	This is not ideal, however for now its the most elegant way
//		of managing deletable objects without adding features to the compiler.
//	-	NOTE: The object begins with a refcount of 0, which means the inital
//		owner should addref() it after allocation
//=============================================================================
class RefCount extends Object
	noexport
	native;
 
var private const int m_RefCount;

#if IG_UC_LATENT_STACK_CLEANUP // Ryan: Latent stack cleanup
var transient private const Array<INT> LatentStackLocations;
#endif

// increment reference count, return new value
native(199) final function int AddRef();

// decrement reference count, return new value
// when the refcount reaches 0, the object is deleted
native(198) final function int Release();
