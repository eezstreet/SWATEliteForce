// TKBMS v1.0 -----------------------------------------------------
//
// PLATFORM		: ALL
// PRODUCT		: HAVOK_2
// VISIBILITY	: PUBLIC
//
// ------------------------------------------------------TKBMS v1.0

inline hkObb::hkObb(const hkTransform& obb2body, const hkVector4& extents)
	: m_transform( obb2body), m_extents(extents) 
{
}

inline hkReal hkObb::getVolume() const
{
	/// The volume of the OBB is  x * y * z, where x, y and z are the respective
	/// dimensions of the OBB ( ie. twice the half extents ).
	return m_extents(0) * m_extents(1) * m_extents(2) * 8.0f;
}

inline const hkTransform& hkObb::getTransform() const
{
	return m_transform;
}

inline hkTransform& hkObb::getTransform()
{
	return m_transform;
}

inline void hkObb::setTransform(const hkTransform& t)
{
	m_transform = t;
}

inline void hkObb::expand(const hkReal tolerance)
{
	m_extents(0) += tolerance;
	m_extents(1) += tolerance;
	m_extents(2) += tolerance;
}

inline void hkObb::getAABB(const hkTransform& body2world, hkAabb& aabbOut) const
{
	hkTransform obb2world;
	obb2world.setMul( body2world, m_transform );

	// transform the extents and min.max them
	hkVector4 orig;

	hkVector4 te0; te0.set(m_extents(0), 0, 0);
	hkVector4 te1; te1.set(0, m_extents(1), 0);
	hkVector4 te2; te2.set(0, 0, m_extents(2));
	
	// extents rotated
	te0.setRotatedDir( obb2world.getRotation(), te0);
	te1.setRotatedDir( obb2world.getRotation(), te1);
	te2.setRotatedDir( obb2world.getRotation(), te2);

	orig = obb2world.getTranslation();

	/// find the bottom corner
	orig.sub4( te0 );
	orig.sub4( te1 );
	orig.sub4( te2 );

	// double the half-extents
	te0.mul4( 2 );
	te1.mul4( 2 );
	te2.mul4( 2 );

	// find all 8 corners 
	hkVector4 c0; c0 = orig;
	hkVector4 c1; c1.setAdd4( c0, te0 );
	hkVector4 c2; c2.setAdd4( c1, te1 );
	hkVector4 c3; c3.setAdd4( c0, te1 );

	hkVector4 c4; c4.setAdd4( c0, te2 );
	hkVector4 c5; c5.setAdd4( c4, te0 );
	hkVector4 c6; c6.setAdd4( c5, te1 );
	hkVector4 c7; c7.setAdd4( c4, te1 );
	
	aabbOut.m_min.setMin4( c0, c1 );
	aabbOut.m_min.setMin4( aabbOut.m_min, c2 );
	aabbOut.m_min.setMin4( aabbOut.m_min, c3 );
	aabbOut.m_min.setMin4( aabbOut.m_min, c4 );
	aabbOut.m_min.setMin4( aabbOut.m_min, c5 );
	aabbOut.m_min.setMin4( aabbOut.m_min, c6 );
	aabbOut.m_min.setMin4( aabbOut.m_min, c7 );
	
	aabbOut.m_max.setMax4( c0, c1 );
	aabbOut.m_max.setMax4( aabbOut.m_max, c2 );
	aabbOut.m_max.setMax4( aabbOut.m_max, c3 );
	aabbOut.m_max.setMax4( aabbOut.m_max, c4 );
	aabbOut.m_max.setMax4( aabbOut.m_max, c5 );
	aabbOut.m_max.setMax4( aabbOut.m_max, c6 );
	aabbOut.m_max.setMax4( aabbOut.m_max, c7 );
}