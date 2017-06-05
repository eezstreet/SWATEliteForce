class GUIAmmoStatus extends SwatGame.GUIAmmoStatusBase;

//NOTE: Should match the corresponding const in ClipBasedAmmo, may be optimized to min number displayed in gui
const MAX_CLIP_ROUNDS_REMAINING = 10;   // 30 should be greater than the number of
                                        // clips we would need.

var(GUIAmmoStatus) EditInline Config GUILabel         LoadedAmmoLabel               "Text that displays the current rounds remaining in the magazine/clip.";
var(GUIAmmoStatus) EditInline Config GUILabel         MagazineSizeLabel             "Text that displays how many rounds fit in the magazine/clip.";
var(GUIAmmoStatus) EditInline Config GUILabel         ExtraAmmoLabel                "Text that displays the current (unloaded) rounds remaining.";
var(GUIAmmoStatus) EditInline Config GUIProgressBar   RoundsRemainingBar            "Progress bar that displays the current (unloaded) rounds remaining.";
var(GUIAmmoStatus) EditInline Config GUIProgressBar   ClipRoundsRemainingBar[MAX_CLIP_ROUNDS_REMAINING]        "Progress bars that displays the current (unloaded) rounds remaining in the other clips.";

var(GUIAmmoStatus) Config Color   ActiveClipColor        "Progress bar that displays the current (loaded) rounds remainings color.";
var(GUIAmmoStatus) Config Color   InActiveClipColor      "Progress bar that displays the current (unloaded) rounds remainings color.";

var localized config string PepperSprayCansStr;


function OnConstruct(GUIController MyController)
{
    local int i;

    Super.OnConstruct(MyController);

    LoadedAmmoLabel=GUILabel(AddComponent( "GUI.GUILabel", self.Name$"_LoadedAmmoLabel" ));
    MagazineSizeLabel=GUILabel(AddComponent( "GUI.GUILabel", self.Name$"_MagazineSizeLabel" ));
    ExtraAmmoLabel=GUILabel(AddComponent( "GUI.GUILabel", self.Name$"_ExtraAmmoLabel" ));
    RoundsRemainingBar=GUIProgressBar(AddComponent( "GUI.GUIProgressBar" , self.Name$"_RoundsRemainingBar"));

    for( i = 0; i < MAX_CLIP_ROUNDS_REMAINING; i++ )
    {
        ClipRoundsRemainingBar[i]=GUIProgressBar(AddComponent( "GUI.GUIProgressBar" , self.Name$"_"$i$"_ClipRoundsRemainingBar"));
    }
}

function InitComponent(GUIComponent Owner)
{
    Super.InitComponent(Owner);
}

function SetWeaponStatus( Ammunition Ammo )
{
    local ClipBasedAmmo ClipAmmo;
    local RoundBasedAmmo RoundAmmo;
//log("[dkaplan] In SetWeaponStatus, Ammo = "$Ammo);
    ClipAmmo = ClipBasedAmmo( Ammo );
    RoundAmmo = RoundBasedAmmo( Ammo );

    if( ClipAmmo != None )
        SetClipBasedWeaponStatus( ClipAmmo );
    else if( RoundAmmo != None )
        SetRoundBasedWeaponStatus( RoundAmmo );
    else
        AssertWithDescription( false, "[dkaplan] Could not Set the Weapon Status hud display for Ammunition "$Ammo$" as it was neither ClipBased nor RoundBased.");
}

function SetTacticalAidStatus(int Count, optional Ammunition Ammo)
{
  if(Ammo != None)
  {
    SetPepperSprayStatus(count, Ammo);
  }
  else
  {
    // Other stuff, for other tac-aids (lightstick, grenades, wedges, etc)
  }
}

private function SetPepperSprayStatus(int Count, optional Ammunition Ammo)
{
  local RoundBasedAmmo RBAmmo;

  RBAmmo = RoundBasedAmmo(Ammo);
  assert(RBAmmo != None);

  SetRoundBasedWeaponStatus(RBAmmo);

  ExtraAmmoLabel.SetCaption("+" $ string(Count) $ " " $ PepperSprayCansStr);
}

private function SetRoundBasedWeaponStatus( RoundBasedAmmo Ammo )
{
    local int i, loadedAmmo, magazineSize, extraRounds, initialExtraRounds;

    loadedAmmo = Ammo.GetCurrentRounds();
    magazineSize = Ammo.GetMagazineSize();
    extraRounds = Ammo.GetReserveRounds();
    initialExtraRounds = Ammo.GetInitialReserveRounds();

    LoadedAmmoLabel.SetCaption( string(loadedAmmo) );
    LoadedAmmoLabel.Show();

    MagazineSizeLabel.SetCaption( "/" $ string(magazineSize) );
    MagazineSizeLabel.Show();

    ExtraAmmoLabel.SetCaption( "+" $ string(extraRounds) );
    ExtraAmmoLabel.Show();

//    if( initialExtraRounds > 0 )
//    {
//        RoundsRemainingBar.Value = float(extraRounds)/float(initialExtraRounds);
        RoundsRemainingBar.Value = float(loadedAmmo)/float(magazineSize);
        RoundsRemainingBar.Show();
//    }
//    else
//        RoundsRemainingBar.Hide();

    for( i = 0; i < MAX_CLIP_ROUNDS_REMAINING; i++ )
    {
        ClipRoundsRemainingBar[i].Hide();
    }
}

private function SetClipBasedWeaponStatus( ClipBasedAmmo Ammo )
{
    local int i, clipCount, currentClip, magazineSize;

    clipCount = Ammo.GetClipCount();
    magazineSize = Ammo.GetMagazineSize();
    currentClip = Ammo.GetCurrentClip();

    LoadedAmmoLabel.SetCaption( string(Ammo.GetClip(currentClip)) );
    LoadedAmmoLabel.Show();

    MagazineSizeLabel.SetCaption( "/" $ string(magazineSize) );
    MagazineSizeLabel.Show();

    ExtraAmmoLabel.Hide();

    RoundsRemainingBar.Hide();

    for( i = 0; i < MAX_CLIP_ROUNDS_REMAINING; i++ )
    {
        if( i < clipCount )
        {
            ClipRoundsRemainingBar[i].Value = float(Ammo.GetClip(i))/float(magazineSize);
            if( i == currentClip )
            {
                ClipRoundsRemainingBar[i].BarColor = ActiveClipColor;
            }
            else
            {
                ClipRoundsRemainingBar[i].BarColor = InActiveClipColor;
            }
            ClipRoundsRemainingBar[i].SetEnabled( i == currentClip );
            ClipRoundsRemainingBar[i].Show();
        }
        else
            ClipRoundsRemainingBar[i].Hide();
    }
}

defaultproperties
{
    PepperSprayCansStr="cans"

    PropagateState=false
    PropagateActivity=false
    PropagateVisibility=false

    ActiveClipColor=(R=255,G=255,B=255,A=255)
    InActiveClipColor=(R=155,G=155,B=155,A=255)
}
