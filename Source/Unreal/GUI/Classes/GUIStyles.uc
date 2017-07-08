// ====================================================================
//  Class:  GUI.GUIStyles
//
//	The GUIStyle is an object that is used to describe common visible
//  components of the interface.
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

class GUIStyles extends GUI
    PerObjectConfig
    Config(GuiBase)
	Native;

cpptext
{
		void Draw(UCanvas* Canvas, BYTE MenuState, FLOAT Left, FLOAT Top, FLOAT Width, FLOAT Height, FLOAT Transparency);
		void TextSize(UCanvas* Canvas, BYTE MenuState, const TCHAR* Test, INT& XL, INT& YL, BYTE TextStyle = 0);

        void UGUIStyles::DrawText(UCanvas* Canvas, BYTE MenuState, FLOAT Left, FLOAT Top, FLOAT Width, FLOAT Height, FLOAT Transparency, BYTE Just, const TArray<FString> &Lines, UBOOL bParseCodes = false, INT NumOffsetLines = 0, UBOOL bDontCenterVertically = false);
        void UGUIStyles::DrawText(UCanvas* Canvas, BYTE MenuState, FLOAT Left, FLOAT Top, FLOAT Width, FLOAT Height, FLOAT Transparency, BYTE Just, const TCHAR* Text, UBOOL bParseCodes = false, UBOOL bMultiline = false, TCHAR seperator = '\n', INT NumOffsetLines = 0, UBOOL bDontCenterVertically = false);
        void UGUIStyles::WrapTextToArray(UCanvas* Canvas, FLOAT Width, const TCHAR* Text, TArray<FString> *OutArray, UBOOL bParseCodes = false, TCHAR seperator = '\n', BYTE MenuState = 0 );

        virtual void Modify(); //callback from the object browser
}

struct native sBorderOffset
{
    var() config float LeftOffset "The offset from the left of the component";
    var() config float RightOffset "The offset from the right of the component";
    var() config float TopOffset "The offset from the top of the component";
    var() config float BottomOffset "The offset from the bottom of the component";
};

var()	config              string				KeyName     "This is the name of the style used for lookup";
var()   config editinline	array<EMenuRenderStyle>	RStyles  "The render styles for each state";
var()	config editinline   array<Material>			Images   "This array holds 1 material for each state (Blurry, Watched, Focused, Pressed, Disabled)";
var()	config editinline	array<eImgStyle>			ImgStyle "How should each image for each state be drawn";
var()	config editinline	array<Color>				FontColors "This array holds 1 font color for each state";
var()	config editinline	array<Color>				ImgColors "This array holds 1 image color for each state";
var()	config editinline	array<sBorderOffset>		BorderOffsets "How thick is the border (offset in pixels at 1600x1200)";
var()	config editinline	array<string>				FontNames "Holds the names of the 5 fonts to use";
var()	EditConst editinline array<GUIFont>			Fonts "Holds the fonts for each state";
var()	config editinline	array<string>				BoldFontNames "Holds the names of the 5 bold fonts to use";
var()	EditConst editinline array<GUIFont>			BoldFonts "Holds the bold fonts for each state";
var()	config editinline	array<string>				ItalicFontNames "Holds the names of the 5 italic fonts to use";
var()	EditConst editinline array<GUIFont>			ItalicFonts "Holds the italic fonts for each state";
var()	config editinline	array<string>				BoldItalicFontNames "Holds the names of the 5 underline fonts to use";
var()	EditConst editinline array<GUIFont>			BoldItalicFonts "Holds the underline fonts for each state";
var()   config int UnderlineWeight "Number of pixels in height to be used for underlining";

var()   config Name     EffectCategory "The effect category GUIComponents of this style belong to; used for GUI effect events";


// Set by Controller
var bool                    bExternalMultilining;       // when true, will not clear state after doing a draw text
var bool                    bLastBold;
var bool                    bLastItalics;
var bool                    bLastUnderlined;
var Font                    LastFont;
var Color                   LastColor;

// the OnDraw delegate Can be used to draw.  Return true to skip the default draw method

delegate bool OnDraw(Canvas Canvas, eMenuState MenuState, float left, float top, float width, float height, float Transparency);
delegate bool OnDrawText(Canvas Canvas, eMenuState MenuState, float left, float top, float width, float height, float Transparency, eTextAlign Align, string Text, optional bool bParseCodes, optional bool bMultiline);

native function Draw(Canvas Canvas, eMenuState MenuState, float left, float top, float width, float height, float Transparency);
native function DrawText(Canvas Canvas, eMenuState MenuState, float left, float top, float width, float height, float Transparency, eTextAlign Align, string Text, optional bool bParseCodes, optional bool bMultiline);

event Initialize()
{
	local int i;

	// Preset all the data if needed

	for (i=0;i<5;i++)
	{
		Fonts[i] = Controller.GetMenuFont(FontNames[i]);
		AssertWithDescription( Fonts[i] != None, "Invalid GUIFont specified for menu state "$GetEnum(eMenuState,i)$" in GUIStyle "$self.Name$".  Please specify a valid GUIFont key name in the Content\\System\\*GuiBase.ini file for this GUIStyle.");

		BoldFonts[i] = Controller.GetMenuFont(BoldFontNames[i]);
        if( BoldFonts[i] == None )		
        {
            log("Could not load the Bold GUIFont specified for menu state "$GetEnum(eMenuState,i)$" in GUIStyle "$self.Name$".  Reverting to the Normal GUIFont for this GUIStyle & MenuState ("$Fonts[i]$").");
            BoldFonts[i] = Fonts[i];
        }

		ItalicFonts[i] = Controller.GetMenuFont(ItalicFontNames[i]);
        if( ItalicFonts[i] == None )		
        {
            log("Could not load the Italic GUIFont specified for menu state "$GetEnum(eMenuState,i)$" in GUIStyle "$self.Name$".  Reverting to the Normal GUIFont for this GUIStyle & MenuState ("$Fonts[i]$").");
            ItalicFonts[i] = Fonts[i];
        }

		BoldItalicFonts[i] = Controller.GetMenuFont(BoldItalicFontNames[i]);
        if( BoldItalicFonts[i] == None )		
        {
            log("Could not load the BoldItalic GUIFont specified for menu state "$GetEnum(eMenuState,i)$" in GUIStyle "$self.Name$".  Reverting to the Normal GUIFont for this GUIStyle & MenuState ("$Fonts[i]$").");
            BoldItalicFonts[i] = Fonts[i];
        }
	}
}

defaultproperties
{
	RStyles(0)=MSTY_Normal;
	RStyles(1)=MSTY_Normal;
	RStyles(2)=MSTY_Normal;
	RStyles(3)=MSTY_Normal;
	RStyles(4)=MSTY_Normal;

	ImgStyle(0)=ISTY_Scaled
	ImgStyle(1)=ISTY_Scaled
	ImgStyle(2)=ISTY_Scaled
	ImgStyle(3)=ISTY_Scaled
	ImgStyle(4)=ISTY_Scaled

	Images(0)=None
	Images(1)=None
	Images(2)=None
	Images(3)=None
	Images(4)=None

	ImgColors(0)=(R=255,G=255,B=255,A=255)
	ImgColors(1)=(R=255,G=255,B=255,A=255)
	ImgColors(2)=(R=255,G=255,B=255,A=255)
	ImgColors(3)=(R=255,G=255,B=255,A=255)
	ImgColors(4)=(R=128,G=128,B=128,A=255)

	FontColors(0)=(R=255,G=255,B=255,A=255)
	FontColors(1)=(R=255,G=255,B=255,A=255)
	FontColors(2)=(R=255,G=255,B=255,A=255)
	FontColors(3)=(R=255,G=255,B=255,A=255)
	FontColors(4)=(R=128,G=128,B=128,A=255)

	FontNames(0)="SwatOS"
	FontNames(1)="SwatOS"
	FontNames(2)="SwatOS"
	FontNames(3)="SwatOS"
	FontNames(4)="SwatOS"

	BoldFontNames(0)="SwatOS"
	BoldFontNames(1)="SwatOS"
	BoldFontNames(2)="SwatOS"
	BoldFontNames(3)="SwatOS"
	BoldFontNames(4)="SwatOS"

	ItalicFontNames(0)="SwatOS"
	ItalicFontNames(1)="SwatOS"
	ItalicFontNames(2)="SwatOS"
	ItalicFontNames(3)="SwatOS"
	ItalicFontNames(4)="SwatOS"

	BoldItalicFontNames(0)="SwatOS"
	BoldItalicFontNames(1)="SwatOS"
	BoldItalicFontNames(2)="SwatOS"
	BoldItalicFontNames(3)="SwatOS"
	BoldItalicFontNames(4)="SwatOS"

	BorderOffsets(0)=(LeftOffset=0.0,RightOffset=0.0,TopOffset=0.0,BottomOffset=0.0)
	BorderOffsets(1)=(LeftOffset=0.0,RightOffset=0.0,TopOffset=0.0,BottomOffset=0.0)
	BorderOffsets(2)=(LeftOffset=0.0,RightOffset=0.0,TopOffset=0.0,BottomOffset=0.0)
	BorderOffsets(3)=(LeftOffset=0.0,RightOffset=0.0,TopOffset=0.0,BottomOffset=0.0)
	BorderOffsets(4)=(LeftOffset=0.0,RightOffset=0.0,TopOffset=0.0,BottomOffset=0.0)

    UnderlineWeight=2
}