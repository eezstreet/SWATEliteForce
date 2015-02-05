//=============================================================================
// xWeatherEffect 
// Copyright 2001 Digital Extremes - All Rights Reserved.
// Confidential.
//=============================================================================

class xWeatherEffect extends Actor
    native
    placeable;

//#exec Texture Import File=Textures\S_Wind.tga Name=S_Wind Mips=Off

struct native WeatherPcl
{
    var Vector	Pos;
    var Vector	Vel;
    var float	Life;
    var float	Size;
    var float   HitTime;
    var float	InvLifeSpan;
    var float   DistAtten;
    var byte	frame;
    var byte	Dummy1;
    var byte	Visible;
	var byte	Dummy2;
};

var() enum EWeatherType
{
    WT_Rain,
    WT_Snow,
    WT_Dust,
} WeatherType;

var() int               numParticles;
var transient int       numActive;
var transient Box		box;
var transient Vector    eyePos;
var transient Vector    eyeDir;
var transient Vector    spawnOrigin;
var transient Vector    eyeMoveVec;
var transient float     eyeVel;
var() float             deviation;

var() float             maxPclEyeDist;

var() float		        numCols;
var() float		        numRows;
var transient float		numFrames;
var transient float		texU;
var transient float		texV;

var transient bool      noReference;       // this effect isn't referenced by any volume

var Vector              spawnVecU;
var Vector              spawnVecV;
var() Vector            spawnVel;

var() RangeVector       Position;
var() Range             Speed;
var() Range             Life;
var() Range             Size;
var() Range             EyeSizeClamp;
var(Force) bool bForceAffected;

var transient array<WeatherPcl>	pcl;
var transient array<Volume>     pclBlockers;

defaultproperties
{
    Texture=S_Actor
    bHidden=false
    bHiddenEd=false
    Physics=PHYS_None
    bUnlit=true
    bNetTemporary=false
    bGameRelevant=true
    RemoteRole=ROLE_SimulatedProxy
    DrawType=DT_Particle
    Style=STY_Translucent

	DrawScale=4.000000
    maxPclEyeDist=590.0
    numCols=4.0
    numRows=4.0
    Position=(X=(Min=-300,Max=300),Y=(Min=-300,Max=300),Z=(Min=-100,Max=300))
    Speed=(Min=100,Max=200)
    Life=(Min=3,Max=4)
	WeatherType=WT_Snow
    Size=(Min=4,Max=5)
    deviation=0.4
    numParticles=1024
    spawnVel=(X=0.0,Y=0.0,Z=-1.0)
    bNoDelete=true
    bHighDetail=True
}