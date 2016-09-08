//=============================================================================
// Actor: The base class of all actors.
// Actor is the base class of all gameplay objects.
// A large number of properties, behaviors and interfaces are implemented in Actor, including:
//
// -	Display
// -	Animation
// -	Physics and world interaction
// -	Making sounds
// -	Networking properties
// -	Actor creation and destruction
// -	Triggering and timers
// -	Actor iterator functions
// -	Message broadcasting
//
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class Actor extends Core.Object
	abstract
	threaded
	native
	nativereplication
#if IG_SWAT // ckline: karma is now disabled
    hidecategories(Karma)
#endif
    ;

#if IG_SWAT //dkaplan: flag for actors to replicate all properties
			//   (including those that do not differ from defaults) when dirty
var bool bShouldReplicateDefaultProperties;
#endif

// Light modulation.
var(Lighting) enum ELightType
{
	LT_None,
	LT_Steady,
	LT_Pulse,
	LT_Blink,
	LT_Flicker,
	LT_Strobe,
	LT_BackdropLight,
	LT_SubtlePulse,
	LT_TexturePaletteOnce,
	LT_TexturePaletteLoop,
	LT_FadeOut
} LightType;

// Spatial light effect to use.
var(Lighting) enum ELightEffect
{
#if IG_RENDERER // rowan: only support these light types
	LE_Pointlight,
	LE_Sunlight,
	LE_Spotlight,
#else
	LE_None,
	LE_TorchWaver,
	LE_FireWaver,
	LE_WateryShimmer,
	LE_Searchlight,
	LE_SlowWave,
	LE_FastWave,
	LE_CloudCast,
	LE_StaticSpot,
	LE_Shock,
	LE_Disco,
	LE_Warp,
	LE_Spotlight,
	LE_NonIncidence,
	LE_Shell,
	LE_OmniBumpMap,
	LE_Interference,
	LE_Cylinder,
	LE_Rotor,
	LE_Sunlight,
	LE_QuadraticNonIncidence
#endif // IG
} LightEffect;

// Lighting info.
var(LightColor) float
	LightBrightness;
var(Lighting) float
	LightRadius;
var(LightColor) byte
	LightHue,
	LightSaturation;
var(Lighting) byte
	LightPeriod,
	LightPhase,
	LightCone;

#if IG_SHADOWS // rowan: SHADOW
var(Lighting) bool bCastsVolumetricShadows;		// light casts volumetric shadows
var(Lighting) bool bDisableShadowOptimisation;	// disable shadow clipping for this light source
var(Lighting) bool bDisableBspVolumetrics;		// disable volumetric shadows and illumination for bsp surfaces affected by this light source
var(Display)  bool bVolumetricShadowCast        "If true, lights with bCastsVolumetricShadows=true will cast volumetric shadows from this actor";
#endif // IG

#if IG_BUMPMAP // rowan: new bump params
// force lights to require an extra pass on bump mapped objects (not go into approximation stream)
var(Lighting) bool bDoNotApproximateBumpmap;
var(Display) float BumpmapLODScale;
#endif

#if IG_SHARED // ckline: lights and projectors can be flagged to only affect the zone they're in
var() bool bOnlyAffectCurrentZone "If this flag is set to TRUE on a light or projector, that light/projector will only affect actors and BSP that are in the same zone at the light/projector.";
#endif

#if IG_SHARED	// rowan: new light stuff
var(Lighting) float MaxTraceDistance;		//max raytrace distance for sunlights in unrealed
var(Lighting) bool bImportantDynamicLight;	// lets the light scalability system know taht it should never cull this light
var(Display) bool bGetOverlayMaterialFromBase;	// inherit your base's overlay
var(Display) bool bGetSkinFromBase;				// inherit your base's skin
#endif

#if IG_SHARED	// rowan: post render callback for fun stuff
// If true, the actor will get a call to the event PostRenderCallback.
//
// IG_SWAT NOTE: ckline-- it will also get a call to the native PreRenderCallback.
// This is a bit of a hack, but I wanted to keep this variable name the same
// as in the shared codebase.
var bool bNeedPostRenderCallback;
#endif

#if IG_EXTERNAL_CAMERAS
// If this flag is set to TRUE then this object will be considered a
// mirror, and be optimized as such in the renderer when rendering
// external cameras
var bool  bIsMirror;
#endif

#if IG_SWAT // Carlos: If this is true, this actor will NEVER draw when the player is drawn.
var bool bNeverDrawIfPlayerIsDrawn;
#endif

// Priority Parameters
// Actor's current physics mode.
var(Movement) const enum EPhysics
{
	PHYS_None,
	PHYS_Walking,
	PHYS_Falling,
	PHYS_Swimming,
	PHYS_Flying,
	PHYS_Rotating,
	PHYS_Projectile,
	PHYS_Interpolating,
	PHYS_MovingBrush,
	PHYS_Spider,
	PHYS_Trailer,
	PHYS_Ladder, // ckline: SWAT doesn't support this, but keeping in to keep same enum ordering as shared codebase objects
	PHYS_RootMotion,
    PHYS_Karma,
    PHYS_KarmaRagDoll,
	PHYS_Havok,
	PHYS_HavokSkeletal,
} Physics;

// Drawing effect.
var(Display) const enum EDrawType
{
	DT_None,
	DT_Sprite,
	DT_Mesh,
	DT_Brush,
	DT_RopeSprite,
	DT_VerticalSprite,
	DT_Terraform,
	DT_SpriteAnimOnce,
	DT_StaticMesh,
	DT_DrawType,
	DT_Particle,
	DT_AntiPortal,
	DT_FluidSurface,
#if IG_FLUID_VOLUME // rowan: draw type for fluid volume objects
	DT_FluidVolume,
#endif
} DrawType;

var(Display) const StaticMesh StaticMesh;		// StaticMesh if DrawType=DT_StaticMesh

// Owner.
var const Actor	Owner;			// Owner actor.
var const Actor	Base;           // Actor we're standing on.

struct ActorRenderDataPtr { var int Ptr; };
struct LightRenderDataPtr { var int Ptr; };

var const native ActorRenderDataPtr	ActorRenderData;
var const native LightRenderDataPtr	LightRenderData;
var const native int				RenderRevision;

#if IG_SHARED	// rowan: sub visibility actors
var const bool UsesSubVisibility;
#endif

enum EFilterState
{
	FS_Maybe,
	FS_Yes,
	FS_No
};

var const native EFilterState	StaticFilterState;

struct BatchReference
{
	var int	BatchIndex,
			ElementIndex;
};

var const native array<BatchReference>	StaticSectionBatches;

#if IG_SHARED // ckline: ForcedVisibilityZoneTag can be used to limit projection to actors in specific zone
var(Display) const name	ForcedVisibilityZoneTag "If set to something other than None, this actor will only render if the Tag of the ZoneInfo of its current zone is set to the same name.\n\nAdditionally, if the actor is a projector it will only project onto actors that are also in the correct zone.";
#else
var(Display) const name	ForcedVisibilityZoneTag; // Makes the visibility code treat the actor as if it was in the zone with the given tag.
#endif

// Lighting.
#if IG_SWAT // ckline: separate out properties that affect lights from properties that affect lighting of objects
var(Display) bool	     bSpecialLit		 "Specifies whether or not this actor is light using special lighting";
var(Display) bool	     bActorShadows		 "If true, lights will cast shadows from this actor";
var(Lighting) bool	   bCorona			 "If true, this light will use its first Skin as a corona. If bDirectional=true, then the corona will scale in size based on the angle to the viewer (no corona when aiming >= 90 degrees from viewer, max corona size when pointing directly at viewer)";
var(Display) bool		   bLightingVisibility "If true, visibility (line checks) will be used to determine if a light affects this object";
#else
var(Lighting) bool	     bSpecialLit;			// Only affects special-lit surfaces.
var(Lighting) bool	     bActorShadows;			// Light casts actor shadows.
var(Lighting) bool	     bCorona;			   // Light uses Skin as a corona.
var(Lighting) bool		 bLightingVisibility;	// Calculate lighting visibility for this actor with line checks.
#endif // IG_SWAT
var(Display) bool		 bUseDynamicLights;
var bool				 bLightChanged;			// Recalculate this light's lighting now.

//	Detail mode enum.

enum EDetailMode
{
	DM_Low,
	DM_High,
	DM_SuperHigh
};

// Flags.
var			  const bool	bStatic;			// Does not move or change over time. Don't let L.D.s change this - screws up net play
var(Advanced)		bool	bHidden;			// Is hidden during gameplay.
var(Advanced) const bool	bNoDelete;			// Cannot be deleted during play.
var			  const	bool	bDeleteMe;			// About to be deleted.
#if IG_SHARED	// rowan: Optimisation: ability to disable touch and tick
var					bool	bDisableTick;
var					bool	bDisableTouch;
#endif
var transient const bool	bTicked;			// Actor has been updated.
var(Lighting)		bool	bDynamicLight;		// This light is dynamic.
var					bool	bTimerLoop;			// Timer loops (else is one-shot).
var					bool    bOnlyOwnerSee;		// Only owner can see this actor.
var(Advanced)		bool    bHighDetail;		// Only show up in high or super high detail mode.
var(Advanced)		bool	bSuperHighDetail;	// Only show up in super high detail mode.
var					bool	bOnlyDrawIfAttached;	// don't draw this actor if not attached (useful for net clients where attached actors and their bases' replication may not be synched)
var(Advanced)		bool	bStasis;			// In StandAlone games, turn off if not in a recently rendered zone turned off if  bStasis  and physics = PHYS_None or PHYS_Rotating.
var					bool	bTrailerAllowRotation; // If PHYS_Trailer and want independent rotation control.
var					bool	bTrailerSameRotation; // If PHYS_Trailer and true, have same rotation as owner.
var					bool	bTrailerPrePivot;	// If PHYS_Trailer and true, offset from owner by PrePivot.
var					bool	bWorldGeometry;		// Collision and Physics treats this actor as world geometry
var(Display)		bool    bAcceptsProjectors;	// Projectors can project onto this actor
#if IG_SHARED // ckline: selectively prevent actors from receiving ShadowProjector shadows
var(Display)		bool    bAcceptsShadowProjectors "If false, ShadowProjectors (e.g., player shadows) will not project onto this actor. This parameter is ignored unless bAcceptsProjectors=true.";
#endif
var					bool	bOrientOnSlope;		// when landing, orient base on slope of floor
var			  const	bool	bOnlyAffectPawns;	// Optimisation - only test ovelap against pawns. Used for influences etc.
var(Display)		bool	bDisableSorting;	// Manual override for translucent material sorting.
var(Movement)		bool	bIgnoreEncroachers; // Ignore collisions between movers and

var					bool    bShowOctreeNodes;
var					bool    bWasSNFiltered;      // Mainly for debugging - the way this actor was inserted into Octree.

// Networking flags
var			  const	bool	bNetTemporary;				// Tear-off simulation in network play.
var					bool	bOnlyRelevantToOwner;			// this actor is only relevant to its owner.
var transient const	bool	bNetDirty;					// set when any attribute is assigned a value in unrealscript, reset when the actor is replicated
var					bool	bAlwaysRelevant;			// Always relevant for network.
var					bool	bReplicateInstigator;		// Replicate instigator to client (used by bNetTemporary projectiles).
var					bool	bReplicateMovement;			// if true, replicate movement/location related properties
var					bool	bSkipActorPropertyReplication; // if true, don't replicate actor class variables for this actor
var					bool	bUpdateSimulatedPosition;	// if true, update velocity/location after initialization for simulated proxies
var					bool	bTearOff;					// if true, this actor is no longer replicated to new clients, and
														// is "torn off" (becomes a ROLE_Authority) on clients to which it was being replicated.
var					bool	bOnlyDirtyReplication;		// if true, only replicate actor if bNetDirty is true - useful if no C++ changed attributes (such as physics)
														// bOnlyDirtyReplication only used with bAlwaysRelevant actors
var					bool	bReplicateAnimations;		// Should replicate SimAnim
var const           bool    bNetInitialRotation;        // Should replicate initial rotation
var					bool	bCompressedPosition;		// used by networking code to flag compressed position replication
var					bool	bAlwaysZeroBoneOffset;		// if true, offset always zero when attached to skeletalmesh

// Net variables.
enum ENetRole
{
	ROLE_None,              // No role at all.
	ROLE_DumbProxy,			// Dumb proxy of this actor.
	ROLE_SimulatedProxy,	// Locally simulated proxy of this actor.
	ROLE_AutonomousProxy,	// Locally autonomous proxy of this actor.
	ROLE_Authority,			// Authoritative control over the actor.
};
var ENetRole RemoteRole, Role;
var const transient int		NetTag;
var const float NetUpdateTime;	// time of last update
var float NetUpdateFrequency; // How many seconds between net updates.
var float NetPriority; // Higher priorities means update it more frequently.
var Pawn                  Instigator;    // Pawn responsible for damage caused by this actor.
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
var(Sound) sound          AmbientSound;  // Ambient sound effect.
#endif
var const name			AttachmentBone;		// name of bone to which actor is attached (if attached to center of base, =='')

var       const LevelInfo Level;         // Level this actor is on.
var transient const Level	XLevel;			// Level object.
var(Advanced)	float		LifeSpan;		// How old the object lives before dying, 0=forever.

#if IG_ACTOR_GROUPING // ryan: Actor grouping
// ckline note: Ryan says it is safe to static_cast these to UActorGroup* on the native side.
var const array<Object> OwnerGroups;
#endif

//-----------------------------------------------------------------------------
// Structures.

// Identifies a unique convex volume in the world.
struct PointRegion
{
	var zoneinfo Zone;       // Zone.
	var int      iLeaf;      // Bsp leaf.
	var byte     ZoneNumber; // Zone number.
};

// Havok rigid body state
struct HavokRigidBodyState
{
	var vector  Position;
	var quat	Quaternion;
	var vector	LinVel;
	var vector	AngVel;
};

//-----------------------------------------------------------------------------
// Major actor properties.

// Scriptable.
var const PointRegion     Region;        // Region this actor is in.
var				float       TimerRate;		// Timer event, 0=no timer.
var(Display) const mesh		Mesh;			// Mesh if DrawType=DT_Mesh.
var transient float		LastRenderTime;	// last time this actor was rendered.
var(Events) name			Tag;			// Actor's tag name.
var transient array<int>  Leaves;		 // BSP leaves this actor is in.
var(Events) name          Event;         // The event this actor causes.
var Inventory             Inventory;     // Inventory chain.
var		const	float       TimerCounter;	// Counts up until it reaches TimerRate.
var transient MeshInstance MeshInstance;	// Mesh instance.
var(Display) float		  LODBias;
var(Object) name InitialState;
var(Object) name Group;

// Internal.
var const array<Actor>    Touching;		 // List of touching actors.
var const transient array<int>  OctreeNodes;// Array of nodes of the octree Actor is currently in. Internal use only.
var const transient Box	  OctreeBox;     // Actor bounding box cached when added to Octree. Internal use only.
var const transient vector OctreeBoxCenter;
var const transient vector OctreeBoxRadii;
var const actor           Deleted;       // Next actor in just-deleted chain.
var const float           LatentFloat;   // Internal latent function use.
#if IG_SHARED   //tcohen: make FinishAnim() more reliable
var const array<byte>	  LatentAnimChannelCount;	 //when FinishAnim() is called, this is set to the value of AnimationCount on the animation channel that we're blocked on.  Its used to detect if another animation starts playing before we execPollFinishAnim().

#if IG_ANIM_DYNAMIC_TWEENING
enum EChannelTweenMode
{
    kChannelTweenModeNormal, // Default Unreal tweening.
    kChannelTweenModeDynamic
};
#endif // IG_ANIM_DYNAMIC_TWEENING

#endif

// Internal tags.
var const native int CollisionTag;
var const transient int JoinedTag;

// The actor's position and rotation.
var const	PhysicsVolume	PhysicsVolume;	// physics volume this actor is currently in
var(Movement) const vector	Location;		// Actor's location; use Move to set.
var(Movement) const rotator Rotation;		// Rotation.
var(Movement) vector		Velocity;		// Velocity.
var			  vector        Acceleration;	// Acceleration.

var const vector CachedLocation;
var const Rotator CachedRotation;
var Matrix CachedLocalToWorld;

// Attachment related variables
var(Movement)	name	AttachTag;
var const array<Actor>  Attached;			// array of actors attached to this actor.
var const vector		RelativeLocation;	// location relative to base/bone (valid if base exists)
var const rotator		RelativeRotation;	// rotation relative to base/bone (valid if base exists)

var(Movement) bool bHardAttach;             // Uses 'hard' attachment code. bBlockActor and bBlockPlayer must also be false.
											// This actor cannot then move relative to base (setlocation etc.).
											// Dont set while currently based on something!
											//
var const     Matrix    HardRelMatrix;		// Transform of actor in base's ref frame. Doesn't change after SetBase.

// Projectors
struct ProjectorRenderInfoPtr { var int Ptr; };	// Hack to to fool C++ header generation...
struct StaticMeshProjectorRenderInfoPtr { var int Ptr; };
var const native array<ProjectorRenderInfoPtr> Projectors;// Projected textures on this actor
var const native array<StaticMeshProjectorRenderInfoPtr>	StaticMeshProjectors;

//-----------------------------------------------------------------------------
// Display properties.

var(Display) Material		Texture;			// Sprite texture.if DrawType=DT_Sprite
var StaticMeshInstance		StaticMeshInstance; // Contains per-instance static mesh data, like static lighting data.
var const export model		Brush;				// Brush if DrawType=DT_Brush.
var(Display) const float	DrawScale;			// Scaling factor, 1.0=normal size.
var(Display) const vector	DrawScale3D;		// Scaling vector, (1.0,1.0,1.0)=normal size.
var(Display) vector			PrePivot;			// Offset from box center for drawing.
var(Display) array<Material> Skins;				// Multiple skin support - not replicated.
var			Material		RepSkin;			// replicated skin (sets Skins[0] if not none)
var(Display) byte			AmbientGlow;		// Ambient brightness, or 255=pulsing.
var(Display) byte           MaxLights;          // Limit to hardware lights active on this primitive.
#if IG_CLAMP_DYNAMIC_LIGHTS
var(Display) byte           MaxDynamicLights;   // Limit to number of dynamic lights active on this primitive to reduce popping from flashlights coming on and off, etc.
#endif
var(Display) ConvexVolume	AntiPortal;			// Convex volume used for DT_AntiPortal
var(Display) float          CullDistance;       // 0 == no distance cull, < 0 only drawn at distance > 0 cull at distance
var(Display) float			ScaleGlow;

// Style for rendering sprites, meshes.
var(Display) enum ERenderStyle
{
	STY_None,
	STY_Normal,
	STY_Masked,
	STY_Translucent,
	STY_Modulated,
	STY_Alpha,
	STY_Additive,
	STY_Subtractive,
	STY_Particle,
	STY_AlphaZ,
} Style;

// Display.
var(Display)  bool      bUnlit;					// Lights don't affect actor.
var(Display)  bool      bShadowCast;			// Casts static shadows.
var(Display)  bool		bStaticLighting;		// Uses raytraced lighting.
var(Display)  bool		bUseLightingFromBase;	// Use Unlit/AmbientGlow from Base

// Advanced.
var			  bool		bHurtEntry;				// keep HurtRadius from being reentrant
var(Advanced) bool		bGameRelevant;			// Always relevant for game
var(Advanced) bool		bCollideWhenPlacing;	// This actor collides with the world when placing.
var			  bool		bTravel;				// Actor is capable of travelling among servers.
var(Advanced) bool		bMovable;				// Actor can be moved.
var			  bool		bDestroyInPainVolume;	// destroy this actor if it enters a pain volume
var			  bool		bCanBeDamaged;			// can take damage
var(Advanced) bool		bShouldBaseAtStartup;	// if true, find base for this actor at level startup, if collides with world and PHYS_None or PHYS_Rotating
var			  bool		bPendingDelete;			// set when actor is about to be deleted (since endstate and other functions called
												// during deletion process before bDeleteMe is set).
var					bool	bAnimByOwner;		// Animation dictated by owner.
var 				bool	bOwnerNoSee;		// Everything but the owner can see this actor.
var(Advanced)		bool	bCanTeleport;		// This actor can be teleported.
var					bool	bClientAnim;		// Don't replicate any animations - animation done client-side
var					bool    bDisturbFluidSurface; // Cause ripples when in contact with FluidSurface.
var			  const	bool	bAlwaysTick;		// Update even when players-only.

//-----------------------------------------------------------------------------
// Sound.

#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
// Ambient sound.
var(Sound) float        SoundRadius;			// Radius of ambient sound.
var(Sound) byte         SoundVolume;			// Volume of ambient sound.
var(Sound) byte         SoundPitch;				// Sound pitch shift, 64.0=none.
#endif

#if (IG_SHARED && !IG_EFFECTS) // david: Added this variable so we can turn off the default light brightness->sound volume behaviour
var(Sound) bool         bScaleVolumeByLightBrightness;
#endif

// Sound occlusion
enum ESoundOcclusion
{
	OCCLUSION_Default,
	OCCLUSION_None,
	OCCLUSION_BSP,
	OCCLUSION_StaticMeshes,
};

#if IG_SWAT_OCCLUSION // ckline: swat handles occlusion differently; leaving variable in to avoid changing tons of other code
var         ESoundOcclusion SoundOcclusion;		// Sound occlusion approach.
#else
var(Sound) ESoundOcclusion SoundOcclusion;		// Sound occlusion approach.
#endif

#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
var(Sound) bool				bFullVolume;		// Whether to apply ambient attenuation.
#endif

// Carlos:  The effects system handles this in a completely different fashion.  This was used previously to have sounds
// cut off other sounds playing in the same slot.  This has been superceded by the Monophonic system in the ig effects system.
#if !IG_EFFECTS
// Sound slots for actors.
enum ESoundSlot
{
	SLOT_None,
	SLOT_Misc,
	SLOT_Pain,
	SLOT_Interact,
	SLOT_Ambient,
	SLOT_Talk,
	SLOT_Interface,
};
#endif // IG_EFFECTS

// Music transitions.
enum EMusicTransition
{
	MTRAN_None,
	MTRAN_Instant,
	MTRAN_Segue,
	MTRAN_Fade,
	MTRAN_FastFade,
	MTRAN_SlowFade,
};


#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
// Regular sounds.
var(Sound) float TransientSoundVolume;	// default sound volume for regular sounds (can be overridden in playsound)
var(Sound) float TransientSoundRadius;	// default sound radius for regular sounds (can be overridden in playsound)
#endif

//-----------------------------------------------------------------------------
// Collision.

// Collision size.
var(Collision) const float CollisionRadius;		// Radius of collision cyllinder.
var(Collision) const float CollisionHeight;		// Half-height cyllinder.

// Collision flags.
var(Collision) const bool bCollideActors;		// Collides with other actors.
var(Collision) bool       bCollideWorld;		// Collides with the world.
var(Collision) bool       bBlockActors;			// Blocks other nonplayer actors.
var(Collision) bool       bBlockPlayers;		// Blocks other player actors.
#if IG_SWAT
// To work around Unreal's limited collision/blocking flags, we have to add yet more flags. Sigh.
// This is really only needed by the PawnCollisionHandler, so we can determine if a pawn is moving
// into another pawn, even when bBlockActors is set to false (for example, when the pawn is
// restrained). Otherwise, this flag should always be set to false.
var(Collision) bool       bIsBlockedByIgnoresPawnBlockingFlags;
#endif
var(Collision) bool       bProjTarget;			// Projectiles should potentially target this actor.
var(Collision) bool		  bBlockZeroExtentTraces; // block zero extent actors/traces
var(Collision) bool		  bBlockNonZeroExtentTraces;	// block non-zero extent actors/traces
var(Collision) bool       bAutoAlignToTerrain;  // Auto-align to terrain in the editor
var(Collision) bool		  bUseCylinderCollision;// Force axis aligned cylinder collision (useful for static mesh pickups, etc.)
var(Collision) const bool bBlockKarma;			// Block actors being simulated with Karma.
var(Collision) const bool bBlockHavok;			// Block actors being simulated with Havok.

var       			bool    bNetNotify;                 // actor wishes to be notified of replication events

#if IG_SWAT
var(Collision) bool       bWeaponTestsPassThrough "When true, any weapon fire test trace that hits this actor will pass through this actor (useful for letting AIs think that this object won't block their weapon fire)";

var(Collision) bool       bUseCollisionBoneBoundingBox "This parameter is ignored if DrawType != DT_Mesh. If true, and this actor is DT_Mesh and has bone boxes, then the collision bounding box for this actor (which is used for determination of octree nodes) will be based on the union of the skeletal mesh's bone boxes. Otherwise, the collision bounding box will be based off of the actor's collision cylinder.";
#endif

//-----------------------------------------------------------------------------
// Physics.

// Options.
var			  bool		  bIgnoreOutOfWorld; // Don't destroy if enters zone zero
var(Movement) bool        bBounce;           // Bounces when hits ground fast.
var(Movement) bool		  bFixedRotationDir; // Fixed direction of rotation.
var(Movement) bool		  bRotateToDesired;  // Rotate to DesiredRotation.
var           bool        bInterpolating;    // Performing interpolating.
var			  const bool  bJustTeleported;   // Used by engine physics - not valid for scripts.

// Physics properties.
//TMC made Mass config
//var(Movement) float       Mass;			// Mass of this actor.
var(Movement) config float  Mass;			// Mass of this actor.
var(Movement) float       Buoyancy;			// Water buoyancy.
var(Movement) rotator	  RotationRate;		// Change in rotation per second.
var(Movement) rotator     DesiredRotation;	// Physics will smoothly rotate actor to this rotation if bRotateToDesired.
var			  Actor		  PendingTouch;		// Actor touched during move which wants to add an effect after the movement completes
var       const vector    ColLocation;		// Actor's old location one move ago. Only for debugging

const MAXSTEPHEIGHT = 16.0; // Maximum step height walkable by pawns
const MINFLOORZ = 0.7; // minimum z value for floor normal (if less, not a walkable floor)
					   // 0.7 ~= 45 degree angle for floor

#if WITH_KARMA

// Used to avoid compression
struct KRBVec
{
	var float	X, Y, Z;
};

struct KRigidBodyState
{
	var KRBVec	Position;
	var Quat	Quaternion;
	var KRBVec	LinVel;
	var KRBVec	AngVel;
};

var(Karma) export editinline KarmaParamsCollision KParams; // Parameters for Karma Collision/Dynamics.
var const native int KStepTag;
#endif // Karma stuff...

#if IG_SWAT // ckline: do not expose to UnrealEd
// In SWAT HavokData itself is not exposed to designers. Instead, if HavokDataClass is not None
// it will be instantiated and assigned to HavokData when the actor is initialized.
var transient editinline HavokObject HavokData; // Havok Dynamics info
var(Havok) config class<HavokObject> HavokDataClass;
#else
var(Havok) export editinline HavokObject HavokData; // Havok Dynamics info
#endif

#if IG_SHARED // Alex:
var private vector havokGameTickForce;
var private vector havokGameTickForcePosition;
#endif

// endif

//-----------------------------------------------------------------------------
// Animation replication
struct AnimRep
{
	var name AnimSequence;
	var bool bAnimLoop;
	var byte AnimFrame;
#if IG_SWAT
    var bool bIsAnimating;
    var int  AnimationCount;
#else // don't replicate the AnimRate (it's always 1.0), or TweenRate in SWAT
	var byte AnimRate;		// note that with compression, max replicated animrate is 4.0
	var byte TweenRate;		// note that with compression, max replicated tweentime is 4 seconds
#endif
};



var transient AnimRep		  SimAnim;		   // only replicated if bReplicateAnimations is true
#if IG_SWAT
// In a network game, allows us to replicate the special channel for SwatAICharacters
var transient AnimRep		  SpecialAnimRepInfo;

// In seconds. After each update, the next update time will be randomly chosen
// between the min and max update frequency. This should hopefully stagger the
// network data being sent out for each replicated pawn's animation.
var transient float ServerNextUpdateTimeForRepAnims;
const RepAnimUpdateFrequencyMin = 0.2;
const RepAnimUpdateFrequencyMax = 0.4;
#endif

//-----------------------------------------------------------------------------
// Forces.

enum EForceType
{
	FT_None,
	FT_DragAlong,
};

var (Force) EForceType	ForceType;
var (Force)	float		ForceRadius;
var (Force) float		ForceScale;


//-----------------------------------------------------------------------------
// Networking.

// Symmetric network flags, valid during replication only.
var const bool bNetInitial;       // Initial network update.
var const bool bNetOwner;         // Player owns this actor.
var const bool bNetRelevant;      // Actor is currently relevant. Only valid server side, only when replicating variables.
var const bool bDemoRecording;	  // True we are currently demo recording
var const bool bClientDemoRecording;// True we are currently recording a client-side demo
var const bool bRepClientDemo;		// True if remote client is recording demo
var const bool bClientDemoNetFunc;// True if we're client-side demo recording and this call originated from the remote.
var const bool bDemoOwner;			// Demo recording driver owns this actor.
var bool	   bNoRepMesh;			// don't replicate mesh

//Editing flags
#if IG_ACTOR_GROUPING // Ryan: Don't allow hiding and unhidding from the properties window
var const bool        bHiddenEd;     // Is hidden during editing.
    #if IG_NOCOPY // ckline: Never export a non-default value of bHiddenEdGroup, else a pasted actora that was copied from an actor in a hidden group will be hidden and difficult to unhide.
        // use nocopy keyword to prevent copying of bHiddenEdGroup
        var const nocopy bool bHiddenEdGroup;// Is hidden by the group brower.
    #else
        // UObject::ExportProperties will prevent copying of bHiddenEdGroup via a slower property name check
var const bool        bHiddenEdGroup;// Is hidden by the group brower.
    #endif
#else
var(Advanced) bool        bHiddenEd;     // Is hidden during editing.
var(Advanced) bool        bHiddenEdGroup;// Is hidden by the group brower.
#endif // IG
var(Advanced) bool        bDirectional;  // Actor shows direction arrow during editing.
var const bool            bSelected;     // Selected in UnrealEd.
var(Advanced) bool        bEdShouldSnap; // Snap to grid in editor.
var transient bool        bEdSnap;       // Should snap to grid in UnrealEd.
var transient const bool  bTempEditor;   // Internal UnrealEd.
var	bool				  bObsolete;	 // actor is obsolete - warn level designers to remove it
var(Collision) bool		  bPathColliding;// this actor should collide (if bWorldGeometry && bBlockActors is true) during path building (ignored if bStatic is true, as actor will always collide during path building)
var transient bool		  bPathTemp;	 // Internal/path building
var	bool				  bScriptInitialized; // set to prevent re-initializing of actors spawned during level startup
var(Advanced) bool        bLockLocation; // Prevent the actor from being moved in the editor.

var class<LocalMessage> MessageClass;

#if IG_SWAT //tcohen: player interaction
var() bool Examinable "True indicates that this Actor can be Examined.";
#endif

#if IG_EFFECTS // tcohen: startup time optimization: most actors don't care about Alive or Spawned events. Saves TONS of time in debug builds by avoiding no-op triggers of Spawned and Alive events.
// If false (the default), then TriggerEffectEvent() calls on this Actor that occur
// before the game starts (i.e., before first Tick()) will be ignored.
// If true, then effect events that happen before the game starts (such as
// 'Alive' and 'Spawned' events) will be queued and triggered once the game starts
var(Advanced) bool bTriggerEffectEventsBeforeGameStarts;
var(Advanced) bool bNeedLifetimeEffectEvents;
#endif

//-----------------------------------------------------------------------------
// Enums.

// Travelling from server to server.
enum ETravelType
{
	TRAVEL_Absolute,	// Absolute URL.
	TRAVEL_Partial,		// Partial (carry name, reset server).
	TRAVEL_Relative,	// Relative URL.
};


// double click move direction.
enum EDoubleClickDir
{
	DCLICK_None,
	DCLICK_Left,
	DCLICK_Right,
	DCLICK_Forward,
	DCLICK_Back,
	DCLICK_Active,
	DCLICK_Done
};

enum eKillZType
{
	KILLZ_None,
	KILLZ_Suicide
};

enum ESkeletalRegion
{
    REGION_None,
    REGION_Head,
    REGION_Torso,
    REGION_LeftArm,
    REGION_RightArm,
    REGION_LeftLeg,
    REGION_RightLeg,
    REGION_Body_Max,
    REGION_Door_WedgeSpot,
    REGION_Door_ToolkitSpot,
    REGION_Door_OptiwandSpot,
    REGION_Door_BreachingSpot
};

#if IG_ACTOR_LABEL // david: Labels
// Script variables
var() Name Label				"This object's label for use within the GUI editing system, and scripting (not mandatory)";
#endif

#if IG_SCRIPTING // david: Script
// Script variables
var() const String TriggeredBy		"This actor only receives messages from actors that have a matching label";
#endif

#if IG_SWAT // darren: ais taking cover
var() const bool IsCoverForAIs  "If true, a cover plane of an appropriate size will be auto-generated for this object";
const kCoverPlaneNumVertices = 4;
#endif

#if IG_SWAT // tcohen: hold references to loaded animation sets
// @NOTE: This is hacky. We maintain a reference array to the dynamically
// loaded animation groups. Since we load a group, then immediately pass
// it off to the native skeletal mesh object, we run the risk of these
// groups getting gc'd when they shouldn't be. This fixed that. [darren]
var private array<MeshAnimation> AnimationSetReferences;
#endif

#if IG_SHARED // ckline: notifications upon Pawn death and Actor destruction
var(Advanced) bool bSendDestructionNotification "If true, all registered IInterestedActorDestroyed objects will be notified when this actor is destroyed. NOTE: this setting is ignored if bStatic=true.";
#endif

#if IG_UC_LATENT_STACK_CLEANUP // Ryan: Latent stack cleanup
var transient noexport private const Array<INT> LatentStackLocations;
#endif

#if IG_SWAT //dkaplan: added state code ticking for some non-networked actors
var private bool bAlwaysProcessState;
#endif

#if IG_SHARED // johna: support for AddDebugMessage()
// Adds a line of text to be displayed in front of the actor (if the actor is visible)
// Only valid for the current update, so it must be called each update
native function AddDebugMessage(string NewMessage, optional color NewMessageColor);
#endif // IG_SHARED

//-----------------------------------------------------------------------------
// natives.

// Execute a console command in the context of the current level and game engine.
native function string ConsoleCommand( string Command );

//-----------------------------------------------------------------------------
// Network replication.

replication
{
	// Location
	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& (((RemoteRole == ROLE_AutonomousProxy) && bNetInitial)
						|| ((RemoteRole == ROLE_SimulatedProxy) && (bNetInitial || bUpdateSimulatedPosition) && ((Base == None) || Base.bWorldGeometry))
						|| ((RemoteRole == ROLE_DumbProxy) && ((Base == None) || Base.bWorldGeometry))) )
		Location;

	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& ((DrawType == DT_Mesh) || (DrawType == DT_StaticMesh))
					&& (((RemoteRole == ROLE_AutonomousProxy) && bNetInitial)
						|| ((RemoteRole == ROLE_SimulatedProxy) && (bNetInitial || bUpdateSimulatedPosition) && ((Base == None) || Base.bWorldGeometry))
						|| ((RemoteRole == ROLE_DumbProxy) && ((Base == None) || Base.bWorldGeometry))) )
		Rotation;

	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& RemoteRole<=ROLE_SimulatedProxy )
		Base,bOnlyDrawIfAttached;

	unreliable if( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& RemoteRole<=ROLE_SimulatedProxy && (Base != None) && !Base.bWorldGeometry)
		RelativeRotation, RelativeLocation, AttachmentBone;

	// Physics
	unreliable if( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& (((RemoteRole == ROLE_SimulatedProxy) && (bNetInitial || bUpdateSimulatedPosition))
						|| ((RemoteRole == ROLE_DumbProxy) && (Physics == PHYS_Falling))) )
		Velocity;

	unreliable if( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& (((RemoteRole == ROLE_SimulatedProxy) && bNetInitial)
						|| (RemoteRole == ROLE_DumbProxy)) )
		Physics;

	unreliable if( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& (RemoteRole <= ROLE_SimulatedProxy) && (Physics == PHYS_Rotating) )
		bFixedRotationDir, bRotateToDesired, RotationRate, DesiredRotation;

#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
	// Ambient sound.
	unreliable if( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority) && (!bNetOwner || !bClientAnim) )
		AmbientSound;
#endif

#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
	unreliable if( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority) && (!bNetOwner || !bClientAnim) && (AmbientSound!=None))
		SoundRadius, SoundVolume, SoundPitch;
#endif

	// Animation.
	unreliable if( (!bSkipActorPropertyReplication || bNetInitial)
				&& (Role==ROLE_Authority) && (DrawType==DT_Mesh) && bReplicateAnimations )
#if IG_SWAT
		SpecialAnimRepInfo,
#endif
		SimAnim;

#if IG_SHARED // Alex: required to fix SimAnim not playing animation in some instances
	unreliable if( (!bSkipActorPropertyReplication || bNetInitial)
				&& (Role==ROLE_Authority) && (DrawType==DT_Mesh) )
		bReplicateAnimations;
#endif

	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority) )
		bHidden, bHardAttach;

	// Properties changed using accessor functions (Owner, rendering, and collision)
	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority) && bNetDirty )
		Owner, DrawScale, DrawType, bCollideActors,bCollideWorld,bOnlyOwnerSee,Texture,Style, RepSkin;

	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority) && bNetDirty
					&& (bCollideActors || bCollideWorld) )
		bProjTarget, bBlockActors, bBlockPlayers, CollisionRadius, CollisionHeight;

	// Properties changed only when spawning or in script (relationships, rendering, lighting)
	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority) )
		Role,RemoteRole,bNetOwner,LightType,bTearOff;

	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority)
					&& bNetDirty && bNetOwner )
		Inventory;

	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority)
					&& bNetDirty && bReplicateInstigator )
		Instigator;

	// Infrequently changed mesh properties
	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority)
					&& bNetDirty && (DrawType == DT_Mesh) )
		AmbientGlow,bUnlit,PrePivot;

	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority)
					&& bNetDirty && !bNoRepMesh && (DrawType == DT_Mesh) )
		Mesh;

	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority)
				&& bNetDirty && (DrawType == DT_StaticMesh) )
		StaticMesh;

	// Infrequently changed lighting properties.
	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && (Role==ROLE_Authority)
					&& bNetDirty && (LightType != LT_None) )
		LightEffect, LightBrightness, LightHue, LightSaturation,
		LightRadius, LightPeriod, LightPhase, bSpecialLit;

	// replicated functions
	unreliable if( bDemoRecording )
		DemoPlaySound;
}

//=============================================================================
// Actor error handling.

// Handle an error and kill this one actor.
native(233) final function Error( coerce string S );

//=============================================================================
// General functions.

#if IG_SHARED	// rowan: rendering stuff
simulated event Material GetOverlayMaterial(int Index)
{
	if (Base != None && bGetOverlayMaterialFromBase)
		return Base.GetOverlayMaterial(Index);

	return None;
}
#endif

#if IG_SHARED	// rowan: post render callback for fun stuff
simulated event PostRenderCallback(bool InMainScene);
#endif

#if IG_SWAT // tcohen: copied from Tribes for scripting support
native function bool IsOverlapping(Actor Other);
#endif

#if IG_SHARED //dkaplan: allow to find by actors unique id
//findByUniqueID
simulated function Actor FindByUniqueID( class<Actor> TheActorClass, String UniqueID )
{
	local Actor a;
	local class<Actor> findClass;

	if (TheActorClass != None)
	{
		findClass = TheActorClass;
	}
	else
	{
		findClass = class'Actor';
	}

	ForEach DynamicActors(findClass, a)
	{
		if (a.UniqueID() == UniqueID)
			return a;
	}

	return None;
}

//Returns a unique ID for the actor
simulated function String UniqueID()
{
    return String(Name);
}
#endif

#if IG_SCRIPTING // david: functions to find objects by their script label
// findByLabel
// Finds the first actor with label
function Actor findByLabel(class<Actor> actorClass, Name label)
{
	local Actor a;
	local class<Actor> findClass;

	if (actorClass != None)
	{
		findClass = actorClass;
	}
	else
	{
		findClass = class'Actor';
	}

	ForEach DynamicActors(findClass, a)
	{
		if (a.label == label)
			return a;
	}

	return None;
}

// Iterator for all actors with label (same as findByLabel but for all matches, not just the first)
native final iterator function actorLabel(class<Actor> actorClass, out Actor foundActor, Name label);

// findStaticByLabel
// Finds the first actor with label including static actors
function Actor findStaticByLabel(class<Actor> actorClass, Name label)
{
	local Actor a;
	local class<Actor> findClass;

	if (actorClass != None)
	{
		findClass = actorClass;
	}
	else
	{
		findClass = class'Actor';
	}

	ForEach AllActors(findClass, a)
	{
		if (a.label == label)
			return a;
	}

	return None;
}

// Iterator for all actors with label including static actors (same as findStaticByLabel but for all matches, not just the first)
native final iterator function staticActorLabel(class<Actor> actorClass, out Actor foundActor, Name label);
#endif // IG_SCRIPTING

#if IG_UC_ACTOR_ALLOCATOR // karl: Added Actor Allocator
// Called by new operator (on the default object of a particular class).
// Allocates and returns an object of that class.
native static function Object Allocate( Object Context, Object Outer, optional string n, optional INT flags, optional Object Template );

// Constructor
overloaded native function Construct();
overloaded native function Construct( actor Owner, optional optional name Tag,
				  optional vector Location, optional rotator Rotation);
#endif // IG_UC_ACTOR_ALLOCATOR

// Latent functions.
#if IG_UC_THREADED // karl: Moved sleep to Object
#else
native(256) final latent function Sleep( float Seconds );
#endif

// Collision.
native(262) final function SetCollision( optional bool NewColActors, optional bool NewBlockActors, optional bool NewBlockPlayers );
native(283) final function bool SetCollisionSize( float NewRadius, float NewHeight );
native final function SetDrawScale(float NewScale);
native final function SetDrawScale3D(vector NewScale3D);
native final function SetStaticMesh(StaticMesh NewStaticMesh);
native final function SetDrawType(EDrawType NewDrawType);

// Movement.
native(266) final function bool Move( vector Delta );
native(267) final function bool SetLocation( vector NewLocation );
native(299) final function bool SetRotation( rotator NewRotation );

#if IG_SWAT
native final function bool CanSetLocation(vector NewLocation);
#endif

// SetRelativeRotation() sets the rotation relative to the actor's base
native final function bool SetRelativeRotation( rotator NewRotation );
native final function bool SetRelativeLocation( vector NewLocation );

native(3969) final function bool MoveSmooth( vector Delta );
native(3971) final function AutonomousPhysics(float DeltaSeconds);

// Relations.
native(298) final function SetBase( actor NewBase, optional vector NewFloor );
native(272) final function SetOwner( actor NewOwner );

#if IG_TRIBES3	// marc: make an actor dormant for level designers
// "onOff": true: make dormant; false: wake up
function makeDormant( bool onOff )
{
	local Pawn pawn;

	pawn = Pawn(self);

	if ( onOff )
	{
		//log( "Making" @ name @ "dormant" );
		if ( pawn != None )
		{
			level.AI_Setup.stopActions( pawn );
			pawn.AI_LOD_LevelOrig = pawn.AI_LOD_Level;
			level.AI_Setup.setAILOD( pawn, AILOD_NONE );
		}
		SetPhysics(PHYS_None);					// stop physics
		bHidden = true;							// make invisible
		setCollision( false, false, false );	// disable collisions
	}
	else
	{
		//log( "Waking" @ name @ "up" );
		SetPhysics(default.Physics);			// restore physics
		bHidden = default.bHidden;				// make visible
		setCollision( default.bCollideActors, default.bBlockActors, default.bBlockPlayers );	// enable collisions
		if ( pawn != None )
		{
			level.AI_Setup.setAILOD( pawn, pawn.AI_LOD_LevelOrig );
			pawn.rematchGoals();
		}
	}
}
#endif

//=============================================================================
// Animation.

native final function string GetMeshName();

// Animation functions.
native(259) final function PlayAnim( name Sequence, optional float Rate, optional float TweenTime, optional int Channel );
native(260) final function LoopAnim( name Sequence, optional float Rate, optional float TweenTime, optional int Channel );

#if IG_ANIM_ADDITIVE_BLENDING // darren: additive anim blending
// Additively blends the animation specified by Sequence in the given
// channel. PlayAnimAdditive uses the first frame of animation specified
// by RefSequence as a reference, and blends the differences between
// this reference and each frame of the Sequence animation. If
// RefSequence is NULL, the first frame of the Sequence is used
// as the reference. [darren]
native final function PlayAnimAdditive( name Sequence, optional float Rate, optional float TweenTime, optional int Channel, optional name RefSequence );
native final function LoopAnimAdditive( name Sequence, optional float Rate, optional float TweenTime, optional int Channel, optional name RefSequence );
#endif

native(294) final function TweenAnim( name Sequence, float Time, optional int Channel );
native(282) final function bool IsAnimating(optional int Channel);
native(261) final latent function FinishAnim(optional int Channel);
native(263) final function bool HasAnim( name Sequence );
#if IG_SWAT
// if the specific channel is set to anything greater than 0, the ClearAllButBase parameter is ignored
native final function StopAnimating( optional bool ClearAllButBase, optional int SpecificChannel );
#else
native final function StopAnimating( optional bool ClearAllButBase );
#endif
native final function FreezeAnimAt( float Time, optional int Channel);
native final function SetAnimFrame( float Time, optional int Channel, optional int UnitFlag );
native final function name GetAnimName(optional int Channel);
native final function bool IsTweening(int Channel);

#if IG_SHARED
// Get the length (in seconds) of an animation
native final function float GetAnimLength( name Sequence, optional float Rate, optional float TweenTime, optional int Channel);

#if IG_ANIM_DYNAMIC_TWEENING
native final function SetTweenMode(int Channel, EChannelTweenMode Mode);
#endif

#endif

// ifdef WITH_LIPSINC
native final function PlayLIPSincAnim(
	name                    LIPSincAnimName,
	optional float		Volume,
	optional float		Radius,
	optional float		Pitch
    );

native final function StopLIPSincAnim();

native final function bool HasLIPSincAnim( name LIPSincAnimName );
native final function bool IsPlayingLIPSincAnim();
native final function string CurrentLIPSincAnim();

// LIPSinc Animation notifications.
event LIPSincAnimEnd();
// endif

// Animation notifications.
event AnimEnd( int Channel );
native final function EnableChannelNotify ( int Channel, int Switch );
native final function int GetNotifyChannel();

// Skeletal animation.
simulated native final function LinkSkelAnim( MeshAnimation Anim, optional mesh NewMesh );
simulated native final function LinkMesh( mesh NewMesh, optional bool bKeepAnim );
native final function BoneRefresh();

native final function AnimBlendParams( int Stage, optional float BlendAlpha, optional float InTime, optional float OutTime, optional name BoneName, optional bool bGlobalPose);
native final function AnimBlendToAlpha( int Stage, float TargetAlpha, float TimeInterval );

#if IG_SHARED
native final function float AnimGetChannelAlpha(int Channel);
#endif

native final function coords  GetBoneCoords(   name BoneName
#if IG_SHARED // johna: optionally include offset to socket if BoneName is the name of a socket
			  // -if BoneName is the name of a bone, bGetSocketCoords has no effect
			  // -if BoneName is the name of a socket and bGetSocketCoords is false, the function returns the coords of the bone the socket is attached to
			  // -if BoneName is the name of a socket and bGetSocketCoords is true, the function returns the coords of the socket (i.e., get the current world space location of the socket)
											, optional bool bGetSocketCoords
#endif
											);
native final function rotator GetBoneRotation( name BoneName, optional int Space );

native final function vector  GetRootLocation();
native final function rotator GetRootRotation();
native final function vector  GetRootLocationDelta();
native final function rotator GetRootRotationDelta();

native final function bool  AttachToBone( actor Attachment, name BoneName );
native final function bool  DetachFromBone( actor Attachment );
#if IG_SHARED // ckline: forcibly update the position of an Actor's attachments, even if the Actor is not visible
// Causes all attachments to have their positions/rotations updated, regardless of
// whether or not this actor is visible.
native final function UpdateAttachmentLocations();
#endif

native final function LockRootMotion( int Lock );
native final function SetBoneScale( int Slot, optional float BoneScale, optional name BoneName );

native final function SetBoneDirection( name BoneName, rotator BoneTurn, optional vector BoneTrans, optional float Alpha, optional int Space );
native final function SetBoneLocation( name BoneName, optional vector BoneTrans, optional float Alpha );
native final function SetBoneRotation( name BoneName, optional rotator BoneTurn, optional int Space, optional float Alpha );
native final function GetAnimParams( int Channel, out name OutSeqName, out float OutAnimFrame, out float OutAnimRate );
native final function bool AnimIsInGroup( int Channel, name GroupName );

//=========================================================================
// Rendering.

native final function plane GetRenderBoundingSphere();
native final function DrawDebugLine( vector LineStart, vector LineEnd, byte R, byte G, byte B); // SLOW! Use for debugging only!

//=========================================================================
// Physics.

native final function DebugClock();
native final function DebugUnclock();

// Physics control.
native(301) final latent function FinishInterpolation();
native(3970) final function SetPhysics( EPhysics newPhysics );

native final function OnlyAffectPawns(bool B);

#if WITH_KARMA
native final function quat KGetRBQuaternion();

native final function KGetRigidBodyState(out KRigidBodyState RBstate);
native final function KDrawRigidBodyState(KRigidBodyState RBState, bool AltColour); // SLOW! Use for debugging only!
native final function vector KRBVecToVector(KRBVec RBvec);
native final function KRBVec KRBVecFromVector(vector v);

native final function KSetMass( float mass );
native final function float KGetMass();

// Set inertia tensor assuming a mass of 1. Scaled by mass internally to calculate actual inertia tensor.
native final function KSetInertiaTensor( vector it1, vector it2 );
native final function KGetInertiaTensor( out vector it1, out vector it2 );

native final function KSetDampingProps( float lindamp, float angdamp );
native final function KGetDampingProps( out float lindamp, out float angdamp );

native final function KSetFriction( float friction );
native final function float KGetFriction();

native final function KSetRestitution( float rest );
native final function float KGetRestitution();

native final function KSetCOMOffset( vector offset );
native final function KGetCOMOffset( out vector offset );
native final function KGetCOMPosition( out vector pos ); // get actual position of actors COM in world space

native final function KSetImpactThreshold( float thresh );
native final function float KGetImpactThreshold();

native final function KWake();
native final function bool KIsAwake();
native final function KAddImpulse( vector Impulse, vector Position, optional name BoneName );

native final function KSetStayUpright( bool stayUpright, bool allowRotate );
native final function KSetStayUprightParams( float stiffness, float damping );

native final function KSetBlockKarma( bool newBlock );

native final function KSetActorGravScale( float ActorGravScale );
native final function float KGetActorGravScale();

// Disable/Enable Karma contact generation between this actor, and another actor.
// Collision is on by default.
native final function KDisableCollision( actor Other );
native final function KEnableCollision( actor Other );

// Ragdoll-specific functions
native final function KSetSkelVel( vector Velocity, optional vector AngVelocity, optional bool AddToCurrent );
native final function float KGetSkelMass();
native final function KFreezeRagdoll();

// You MUST turn collision off (KSetBlockKarma) before using bone lifters!
native final function KAddBoneLifter( name BoneName, InterpCurve LiftVel, float LateralFriction, InterpCurve Softness );
native final function KRemoveLifterFromBone( name BoneName );
native final function KRemoveAllBoneLifters();

// Used for only allowing a fixed maximum number of ragdolls in action.
native final function KMakeRagdollAvailable();
native final function bool KIsRagdollAvailable();

// event called when Karmic actor hits with impact velocity over KImpactThreshold
event KImpact(actor other, vector pos, vector impactVel, vector impactNorm);

// event called when karma actor's velocity drops below KVelDropBelowThreshold;
event KVelDropBelow();

// event called when a ragdoll convulses (see KarmaParamsSkel)
event KSkelConvulse();

// event called just before sim to allow user to
// NOTE: you should ONLY put numbers into Force and Torque during this event!!!!
event KApplyForce(out vector Force, out vector Torque);

// This is called from inside C++ physKarma at the appropriate time to update state of Karma rigid body.
// If you return true, newState will be set into the rigid body. Return false and it will do nothing.
event bool KUpdateState(out KRigidBodyState newState);
#endif // WITH_KARMA

// Unreal Havok
#if !IG_SHARED	// rowan: added new version of this that supports activation and deactivation
native final function HavokActivate();
#endif
native final event function bool HavokIsActive();

native final function HavokImpartImpulse( vector Impulse, vector Position, optional name BoneName );
native final function HavokImpartForce( vector Force, vector Position, optional name BoneName );

// You can do this though HGetState / HavokUpdateState, but here is a quicker, specific to
// just the velocities. If BoneName is None for a skeletal system, the last traced bone is used.
// If you just set one bone in a skeletal system you will be introducing error into the system.
#if IG_SHARED // ckline: if socket name specified, return velocity of bone socket is associated with
//   Note: if HavokGet{Linear/Angular}Velocity is passed the name of a socket, the function will
//   return the velocity of the bone to which the socket is attached.
#endif
native final function vector HavokGetLinearVelocity( optional name BoneName ); // in Unreal units
native final function vector HavokGetAngularVelocity( optional name BoneName ); // in Unreal units
native final function HavokSetLinearVelocity( vector Linear, optional name BoneName ); // in Unreal units
native final function HavokSetAngularVelocity( vector Angular, optional name BoneName ); // in Unreal units
native final function HavokSetLinearVelocityAll( vector Linear ); // Only really for Skeletal systems.
#if IG_SHARED // ckline: can set havok damping from script
// Set linear/angular damping on an actor. If this actor is a ragdoll, damping
// will be applied to all bones unless a specific BoneName is specified.
// Damping must be non-negative. As a reference, the default linear damping
// on a rigid body is 0, and the default angular damping is 0.5.
native final function HavokSetLinearDamping(float Damping, optional name BoneName);
native final function HavokSetAngularDamping(float Damping, optional name BoneName);
#endif
native final function name HavokGetLastTracedBone();
#if IG_SHARED	// rowan: IG extensions to havok integration
native final function HavokImpartCOMImpulse( vector Impulse, optional name BoneName );	// apply impulse at exact havok COM
native final event function HavokActivate(optional bool Activate);
#endif
#if IG_SHARED // ckline: change bBlockHavok at runtime
native final function HavokSetBlocking(bool blockHavok); // default param value is false
#endif

#if IG_SHARED // Alex: Imparts a force for the duration of a game tick. HavokImpartForce only applies force for the
		// duration of a Havok tick. This function can only be called once per tick per actor, previous calls are
		// ignored otherwise. Force is actually applied in the next game tick.
native final function HavokSetGameTickForce(vector Force, vector Position);
#endif

// If you change the state and return true for this event, you will directly
// effect the pos and rot of the given body. Note that this will cause the body to
// effectlively teleport to that state, so make sure that that state is valid!
native final function HavokGetState(out HavokRigidBodyState state, optional name BoneName);
event bool HavokUpdateState(out HavokRigidBodyState newState);

// Pairwise Collision Detection filter. THIS CAUSES SLOW DOWN AT RUNTIME (LIST CHECKS IN COLLISION CALLBACKS)
// Try to use Collision Groups in the HavokRigidBidy instead (see after these funcs):
native final function HavokSlowSetCollisionEnabled( actor Other, bool Enabled, optional name BoneNameA, optional name BoneNameB );

// Change the Collision Groups info for this body.
// 32768 system groups, 32 layers, 64 subpart ids. See the HavokRigidBody.uc  for more info.
native final function HavokCollisionGroupChange( int layer, int systemGroup, int subpartID, int	subpartIgnoreID, optional name BoneName );

// Call this after causing HavokQuit to be called (through SetPhysics( PHYS_None ) for instance if
// you want to reset the animation flags so that the Havok pose is no longer the one used
// and the animation is in full control. The first PHYSICAL bone in the hierarchy will be kept
// the same orientation (by changing the Actor pos after refreshing the pose) and the actor pos
// will remain unchanged. Thus you should be able to predict, given an animation set,
// where the pose will be at the end of this call.
native final function HavokReturnSkeletalActorToAnimationSystem();

// end Unreal Havok

// Timing
native final function Clock(out float time);
native final function UnClock(out float time);

//=========================================================================
// Music

native final function int PlayMusic( string Song, float FadeInTime );
native final function StopMusic( int SongHandle, float FadeOutTime );
native final function StopAllMusic( float FadeOutTime );


//=========================================================================
// Engine notification functions.

//
// Major notifications.
//
#if IG_SWAT // SWAT untriggers 'alive' and triggers 'destroyed' in specific Handlers for ReactiveWorldObjects
simulated event Destroyed();
#else
simulated event Destroyed()
{
#if IG_EFFECTS
	if (bNeedLifetimeEffectEvents)
	{
    UntriggerEffectEvent('Alive');
}
#endif
}
#endif
event GainedChild( Actor Other );
event LostChild( Actor Other );
event Tick( float DeltaTime );
event PostNetReceive();

//
// Triggers.
//
#if IG_SWAT //dkaplan: Sets up to Broadcast a triggered message to all clients
simulated function BroadcastTrigger( Actor Other, Pawn EventInstigator )
{
    if ( Level.NetMode != NM_Standalone )
    {
        Level.GetGameReplicationInfo().ServerBroadcastTrigger( Self, UniqueID(), Other, EventInstigator );
    }
    else
    {
        Trigger( Other, EventInstigator );
    }
}
#endif //IG_SWAT

simulated event Trigger( Actor Other, Pawn EventInstigator );
event UnTrigger( Actor Other, Pawn EventInstigator );
event BeginEvent();
event EndEvent();

//
// Physics & world interaction.
//
event Timer();
event HitWall( vector HitNormal, actor HitWall );
event Falling();
event Landed( vector HitNormal );
event ZoneChange( ZoneInfo NewZone );
event PhysicsVolumeChange( PhysicsVolume NewVolume );
event Touch( Actor Other );
event PostTouch( Actor Other ); // called for PendingTouch actor after physics completes
event UnTouch( Actor Other );

#if IG_RWO
simulated function BroadcastReactToBumped( Actor Other )
{
    local Controller Itr;
    local String UniqueIdentifier;
    local PlayerController LPC;

    UniqueIdentifier = UniqueID();

    LPC = Level.GetLocalPlayerController();

    Itr = Level.ControllerList;
    while ( Itr != None ) // Walk the controller list
    {
        if( Itr.IsA( 'PlayerController' ) && Itr != LPC )
            PlayerController(Itr).ClientBroadcastReactToBumped( UniqueIdentifier, Other );
        Itr = Itr.NextController;
    }

    ReactToBumped( Other );
}

final event Bump( Actor Other )
{
    ReactToBumped(Other);

    PostBump(Other);
}
function PostBump(Actor Other);
simulated function ReactToBumped(Actor Other);
#else
event Bump( Actor Other );
#endif

//end Irrational
event BaseChange();
event Attach( Actor Other );
event Detach( Actor Other );
event Actor SpecialHandling(Pawn Other);
event bool EncroachingOn( actor Other );
event EncroachedBy( actor Other );
event FinishedInterpolation()
{
	bInterpolating = false;
}

event EndedRotation();			// called when rotation completes
event UsedBy( Pawn user ); // called if this Actor was touching a Pawn who pressed Use

simulated event FellOutOfWorld(eKillZType KillType)
{
	SetPhysics(PHYS_None);
#if IG_SWAT
    Log("!!!! WARNING !!!!! Destroying actor "$self$" because it fell out of world at location "$Location.X$", "$Location.Y$", "$Location.Z);
#endif
	Destroy();
}

//
// Damage and kills.
//
event KilledBy( pawn EventInstigator );

#if (IG_EFFECTS || IG_RWO)  //tcohen: hooked, used by effects system and reactive world objects
final
#endif
simulated event TakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
#if IG_EFFECTS
#if IG_SWAT // swat wants to know about all the same info (like damage type) as everybody else
    TakeDamageEffectsHook(Damage, EventInstigator, HitLocation, Momentum, DamageType);
#else
    TakeDamageEffectsHook();
#endif //IG_SWAT
#endif

#if IG_RWO
    TakeDamageRWOHook(Damage, EventInstigator, HitLocation, Momentum, DamageType);
#endif

    PostTakeDamage(Damage, EventInstigator, HitLocation, Momentum, DamageType);
}

#if IG_SWAT //dkaplan- we overwrite TakeDamageEffectsHook() in NetPlayer to allow for a broader range of hit effects
            // swat wants to know about all the same info (like damage type) as everybody else
simulated function TakeDamageEffectsHook( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType )
#else
final simulated function TakeDamageEffectsHook()
#endif
{
#if IG_EFFECTS
    if (IsA('Pawn') && Pawn(self).Health <= 0)
        TriggerEffectEvent('DamagedDead');
    else
        TriggerEffectEvent('Damaged');
#endif
}

#if IG_RWO
simulated function BroadcastReactToDamaged(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    local Controller Itr;
    local String UniqueIdentifier;
    local PlayerController LPC;

    UniqueIdentifier = UniqueID();

    LPC = Level.GetLocalPlayerController();

    Itr = Level.ControllerList;
    while ( Itr != None ) // Walk the controller list
    {
        if( Itr.IsA( 'PlayerController' ) && Itr != LPC )
            PlayerController(Itr).ClientBroadcastReactToDamaged( UniqueIdentifier, Damage, EventInstigator, HitLocation, Momentum, DamageType );
        Itr = Itr.NextController;
    }

    ReactToDamaged( Damage, EventInstigator, HitLocation, Momentum, DamageType );
}

simulated final function TakeDamageRWOHook( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    //log( Self$" TakeDamageRWOHook()!!!!" );
    BroadcastReactToDamaged(Damage, EventInstigator, HitLocation, Momentum, DamageType);
}
simulated function ReactToDamaged(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType);
#endif

event PostTakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType);

#if IG_SWAT
simulated event TakeHitImpulse(vector HitLocation, vector Momentum, class<DamageType> DamageType);
#endif

//
// Trace a line and see what it collides with first.
// Takes this actor's collision properties into account.
// Returns first hit actor, Level if hit level, or None if hit nothing.
//
native(277) final function Actor Trace
(
	out vector      HitLocation,
	out vector      HitNormal,
	vector          TraceEnd,
	optional vector TraceStart,
	optional bool   bTraceActors,
	optional vector Extent,
	optional out material Material
#if IG_SWAT
   ,optional bool   bWeaponFireTest,		// note the comma(s).
    optional bool   bTraceThroughSeeThroughMaterials,
    optional bool   bSkeletalBoxTest,
    optional out ESkeletalRegion SkeletalRegionHit  // Only valid if bSkeletalBoxTest is true.
#if IG_MULTILINE_EXIT_RESULTS
    ,optional bool  bFindExitLocation,
    optional out vector ExitLocation,
    optional out vector ExitNormal,
    optional out material ExitMaterial
#endif // IG_MULTILINE_EXIT_RESULTS
#endif // IG_SWAT
);

#if IG_SWAT // ckline: info on bone hit if trace hit skeletal mesh
// If the most recent call to Trace(), FastTrace(), or TraceActors() hit a skeletal
// mesh bone collision representation, this method will return the name of the
// closest bone hit. Otherwise returns NAME_None (i.e., '').
native final function Name GetLastTracedBone();
native final function Actor GetLastTracedActor();
#endif

// returns true if did not hit world geometry
native(548) final function bool FastTrace
(
	vector          TraceEnd,
	optional vector TraceStart
);

//
// Spawn an actor. Returns an actor of the specified class, not
// of class Actor (this is hardcoded in the compiler). Returns None
// if the actor could not be spawned (either the actor wouldn't fit in
// the specified location, or the actor list is full).
// Defaults to spawning at the spawner's location.
//
native(278) final function actor Spawn
(
	class<actor>      SpawnClass,
	optional actor	  SpawnOwner,
	optional name     SpawnTag,
	optional vector   SpawnLocation,
	optional rotator    SpawnRotation,
    optional bool       bNoCollisionFail
);

//
// Destroy this actor. Returns true if destroyed, false if indestructable.
// Destruction is latent. It occurs at the end of the tick.
//
native(279) final function bool Destroy();

// Networking - called on client when actor is torn off (bTearOff==true)
event TornOff();

//=============================================================================
// Timing.

// Causes Timer() events every NewTimerRate seconds.
native(280) final function SetTimer( float NewTimerRate, bool bLoop );

//=============================================================================
// Sound functions.

#if IG_SWAT //dkaplan: function to simulate playing a sound on a dedicated server so that AI's can recieve audio stimuli
native final function SimulateSoundOnDedicatedServer( optional int flags, optional bool Attenuate, optional float AISoundRadius, optional Name SoundCategory );
#endif

/* Play a sound effect.
*/
native(264) final function int PlaySound
(
	sound				Sound,
#if !IG_EFFECTS
	optional ESoundSlot Slot,
#endif
	optional float		Volume,
	optional bool		bNoOverride,
#if IG_EFFECTS
	optional float		InnerRadius,
	optional float		OuterRadius,
#else
	optional float		Radius,
#endif
	optional float		Pitch,
#if IG_EFFECTS
	optional int       	Flags,
    optional float      FadeInTime,
#endif
	optional bool		        Attenuate,
    optional float              AISoundRadius,
    optional Name               SoundCategory
);

/* play a sound effect, but don't propagate to a remote owner
 (he is playing the sound clientside)
 */
native simulated final function PlayOwnedSound
(
	sound				Sound,
#if !IG_EFFECTS
	optional ESoundSlot Slot,
#endif
	optional float		Volume,
	optional bool		bNoOverride,
#if IG_EFFECTS
	optional float		InnerRadius,
	optional float		OuterRadius,
#else
	optional float		Radius,
#endif
	optional float		Pitch,
#if IG_EFFECTS
    optional int        Flags,
    optional float      FadeInTime,
#endif
	optional bool		Attenuate
);

native simulated event DemoPlaySound
(
	sound				Sound,
#if !IG_EFFECTS
	optional ESoundSlot Slot,
#endif
	optional float		Volume,
	optional bool		bNoOverride,
#if IG_EFFECTS
	optional float		InnerRadius,
	optional float		OuterRadius,
#else
	optional float		Radius,
#endif
	optional float		Pitch,
#if IG_EFFECTS
        optional int		Flags,
        optional float      FadeInTime,
#endif
	optional bool		Attenuate
);

/* Get a sound duration.
*/
native final function float GetSoundDuration( sound Sound );

//=============================================================================
// Force Feedback.
// jdf ---
native(566) final function PlayFeedbackEffect( String EffectName );
native(567) final function StopFeedbackEffect( optional String EffectName ); // Pass no parameter or "" to stop all
native(568) final function bool ForceFeedbackSupported( optional bool Enable );
// --- jdf

//=============================================================================
// AI functions.

/* Inform other creatures that you've made a noise
 they might hear (they are sent a HearNoise message)
 Senders of MakeNoise should have an instigator if they are not pawns.
*/
native(512) final function MakeNoise( float Loudness );

/* PlayerCanSeeMe returns true if any player (server) or the local player (standalone
or client) has a line of sight to actor's location.
*/
native(532) final function bool PlayerCanSeeMe();

native final function vector SuggestFallVelocity(vector Destination, vector Start, float MaxZ, float MaxXYSpeed);

//=============================================================================
// Regular engine functions.

// Teleportation.
event bool PreTeleport( Teleporter InTeleporter );
event PostTeleport( Teleporter OutTeleporter );

// Level state.
event BeginPlay();

//========================================================================
// Disk access.

// Find files.
native(539) final function string GetMapName( string NameEnding, string MapName, int Dir );
native(545) final function GetNextSkin( string Prefix, string CurrentSkin, int Dir, out string SkinName, out string SkinDesc );
native(547) final function string GetURLMap();
native final function string GetNextInt( string ClassName, int Num );
native final function GetNextIntDesc( string ClassName, int Num, out string Entry, out string Description );
native final function bool GetCacheEntry( int Num, out string GUID, out string Filename );
native final function bool MoveCacheEntry( string GUID, optional string NewFilename );

//=============================================================================
// Iterator functions.

// Iterator functions for dealing with sets of actors.

/* AllActors() - avoid using AllActors() too often as it iterates through the whole actor list and is therefore slow
*/
native(304) final iterator function AllActors     ( class<object> BaseClass, out actor Actor, optional name MatchTag );

/* DynamicActors() only iterates through the non-static actors on the list (still relatively slow, bu
 much better than AllActors).  This should be used in most cases and replaces AllActors in most of
 Epic's game code.
*/
#if IG_SHARED //darren: permit iterating over Actors that implement an Interface
native(313) final iterator function DynamicActors     ( class<object> BaseClass, out actor Actor, optional name MatchTag );
#else
native(313) final iterator function DynamicActors     ( class<actor> BaseClass, out actor Actor, optional name MatchTag );
#endif

/* ChildActors() returns all actors owned by this actor.  Slow like AllActors()
*/
native(305) final iterator function ChildActors   ( class<actor> BaseClass, out actor Actor );

/* BasedActors() returns all actors based on the current actor (slow, like AllActors)
*/
native(306) final iterator function BasedActors   ( class<actor> BaseClass, out actor Actor );

/* TouchingActors() returns all actors touching the current actor (fast)
*/
native(307) final iterator function TouchingActors( class<actor> BaseClass, out actor Actor );

/* TraceActors() return all actors along a traced line.  Reasonably fast (like any trace)
*/
#if IG_SHARED //tcohen: added Material parameter. Pass HitMaterial=None to skip Material determination.

#if IG_MULTILINE_EXIT_RESULTS // Carlos: Added exit results
native(309) final iterator function TraceActors   ( class<actor> BaseClass, out actor Actor, out vector HitLoc, out vector HitNorm, out Material HitMaterial, vector End, optional vector Start, optional vector Extent, optional bool bSkeletalBoxTest, optional out ESkeletalRegion SkeletalRegionHit, optional bool bGetMaterial, optional bool bFindExitLocation, optional out Vector ExitLocation, optional out Vector ExitNormal, optional out Material ExitMaterial  );
#else //
native(309) final iterator function TraceActors   ( class<actor> BaseClass, out actor Actor, out vector HitLoc, out vector HitNorm, out Material HitMaterial, vector End, optional vector Start, optional vector Extent, optional bool bSkeletalBoxTest, optional out ESkeletalRegion SkeletalRegionHit, optional bool bGetMaterial  );
#endif // IG_MULTILINE_EXIT_RESULTS

#else
native(309) final iterator function TraceActors   ( class<actor> BaseClass, out actor Actor, out vector HitLoc, out vector HitNorm, vector End, optional vector Start, optional vector Extent );
#endif

/* RadiusActors() returns all actors within a give radius.  Slow like AllActors().  Use CollidingActors() or VisibleCollidingActors() instead if desired actor types are visible
(not bHidden) and in the collision hash (bCollideActors is true)
*/
#if IG_SHARED //tcohen: permit iterating over Actors that implement an Interface
native(310) final iterator function RadiusActors  ( class<object> BaseClass, out actor Actor, float Radius, optional vector Loc );
#else
native(310) final iterator function RadiusActors  ( class<actor> BaseClass, out actor Actor, float Radius, optional vector Loc );
#endif

/* VisibleActors() returns all visible actors within a radius.  Slow like AllActors().  Use VisibleCollidingActors() instead if desired actor types are
in the collision hash (bCollideActors is true)
*/
native(311) final iterator function VisibleActors ( class<actor> BaseClass, out actor Actor, optional float Radius, optional vector Loc );

/* VisibleCollidingActors() returns visible (not bHidden) colliding (bCollideActors==true) actors within a certain radius.
Much faster than AllActors() since it uses the collision hash
*/
#if IG_SHARED //tcohen: permit iterating over Actors that implement an Interface
native(312) final iterator function VisibleCollidingActors ( class<object> BaseClass, out object Actor, float Radius, optional vector Loc, optional bool bIgnoreHidden );
#else
native(312) final iterator function VisibleCollidingActors ( class<actor> BaseClass, out actor Actor, float Radius, optional vector Loc, optional bool bIgnoreHidden );
#endif

/* CollidingActors() returns colliding (bCollideActors==true) actors within a certain radius.
Much faster than AllActors() for reasonably small radii since it uses the collision hash
*/
native(321) final iterator function CollidingActors ( class<actor> BaseClass, out actor Actor, float Radius, optional vector Loc );

//=============================================================================
// Color functions
native(549) static final operator(20) color -     ( color A, color B );
native(550) static final operator(16) color *     ( float A, color B );
native(551) static final operator(20) color +     ( color A, color B );
native(552) static final operator(16) color *     ( color A, float B );

//=============================================================================
// Scripted Actor functions.

/* RenderOverlays()
called by player's hud to request drawing of actor specific overlays onto canvas
*/
function RenderOverlays(Canvas Canvas);


//=============================================================================
// Scripted Texture Support

// RenderTexture
// Called when this actor is expected to render into the texture
event RenderTexture(ScriptedTexture Tex);
#if IG_EXTERNAL_CAMERAS
// Called to notify this class that the scripted texture is being rendered, client has a chance to modify revision in this call to
// receive a RenderTexture call when it's time.
event PreScriptedTextureRendered(ScriptedTexture Tex);
#endif

//
// Called immediately before gameplay begins.
//
event PreBeginPlay()
{
	// Handle autodestruction if desired.
	if( !bGameRelevant && (Level.NetMode != NM_Client) && !Level.Game.BaseMutator.CheckRelevance(Self) )
		Destroy();
}

//
// Broadcast a localized message to all players.
// Most message deal with 0 to 2 related PRIs.
// The LocalMessage class defines how the PRI's and optional actor are used.
//
event BroadcastLocalizedMessage( class<LocalMessage> MessageClass, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	Level.Game.BroadcastLocalized( self, MessageClass, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
}

// Called immediately after gameplay begins.
//
#if IG_SHARED // carlos: allow spawned/alive events to play on MP clients
simulated event PostBeginPlay()
#else
event PostBeginPlay()
#endif
{
#if IG_EFFECTS
    //Please Note:
    //Actors that are spawned at zero, and whose real location are calculated later
    //  (eg. immediately attached to something else, like attached visual effects,)
    //  should TriggerEffectEvent('Spawned') after their location is set, or they
    //  are attached to their host.
    if (bNeedLifetimeEffectEvents && Location != vect(0,0,0))
    {
        TriggerEffectEvent('Spawned');
        TriggerEffectEvent('Alive');
    }
#endif
}

// Called after PostBeginPlay.
//
simulated event SetInitialState()
{
	bScriptInitialized = true;
	if( InitialState!='' )
		GotoState( InitialState );
	else
		GotoState( 'Auto' );
}

// called after PostBeginPlay.  On a net client, PostNetBeginPlay() is spawned after replicated variables have been initialized to
// their replicated values
event PostNetBeginPlay();

#if IG_SHARED // karl: called after savegame is loaded
event PostLoadGame();
#endif

#if IG_SHARED // tcohen: called after native AActor::PostEditChange()
event function PostEditChange();
#endif

simulated event UpdatePrecacheRenderData()
{
	local int i;
	for ( i=0; i<Skins.Length; i++ )
		Level.AddPrecacheMaterial(Skins[i]);

	if ( (DrawType == DT_StaticMesh) && !bStatic && !bNoDelete )
		Level.AddPrecacheStaticMesh(StaticMesh);

	if ( DrawType == DT_Mesh && Mesh != None)
		Level.AddPrecacheMesh(Mesh);
}

/* HurtRadius()
 Hurt locally authoritative actors within the radius.
*/
#if IG_SWAT
simulated function bool CanBeAffectedByHurtRadius()
{
    return true;
}
#endif

simulated final function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;

	if( bHurtEntry )
		return;

	bHurtEntry = true;
	foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
#if IG_SWAT
        if( (Victims != self) && Victims.CanBeAffectedByHurtRadius() )
#else
		if( (Victims != self) && (Victims.Role == ROLE_Authority) && (!Victims.IsA('FluidSurfaceInfo')) )
#endif // IG_SWAT
		{
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
			Victims.TakeDamage
			(
				damageScale * DamageAmount,
				Instigator,
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
				(damageScale * Momentum * dir),
				DamageType
			);
		}
	}
	bHurtEntry = false;
}

// Called when carried onto a new level, before AcceptInventory.
//
event TravelPreAccept();

// Called when carried into a new level, after AcceptInventory.
//
event TravelPostAccept();

// Called by PlayerController when this actor becomes its ViewTarget.
//
function BecomeViewTarget();

// Returns the string representation of the name of an object without the package
// prefixes.
//
function String GetItemName( string FullName )
{
	local int pos;

	pos = InStr(FullName, ".");
	While ( pos != -1 )
	{
		FullName = Right(FullName, Len(FullName) - pos - 1);
		pos = InStr(FullName, ".");
	}

	return FullName;
}

// Returns the human readable string representation of an object.
//
simulated function String GetHumanReadableName()
{
	return GetItemName(string(class));
}

final function ReplaceText(out string Text, string Replace, string With)
{
	local int i;
	local string Input;

	Input = Text;
	Text = "";
	i = InStr(Input, Replace);
	while(i != -1)
	{
		Text = Text $ Left(Input, i) $ With;
		Input = Mid(Input, i + Len(Replace));
		i = InStr(Input, Replace);
	}
	Text = Text $ Input;
}

// Set the display properties of an actor.  By setting them through this function, it allows
// the actor to modify other components (such as a Pawn's weapon) or to adjust the result
// based on other factors (such as a Pawn's other inventory wanting to affect the result)
function SetDisplayProperties(ERenderStyle NewStyle, Material NewTexture, bool bLighting )
{
	Style = NewStyle;
	texture = NewTexture;
	bUnlit = bLighting;
}

function SetDefaultDisplayProperties()
{
	Style = Default.Style;
	texture = Default.Texture;
	bUnlit = Default.bUnlit;
}

// Get localized message string associated with this actor
static function string GetLocalString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2
	)
{
	return "";
}

function MatchStarting(); // called when gameplay actually starts
function SetGRI(GameReplicationInfo GRI);

function String GetDebugName()
{
	return GetItemName(string(self));
}

/* DisplayDebug()
list important actor variable on canvas.  HUD will call DisplayDebug() on the current ViewTarget when
the ShowDebug exec is used
*/
simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	local string T;
	local float XL;
	local int i;
	local Actor A;
	local name anim;
	local float frame,rate;

	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.StrLen("TEST", XL, YL);
	YPos = YPos + YL;
	Canvas.SetPos(4,YPos);
	Canvas.SetDrawColor(255,0,0);
	T = GetDebugName();
	if ( bDeleteMe )
		T = T$" DELETED (bDeleteMe == true)";

	Canvas.DrawText(T, false);
	YPos += YL;
	Canvas.SetPos(4,YPos);
	Canvas.SetDrawColor(255,255,255);

	if ( Level.NetMode != NM_Standalone )
	{
		// networking attributes
		T = "ROLE ";
		Switch(Role)
		{
			case ROLE_None: T=T$"None"; break;
			case ROLE_DumbProxy: T=T$"DumbProxy"; break;
			case ROLE_SimulatedProxy: T=T$"SimulatedProxy"; break;
			case ROLE_AutonomousProxy: T=T$"AutonomousProxy"; break;
			case ROLE_Authority: T=T$"Authority"; break;
		}
		T = T$" REMOTE ROLE ";
		Switch(RemoteRole)
		{
			case ROLE_None: T=T$"None"; break;
			case ROLE_DumbProxy: T=T$"DumbProxy"; break;
			case ROLE_SimulatedProxy: T=T$"SimulatedProxy"; break;
			case ROLE_AutonomousProxy: T=T$"AutonomousProxy"; break;
			case ROLE_Authority: T=T$"Authority"; break;
		}
		if ( bTearOff )
			T = T$" Tear Off";
		Canvas.DrawText(T, false);
		YPos += YL;
		Canvas.SetPos(4,YPos);
	}
	T = "Physics ";
	Switch(PHYSICS)
	{
		case PHYS_None: T=T$"None"; break;
		case PHYS_Walking: T=T$"Walking"; break;
		case PHYS_Falling: T=T$"Falling"; break;
		case PHYS_Swimming: T=T$"Swimming"; break;
		case PHYS_Flying: T=T$"Flying"; break;
		case PHYS_Rotating: T=T$"Rotating"; break;
		case PHYS_Projectile: T=T$"Projectile"; break;
		case PHYS_Interpolating: T=T$"Interpolating"; break;
		case PHYS_MovingBrush: T=T$"MovingBrush"; break;
		case PHYS_Spider: T=T$"Spider"; break;
		case PHYS_Trailer: T=T$"Trailer"; break;
#if !IG_SWAT // ckline: we don't support this
		case PHYS_Ladder: T=T$"Ladder"; break;
#endif
#if IG_SHARED // Alex:
		case PHYS_Havok: T=T$"Havok"; break;
		#endif
	}
	T = T$" in physicsvolume "$GetItemName(string(PhysicsVolume))$" on base "$GetItemName(string(Base));
	if ( bBounce )
		T = T$" - will bounce";
	Canvas.DrawText(T, false);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	Canvas.DrawText("Location: "$Location$" Rotation "$Rotation, false);
	YPos += YL;
	Canvas.SetPos(4,YPos);
	Canvas.DrawText("Velocity: "$Velocity$" Speed "$VSize(Velocity), false);
	YPos += YL;
	Canvas.SetPos(4,YPos);
	Canvas.DrawText("Acceleration: "$Acceleration, false);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	Canvas.DrawColor.B = 0;
	Canvas.DrawText("Collision Radius "$CollisionRadius$" Height "$CollisionHeight);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	Canvas.DrawText("Collides with Actors "$bCollideActors$", world "$bCollideWorld$", proj. target "$bProjTarget);
	YPos += YL;
	Canvas.SetPos(4,YPos);
	Canvas.DrawText("Blocks Actors "$bBlockActors$", players "$bBlockPlayers);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	T = "Touching ";
	ForEach TouchingActors(class'Actor', A)
		T = T$GetItemName(string(A))$" ";
	if ( T == "Touching ")
		T = "Touching nothing";
	Canvas.DrawText(T, false);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	Canvas.DrawColor.R = 0;
	T = "Rendered: ";
	Switch(Style)
	{
		case STY_None: T=T; break;
		case STY_Normal: T=T$"Normal"; break;
		case STY_Masked: T=T$"Masked"; break;
		case STY_Translucent: T=T$"Translucent"; break;
		case STY_Modulated: T=T$"Modulated"; break;
		case STY_Alpha: T=T$"Alpha"; break;
	}

	Switch(DrawType)
	{
		case DT_None: T=T$" None"; break;
		case DT_Sprite: T=T$" Sprite "; break;
		case DT_Mesh: T=T$" Mesh "; break;
		case DT_Brush: T=T$" Brush "; break;
		case DT_RopeSprite: T=T$" RopeSprite "; break;
		case DT_VerticalSprite: T=T$" VerticalSprite "; break;
		case DT_Terraform: T=T$" Terraform "; break;
		case DT_SpriteAnimOnce: T=T$" SpriteAnimOnce "; break;
		case DT_StaticMesh: T=T$" StaticMesh "; break;
	}

	if ( DrawType == DT_Mesh )
	{
		T = T$GetItemName(string(Mesh));
		if ( Skins.length > 0 )
		{
			T = T$" skins: ";
			for ( i=0; i<Skins.length; i++ )
			{
				if ( skins[i] == None )
					break;
				else
					T =T$GetItemName(string(skins[i]))$", ";
			}
		}

		Canvas.DrawText(T, false);
		YPos += YL;
		Canvas.SetPos(4,YPos);

		// mesh animation
		GetAnimParams(0,Anim,frame,rate);
		T = "AnimSequence "$Anim$" Frame "$frame$" Rate "$rate;
		if ( bAnimByOwner )
			T= T$" Anim by Owner";
	}
	else if ( (DrawType == DT_Sprite) || (DrawType == DT_SpriteAnimOnce) )
		T = T$Texture;
	else if ( DrawType == DT_Brush )
		T = T$Brush;

	Canvas.DrawText(T, false);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	Canvas.DrawColor.B = 255;
	Canvas.DrawText("Tag: "$Tag$" Event: "$Event$" STATE: "$GetStateName(), false);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	Canvas.DrawText("Instigator "$GetItemName(string(Instigator))$" Owner "$GetItemName(string(Owner)));
	YPos += YL;
	Canvas.SetPos(4,YPos);

#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
	Canvas.DrawText("Timer: "$TimerCounter$" LifeSpan "$LifeSpan$" AmbientSound "$AmbientSound);
#else
	Canvas.DrawText("Timer: "$TimerCounter$" LifeSpan "$LifeSpan);
#endif
	YPos += YL;
	Canvas.SetPos(4,YPos);
}

// NearSpot() returns true is spot is within collision cylinder
simulated final function bool NearSpot(vector Spot)
{
	local vector Dir;

	Dir = Location - Spot;

	if ( abs(Dir.Z) > CollisionHeight )
		return false;

	Dir.Z = 0;
	return ( VSize(Dir) <= CollisionRadius );
}

simulated final function bool TouchingActor(Actor A)
{
	local vector Dir;

	Dir = Location - A.Location;

	if ( abs(Dir.Z) > CollisionHeight + A.CollisionHeight )
		return false;

	Dir.Z = 0;
	return ( VSize(Dir) <= CollisionRadius + A.CollisionRadius );
}

/* StartInterpolation()
when this function is called, the actor will start moving along an interpolation path
beginning at Dest
*/
simulated function StartInterpolation()
{
	GotoState('');
	SetCollision(True,false,false);
	bCollideWorld = False;
	bInterpolating = true;
	SetPhysics(PHYS_None);
}

/* Reset()
reset actor to initial state - used when restarting level without reloading.
*/
function Reset();

/*
Trigger an event
*/
event TriggerEvent( Name EventName, Actor Other, Pawn EventInstigator )
{
	local Actor A;

	if ( EventName == '' )
		return;

	ForEach DynamicActors( class 'Actor', A, EventName )
    {
#if IG_EFFECTS
        A.PreTrigger(Other, EventInstigator);
#endif
		A.Trigger(Other, EventInstigator);
}
}

/*
Untrigger an event
*/
function UntriggerEvent( Name EventName, Actor Other, Pawn EventInstigator )
{
	local Actor A;

	if ( EventName == '' )
		return;

	ForEach DynamicActors( class 'Actor', A, EventName )
		A.Untrigger(Other, EventInstigator);
}

function bool IsInVolume(Volume aVolume)
{
	local Volume V;

	ForEach TouchingActors(class'Volume',V)
		if ( V == aVolume )
			return true;
	return false;
}

function bool IsInPain()
{
	local PhysicsVolume V;

	ForEach TouchingActors(class'PhysicsVolume',V)
		if ( V.bPainCausing && (V.DamagePerSec > 0) )
			return true;
	return false;
}

function PlayTeleportEffect(bool bOut, bool bSound);

function bool CanSplash()
{
	return false;
}

function vector GetCollisionExtent()
{
	local vector Extent;

	Extent = CollisionRadius * vect(1,1,0);
	Extent.Z = CollisionHeight;
	return Extent;
}

simulated function bool EffectIsRelevant(vector SpawnLocation, bool bForceDedicated )
{
	local PlayerController P;
	local bool bResult;

	if ( Level.NetMode == NM_DedicatedServer )
		bResult = bForceDedicated;
	else if ( Level.NetMode == NM_Client )
		bResult = true;
	else if ( (Instigator != None) && Instigator.IsHumanControlled() )
		bResult =  true;
	else if ( SpawnLocation == Location )
		bResult = ( Level.TimeSeconds - LastRenderTime < 3 );
	else if ( (Instigator != None) && (Level.TimeSeconds - Instigator.LastRenderTime < 3) )
		bResult = true;
	else
	{
		P = Level.GetLocalPlayerController();
		if ( P == None )
			bResult = false;
		else
			bResult = ( (Vector(P.Rotation) Dot (SpawnLocation - P.ViewTarget.Location)) > 0.0 );
	}
	return bResult;
}

#if IG_SWAT
// returns the location that the animation system will use to aim at (instead of always aiming at the root location)
// - it does default in Actor to the root location
native function vector GetAimLocation(HandheldEquipment WeaponToAim);

// returns the location that the animation system will use to look at (instead of always looking at the root location)
// - it does default in Actor to the root location
native function vector GetLookLocation();

// returns the location that any AIs will use to fire at (instead of always firing at the root or aim location)
// - it does default in Actor to the root location
native function vector GetFireLocation(HandheldEquipment WeaponToFire);
#endif

#if IG_RWO // tcohen: Reactive World Objects
simulated function BroadcastReactToTriggered( Actor Other )
{
    local Controller Itr;
    local String UniqueIdentifier;
    local PlayerController LPC;

    UniqueIdentifier = UniqueID();

    LPC = Level.GetLocalPlayerController();

    Itr = Level.ControllerList;
    while ( Itr != None ) // Walk the controller list
    {
        if( Itr.IsA( 'PlayerController' ) && Itr != LPC )
            PlayerController(Itr).ClientBroadcastReactToTriggered( UniqueIdentifier, Other );
        Itr = Itr.NextController;
    }

    ReactToTriggered( Other );
}

simulated function BroadcastReactToUsed( Actor Other )
{
    local Controller Itr;
    local String UniqueIdentifier;
    local PlayerController LPC;

    UniqueIdentifier = UniqueID();

    LPC = Level.GetLocalPlayerController();

    Itr = Level.ControllerList;
    while ( Itr != None ) // Walk the controller list
    {
        if( Itr.IsA( 'PlayerController' ) && Itr != LPC )
            PlayerController(Itr).ClientBroadcastReactToUsed( UniqueIdentifier, Other );
        Itr = Itr.NextController;
    }

    ReactToUsed( Other );
}

simulated function ReactToTriggered(Actor Other);
simulated function ReactToUsed(Actor Other);
#endif // IG_RWO

#if IG_EFFECTS
// Register for notification that gameplay has started
simulated final function RegisterNotifyGameStarted() { Level.InternalRegisterNotifyGameStarted(self); }
// Callback when gameplay has started
simulated function OnGameStarted();

simulated function AddPersistentEffectContext(name Context)
{
    Level.EffectsSystem.AddPersistentContext(Context);
}

simulated function RemovePersistentEffectContext(name Context)
{
    Level.EffectsSystem.RemovePersistentContext(Context);
}

// Add a context to be considered for the _next_ TriggerEffectEvent().
//
// WARNING: Caller should _always_ TriggerEffectEvent() after adding
//          contexts.  Failure to do so may adversely affect the next
//          call to TriggerEffectEvent().
simulated function AddContextForNextEffectEvent(name Context)
{
    Level.EffectsSystem.AddContextForNextEffectEvent(Context);
}

// Set the seed to be used for the _next_ TriggerEffectEvent().
simulated function SetSeedForNextEffectEvent( int Seed )
{
    Level.EffectsSystem.SetSeedForNextEffectEvent(Seed);
}

// Broadcasts the given sound effect specification to all clients.  Avoids matching
simulated function BroadcastSoundEffectSpecification( name EffectSpecification,
                                                      Actor Source,
                                                      optional Actor Target,
                                                      optional Material Material,
                                                      optional vector overrideWorldLocation,
                                                      optional rotator overrideWorldRotation,
                                                      optional IEffectObserver Observer )
{
    if ( Level.NetMode != NM_Standalone )
    {
        Level.GetGameReplicationInfo().ServerBroadcastSoundEffectSpecification( EffectSpecification, Source, Target, material, overrideWorldLocation, overrideWorldRotation, Observer );
    }
}

// In MP this will broadcast the trigger effect event call to every client, including the server.
// In standalone, behaves exactly the same way as a TriggerEffectEvent call.
// Needs access to the LocalPlayerController() to send the RPC, so will have to be looked at again when we add dedicated servers.
simulated function BroadcastEffectEvent( name EffectEvent,
                                           optional Actor Other,
                                           optional Material TargetMaterial,
                                           optional Vector HitLocation,
                                           optional Rotator HitNormal,
                                           optional bool PlayOnOther,
                                           optional bool QueryOnly,
                                           optional IEffectObserver Observer,
                                           optional name ReferenceTag)
{
    if ( Level.NetMode != NM_Standalone )
    {
        Level.GetGameReplicationInfo().ServerBroadcastEffectEvent( Self, UniqueID(), EffectEvent, Other, TargetMaterial, HitLocation, HitNormal, PlayOnOther, QueryOnly, Observer, ReferenceTag );
    } else
    {
        TriggerEffectEvent( EffectEvent, Other, TargetMaterial, HitLocation, HitNormal, PlayOnOther, QueryOnly, Observer, ReferenceTag );
    }
}

//returns True iff any effect event responses match the effect event that occurred.
simulated event bool TriggerEffectEvent(
    name EffectEvent,                   // The name of the effect event to trigger.  Should be a verb in past tense, eg. 'Landed'.
    // -- Optional Parameters --        // -- Optional Parameters --
    optional Actor Other,               // The "other" Actor involved in the effect event, if any.
    optional Material TargetMaterial,   // The Material involved in the effect event, eg. the matterial that a 'BulletHit'.
    optional vector HitLocation,        // The location in world-space (if any) at which the effect event occurred.
    optional rotator HitNormal,         // The normal to the involved surface (if any) at the HitLocation.
    optional bool PlayOnOther,          // If true, then any effects played will be associated with Other rather than Self.
    optional bool QueryOnly,            // If true, then don't actually play any effects.
                                        //   _True_ is still returned iff any responses matched the effect event.
                                        //   This can be used to determine if there are any effects associated with a particular effect event,
                                        //   without actually responding to the effect event.
    optional IEffectObserver Observer,  // Optional Observer that gets callbacks when effects are started and stopped.
                                        // Useful when you want to edit an effect dynamically
    optional name ReferenceTag,         // If ReferenceTag is not passed (or is ''), then Other.Tag is used instead
										//   when matching event triggers to responses.
    optional name SkipSubsystemWithThisName) // If this is set, effects will not be triggered for any effects subsystem whose class name matches this name
{
    if( !ReadyToTriggerEffectEvents() )
        return false;

    if (Level.HasGameStarted() || bTriggerEffectEventsBeforeGameStarts)
    {
			//log("TriggerEffectEvent: EffectEvent("$EffectEvent$"), Other("$Other$"), Observer("$Observer$"), ReferenceTag("$ReferenceTag$")");
		return Level.EffectsSystem.EffectEventTriggered(
                self,
                EffectEvent,
                Other,
                TargetMaterial,
                HitLocation,
                HitNormal,
                false,
                PlayOnOther,
                QueryOnly,
                Observer,
                ReferenceTag,
                SkipSubsystemWithThisName);
    }
    else
    {
        return false;   //we don't want to trigger effect events before the game starts
    }
}


// In MP this will broadcast the trigger effect event call to every client, including the server.
// In standalone, behaves exactly the same way as a TriggerEffectEvent call.
// Needs access to the LocalPlayerController() to send the RPC, so will have to be looked at again when we add dedicated servers.
simulated function BroadcastUnTriggerEffectEvent( name EffectEvent,
                                           optional name ReferenceTag)
{
    if ( Level.NetMode != NM_Standalone )
    {
        Level.GetGameReplicationInfo().ServerBroadcastUnTriggerEffectEvent( Self, UniqueID(), EffectEvent, ReferenceTag );
    } else
    {
        UnTriggerEffectEvent( EffectEvent, ReferenceTag );
    }
}

simulated event UnTriggerEffectEvent(name EffectEvent,optional name ReferenceTag)
{
    Level.EffectsSystem.EffectEventTriggered(
            self, EffectEvent,,,,,true,,,,ReferenceTag);  //untriggered
}

//gets called before Trigger()
simulated final function PreTrigger( Actor Other, Pawn EventInstigator )
{
    TriggerEffectEvent('Triggered');
}

simulated function bool ReadyToTriggerEffectEvents()
{
    return true;
}
#endif // IG_EFFECTS

#if IG_SHARED  //tcohen (by ckline): get a material on a mesh
// Retrieves a reference to the 'active' material at the specified index. First
// the actor is checked for an instance-specific material at the given
// index in the Skins array; if this is not null then it is returned. Next the
// default materials are checked. If there is not valid
// instance-specific or default material at the given Index, then
// None is returned.
// This method handles objects that are DrawType DT_Mesh and DT_StaticMesh,
// but not other drawtypes.
native final event Material GetCurrentMaterial(optional int Index); //defaults to 0
#endif

#if IG_SWAT // ckline
// Sets the actor's skins to its materials.
//
// If ShouldNotOverwriteExistingSkins is true (default is false) then will
// not copy over an existing skin.
native final event CopyMaterialsToSkins(optional bool ShouldNotOverwriteExistingSkins /* = false */);
#endif

#if IG_SCRIPTING // david:
// onMessage
event function onMessage(Message msg);

// registerMessage
// Convenience function
// triggeredByFilter is a comma-separated list of actor labels
function registerMessage(class<Message> messageClass, coerce string triggeredByFilter)
{
    // registerReceiver will not register the receiver if triggeredByFilter is equivalent of NAME_None
    AssertWithDescription(triggeredByFilter != "None" && triggeredByFilter != "", "triggeredByFilter with value of '"$triggeredByFilter$"' was passed by "$Name$" to RegisterMessage("$messageClass$")");
	Level.messageDispatcher.registerReceiver(self, messageClass, triggeredByFilter);
}

// registerClientMessage
// The message could potentially be receieved on both a server and a net client
// (Most messages should have no need to be client-side)
// triggeredByFilter is a comma-separated list of actor labels
simulated function registerClientMessage(class<Message> messageClass, coerce string triggeredByFilter)
{
    // registerReceiver will not register the receiver if triggeredByFilter is equivalent of NAME_None
    AssertWithDescription(triggeredByFilter != "None" && triggeredByFilter != "", "triggeredByFilter with value of '"$triggeredByFilter$"' was passed by "$Name$" to RegisterClientMessage("$messageClass$")");
	Level.messageDispatcher.registerReceiver(self, messageClass, triggeredByFilter);
}

// dispatchMessage
// Convenience function
function dispatchMessage(Message msg)
{
	Level.messageDispatcher.dispatch(self, msg);
}

// clientDispatchMessage
// The message could potentially be dispatched on both a server and a net client
simulated function clientDispatchMessage(Message msg)
{
	Level.messageDispatcher.dispatch(self, msg);
}
#endif // IG_SCRIPTING

#if IG_SWAT
// returns the center of the render bounding box, in world space
native event vector GetRenderBoundingBoxCenter();
#endif

#if IG_SHARED // ckline: Used by effects system, but could also be of general use

// OptimizeOut: makes this actor as lightweight and optimal as possible by making sure it's not rendered, or ticked
final function OptimizeOut()
{
	// Hide the actor
    bHidden = true;

    // Make the actor not get ticked
    SetPhysics(PHYS_None);
    bStasis = true;

    OnOptimizedOut();
}

// OptimizedIn: returns from an OptimizedOut state, which resets the values back to defaults (Note: maybe they should be backed up from the last optimized out call)
final function OptimizeIn()
{
	// Show the actor.
    bHidden = Default.bHidden;

    // Make the actor receive ticks again
    SetPhysics(Default.Physics);
    bStasis = Default.bStasis;

	// Allow subclasses to hook into this.
    OnOptimizedIn();
}
simulated function OnOptimizedOut();      // Notification we've been optimized out
simulated function OnOptimizedIn();       // Notification we've been optimized in

// Make an actor hidden, and stop it from ticking.
// Note: it is not an error to hide something that is already hidden
final function Hide()
{
	// Hide the actor
    bHidden = true;
    OnHidden();
}
// Allow subclasses to implement additional functionality when an actor gets a Hide() call
function OnHidden();

// Un-hide an actor that was previously hidden via Hide()
// Note: it is not an error to show something that is not hidden.
final function Show()
{
	// Show the actor.
    bHidden = false;
    OnShown();
}

// Allow subclasses to implement additional functionality when an actor gets a Show() call
function OnShown();

#endif // IG_SHARED

#if IG_SWAT
//subclasses can modify the way their MomentumToPenetrate is calculated, eg. StaticMeshActors do this
simulated function float GetMomentumToPenetrate(vector HitLocation, vector HitNormal, Material MaterialHit)
{
    if (MaterialHit != None)
        return MaterialHit.MomentumToPenetrate;
    else // sometimes people accidentally pass None because they hit LevelInfo (e.g., bsp)
        return class'Material'.Default.MomentumToPenetrate;
}

function bool CanBeUsed()
{
    return false;
}

//this refers to Epic's "Animation Sets" rather than SWAT's "Animation Sets"
simulated function LoadAnimationSets(array<string> AnimationSets, optional bool bDontLink )
{
    local int i;

    for (i=0; i<AnimationSets.length; ++i)
    {
    //log( self$"::LoadAnimationSets()... DLOing: "$AnimationSets[i] );
        AnimationSetReferences[i] = MeshAnimation(DynamicLoadObject(AnimationSets[i], class'MeshAnimation'));

        assertWithDescription(AnimationSetReferences[i] != None,
            "[tcohen] The AnimationSet at index "$i
            $" for the "$class.name
            $" class was specified as "$AnimationSets[i]
            $", but that is not a valid Animation Set for the specified Mesh ("$Mesh
            $").");

        if( bDontLink )
            continue;

    //log( self$"::LoadAnimationSets()... Linking: "$AnimationSetReferences[i] );
        LinkSkelAnim(AnimationSetReferences[i]);
    }
}

//implemented in terms of LoadAnimationSets()
simulated function LoadAnimationSet(string AnimationSet)
{
    local array<string> AnimationSets;

    AnimationSets[0] = AnimationSet;

    LoadAnimationSets(AnimationSets);
}
#endif // IG_SWAT

defaultproperties
{
     DrawType=DT_Sprite
     Texture=Texture'Engine_res.S_Actor'
     DrawScale=+00001.000000
	 MaxLights=8
//#if IG_CLAMP_DYNAMIC_LIGHTS
	 MaxDynamicLights=5
//#endif
	 DrawScale3D=(X=1,Y=1,Z=1)
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
//     SoundRadius=64
//     SoundVolume=128
//     SoundPitch=64
//#endif
     ScaleGlow=1.0
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
//	 TransientSoundVolume=0.3
//   TransientSoundRadius=300.0
//#endif
     CollisionRadius=+00022.000000
     CollisionHeight=+00022.000000
     bJustTeleported=True
     Mass=+00100.000000
     Role=ROLE_Authority
     RemoteRole=ROLE_DumbProxy
     NetPriority=+00001.000000
	 Style=STY_Normal
	 bMovable=True
	 bHighDetail=False
	 bSuperHighDetail=False
	 InitialState=None
	 NetUpdateFrequency=100
	 LODBias=1.0
	 MessageClass=class'LocalMessage'
	 bHiddenEdGroup=False
	 bBlockZeroExtentTraces=true
	 bBlockNonZeroExtentTraces=true
	 bReplicateMovement=true
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
//	 bScaleVolumeByLightBrightness = false
//#endif
	 CullDistance=0.0
	 bAcceptsProjectors=True
//#if IG_SHARED // ckline: selectively prevent actors from receiving ShadowProjector shadows
    bAcceptsShadowProjectors=true
//#endif
     bLightingVisibility=True
     StaticFilterState=FS_Maybe
     bUseDynamicLights=True

// #if IG_R // rowan:
	bCastsVolumetricShadows = false
	bVolumetricShadowCast = false
	BumpmapLODScale = 1
// #endif

// #if IG_SHARED
	MaxTraceDistance = 5000
// #endif

// #if IG_SHARED
    bOnlyAffectCurrentZone=false
// #endif

// #if IG_SHARED // ckline: notifications upon Pawn death and Actor destruction
	bSendDestructionNotification=false
// #endif

// #if IG_EFFECTS // rowan:
	bNeedLifetimeEffectEvents=true
// #endif
}
