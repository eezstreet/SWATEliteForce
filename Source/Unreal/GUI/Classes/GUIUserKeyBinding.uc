// ====================================================================
// (C) 2002, Epic Games
//
//
// The GUIUSerKeyBinding is a class tha allows mod authors to add keys
// to the control menu.  It works as follows:
//
// Mod authors subclass this actor in their package.  They then need
// to add the following line to their .INT file
//
// Object=(Class=class;MetaClass=GUI.GUIUserKeyBinding,Name=<classname>)
//
// The controller config menu will preload all of these on startup and
// add them to it's list.
//
// Alias is the actual alias you wish to bind.
// KeyLebel is the text description that will be displayed in the list
// bIzSection if set, will cause the menu to add it as a section label
//
// ====================================================================

class GUIUserKeyBinding extends GUI;

struct KeyInfo
{
	var	string Alias;					// The Alias used for this binding
	var string KeyLabel;				// The text label for this binding
    var bool   bIsSection;				// Is this a section label
};

var array<KeyInfo> KeyData;

defaultproperties
{
}