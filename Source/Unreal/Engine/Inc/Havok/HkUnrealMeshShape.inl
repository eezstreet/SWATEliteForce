int hkUnrealMeshShape::getNumSubparts() const
{
	return m_subparts.getSize();
}

hkUnrealMeshShape::Subpart& hkUnrealMeshShape::getSubpartAt( int i )
{
	HK_ASSERT2(1028, (i>=0) && (i<m_subparts.getSize()), "You are trying to access a subpart which is not in the subpart array");
	return m_subparts[i];
}

const hkUnrealMeshShape::Subpart& hkUnrealMeshShape::getSubpartAt( int i ) const
{
	HK_ASSERT2(1029, (i>=0) && (i<m_subparts.getSize()), "You are trying to access a subpart which is not in the subpart array");
	return m_subparts[i];
}

	/// get the extra radius for every triangle
hkReal hkUnrealMeshShape::getRadius() const
{
	return m_radius;
}

	/// set the extra radius for every triangle
void hkUnrealMeshShape::setRadius(hkReal r )
{
	m_radius = r;
}

inline hkUnrealMeshShape::Subpart::Subpart()
{
	// 'must set' values, defaults are error flags effectively for HK_ASSERTS in the cpp.
	#ifdef HK_DEBUG
		m_vertexBase = HK_NULL;
		m_vertexStriding = -1;
		m_numVertices = -1;
		m_index32Base = HK_NULL;
		m_stridingType = HK_INVALID_INDICES;
		m_indexStriding = -1;
		m_numTriangles = -1;
		m_type = HK_UNREAL_UNKNOWN; 
//		m_unrealPtr = HK_NULL;
		m_scaling.setAll(1);
	#endif
}
