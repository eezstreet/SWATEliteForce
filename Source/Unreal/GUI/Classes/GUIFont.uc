// ====================================================================
//  Class:  GUI.GUIFont
// 
//  GUIFont is used to give a single pipeline for handling fonts at
//	multiple resolutions while at the same time supporting resolution
//	independant fonts (for browsers, etc). 
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================
/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIFont extends GUI
    PerObjectConfig
    Config(GuiBase)
	Native;

cpptext
{
        virtual void Modify(); //callback from the object browser
}

var() config string		KeyName;
var() config bool		bFixedSize "If true, only FontArray[0] is used";
var() config float      AppliedKerning "Amount of Kerning to apply in the GUI";
var() config float      AppliedLeading "Amount of Leading to apply in the GUI";
var() config editinline    array<String>	FontArrayNames "Holds all of the names of the fonts"; 		
var() EditConst editinline    array<Font>	FontArrayFonts	"Holds all of the fonts";

native event Font GetFont(int XRes);			// Returns the font for the current resolution

// Dynamically load font.
static function Font LoadFontStatic(int i)
{
	if( i>=default.FontArrayFonts.Length || default.FontArrayFonts[i] == None )
	{
		default.FontArrayFonts[i] = Font(DynamicLoadObject(default.FontArrayNames[i], class'Font'));
		if( default.FontArrayFonts[i] == None )
			Log("Warning: "$default.Class$" Couldn't dynamically load font "$default.FontArrayNames[i]);
	}

	return default.FontArrayFonts[i];
}

function Font LoadFont(int i)
{
	if( i>=FontArrayFonts.Length || FontArrayFonts[i] == None )
	{
		FontArrayFonts[i] = Font(DynamicLoadObject(FontArrayNames[i], class'Font'));
		if( FontArrayFonts[i] == None )
			Log("Warning: "$Self$" Couldn't dynamically load font "$FontArrayNames[i]);
	}
	return FontArrayFonts[i];
}

defaultproperties
{
    AppliedKerning=1.0
    AppliedLeading=1.0
}
