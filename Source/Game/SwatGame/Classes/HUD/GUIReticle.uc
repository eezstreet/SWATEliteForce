class GUIReticle extends GUI.GUIImage
    ;

//tick marks
var(GUIReticle) config Material UpImage;
var(GUIReticle) config Material DownImage;
var(GUIReticle) config Material LeftImage;
var(GUIReticle) config Material RightImage;
var(GUIReticle) config Material CenterDotImage;
var(GUIReticle) config int      TickSize;
var(GUIReticle) config int      CenterDotSize;
var(GUIReticle) config Color    TickColor;

//image to display at the center of the reticle...
var(GUIReticle) config Material CenterNonFiredImage;    //...when holding a non-FiredWeapon piece of HandheldEquipment
var(GUIReticle) config Material CenterFiredImage;       //...when holding a FiredWeapon
var(GUIReticle) Material CenterPreviewImage;            //...when previewing a piece of equipment
var(GUIReticle) config Material CenterNonlethaledImage; //...when affected by a nonlethal weapon
var(GUIReticle) config Material CenterArrestedImage;    //...when arrested

var byte CenterPreviewAlpha;

function InitComponent(GUIComponent Owner)
{
    Super.InitComponent(Owner);
}

private function bool RenderReticle(canvas Canvas)
{
    local HandheldEquipment ActiveItem;
    local vector Center;
    local float AimError;
    local float ReticleRadius;
	local FiredWeapon ActiveFiredWeapon; // ActiveItem cast to FiredWeapon
	local PlayerController Player; 
	
    Image = None;

	Player = PlayerOwner();
    if ( Player.Pawn == None )
        return false;

    ActiveItem = SwatPlayer(Player.Pawn).GetActiveItem();
    if (ActiveItem == None)
        return false;

    ActiveFiredWeapon = FiredWeapon(ActiveItem);
    if (None==ActiveFiredWeapon && !ActiveItem.IsIdle())
        return false;

    if (Player.ActiveViewport != None)   //controlling a viewport
        return false;

    Canvas.bNoSmooth = False;
    Canvas.Style = ImageRenderStyle;
    Canvas.DrawColor = TickColor;

    GetTickMarkCenter( Center, Canvas );

	if ( Player.Level.NetMode != NM_Standalone &&     // in standalone you're allowed to fire while nonlethaled
        SwatPlayer(Player.Pawn).IsArrested() ) // is arrested
	{
        Image = CenterArrestedImage;
        ImageColor.A = 255;
	}
	else if ( Player.Level.NetMode != NM_Standalone && // in standalone you're allowed to fire while nonlethaled
              SwatPlayer(Player.Pawn).CanBeArrestedNow() ) // is affected by non-lethal
	{
        Image = CenterNonlethaledImage;
        ImageColor.A = 255;
	}
    else if (CenterPreviewImage != None) // is pointing at a 'hotspot' on a door
    {
		// render the 'quick equip' preview icon
        Image = CenterPreviewImage;
        ImageColor.A = CenterPreviewAlpha;
    }
    else if (ActiveFiredWeapon != None) // has a weapon in hand
    {
        Image = CenterFiredImage;
        ImageColor.A = 255;

        //draw ticks too

        AimError = ActiveFiredWeapon.GetAimError();

        ReticleRadius = Canvas.ClipX * Tan(DEGREES_TO_RADIANS * AimError/2.0) / Tan(DEGREES_TO_RADIANS * Player.FovAngle/2.0);

        //up
        Canvas.SetPos(Center.X - TickSize / 2, Center.Y - ReticleRadius - TickSize);
        Canvas.DrawTile(UpImage, TickSize, TickSize, 0, 0, TickSize, TickSize);
        //down
        Canvas.SetPos(Center.X - TickSize / 2, Center.Y + ReticleRadius - 1);
        Canvas.DrawTile(DownImage, TickSize, TickSize, 0, 0, TickSize, TickSize);
        //left
        Canvas.SetPos(Center.X - ReticleRadius - TickSize + 1, Center.Y - TickSize / 2);
        Canvas.DrawTile(LeftImage, TickSize, TickSize, 0, 0, TickSize, TickSize);
        //right
        Canvas.SetPos(Center.X + ReticleRadius, Center.Y - TickSize / 2);
        Canvas.DrawTile(RightImage, TickSize, TickSize, 0, 0, TickSize, TickSize);
        //center
        Canvas.SetPos(Center.X, Center.Y - 1);
        Canvas.DrawTile(CenterDotImage, CenterDotSize, CenterDotSize, 0, 0, CenterDotSize, CenterDotSize);
    }
    else if (ActiveItem.ShouldDisplayReticle())   // ActiveFiredWeapon == None, use default reticle
    {
        Image = CenterNonFiredImage;
        ImageColor.A = 255;
    }
    
    return false;
}

private function GetTickMarkCenter( out vector Center, canvas Canvas )
{
    if( GUIPage(MenuOwner) != None && GUIPage(MenuOwner).bIsHUD )
    {
        Center.X = (0.5 * Canvas.ClipX);
        Center.Y = (0.5 * Canvas.ClipY);
    }
    else
    {
        Center.X = ClientBounds[0] + (0.5 * (ClientBounds[2] - ClientBounds[0]));
        Center.Y = ClientBounds[1] + (0.5 * (ClientBounds[3] - ClientBounds[1]));
    }
}

defaultproperties
{
    OnDraw=RenderReticle

    UpImage=Texture'HUD.TopReticle'
    DownImage=Texture'HUD.BottomReticle'
    LeftImage=Texture'HUD.LeftReticle'
    RightImage=Texture'HUD.RightReticle'
    CenterDotImage=Texture'HUD.CenterReticle'
    TickSize=16
    CenterDotSize=4
    CenterNonFiredImage=Material'HUD.ToolReticle'
    CenterNonlethaledImage=Material'HUD.NonLethaledReticle'
    CenterArrestedImage=Material'HUD.ArrestedReticle'
	TickColor=(R=255,G=255,B=255,A=255)
    bPersistent=True
}

