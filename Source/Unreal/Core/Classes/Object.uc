//=============================================================================
// Object: The base class all objects.
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class Object
	native
	noexport;

//
// Shared codebase features
//
#define IG_SHARED 1

#define IG_THIS_IS_SHIPPING_VERSION 1
#define IG_SWAT_DISABLE_VISUAL_DEBUGGING 1 // *** should be same as IG_THIS_IS_SHIPPING_VERSION

#define IG_NATIVE_SIZE_CHECK 1
#define IG_UC_CONSTRUCTOR 1
#define IG_UC_ALLOCATOR 1
#define IG_UC_ACTOR_ALLOCATOR 1
#define IG_UC_THREADED 1
#define IG_UC_LATENT 1
#define IG_UC_LATENT_STACK_CLEANUP 0
#define IG_UC_CLASS_CONSTRUCTOR 1
#define IG_NOCOPY 1
#define IG_UC_FLAT_CATEGORIES 1
#define IG_R 1
#define IG_MOJO 0
#define WITH_KARMA 0
#define IG_SHADOWS 1
#define IG_BUMPMAP 1
#define IG_RENDERER 1
#define IG_CLAMP_DYNAMIC_LIGHTS 1 // henry: For reducing the popping effects of dynamic lights coming into view
#define IG_SHADER 1
#define IG_MACROTEX 1
#define IG_FOG 1
#define IG_ACTOR_GROUPING 1
#define IG_ACTOR_LABEL 1
#define IG_EFFECTS 1
#define IG_FLUID_VOLUME 1
#define IG_SCRIPTING 1
#define IG_AUTOTEST 1
#define IG_UDN_UTRACE_DEBUGGING 1
#define IG_GLOW 1
#define IG_DYNAMIC_SHADOW_DETAIL 1
#define IG_ZONECONSTRAINED_LIGHTS 1
#define IG_GUI_LAYOUT 1
#define IG_ACTOR_CONFIG 1
#define IG_ANIM_ADDITIVE_BLENDING 1
#define IG_ANIM_DYNAMIC_TWEENING 1
#define IG_EXTERNAL_CAMERAS 1
#define IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT 1
#define IG_PACKAGE_EFFECTS_CONFIG 1
#define IG_SPEED_HACK_PROTECTION 0
#define IG_CAPTIONS 1
#define IG_BINK_ROQ_INTERGRATION 1
//
// Features that are not in the shared codebase go below
//
#define IG_ALL_KNOWING_AIS 1
#define IG_SPEECH_RECOGNITION 1
#define IG_LEVEL_LOAD_ACTOR_CALLBACK 1
#define IG_BATTLEROOM 1
#define IG_RWO 1
#define IG_LEVELINFO_SUBCLASS 0
#define IG_SMOOTH_PHYSICS_STEPPING 1

// Define the following project-specific symbols to 0 so the script compiler
// won't warn about undefined symbols. These MUST stay as 0 in the shared engine.
#define IG_TRIBES3 0
#define IG_SWAT 1
#define IG_SWAT_OCCLUSION 1
#define IG_MULTILINE_EXIT_RESULTS 1

// SWAT-specific #defines

#define IG_SWAT_PROGRESS_BAR 1
#define IG_SWAT_AUDIT_FOCUS 1
#define IG_SWAT_INTERRUPT_STATE_SUPPORT 1
#define IG_SWAT_DEBUG_VISION 0
#define IG_SWAT_TESTING_MP_CI_IN_SP 0 //tcohen: testing MP CommandInterface behavior in SP
#define UGLY_RENDER_CORRUPTION_WORKAROUND 1
#define IG_ADCLIENT_INTEGRATION 1 // dbeswick: Massive AdClient integration

//demo version
#define IG_SWAT_SP_DEMO 0
#define IG_SWAT_MP_DEMO 0


//=============================================================================
// UObject variables.

// Internal variables.
var native private const int ObjectInternal[6];


var(Object) native const editconst object Outer;
var native const int ObjectFlags;
var(Object) native const editconst name Name;
var native const editconst class Class;

//=============================================================================
// Unreal base structures.

// Object flags.
const RF_Transactional	= 0x00000001; // Supports editor undo/redo.
const RF_Public         = 0x00000004; // Can be referenced by external package files.
const RF_Transient      = 0x00004000; // Can't be saved or loaded.
const RF_NotForClient	= 0x00100000; // Don't load for game client.
const RF_NotForServer	= 0x00200000; // Don't load for game server.
const RF_NotForEdit		= 0x00400000; // Don't load for editor.
#if IG_SHARED // david: added unnamed objects - objects have no name entry in the hash
const RF_Unnamed		= 0x08000000; // object has no name or FName hash entry
#endif

// A globally unique identifier.
struct Guid
{
	var int A, B, C, D;
};

// A point or direction vector in 3d space.
struct Vector
{
	var() config float X, Y, Z;
};

// A plane definition in 3d space.
struct Plane extends Vector
{
	var() config float W;
};

// An orthogonal rotation in 3d space.
struct Rotator
{
	var() config int Pitch, Yaw, Roll;
};

// An arbitrary coordinate system in 3d space.
struct Coords
{
	var() config vector Origin, XAxis, YAxis, ZAxis;
};

// Quaternion
struct Quat
{
	var() config float X, Y, Z, W;
};

// Used to generate random values between Min and Max
struct Range
{
	var() config float Min;
	var() config float Max;
};

#if IG_SHARED
// Used to generate random values between Min and Max
struct IntegerRange
{
	var() config int Min;
	var() config int Max;
};
#endif

// Vector of Ranges
struct RangeVector
{
	var() config range X;
	var() config range Y;
	var() config range Z;
};

// A scale and sheering.
struct Scale
{
	var() config vector Scale;
	var() config float SheerRate;
	var() config enum ESheerAxis
	{
		SHEER_None,
		SHEER_XY,
		SHEER_XZ,
		SHEER_YX,
		SHEER_YZ,
		SHEER_ZX,
		SHEER_ZY,
	} SheerAxis;
};

// Camera orientations for Matinee
enum ECamOrientation
{
	CAMORIENT_None,
	CAMORIENT_LookAtActor,
	CAMORIENT_FacePath,
	CAMORIENT_Interpolate,
	CAMORIENT_Dolly,
};

// Generic axis enum.
enum EAxis
{
	AXIS_X,
	AXIS_Y,
	AXIS_Z
};

// A color.
struct Color
{
	var() config byte B, G, R, A;
};

// A bounding box.
struct Box
{
	var vector Min, Max;
	var byte IsValid;
};

// A bounding box sphere together.
struct BoundingVolume extends Box
{
	var plane Sphere;
};

// a 4x4 matrix
struct Matrix
{
	var() Plane XPlane;
	var() Plane YPlane;
	var() Plane ZPlane;
	var() Plane WPlane;
};

// A interpolated function
struct InterpCurvePoint
{
	var() float InVal;
	var() float OutVal;
};

struct InterpCurve
{
	var() array<InterpCurvePoint>	Points;
};

struct CompressedPosition
{
	var vector Location;
	var rotator Rotation;
	var vector Velocity;
};

//=============================================================================
// Constants.

const MaxInt = 0x7fffffff;
const Pi     = 3.1415926535897932;

#if IG_SWAT

// These must be kept in-sync with the constants in UnMath.h

// DEGREES_TO_RADIANS = 2.0 * Pi / 360.0
const DEGREES_TO_RADIANS = 0.017453292519943295555555555555556;

// DEGREES_TO_TWOBYTE = 65536.0 / 360.0
const DEGREES_TO_TWOBYTE = 182.04444444444444444444444444444;

// TWOBYTE_TO_DEGREES = 360.0 / 65536.0
const TWOBYTE_TO_DEGREES = 0.0054931640625;

// TWOBYTE_TO_RADIANS = 2.0 * Pi / 65536.0
const TWOBYTE_TO_RADIANS = 0.000095873799242852;

// RADIANS_TO_TWOBYTE = 65536.0 / (2.0 * Pi)
const RADIANS_TO_TWOBYTE = 10430.37835047;

// RADIANS_TO_DEGREES = 360.0 / (2.0 * Pi)
const RADIANS_TO_DEGREES = 57.295779513;
#endif

//=============================================================================
// Basic native operators and functions.

// Bool operators.
native(129) static final preoperator  bool  !  ( bool A );
native(242) static final operator(24) bool  == ( bool A, bool B );
native(243) static final operator(26) bool  != ( bool A, bool B );
native(130) static final operator(30) bool  && ( bool A, skip bool B );
native(131) static final operator(30) bool  ^^ ( bool A, bool B );
native(132) static final operator(32) bool  || ( bool A, skip bool B );

// Byte operators.
native(133) static final operator(34) byte *= ( out byte A, byte B );
native(134) static final operator(34) byte /= ( out byte A, byte B );
native(135) static final operator(34) byte += ( out byte A, byte B );
native(136) static final operator(34) byte -= ( out byte A, byte B );
native(137) static final preoperator  byte ++ ( out byte A );
native(138) static final preoperator  byte -- ( out byte A );
native(139) static final postoperator byte ++ ( out byte A );
native(140) static final postoperator byte -- ( out byte A );

// Integer operators.
native(141) static final preoperator  int  ~  ( int A );
native(143) static final preoperator  int  -  ( int A );
native(144) static final operator(16) int  *  ( int A, int B );
native(145) static final operator(16) int  /  ( int A, int B );
native(146) static final operator(20) int  +  ( int A, int B );
native(147) static final operator(20) int  -  ( int A, int B );
native(148) static final operator(22) int  << ( int A, int B );
native(149) static final operator(22) int  >> ( int A, int B );
native(196) static final operator(22) int  >>>( int A, int B );
native(150) static final operator(24) bool <  ( int A, int B );
native(151) static final operator(24) bool >  ( int A, int B );
native(152) static final operator(24) bool <= ( int A, int B );
native(153) static final operator(24) bool >= ( int A, int B );
native(154) static final operator(24) bool == ( int A, int B );
native(155) static final operator(26) bool != ( int A, int B );
native(156) static final operator(28) int  &  ( int A, int B );
native(157) static final operator(28) int  ^  ( int A, int B );
native(158) static final operator(28) int  |  ( int A, int B );
native(159) static final operator(34) int  *= ( out int A, float B );
native(160) static final operator(34) int  /= ( out int A, float B );
native(161) static final operator(34) int  += ( out int A, int B );
native(162) static final operator(34) int  -= ( out int A, int B );
native(163) static final preoperator  int  ++ ( out int A );
native(164) static final preoperator  int  -- ( out int A );
native(165) static final postoperator int  ++ ( out int A );
native(166) static final postoperator int  -- ( out int A );

// Integer functions.
native(167) static final Function     int  Rand  ( int Max );
native(249) static final function     int  Min   ( int A, int B );
native(250) static final function     int  Max   ( int A, int B );
native(251) static final function     int  Clamp ( int V, int A, int B );

// Float operators.
native(169) static final preoperator  float -  ( float A );
native(170) static final operator(12) float ** ( float A, float B );
native(171) static final operator(16) float *  ( float A, float B );
native(172) static final operator(16) float /  ( float A, float B );
native(173) static final operator(18) float %  ( float A, float B );
native(174) static final operator(20) float +  ( float A, float B );
native(175) static final operator(20) float -  ( float A, float B );
native(176) static final operator(24) bool  <  ( float A, float B );
native(177) static final operator(24) bool  >  ( float A, float B );
native(178) static final operator(24) bool  <= ( float A, float B );
native(179) static final operator(24) bool  >= ( float A, float B );
native(180) static final operator(24) bool  == ( float A, float B );
native(210) static final operator(24) bool  ~= ( float A, float B );
native(181) static final operator(26) bool  != ( float A, float B );
native(182) static final operator(34) float *= ( out float A, float B );
native(183) static final operator(34) float /= ( out float A, float B );
native(184) static final operator(34) float += ( out float A, float B );
native(185) static final operator(34) float -= ( out float A, float B );

// Float functions.
native(186) static final function     float Abs   ( float A );
native(187) static final function     float Sin   ( float A );
native      static final function	  float Asin  ( float A );
native(188) static final function     float Cos   ( float A );
native      static final function     float Acos  ( float A );
native(189) static final function     float Tan   ( float A );
native(190) static final function     float Atan  ( float A, float B );
native(191) static final function     float Exp   ( float A );
native(192) static final function     float Loge  ( float A );
native(193) static final function     float Sqrt  ( float A );
native(194) static final function     float Square( float A );
native(195) static final function     float FRand ();
native(244) static final function     float FMin  ( float A, float B );
native(245) static final function     float FMax  ( float A, float B );
native(246) static final function     float FClamp( float V, float A, float B );
native(247) static final function     float Lerp  ( float Alpha, float A, float B );
native(248) static final function     float Smerp ( float Alpha, float A, float B );

// Vector operators.
native(211) static final preoperator  vector -     ( vector A );
native(212) static final operator(16) vector *     ( vector A, float B );
native(213) static final operator(16) vector *     ( float A, vector B );
native(296) static final operator(16) vector *     ( vector A, vector B );
native(214) static final operator(16) vector /     ( vector A, float B );
native(215) static final operator(20) vector +     ( vector A, vector B );
native(216) static final operator(20) vector -     ( vector A, vector B );
native(275) static final operator(22) vector <<    ( vector A, rotator B );
native(276) static final operator(22) vector >>    ( vector A, rotator B );
native(217) static final operator(24) bool   ==    ( vector A, vector B );
native(218) static final operator(26) bool   !=    ( vector A, vector B );
native(219) static final operator(16) float  Dot   ( vector A, vector B );
native(220) static final operator(16) vector Cross ( vector A, vector B );
native(221) static final operator(34) vector *=    ( out vector A, float B );
native(297) static final operator(34) vector *=    ( out vector A, vector B );
native(222) static final operator(34) vector /=    ( out vector A, float B );
native(223) static final operator(34) vector +=    ( out vector A, vector B );
native(224) static final operator(34) vector -=    ( out vector A, vector B );

// Vector functions.
native(225) static final function float  VSize  ( vector A );
native(226) static final function vector Normal ( vector A );
native(227) static final function        Invert ( out vector X, out vector Y, out vector Z );
native(252) static final function vector VRand  ( );
native(300) static final function vector MirrorVectorByNormal( vector Vect, vector Normal );
#if IG_SHARED
// marc: additional vector convenience functions
native(228) static final function float	 VSize2D( vector A );
native		static final function float  VSizeSquared( vector A );
native		static final function float  VSizeSquared2D( vector A );
native		static final function bool	 IsZero( vector A );
native		static final function bool	 IsNearlyZero( vector A );
// darren: distance and distance squared functions
native      static final function float  VDist( vector A, vector B );
native      static final function float  VDistSquared( vector A, vector B );
#endif

// Rotator operators and functions.
native(142) static final operator(24) bool ==     ( rotator A, rotator B );
native(203) static final operator(26) bool !=     ( rotator A, rotator B );
native(287) static final operator(16) rotator *   ( rotator A, float    B );
native(288) static final operator(16) rotator *   ( float    A, rotator B );
native(289) static final operator(16) rotator /   ( rotator A, float    B );
native(290) static final operator(34) rotator *=  ( out rotator A, float B  );
native(291) static final operator(34) rotator /=  ( out rotator A, float B  );
native(316) static final operator(20) rotator +   ( rotator A, rotator B );
native(317) static final operator(20) rotator -   ( rotator A, rotator B );
native(318) static final operator(34) rotator +=  ( out rotator A, rotator B );
native(319) static final operator(34) rotator -=  ( out rotator A, rotator B );
native(229) static final function GetAxes         ( rotator A, out vector X, out vector Y, out vector Z );
native(230) static final function GetUnAxes       ( rotator A, out vector X, out vector Y, out vector Z );
native(320) static final function rotator RotRand ( optional bool bRoll );
native      static final function rotator OrthoRotation( vector X, vector Y, vector Z );
native      static final function rotator Normalize( rotator Rot );
native		static final operator(24) bool ClockwiseFrom( int A, int B );

#if IG_SHARED
// rotator inverse function [crombie]
native		static final function rotator Inverse  ( rotator A );
// lerp between two rotators [darren]
native      static final function rotator RotatorLerp(rotator A, rotator B, float Alpha);
#endif

// String operators.
//  Convert-to-string operators
native(112) static final operator(40) string $  ( coerce string A, coerce string B );
native(168) static final operator(40) string @  ( coerce string A, coerce string B );
//  Case-sensitive string comparisons (equivalent to appStrcmp operations)
native(115) static final operator(24) bool   <  ( string A, string B );
native(116) static final operator(24) bool   >  ( string A, string B );
native(120) static final operator(24) bool   <= ( string A, string B );
native(121) static final operator(24) bool   >= ( string A, string B );
native(122) static final operator(24) bool   == ( string A, string B );
native(123) static final operator(26) bool   != ( string A, string B );
//  Case-INSENSITIVE string comparison '~=' (equivalent to appStricmp)
native(124) static final operator(24) bool   ~= ( string A, string B );

// String functions.
native(125) static final function int    Len    ( coerce string S );
native(126) static final function int    InStr  ( coerce string S, coerce string t );
native(127) static final function string Mid    ( coerce string S, int i, optional int j );
native(128) static final function string Left   ( coerce string S, int i );
native(234) static final function string Right  ( coerce string S, int i );
native(235) static final function string Caps   ( coerce string S );
#if IG_SHARED
native      static final function string Lower  ( coerce string S );
native(202) static final function string Repl	( coerce string Src, coerce string Match, coerce string With, optional bool bCaseSensitive );
native(400) static final function int    Split  ( coerce string Src, string Divider, out array<string> Parts );
#endif
native(236) static final function string Chr    ( int i );
native(237) static final function int    Asc    ( string S );

static function String FormatTextString( string Format, optional coerce string Param1, optional coerce string Param2, optional coerce string Param3)
{
    Format = ReplaceExpression( Format, "%1", Param1 );
    Format = ReplaceExpression( Format, "%2", Param2 );
    Format = ReplaceExpression( Format, "%3", Param3 );

    return Format;
}

static function string GetFirstField( out string In, string Seperator )
{
    local int Index;
    local string RetStr;

    Index = InStr( In, Seperator );
    if( Index >= 0 )
    {
        RetStr = Left( In, Index );
        In = Right( In, len(In) - (len(Seperator) + Index));
    }
    else
    {
        RetStr = In;
        In = "";
    }
    return RetStr;
}

static function string ReplaceExpression( string In, string Expression, string Replace )
{
    local int Index;
    Index = InStr( In, Expression );
    if( Index >= 0 )
        return Left( In, Index ) $ Replace $ Right( In, Len(In) - (Index+Len(Expression)) );
    else
        return In;
}

// Object operators.
native(114) static final operator(24) bool == ( Object A, Object B );
native(119) static final operator(26) bool != ( Object A, Object B );

// Name operators.
native(254) static final operator(24) bool == ( name A, name B );
native(255) static final operator(26) bool != ( name A, name B );

// InterpCurve operator
native		static final function float InterpCurveEval( InterpCurve curve, float input );
native		static final function InterpCurveGetOutputRange( InterpCurve curve, out float min, out float max );
native		static final function InterpCurveGetInputDomain( InterpCurve curve, out float min, out float max );

// Quaternion functions
native		static final function Quat QuatProduct( Quat A, Quat B );
native		static final function Quat QuatInvert( Quat A );
native		static final function vector QuatRotateVector( Quat A, vector B );
native		static final function Quat QuatFindBetween( Vector A, Vector B );
native		static final function Quat QuatFromAxisAndAngle( Vector Axis, Float Angle );
native		static final function Quat QuatFromRotator( rotator A );
native		static final function rotator QuatToRotator( Quat A );
native      static final function Quat QuatSlerp(Quat A, Quat B, float Alpha);

//=============================================================================
// General functions.

#if IG_UC_ALLOCATOR // karl: Added Allocator
// Called by new operator (on the default object of a particular class).
// Allocates and returns an object of that class.
native static function Object Allocate( Object Context,				// auto parameter, calling object
										optional Object Outer,		// override outer object
										optional string n,			// override name of new object
										optional INT flags,			// flags for new object
										optional Object Template	// copy from this object
										 );
#endif

// Logging.
 native(231) final static function Log( coerce string S, optional name Tag );
#if IG_SWAT //tcohen: support for multiplayer-only logs
native final static function MPLog( coerce string S, optional name Tag );
#endif
#if IG_SHARED
// Writes the stack of guard/unguard blocks to the log file.
// IG_LOG_GUARD_STACK must be enabled in IrrationalBuild.h [darren]
native final static function LogGuardStack();
#endif
native(232) final static function Warn( coerce string S );
native static function string Localize( string SectionName, string KeyName, string PackageName );
#if IG_SCRIPTING // Ryan: Separate log for scripting logs
native static function bool CanSLog();
native static function SLog(coerce string msg);
#endif // IG
#if IG_AUTOTEST // Mathi: Separate log for automated test results
native static function ATLog(coerce string msg);
#endif // IG

#if IG_UDN_UTRACE_DEBUGGING // ckline: UDN UTrace code
native static final function SetUTracing( bool bNewUTracing );
native static final function bool IsUTracing();
#endif

#if IG_SWAT // tcohen: debug sentinel
//How to use a DebugSentinel:
//  Say you want to debug one specific call to a native function from script,
//      but the function is called a million times elsewhere.
//  Solution: call DebugSentinel() just before the call you're interested in.
//      Then put a breakpoint in UObject::execDebugSentinel().  If/When
//      you break at the DebugSentinel, then set another breakpoint
//      in the function you're interested in.  Continue the program,
//      and voila.
//NOTE: Please DO NOT submit code with DebugSentinel() calls... that would
//  dramatically reduce the effectiveness of the technique.  Thanks!
native final function DebugSentinel();
#endif

// Goto state and label.
native(113) final function GotoState( optional name NewState, optional name Label );
native(281) final function bool IsInState( name TestState );
native(284) final function name GetStateName();

#if IG_UC_THREADED // karl: Moved sleep to Object
native(256) final latent function Sleep( float Seconds );

// Force end to sleep
native final function StopWaiting();
#endif

// Objects.
native(258) static final function bool ClassIsChildOf( class TestClass, class ParentClass );
native(303) final function bool IsA( name ClassName );
#if IG_SHARED
native static final function class CommonBase(Array<class> classes);
#endif // IG

// Probe messages.
native(117) final function Enable( name ProbeFunc );
native(118) final function Disable( name ProbeFunc );

// Properties.
#if IG_SHARED // david: Get field names from a class
// Includes properties for super classes up to but not including "TerminatingSuperClass"
// 'None' returns all properties including those in class "Object"
native final iterator function AllProperties ( class FromClass, class TerminatingSuperClass, out Name PropName, optional out string PropType );
native final iterator function AllEditableProperties ( class FromClass, class TerminatingSuperClass, out Name PropName, optional out string PropType );
#endif
#if IG_SHARED // david: Get all classes of a given type
// Gets all classes of a given type
// Specify 'None' to return all registered classes
native final iterator function AllClasses ( class BaseClass, out class OutClass );
#endif
native final function string GetPropertyText( string PropName );
native final function SetPropertyText( string PropName, string PropValue );
native static final function name GetEnum( object E, int i );
native static final function object DynamicLoadObject( string ObjectName, class ObjectClass, optional bool MayFail );
#if IG_SHARED // david: Optional outer to find object in
native static final function object FindObject( string ObjectName, class ObjectClass, optional Object Outer );
#else
native static final function object FindObject( string ObjectName, class ObjectClass);
#endif

// Configuration.
native(536) final function SaveConfig(
#if IG_ACTOR_CONFIG || IG_GUI_LAYOUT //dkaplan - Update to allow config file and config section to be explicitly set
			optional string OverrideSectionName, optional string FileName
#endif
#if IG_SHARED // ckline
			, optional bool FlushToDisk // ckline: default = 1; if set to 0 .ini will not be written to disk (needed to speed up GUI Editor)
			, optional bool bDoNotSaveDefaults // dkaplan: default = 0; if set to 1 .ini will not write out properties which differ from the defaults
#endif
			);

native static final function StaticSaveConfig();

native static final function ResetConfig(
#if IG_ACTOR_CONFIG //no section header override if this is not defined
			optional string OverrideName, optional string FileName
#endif
			);

#if IG_SHARED // ckline: FlushConfig will force all .ini files in memory to be written to disk. Useful to call after making many calls to SaveConfig(..., FlushToDisk=0)
native final function FlushConfig();
#endif

// Return a random number within the given range.
native final function float RandRange( float Min, float Max );

#if IG_UC_CONSTRUCTOR // karl: Added constructors
overloaded function Construct();
#endif

#if IG_SHARED	// rowan: so we can call app seconds in script
native final function float AppSeconds();
#endif

#if IG_SHARED	// marc/ryan: for save games: NULL out all actor references
native final function NullReferences();
#endif

//=============================================================================
// Engine notification functions.

//
// Called immediately when entering a state, while within
// the GotoState call that caused the state change.
//
event BeginState();

//
// Called immediately before going out of the current state,
// while within the GotoState call that caused the state change.
//
event EndState();

#if IG_UC_CLASS_CONSTRUCTOR // karl: Added class constructor
// This function is reponsible for initializing the properties of classes at compile time.
// this function is called at compile time, after compilation of the package
// and after legacy default properties are processed.
// Note: Do not call super.ClassConstruct(), this is done automatically due to
//	legacy considerations
function ClassConstruct()
{
}
#endif

#if IG_SHARED
native static final function AssertWithDescription(bool expression, string description);
native static final function SetAssertWithDescriptionShouldUseDialog(bool expression);
native static final function object DynamicFindObject( string ObjectName, class ObjectClass );
native static final function Class GetSuperClass(Class derived);
native static final function int Hash(string Key, optional int Mod);
native static final function string ComputeMD5Checksum(string inString);

native final iterator function FileMatchingPattern(string Pattern, out string Filename);
#endif

#if IG_SWAT
native function int WrapAngle0To2Pi(int angle);
native function int WrapAngleNegPiToPi(int angle);

// Returns true iff the point specified by TestPoint is within the infinite
// cone specified by the following parameters:
//
// ConeOrigin: Point from which the cone originates
// ConeDirection: The direction of the central axis (centerline) of the cone
// TestPoint: the point in question
// FullAngleRadian: the full angle of the cone. That is, if
//     TestPoint is within (FullAngleRadians/2.0) radians on either side of the
//     line extending Origin in the direction specified by Facing, then this
//     function will return true.
native function bool PointWithinInfiniteCone(vector ConeOrigin, vector ConeDirection, vector TestPoint, float FullAngleRadians);

// dbeswick: patching; Get the build number
native static final function String GetBuildNumber();
native static final function String GetMinCompatibleBuildNumber();
#endif

defaultproperties
{
}
