class Mirror extends Actor
    HideCategories(Advanced, Mirrors, Events, Force, Karma, Havok, LightColor, Lighting, Movement, Object, Sound)
    placeable
    native;

cpptext 
{
	virtual void CheckForErrors();
    virtual void PostEditAdd(GroupFactory& Grouper);
	virtual void PostEditChange();
	virtual void PostEditLoad();
    
    static void SetMirrorsEnabled(UBOOL Enabled); // turn realtime mirrors on/off globally
    static UBOOL GetMirrorsEnabled();
    
  private:
    static UBOOL bMirrorsEnabled;
}

var private nocopy MirrorCamera MyCamera; // The MirrorCamera must be spawned by PostEditAdd() when the Mirror is placed
var() int MirrorSkinIndex "This is the Skin array index that the mirror texture will override.";
var() private string DefaultMirrorMaterialString "This is the Package.Name of the material that is used when mirrors are disabled";
var private Material DefaultMirrorMaterial;

static native function SetMirrorsEnabled(bool bInMirrorsEnabled);
native function Initialize();

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    assertWithDescription( MyCamera != None, "Error: MyCamera is none for "$Self$".  This is either an old instance of the mirror, or someone deleted the MirrorCamera that was auto-created when this Mirror was placed has been deleted. Please delete this Mirror, and place a new one." );  
    Initialize();
    MyCamera.OwnerMirror = Self;
}

defaultproperties
{
    DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'Hotel_sm.hot_medicinecabinet'
    DrawScale=1.0
    bIsMirror=true
    bEdShouldSnap=True
	bStatic=false
    bStaticLighting=false
    bShadowCast=True
    bCollideActors=True
    bBlockActors=True
    bBlockPlayers=True
    bBlockKarma=True
    bWorldGeometry=True
	CollisionHeight=+000030.000000
    CollisionRadius=+000001.000000
    bAcceptsProjectors=True
    DefaultMirrorMaterialString="Repo_Tex.repo_catwalk_cubemap_env"
    
    RemoteRole=ROLE_None
    bNoDelete=true
}
