///////////////////////////////////////////////////////////////////////////////
//
// SwatOfficerStart.uc - the SwatOfficerStart class
// Placed object that spawns officers when we begin the game

class SwatOfficerStart extends SwatStartPointBase
    placeable
	native;
///////////////////////////////////////////////////////////////////////////////

enum EOfficerStartType
{
	RedOneStart,
	RedTwoStart,
	BlueOneStart,
	BlueTwoStart
};

var() EOfficerStartType OfficerStartType;

var   private Texture	OfficerStartPointIcons[EOfficerStartType.EnumCount];
var   private bool		bOfficerStartCheckedForNumberErrors;

///////////////////////////////////////////////////////////////////////////////

cpptext
{
	virtual void PostEditChange();
	virtual void PostEditLoad();
	void UpdateIcon();
	virtual void CheckForErrors();
	void CheckNumberOfSwatOfficerStarts();
}

///////////////////////////////////////////////////////////////////////////////

private function class<SwatOfficer> GetOfficerClass()
{
	switch (OfficerStartType)
	{
		case RedOneStart:
			return class'OfficerRedOne';
		case RedTwoStart:
			return class'OfficerRedTwo';
		case BlueOneStart:
			return class'OfficerBlueOne';
		case BlueTwoStart:
			return class'OfficerBlueTwo';
	}
}

function SpawnOfficer()
{
	local SwatOfficer SpawnedOfficer;
	SpawnedOfficer = Spawn(GetOfficerClass(),,,Location,Rotation);
	assertWithDescription((SpawnedOfficer != None), "SwatOfficerStart::SpawnOfficer - "@name@" could not spawn an officer at location:"@Location);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	bSinglePlayerStart=false
	Texture=Texture'Swat4EditorTex.R1Start'
	OfficerStartPointIcons(0)=Texture'Swat4EditorTex.R1Start'
	OfficerStartPointIcons(1)=Texture'Swat4EditorTex.R2Start'
	OfficerStartPointIcons(2)=Texture'Swat4EditorTex.B1Start'
	OfficerStartPointIcons(3)=Texture'Swat4EditorTex.B2Start'
}
