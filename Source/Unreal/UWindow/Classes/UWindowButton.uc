//=============================================================================
// UWindowButton - A button
//=============================================================================
class UWindowButton extends UWindowDialogControl;

var bool		bDisabled;
var bool		bStretched;
var texture		UpTexture, DownTexture, DisabledTexture, OverTexture;
var Region		UpRegion,  DownRegion,  DisabledRegion,  OverRegion;
var bool		bUseRegion;
var float		RegionScale;
var string		ToolTipString;
var float		ImageX, ImageY;
var Engine.sound		OverSound, DownSound;

function Created()
{
	Super.Created();

	ImageX = 0;
	ImageY = 0;
	TextX = 0;
	TextY = 0;
	RegionScale = 1;
}

function BeforePaint(Canvas C, float X, float Y)
{
	C.Font = Root.Fonts[Font];
}

function Paint(Canvas C, float X, float Y)
{
	C.Font = Root.Fonts[Font];

	if(bDisabled) {
		if(DisabledTexture != None)
		{
			if(bUseRegion)
				DrawStretchedTextureSegment( C, ImageX, ImageY, DisabledRegion.W*RegionScale, DisabledRegion.H*RegionScale, 
											DisabledRegion.X, DisabledRegion.Y, 
											DisabledRegion.W, DisabledRegion.H, DisabledTexture );
			else if(bStretched)
				DrawStretchedTexture( C, ImageX, ImageY, WinWidth, WinHeight, DisabledTexture );
			else
				DrawClippedTexture( C, ImageX, ImageY, DisabledTexture);
		}
	} else {
		if(bMouseDown)
		{
			if(DownTexture != None)
			{
				if(bUseRegion)
					DrawStretchedTextureSegment( C, ImageX, ImageY, DownRegion.W*RegionScale, DownRegion.H*RegionScale, 
												DownRegion.X, DownRegion.Y, 
												DownRegion.W, DownRegion.H, DownTexture );
				else if(bStretched)
					DrawStretchedTexture( C, ImageX, ImageY, WinWidth, WinHeight, DownTexture );
				else
					DrawClippedTexture( C, ImageX, ImageY, DownTexture);
			}
		} else {
			if(MouseIsOver()) {
				if(OverTexture != None)
				{
					if(bUseRegion)
						DrawStretchedTextureSegment( C, ImageX, ImageY, OverRegion.W*RegionScale, OverRegion.H*RegionScale, 
													OverRegion.X, OverRegion.Y, 
													OverRegion.W, OverRegion.H, OverTexture );
					else if(bStretched)
						DrawStretchedTexture( C, ImageX, ImageY, WinWidth, WinHeight, OverTexture );
					else
						DrawClippedTexture( C, ImageX, ImageY, OverTexture);
				}
			} else {
				if(UpTexture != None)
				{
					if(bUseRegion)
						DrawStretchedTextureSegment( C, ImageX, ImageY, UpRegion.W*RegionScale, UpRegion.H*RegionScale, 
													UpRegion.X, UpRegion.Y, 
													UpRegion.W, UpRegion.H, UpTexture );
					else if(bStretched)
						DrawStretchedTexture( C, ImageX, ImageY, WinWidth, WinHeight, UpTexture );
					else
						DrawClippedTexture( C, ImageX, ImageY, UpTexture);
				}
			}
		}
	}

	if(Text != "")
	{
		C.DrawColor=TextColor;
		ClipText(C, TextX, TextY, Text, True);
		C.SetDrawColor(255,255,255);
	}
}

function MouseLeave()
{
	Super.MouseLeave();
	if(ToolTipString != "") ToolTip("");
}

simulated function MouseEnter()
{
	Super.MouseEnter();
	if(ToolTipString != "") ToolTip(ToolTipString);
	if (!bDisabled && (OverSound != None))
#if IG_EFFECTS
		GetPlayerOwner().PlaySound(OverSound);
#else
		GetPlayerOwner().PlaySound(OverSound, SLOT_Interface);
#endif
}

simulated function Click(float X, float Y) 
{
	Notify(DE_Click);
	if (!bDisabled && (DownSound != None))
#if IG_EFFECTS
        GetPlayerOwner().PlaySound(DownSound);
#else
		GetPlayerOwner().PlaySound(DownSound, SLOT_Interact);
#endif
}

function DoubleClick(float X, float Y) 
{
	Notify(DE_DoubleClick);
}

function RClick(float X, float Y) 
{
	Notify(DE_RClick);
}

function MClick(float X, float Y) 
{
	Notify(DE_MClick);
}

function KeyDown(int Key, float X, float Y)
{
	local Engine.PlayerController P;

	P = Root.GetPlayerOwner();

	switch (Key)
	{
	case P.Player.Console.EInputKey.IK_Space:
		LMouseDown(X, Y);
		LMouseUp(X, Y);
		break;
	default:
		Super.KeyDown(Key, X, Y);
		break;
	}
}

defaultproperties
{
	bIgnoreLDoubleClick=True
	bIgnoreMDoubleClick=True
	bIgnoreRDoubleClick=True
}