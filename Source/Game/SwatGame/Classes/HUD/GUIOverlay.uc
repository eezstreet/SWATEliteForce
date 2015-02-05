class GUIOverlay extends GUI.GUIImage
    ;

function InitComponent(GUIComponent Owner)
{
    Super.InitComponent(Owner);
    bCanBeShown=true;
}

event Show()
{
    UpdateImage();
    Super.Show();
}

event Hide()
{
    Image = None;
    Super.Hide();
}

event UpdateImage()
{
    local SwatPlayer PlayerPawn;
	local IVisionEnhancement Vision;

    PlayerPawn = SwatPlayer(PlayerOwner().Pawn);
    
    WinLeft=0.0;
    WinTop=0.0;
    WinWidth=1.0;
    WinHeight=1.0;
    Transparency=1.0;

	// dbeswick: apply vision enhancements
	Vision = IVisionEnhancement(PlayerPawn.GetSkeletalRegionProtection( REGION_Head ));
	
	if (Vision != None && Vision.ShowOverlay())
	{
		Vision.ApplyEnhancement();
	}

    Image = None;
    if ( PlayerPawn != None && PlayerPawn.IsA( 'ICanUseProtectiveEquipment' ) )
    {
		// dbeswick:
		if (Vision != None)
		{
			if (Vision.ShowOverlay())
				Image = PlayerPawn.GetSkeletalRegionProtection( REGION_Head ).FirstPersonOverlay; 
		}
		else if ( PlayerPawn.GetSkeletalRegionProtection( REGION_Head ) != None )
        {
            Image = PlayerPawn.GetSkeletalRegionProtection( REGION_Head ).FirstPersonOverlay; 
            //log("GUI OVERLAY IMAGE IS "$Image$" FROM "$PlayerPawn.GetSkeletalRegionProtection( REGION_Head ));
        }
        else if ( PlayerPawn.GetSkeletalRegionProtection( REGION_None ) != None )
        {
            // Some protective equipment, like the gas mask, doesn't actually protect
            // a particular region, so it's REGION_None. In this case, present any overlay
            // specified for that equipment.
            Image = PlayerPawn.GetSkeletalRegionProtection( REGION_None ).FirstPersonOverlay; 
            //log("GUI OVERLAY IMAGE IS "$Image$" FROM "$PlayerPawn.GetSkeletalRegionProtection( REGION_None ));
        }
        else
        {
            //log("GUI OVERLAY IMAGE IS None because no protective equip with image found");
        }
    }
    else
    {
        //log("GUI OVERLAY IMAGE IS None");
        //log("pawn is "$PlayerPawn);
    }
}

defaultproperties
{   
    RenderWeight=0.0001

    WinLeft=0.0
    WinTop=0.0
    WinWidth=1.0
    WinHeight=1.0
    bPersistent=True
}

