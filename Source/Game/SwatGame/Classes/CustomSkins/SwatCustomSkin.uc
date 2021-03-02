class SwatCustomSkin extends Engine.Equipment
	implements ICanBeSelectedInTheGUI
	Config(SwatSkins);

import enum eTeamValidity from SwatGUIConfig;

var(CustomSkin) Config localized String SkinFriendlyName;
var(CustomSkin) Config localized String SkinDescription;
var(CustomSkin) Config Material GUISkinImage;
var(CustomSkin) Config Material FaceMaterial;
var(CustomSkin) Config Material PantsMaterial;
var(CustomSkin) Config Material HeavyPantsMaterial;
var(CustomSkin) Config Material VestMaterial;
var(CustomSkin) Config Material HeavyVestMaterial;
var(CustomSkin) Config Material NoArmorVestMaterial;
var(CustomSkin) Config Material FirstPersonHandsMaterial;

static function string GetFriendlyName()
{
	return default.SkinFriendlyName;
}

static function string GetDescription()
{
	return default.SkinDescription;
}

static function Material GetGUIImage()
{
	return default.GUISkinImage;
}

static function class<Actor> GetRenderableActorClass()
{
	return None;
}