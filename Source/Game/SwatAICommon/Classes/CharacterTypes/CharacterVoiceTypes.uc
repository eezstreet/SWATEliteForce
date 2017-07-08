///////////////////////////////////////////////////////////////////////////////
class CharacterVoiceTypes extends Core.Object
	within CharacterTypesList
    perobjectconfig;
///////////////////////////////////////////////////////////////////////////////

var config array<name>	VoiceTypes;
var array<int>			VoiceTypesUsed;

///////////////////////////////////////////////////////////////////////////////

overloaded function Construct()
{
	Super.Construct();

	assert(VoiceTypes.Length > 0);
	VoiceTypesUsed.Length = VoiceTypes.Length;
}

///////////////////////////////////////////////////////////////////////////////

function name GetUniqueVoiceType()
{
	local int i, HighestCount, VoiceTypeIndex;
	local array<name> UsableVoiceTypes;
	local name UniqueVoiceType;

	assert(VoiceTypes.Length == VoiceTypesUsed.Length);
	assert(VoiceTypes.Length > 0);

	for(i=0; i<VoiceTypesUsed.Length; ++i)
	{
		if (VoiceTypesUsed[i] > HighestCount)
		{
			HighestCount = VoiceTypesUsed[i];
		}
	}

	for(i=0; i<VoiceTypesUsed.Length; ++i)
	{
		if (VoiceTypesUsed[i] < HighestCount)
		{
			UsableVoiceTypes[UsableVoiceTypes.Length] = VoiceTypes[i];
		}
	}

	if (UsableVoiceTypes.Length == 0)
	{
		UsableVoiceTypes = VoiceTypes;
	}

	VoiceTypeIndex                  = Rand(UsableVoiceTypes.Length);
	UniqueVoiceType                 = UsableVoiceTypes[VoiceTypeIndex];

	for(i=0; i<VoiceTypes.Length; ++i)
	{
		if (VoiceTypes[i] == UniqueVoiceType)
		{
			VoiceTypesUsed[i] += 1;
			break;
		}
	}

	return UniqueVoiceType;
}

function bool HasVoiceType(name inVoiceType)
{
	local int i;

	for(i=0; i<VoiceTypes.Length; ++i)
	{
		if (VoiceTypes[i] == inVoiceType)
		{
			return true;
		}
	}

	return false;
}
