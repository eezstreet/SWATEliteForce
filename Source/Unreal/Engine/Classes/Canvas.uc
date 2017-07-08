//=============================================================================
// Canvas: A drawing canvas.
// This is a built-in Unreal class and it shouldn't be modified.
//
// Notes.
//   To determine size of a drawable object, set Style to STY_None,
//   remember CurX, draw the thing, then inspect CurX and CurYL.
//=============================================================================
class Canvas extends Core.Object
	native
	noexport;

// Modifiable properties.
var const font    DefaultFont;     // Font for DrawText.
var font	Font;
var float   SpaceX, SpaceY;  // Spacing for after Draw*.
var float   OrgX, OrgY;      // Origin for drawing.
var float   ClipX, ClipY;    // Bottom right clipping region.
var float   CurX, CurY;      // Current position for drawing.
var float   Z;               // Z location. 1=no screenflash, 2=yes screenflash.
var byte    Style;           // Drawing style STY_None means don't draw.
var float   CurYL;           // Largest Y size since DrawText.
var color   DrawColor;       // Color for drawing.
var bool    bCenter;         // Whether to center the text.
var bool    bNoSmooth;       // Don't bilinear filter.
var const int SizeX, SizeY;  // Zero-based actual dimensions.

// Stock fonts.
var const font TinyFont, SmallFont, MedFont;
var string DefaultFontName, TinyFontName, SmallFontName, MedFontName;
var Texture WhiteTex;

// Internal.
var const viewport Viewport; // Viewport that owns the canvas.
var const int      pCanvasUtil; 

// native functions.
native(464) final function StrLen( coerce string String, out float XL, out float YL ); // Wrapped!
native(465) final function DrawText( coerce string Text, optional bool CR );
native(466) final function DrawTile( material Mat, float XL, float YL, float U, float V, float UL, float VL );
native(467) final function DrawActor( Actor A, bool Wireframe, optional bool ClearZ, optional float DisplayFOV );
native(468) final function DrawTileClipped( Material Mat, float XL, float YL, float U, float V, float UL, float VL );
native(469) final function DrawTextClipped( coerce string Text, optional bool bCheckHotKey );
native(470) final function TextSize( coerce string String, out float XL, out float YL ); // Clipped!
native(480) final function DrawPortal( int X, int Y, int Width, int Height, actor CamActor, vector CamLocation, rotator CamRotation, optional int FOV, optional bool ClearZ );

native final function WrapStringToArray(string Text, out array<string> OutArray, float dx, string EOL
#if IG_GUI_LAYOUT //dkaplan - allow checking of html style codes
    , optional bool bIsCodedString
#endif
    );

// jmw - These are two helper functions.  The use the whole texture only.  If you need better support, use DrawTile
native final function DrawTileStretched(material Mat, float XL, float YL);
native final function DrawTileJustified(material Mat, byte Justification, float XL, float YL);
native final function DrawTileScaled(material Mat, float XScale, float YScale);
native final function DrawTextJustified(coerce string String, byte Justification, float x1, float y1, float x2, float y2);

#if IG_SHARED // ckline: more convenient text drawing utils
// Draws a multiline text string with the top-left character of the first line at the specified Origin2D in screen space.
// Newline characters inside the Text string will delineate lines in the rendered output. 
// If BackgroundColor.A != 0, then the area under the text will be filled with that color (but the background will be opaque, ignoring the alpha component).
// Default value of BackgroundColor is (0,0,0,A=0)
// If Wrapped is false (the default), then the text will be clipped to the edges of the viewport rather than wrapped around the side.
// If Centered is false (the default), then the text will be left-justified.
native final function DrawTextMultiline(coerce string Text, vector Origin2D, Color ForegroundColor, optional Color BackgroundColor, optional bool Wrapped, optional bool Centered);
#endif

// UnrealScript functions.
event Reset()
{
	Font		= DefaultFont;
	SpaceX      = Default.SpaceX;
	SpaceY      = Default.SpaceY;
	OrgX        = Default.OrgX;
	OrgY        = Default.OrgY;
	CurX        = Default.CurX;
	CurY        = Default.CurY;
	Style       = Default.Style;
	DrawColor   = Default.DrawColor;
	CurYL       = Default.CurYL;
	bCenter     = false;
	bNoSmooth   = false;
	Z           = 1.0;
}
final function SetPos( float X, float Y )
{
	CurX = X;
	CurY = Y;
}
final function SetOrigin( float X, float Y )
{
	OrgX = X;
	OrgY = Y;
}
final function SetClip( float X, float Y )
{
	ClipX = X;
	ClipY = Y;
}
final function DrawPattern( material Tex, float XL, float YL, float Scale )
{
	DrawTile( Tex, XL, YL, (CurX-OrgX)*Scale, (CurY-OrgY)*Scale, XL*Scale, YL*Scale );
}
final function DrawIcon( texture Tex, float Scale )
{
	if ( Tex != None )
		DrawTile( Tex, Tex.USize*Scale, Tex.VSize*Scale, 0, 0, Tex.USize, Tex.VSize );
}
final function DrawRect( texture Tex, float RectX, float RectY )
{
	DrawTile( Tex, RectX, RectY, 0, 0, Tex.USize, Tex.VSize );
}

final function SetDrawColor(byte R, byte G, byte B, optional byte A)
{
	local Color C;
	
	C.R = R;
	C.G = G;
	C.B = B;
	if ( A == 0 )
		A = 255;
	C.A = A;
	DrawColor = C;
}

static final function Color MakeColor(byte R, byte G, byte B, optional byte A)
{
	local Color C;
	
	C.R = R;
	C.G = G;
	C.B = B;
	if ( A == 0 )
		A = 255;
	C.A = A;
	return C;
}

// Draw a vertical line
final function DrawVertical(float X, float height)
{
    SetPos( X, CurY);
    DrawRect(WhiteTex, 2, height);
}

// Draw a horizontal line
final function DrawHorizontal(float Y, float width)
{
    SetPos(CurX, Y);
    DrawRect(WhiteTex, width, 2);
}

// Draw Line is special as it saves it's original position

final function DrawLine(int direction, float size)
{
    local float X, Y;

    // Save current position
    X = CurX;
    Y = CurY;

    switch (direction) 
    {
      case 0:
		  SetPos(X, Y - size);
		  DrawRect(WhiteTex, 2, size);
		  break;
    
      case 1:
		  DrawRect(WhiteTex, 2, size);
		  break;

      case 2:
		  SetPos(X - size, Y);
		  DrawRect(WhiteTex, size, 2);
		  break;
		  
	  case 3:
		  DrawRect(WhiteTex, size, 2);
		  break;
    }
    // Restore position
    SetPos(X, Y);
}

final simulated function DrawBracket(float width, float height, float bracket_size)
{
    local float X, Y;
    X = CurX;
    Y = CurY;

	Width  = max(width,5);
	Height = max(height,5);
	
    DrawLine(3, bracket_size);
    DrawLine(1, bracket_size);
    SetPos(X + width, Y);
    DrawLine(2, bracket_size);
    DrawLine(1, bracket_size);
    SetPos(X + width, Y + height);
    DrawLine(0, bracket_size);
    DrawLine(2, bracket_size);
    SetPos(X, Y + height);
    DrawLine(3, bracket_size);
    DrawLine( 0, bracket_size);

    SetPos(X, Y);
}

final simulated function DrawBox(canvas canvas, float width, float height)
{
	local float X, Y;
	X = canvas.CurX;
	Y = canvas.CurY;
	canvas.DrawRect(WhiteTex, 2, height);
	canvas.DrawRect(WhiteTex, width, 2);
	canvas.SetPos(X + width, Y);
	canvas.DrawRect(WhiteTex, 2, height);
	canvas.SetPos(X, Y + height);
	canvas.DrawRect(WhiteTex, width+1, 2);
	canvas.SetPos(X, Y);
}


defaultproperties
{
     Style=1
	 Z=1
     DrawColor=(R=127,G=127,B=127,A=255)
	 DefaultFontName="Engine_res.Res_DefaultFont"
	 TinyFontName="Engine_res.Res_DefaultFont"
     SmallFontName="Engine_res.Res_DefaultFont"
     MedFontName="Engine_res.Res_DefaultFont"
	 WhiteTex = Texture'engine_res.WhiteSquareTexture'
}
