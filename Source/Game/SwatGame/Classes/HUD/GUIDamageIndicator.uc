class GUIDamageIndicator extends GUI.GUIMultiComponent;

import enum ESkeletalRegion from Engine.Actor;

struct HitRegion
{
    var() float     FlashTime;      //how long this region has left to flash
    var() int       NumFlashed;     //number of times flashed so far: even == colored
    var() bool      bDamaged;       //Whether or not this region is damaged
    var() config GUIImage  RegionImage;    //The image to display for this region
};

var(GUIDamageIndicator) config int      NumFlashes; //how many times to switch flashing color
var(GUIDamageIndicator) config float    FlashLength;  //how long to flash after taking damage
var(GUIDamageIndicator) config Color    FlashColor;
var(GUIDamageIndicator) config Color    NonFlashColor;

var(GUIDamageIndicator) config Material HeadStandingImage;
var(GUIDamageIndicator) config Material TorsoStandingImage;
var(GUIDamageIndicator) config Material LeftArmStandingImage;
var(GUIDamageIndicator) config Material RightArmStandingImage;
var(GUIDamageIndicator) config Material LeftLegStandingImage;
var(GUIDamageIndicator) config Material RightLegStandingImage;

var(GUIDamageIndicator) config Material HeadCrouchingImage;
var(GUIDamageIndicator) config Material TorsoCrouchingImage;
var(GUIDamageIndicator) config Material LeftArmCrouchingImage;
var(GUIDamageIndicator) config Material RightArmCrouchingImage;
var(GUIDamageIndicator) config Material LeftLegCrouchingImage;
var(GUIDamageIndicator) config Material RightLegCrouchingImage;

var(GUIDamageIndicator) private array<HitRegion> HitRegions;

function InitComponent(GUIComponent Owner)
{
    local int i;
    local HitRegion newRegion;

    Super.InitComponent(Owner);
    
    for( i = 0; i < ESkeletalRegion.REGION_Body_Max; i++ )
    {
        newRegion.RegionImage = GUIImage(AddComponent("GUI.GUIImage", self.Name$"_"$GetEnum(ESkeletalRegion,i), true));
        newRegion.RegionImage.ImageStyle = ISTY_Scaled;
        newRegion.RegionImage.ImageRenderStyle = MSTY_Normal;
        newRegion.RegionImage.WinWidth = 1.0;
        newRegion.RegionImage.WinHeight = 1.0;
        newRegion.RegionImage.WinLeft = 0.0;
        newRegion.RegionImage.WinTop = 0.0;
        HitRegions[i] = newRegion;
    }
    
    Reset();
}


function Reset()
{
    Stand();
    ClearDamage();
}

function Stand()
{
    HitRegions[ESkeletalRegion.REGION_Head].RegionImage.Image = HeadStandingImage;
    HitRegions[ESkeletalRegion.REGION_Torso].RegionImage.Image = TorsoStandingImage;
    HitRegions[ESkeletalRegion.REGION_LeftArm].RegionImage.Image = LeftArmStandingImage;
    HitRegions[ESkeletalRegion.REGION_RightArm].RegionImage.Image = RightArmStandingImage;
    HitRegions[ESkeletalRegion.REGION_LeftLeg].RegionImage.Image = LeftLegStandingImage;
    HitRegions[ESkeletalRegion.REGION_RightLeg].RegionImage.Image = RightLegStandingImage;
}

function Crouch()
{
    HitRegions[ESkeletalRegion.REGION_Head].RegionImage.Image = HeadCrouchingImage;
    HitRegions[ESkeletalRegion.REGION_Torso].RegionImage.Image = TorsoCrouchingImage;
    HitRegions[ESkeletalRegion.REGION_LeftArm].RegionImage.Image = LeftArmCrouchingImage;
    HitRegions[ESkeletalRegion.REGION_RightArm].RegionImage.Image = RightArmCrouchingImage;
    HitRegions[ESkeletalRegion.REGION_LeftLeg].RegionImage.Image = LeftLegCrouchingImage;
    HitRegions[ESkeletalRegion.REGION_RightLeg].RegionImage.Image = RightLegCrouchingImage;
}

function ClearDamage()
{
    local int i;
    
    for( i = 0; i < ESkeletalRegion.REGION_Body_Max; i++ )
    {
        HitRegions[i].bDamaged = false;
        HitRegions[i].RegionImage.ImageColor = NonFlashColor;
        HitRegions[i].FlashTime = 0;
    }
    
    KillTimer();
}

//handle hits (TakeDamage)
function SkeletalRegionHit(ESkeletalRegion RegionHit, int damage)
{
    AssertWithDescription( RegionHit < ESkeletalRegion.REGION_Body_Max, self.Name$" recieved an Invalid hit region, "$GetEnum(ESkeletalRegion,RegionHit) );

    if (damage == 0)
        return;

    HitRegions[RegionHit].FlashTime = FlashLength;
    HitRegions[RegionHit].NumFlashed = 0;
    HitRegions[RegionHit].bDamaged = HitRegions[RegionHit].bDamaged || ( damage > 0 );
    HitRegions[RegionHit].RegionImage.ImageColor = FlashColor;
    SetTimer( FlashLength / float(NumFlashes*2), true );
}

//used for damage flashes
event Timer()
{
    local int i;
    local bool bComplete;
    local bool bShowFlash;
    
    bComplete = true;
    for( i = 0; i < ESkeletalRegion.REGION_Body_Max; i++ )
    {
        if( HitRegions[i].FlashTime > 0 )
        {
            HitRegions[i].FlashTime -= FlashLength / float(NumFlashes*2);

            HitRegions[i].NumFlashed++;
            if( HitRegions[i].NumFlashed < NumFlashes*2 )
            {
                bComplete = false;
                bShowFlash = ( HitRegions[i].NumFlashed % 2 == 0 );
            }
            else
            {
                bShowFlash = HitRegions[i].bDamaged;
            }

            if( bShowFlash )
                HitRegions[i].RegionImage.ImageColor = FlashColor;
            else
                HitRegions[i].RegionImage.ImageColor = NonFlashColor;
        }
    }
    if( bComplete )
        KillTimer();
}

defaultproperties
{
    bPersistent=True
}
