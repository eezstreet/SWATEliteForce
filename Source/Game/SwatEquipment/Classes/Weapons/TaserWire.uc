// Actor that models a single taser wire that is shot from a taser gun

class TaserWire extends Engine.Actor
    placeable; // NOTE: only placeable for tuning purposes!

var() name endEffectorName;  // the end bone in the wire's mesh (used to determine end point location)
var() float  minYZScale;     // the minimum scaling in the yz plane
var() float  maxYZScale;     // the maximum scaling in the yz plane

var private Vector initialDrawScale3D;
var private Vector initialSizeVec;
var private float  initialSize;
var private Vector startPos, endPos;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	initialDrawScale3D = DrawScale3D;
	initialSizeVec.X = 131;
	initialSizeVec.Y = 0;
	initialSizeVec.Z = 0;
	if (endEffectorName != '') {
		initialSizeVec = GetBoneCoords(endEffectorName, true).Origin - Location;
	}
	initialSize = VSize(initialSizeVec);
}

simulated function SetStartLocation(Vector start) 
{
	startPos = start;
}

simulated function SetEndLocation(Vector end) 
{
	endPos = end;
}

simulated function UpdateSpan() 
{
	local Vector diff;
	local Rotator rot;
	local Vector newScale;
	//local float  timeFraction, timeScale;
	local float scaleFraction, diffSize;

	local float rawTime, actualAnimRate;
	local name currentAnimation;

	GetAnimParams(0, currentAnimation, rawTime, actualAnimRate);

	//	log("taser wire anim: " $ currentAnimation @ string(rawTime));

	diff = endPos - startPos;
	diffSize = VSize(diff);
	scaleFraction = diffSize / initialSize;
	scaleFraction = FMax(scaleFraction, 0.01);
	newScale.X = initialDrawScale3D.X * scaleFraction;
				
	scaleFraction = FMin(scaleFraction, 1.0);
	scaleFraction = minYZScale + scaleFraction * (maxYZScale - minYZScale);
	newScale.Y = initialDrawScale3D.Y * scaleFraction;
	newScale.Z = initialDrawScale3D.Z * scaleFraction;
	SetDrawScale3D(newScale);
	//log("taser scale: " $ string(newScale));

	if (diffSize > 0.0) {
		rot = Rotator(diff);
		SetRotation(rot);
		// log("taser Rot: " $ string(rot));
	}

	//log("taser Pos: " $ string(startPos));
	SetLocation(startPos);
}

defaultproperties
{
	DrawType=DT_Mesh
	bStatic=false
	Mesh=SkeletalMesh'TaserWire.TaserWire'
	endEffectorName=TaserProng
	minYZScale=0.1
	maxYZScale=1.0
    RemoteRole=ROLE_None
}
