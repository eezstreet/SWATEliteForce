class SwatSkinEquipmentSpec extends SwatEquipmentSpec;

simulated function Initialise()
{
	local String SkinPackageFilename;
	local String SkinPackageName;
	local String SkinClassPath;
	local class<SwatCustomSkin> SkinClass;
	local int SkinIndex;

	EquipmentClassName[0] = "SwatGame.DefaultCustomSkin";
	Validity[0] = NETVALID_MPOnly;
	TeamValidity[0] = TEAMVALID_All;
	bSelectable[0] = 1;

	foreach FileMatchingPattern("*.skn", SkinPackageFilename)
	{
		SkinPackageName = RemoveExtension(SkinPackageFilename);

		// A custom skin class must be named '<SkinPackageName>CustomSkin'
		SkinClassPath = SkinPackageName $ "." $ SkinPackageName $ "CustomSkin";

		SkinClass = class<SwatCustomSkin>(DynamicLoadObject(SkinClassPath, class'Class'));

		AssertWithDescription(SkinClass != None, "Unable to load custom skin class " $ EquipmentClassName[SkinIndex]);

		if (SkinClass != None)
		{
			SkinIndex = EquipmentClassName.Length;

			EquipmentClassName[SkinIndex] = SkinClassPath;
			Validity[SkinIndex] = NETVALID_MPOnly;
			TeamValidity[SkinIndex] = TEAMVALID_All;
			bSelectable[SkinIndex] = 1;
		}
	}

	SkinIndex = EquipmentClassName.Length;

	EquipmentClassName[SkinIndex] = "None";
	Validity[SkinIndex] = NETVALID_ALL;
	TeamValidity[SkinIndex] = TEAMVALID_All;
	bSelectable[SkinIndex] = 0;
}

simulated function string RemoveExtension(String SkinPackageFilename)
{
    if (Right(SkinPackageFilename, Len(".skn")) != ".skn")
        return SkinPackageFilename;    // No extension present
    else
        return Left(SkinPackageFilename, Len(SkinPackageFilename) - Len(".skn"));
}
