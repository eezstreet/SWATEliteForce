// Base class for Havok properties for Actors.

class HavokObject extends Core.Object
	abstract
#if IG_SHARED // ckline
	hidecategories(Object)
#endif
	native;
	
var const transient bool hkInitCalled; // To help debug stay InitGame calls.

