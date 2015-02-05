//=============================================================================
// ZoneInfo, the built-in Unreal class for defining properties
// of zones.  If you place one ZoneInfo actor in a
// zone you have partioned, the ZoneInfo defines the 
// properties of the zone.
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class ZoneInfo extends Info
	native
	placeable;

//-----------------------------------------------------------------------------
// Zone properties.

var skyzoneinfo SkyZone; // Optional sky zone containing this zone's sky.
var() name ZoneTag;
var() localized String LocationName; 

var() float KillZ;		// any actor falling below this level gets destroyed
var() eKillZType KillZType;	// passed by FellOutOfWorldEvent(), to allow different KillZ effects
var() bool bSoftKillZ;	// 2000 units of grace unless land

//-----------------------------------------------------------------------------
// Zone flags.

var()		bool   bTerrainZone;		// There is terrain in this zone.
var()		bool   bDistanceFog;		// There is distance fog in this zone.
var()		bool   bClearToFogColor;	// Clear to fog color if distance fog is enabled.

var const array<TerrainInfo> Terrains;

#if IG_SWAT
var()		bool   bUseFlashlight "When set to true, AI Officers will turn on their flashlight when they enter this zone";
#endif

//-----------------------------------------------------------------------------
// Zone light.
var            vector AmbientVector;
var(ZoneLight) byte AmbientBrightness, AmbientHue, AmbientSaturation;
#if IG_BUMPMAP	// rowan: control ambient ground ratio for this zone
var(ZoneLight) float AmbientXGroundRatio;
#endif

var(ZoneLight) color DistanceFogColor;
var(ZoneLight) float DistanceFogStart;
var(ZoneLight) float DistanceFogEnd;
var(ZoneLight) float DistanceFogBlendTime;

#if IG_FOG	// rowan: control fog type in zone
var(ZoneLight) enum EFogType
{
	FG_Linear,
	FG_Exponential,
} DistanceFogType;

var(ZoneLight) float DistanceFogExpBias;
var(ZoneLight) float DistanceFogClipBias;	// we can make objects clip out before or after they are fully fogged out

var() bool	bClipToDistanceFog;	// objects should be clipped based on the far distance fog distance
#endif

var(ZoneLight) const texture EnvironmentMap;
var(ZoneLight) float TexUPanSpeed, TexVPanSpeed;

var(ZoneSound) editinline I3DL2Listener ZoneEffect;

//------------------------------------------------------------------------------

var(ZoneVisibility) bool bLonelyZone;								// This zone is the only one to see or never seen
var(ZoneVisibility) editinline array<ZoneInfo> ManualExcludes;		// No Idea.. just sounded cool

#if IG_SWAT_OCCLUSION
// list of NavigationPoint's in this zone...
var() array<NavigationPoint>  ZonePropagationNodes;
var() name                  ZoneSoundTag "Zones with the same ZoneSoundTag are linked, and treated as one giant zone for sound propagation purposes";
#endif

#if IG_EFFECTS
var() array<name> EffectsContexts;
#endif

//=============================================================================
// Iterator functions.

// Iterate through all actors in this zone.
native(308) final iterator function ZoneActors( class<actor> BaseClass, out actor Actor );

simulated function LinkToSkybox()
{
	local skyzoneinfo TempSkyZone;

	// SkyZone.
	foreach AllActors( class 'SkyZoneInfo', TempSkyZone, '' )
		SkyZone = TempSkyZone;
	if(Level.DetailMode == DM_Low)
	{
		foreach AllActors( class 'SkyZoneInfo', TempSkyZone, '' )
			if( !TempSkyZone.bHighDetail && !TempSkyZone.bSuperHighDetail )
				SkyZone = TempSkyZone;
	}
	else if(Level.DetailMode == DM_High)
	{
	foreach AllActors( class 'SkyZoneInfo', TempSkyZone, '' )
			if( !TempSkyZone.bSuperHighDetail )
				SkyZone = TempSkyZone;
	}
	else if(Level.DetailMode == DM_SuperHigh)
	{
		foreach AllActors( class 'SkyZoneInfo', TempSkyZone, '' )
			SkyZone = TempSkyZone;
	}
}

//=============================================================================
// Engine notification functions.

simulated function PreBeginPlay()
{
	Super.PreBeginPlay();

	// call overridable function to link this ZoneInfo actor to a skybox
	LinkToSkybox();
}

// When an actor enters this zone.
#if IG_SHARED // Ryan:
event ActorEntered( actor Other )
{
	if (Pawn(Other) != None)
	{
#if IG_SWAT
		Pawn(Other).EnteredZone(self);
#else
		SLog(Other $ " entered zone " $ self);
		dispatchMessage(new class'MessageZoneEntered'(label, Other.label));

        Other.TriggerEffectEvent('InZone');
#endif
	}
}
#else
event ActorEntered( actor Other );
#endif // IG

// When an actor leaves this zone.
#if IG_SHARED // Ryan:
event ActorLeaving( actor Other )
{
	if (Pawn(Other) != None)
	{
#if IG_SWAT
		Pawn(Other).LeftZone(self);	
#else
		SLog(Other $ " leaving zone " $ self);
		dispatchMessage(new class'MessageZoneExited'(label, Other.label));

        Other.UnTriggerEffectEvent('InZone');
#endif
	}
}
#else
event ActorLeaving( actor Other );
#endif // IG

defaultproperties
{
     KillZ=-10000.0
     bStatic=True
     bNoDelete=True
     Texture=Texture'Engine_res.S_ZoneInfo'
     AmbientSaturation=255
	 DistanceFogColor=(R=128,G=128,B=128,A=0)
	 DistanceFogStart=3000
	 DistanceFogEnd=8000
	 DistanceFogBlendTime=1.0
     TexUPanSpeed=+00001.000000
     TexVPanSpeed=+00001.000000

// #if IG_FOG
	DistanceFogExpBias=1.0
	DistanceFogClipBias=1.0
// #endif

//#if IG_BUMPMAP	// rowan: control ambient ground ratio for this zone
	AmbientXGroundRatio=0.3
//#endif
}
