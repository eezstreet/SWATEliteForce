// TKBMS v1.0 -----------------------------------------------------
//
// PLATFORM		: ALL
// PRODUCT		: HAVOK_2
// VISIBILITY	: PUBLIC
//
// ------------------------------------------------------TKBMS v1.0

inline hkUint32 hkAdvancedGroupFilter::calcFilterInfo( int layer, int systemGroup, int subpartID, int ignoreSubpart)
{
	// Collision filter info is 
	// Bit 31-17	System Group
	// Bit 16-11	Subpart ID
	// Bit 10-5		Ignore  ID
	// Bit 4-0		Layer   Bitfield
	HK_ASSERT2(1035, layer >=0 && layer < 32 , "Only 32 collision layers allowed in the Advanced Group Filter");
	HK_ASSERT2(1036, systemGroup>=0 && systemGroup < 0x8000, "Only 32768 system groups allowed in the Advanced Group  Filter");
	HK_ASSERT2(1037, subpartID >=0 && subpartID < 64 , "Only 64 unique subparts per system group allowed in the Advanced Group Filter");
	HK_ASSERT2(1038, ignoreSubpart >=0 && ignoreSubpart < 64 , "Ignoring : Only 64 unique subparts per system group allowed in the Advanced Group Filter");

	return hkUint32( (systemGroup << 17) | (subpartID << 11) | (ignoreSubpart << 5) | layer );
}

		/// Returns true if the objects are enabled to collide, based on their collision groups.
inline bool hkAdvancedGroupFilter::isCollisionEnabled(const hkCollidable& a, const hkCollidable& b) const
{
	// Get group from prim
	unsigned int infoA = a.getCollisionFilterInfo();
	unsigned int infoB = b.getCollisionFilterInfo();

	// Collision filter info is 
	// Bit 31-18	System Group
	// Bit 11-16	Subpart ID
	// Bit 5-10		Ignore  ID
	// Bit 0-4		Layer   Bitfield
	const hkUint32 systemGroup = (infoA^infoB) & 0xfffe0000; 
	const hkUint32 subpartA    = (infoA & 0x0001f800) >> 11;		   
	const hkUint32 ignoreA     = (infoA & 0x000007e0) >> 5;
	const hkUint32 subpartB    = (infoB & 0x0001f800) >> 11;		   
	const hkUint32 ignoreB     = (infoB & 0x000007e0) >> 5;


	// check for identical system groups
	if ( systemGroup == 0)
	{
		// check whether system group was set
		if ( (infoA & 0xfffe0000) != 0 )
		{
			// Return collision disabled (false) if
			//     ignoreA and ignoreB are both 0
			// or  ignoreA == subpartB
			// or  ignoreB == subpartA
			return ((ignoreA !=0) || (ignoreB !=0)) &&
				   (ignoreA != subpartB) && 
				   (ignoreB != subpartA);
		}
	}

	const hkUint32 f = 0x1f;
	const hkUint32 layerBitsA = m_collisionLookupTable[ infoA & f ];
	const hkUint32 layerBitsB = hkUint32(1 << (infoB & f));

	return 0 != (layerBitsA & layerBitsB);
}