///////////////////////////////////////////////////////////////////////////////
class CharacterTypesList extends Engine.Actor
    config(CharacterTypes);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var config array<Name>				CharacterTypes;
var array<CharacterVoiceTypes> 		CharacterVoiceTypes;

var config array<Name>				FemaleCharacterTypes;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

event PreBeginPlay()
{
    Super.PreBeginPlay();

	VerifyFemaleCharacterTypes();

    CreateVoiceTypes();
}

private function VerifyFemaleCharacterTypes()
{
	local int i;
	local array<string> Problems;

	// make sure all the female character types entered are valid
	for(i=0; i<FemaleCharacterTypes.Length; ++i)
	{
		if (! VerifyCharacterTypeExists(FemaleCharacterTypes[i]))
		{
			Problems[Problems.Length] = "Could not find CharacterType that was found in FemaleCharacterTypes: " $ string(FemaleCharacterTypes[i]);
		}
	}

	if (Problems.Length > 0)
	{
		for(i=0; i<Problems.Length; ++i)
		{
			log(Problems[i]);
		}

		assertWithDescription(false, "Problems were found with character types.  Check the Swat4.log for details!");
	}
}

function bool IsAFemaleCharacterType(name CharacterType)
{
	local int i;

	for(i=0; i<FemaleCharacterTypes.Length; ++i)
	{
		if (FemaleCharacterTypes[i] == CharacterType)
			return true;
	}

	// nope, didn't find it
	return false;
}

private function CreateVoiceTypes()
{
    local int i;
    local CharacterVoiceTypes NewCharacterVoiceTypes;

    for (i=0; i<CharacterTypes.length; ++i)
    {
        // Create the Animator Idle Definition
        NewCharacterVoiceTypes = new(self, string(CharacterTypes[i]), 0) class'CharacterVoiceTypes';
        assert(NewCharacterVoiceTypes != None);

        CharacterVoiceTypes[i] = NewCharacterVoiceTypes;
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function name GetVoiceTypeForCharacterType(name inCharacterType)
{
	local int i;

	assert(CharacterTypes.Length == CharacterVoiceTypes.Length);

	for(i=0; i<CharacterTypes.Length; ++i)
	{
		if (CharacterTypes[i] == inCharacterType)
		{
			return CharacterVoiceTypes[i].GetUniqueVoiceType();
		}
	}

	assert(false);
	return '';
}

///////////////////////////////////////////////////////////////////////////////
//
// Debug

// debug function to verify a voice type override exists
function bool VerifyVoiceTypeExists(name inVoiceType)
{
	local int i;

	for(i=0; i<CharacterVoiceTypes.Length; ++i)
	{
		if (CharacterVoiceTypes[i].HasVoiceType(inVoiceType))
		{
			return true;
		}
	}

	return false;
}

// debug function to verify a character type override exists
function bool VerifyCharacterTypeExists(name inCharacterType)
{
	local int i;

	for(i=0; i<CharacterTypes.Length; ++i)
	{
		if (CharacterTypes[i] == inCharacterType)
		{
			return true;
		}
	}

	return false;
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	bHidden=true
}