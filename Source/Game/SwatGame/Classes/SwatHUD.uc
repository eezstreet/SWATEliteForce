class SwatHUD extends Engine.HUD
    config(SwatGame)
    native
    dependson(AICoverFinder);

import enum EShowCoverInfoDetail from AICoverFinder;
import enum EFocusInterface from SwatGamePlayerController;

var config float CommandPositionX;  //Position on the screen in percent
var config float CommandPositionY;
var config int CommandTextureSizeX; //Dimensions of the command texture
var config int CommandTextureSizeY; //Dimensions of the command texture

var float ScaleX, ScaleY;
var bool bShowFocusDebug;           // if true, render name of player's focus

var Texture CommandClearTexture;
var Texture CommandFallInTexture;
var Texture CommandStackUpTexture;
var Texture CommandComplyTexture;

var private bool                bShowVisionCones;
var private bool				bShowAIMovementDebugInfo;
var private bool				bShowOfficerAIAssignmentsInfo;

var private bool                 bShowCoverInfo;
var private Pawn                 ShowCoverInfoPawn;
var private EShowCoverInfoDetail ShowCoverInfoDetail;

var private bool                 bShowAwarenessInfo;
var private AwarenessProxy       Awareness;

struct native DebugLine
{
    var vector EndA;
    var vector EndB;
    var color Color;
    var float Lifespan;
};
var private array<DebugLine> DebugLines;

struct native DebugCone
{
    var vector Origin;
    var vector Direction;
    var float Length;
    var float HalfAngle;
    var color Color;
    var float Lifespan;
};
var private array<DebugCone> DebugCones;

var private float LastTimeDebugShapesDrawn;

function PostBeginPlay()
{
    Super.PostBeginPlay();
}

function RenderToScale(Canvas C, Texture T)
{
    C.DrawTile(T, T.USize * ScaleX, T.VSize * ScaleY, 0, 0, T.USize, T.VSize);

    return;
}

function PostRender(Canvas C)
{
	// Need to call Super.PostRender() before checking the value of bHideHud
	// so that we can render Hands without rendering HUD
    Super.PostRender(C);

    if (bHideHud) return;
    
    ScaleX = C.SizeX / 1024.0;
    ScaleY = C.SizeY / 768.0;

    //TMC TODO implement in-game interface
    //RenderCommand(C);

    if (bShowFocusDebug) 
		DebugRenderPlayerInterfaces(C);

    return;
}



simulated event WorldSpaceOverlays()
{
    //if ( log( "bShowDebugInfo: " $ bShowDebugInfo );

    if ( bShowDebugInfo && Pawn(PlayerOwner.ViewTarget) != None )
    {
        DrawRoute();
    }

    if ( bShowVisionCones )
    {
        DrawVisionCones();
    }

	if (bShowAIMovementDebugInfo)
	{
		DrawDebugAIMovement();
	}

    if (bShowCoverInfo)
    {
        DrawDebugCover();
    }

    if (bShowAwarenessInfo)
    {
        DrawDebugAwareness();
    }

	if (bShowOfficerAIAssignmentsInfo)
	{
		DrawOfficerAIAssignmentsInfo();
	}

    DrawDebugShapes(self);
}


// Show & Hide Vision Cones
exec function ShowVC()
{
    bShowVisionCones = true;
    bHideHud = false;
}


exec function HideVC()
{
    bShowVisionCones = false;
}


function DrawVisionCones()
{
    local Pawn Iter;

    for(Iter = Level.PawnList; Iter != None; Iter = Iter.nextPawn)
    {
        if (Iter.IsA('SwatAI'))
        {
            SwatAI(Iter).DrawVisionCone(self);
        }
    }
}

exec function DebugAIMovement()
{
	bShowAIMovementDebugInfo = !bShowAIMovementDebugInfo;
    bHideHud = false;
}

exec function DebugAssignments()
{
	bShowOfficerAIAssignmentsInfo = !bShowOfficerAIAssignmentsInfo;
    bHideHud = false;
}

function DrawDebugAIMovement()
{
	local Pawn Iter;

    for(Iter = Level.PawnList; Iter != None; Iter = Iter.nextPawn)
    {
        if (Iter.IsA('SwatAI'))
        {
            SwatAI(Iter).DrawDebugAIMovement(self);
        }
    }
}

function DrawOfficerAIAssignmentsInfo()
{
	local Pawn Iter;

    for(Iter = Level.PawnList; Iter != None; Iter = Iter.nextPawn)
    {
        if (Iter.IsA('SwatOfficer'))
        {
            SwatOfficer(Iter).DrawLineToAssignment(self);
        }
    }
}

exec function DebugCover(string AINameString)
{
    bHideHud = false;
    DebugCoverInternal(AINameString);
}

exec function DebugCover2(string AINameString)
{
    bHideHud = false;
    if (DebugCoverInternal(AINameString))
    {
        ShowCoverInfoDetail = kSCID_IndividualExtrusions;
    }
}

exec function DebugCover3(string AINameString)
{
    bHideHud = false;
    if (DebugCoverInternal(AINameString))
    {
        ShowCoverInfoDetail = kSCID_IndividualInverseExtrusions;
    }
}

private function bool DebugCoverInternal(string AINameString)
{
    local Pawn Pawn;

    bShowCoverInfo = false;
    ShowCoverInfoPawn = None;
    ShowCoverInfoDetail = kSCID_PlaneAndExtrusionIntersection;

    if (AINameString != "")
    {
        foreach AllActors(class 'Pawn', Pawn)
        {
            if (Pawn.Name == Name(AINameString))
            {
                bShowCoverInfo = true;
                ShowCoverInfoPawn = Pawn;
                return true;
            }
        }
    }

    return false;
}

native function DrawDebugCover();

exec function DebugAwareness(string AINameString)
{
    local Pawn Pawn;
    local SwatAI SwatAI;

    bHideHud = false;
    bShowAwarenessInfo = false;
    Awareness = None;

    if (AINameString != "")
    {
        foreach AllActors(class 'Pawn', Pawn)
        {
            if (Pawn.Name == Name(AINameString))
            {
                SwatAI = SwatAI(Pawn);
                if (SwatAI != None)
                {
                    Awareness = SwatAI.GetAwareness();
                    bShowAwarenessInfo = true;
                }
                break;
            }
        }
    }
}

exec function DebugOfficerAwareness()
{
    bHideHud = false;
    bShowAwarenessInfo = true;
    Awareness = SwatAIRepository(Level.AIRepo).GetHive().GetAwareness();
}

private function DrawDebugAwareness()
{
    if (Awareness != None)
    {
        Awareness.DrawDebugInfo(self);
    }
}

exec function ToggleGUI()
{
	local PlayerController PC;

#if IG_THIS_IS_SHIPPING_VERSION
    if (Level.NetMode != NM_StandAlone)
        return;
#endif

	PC = Level.GetLocalPlayerController();

	PC.Player.GUIController.bHackDoNotRenderGUIPages = !PC.Player.GUIController.bHackDoNotRenderGUIPages;
	if (!PC.Player.GUIController.bHackDoNotRenderGUIPages)
	{
		Log("HIDING GUI");
	}
	else
	{
		Log("SHOWING GUI");
	}
}

exec function ToggleHUD()
{
#if IG_THIS_IS_SHIPPING_VERSION
    if (Level.NetMode != NM_StandAlone)
        return;
#endif

	bHideHud = !bHideHud;

    if (bHideHud)
	{
		Log("HIDING Heads-up Display");
	}
	else
	{
		Log("SHOWING Heads-up Display");
	}
}

exec function ShowFocus()
{
    bShowFocusDebug = !bShowFocusDebug;
    
    bHideHud = false;
}

function RenderCommand(Canvas canvas)
{
    local Texture It;
    
    //TMC TODO implement

	Canvas.bNoSmooth = False;
	Canvas.SetPos(
        CommandPositionX * (Canvas.ClipX - CommandTextureSizeX),
        CommandPositionY * (Canvas.ClipY - CommandTextureSizeY));
	Canvas.Style = ERenderStyle.STY_Alpha;
	Canvas.SetDrawColor(255,255,255);
	Canvas.DrawTile(
        It,
        CommandTextureSizeX, CommandTextureSizeY,
        0, 0,
        CommandTextureSizeX, CommandTextureSizeY);
	Canvas.bNoSmooth = True;
}

simulated function DebugRenderPlayerInterfaces(canvas Canvas)
{
    local SwatGamePlayerController PC;
    local int X, Y;
    local Actor Actor;
    local vector CameraLocation;
    local rotator CameraRotation;

    PC = SwatGamePlayerController(Level.GetLocalPlayerController());
    PC.CalcViewForFocus(Actor, CameraLocation, CameraRotation );
    
    if ( bShowFocusDebug )
    {
        Canvas.SetDrawColor(255,255,255);

        X = 20; Y = 50;

        PC.GetFocusInterface(Focus_Use).DrawDebugText(CameraLocation, Canvas, X, Y);
        PC.GetFocusInterface(Focus_Fire).DrawDebugText(CameraLocation, Canvas, X, Y);
        PC.GetCommandInterface().DrawDebugText(CameraLocation, Canvas, X, Y);
        PC.GetFocusInterface(Focus_LowReady).DrawDebugText(CameraLocation, Canvas, X, Y);
        if (Level.NetMode != NM_Standalone)
            PC.GetFocusInterface(Focus_PlayerTag).DrawDebugText(CameraLocation, Canvas, X, Y);
    }
}

function DrawDebugShapes(HUD DrawTarget)
{
    local int i;

    for (i = DebugLines.length - 1; i >= 0; --i)
    {
        DrawTarget.Draw3DLine(
                DebugLines[i].EndA, 
                DebugLines[i].EndB, 
                DebugLines[i].Color);
        if (DebugLines[i].Lifespan >= 0)
            DebugLines[i].Lifespan -= Level.TimeSeconds - LastTimeDebugShapesDrawn;
        if (DebugLines[i].Lifespan <= 0)
            RemoveDebugLine(i);
    }

    for (i = DebugCones.length - 1; i >= 0; --i)
    {
        DrawTarget.Draw3DCone(
                DebugCones[i].Origin, 
                DebugCones[i].Direction, 
                DebugCones[i].Length,
                DebugCones[i].HalfAngle,
                DebugCones[i].Color);
        if (DebugCones[i].Lifespan >= 0)
            DebugCones[i].Lifespan -= Level.TimeSeconds - LastTimeDebugShapesDrawn;
        if (DebugCones[i].Lifespan <= 0)
            RemoveDebugCone(i);
    }

    LastTimeDebugShapesDrawn = Level.TimeSeconds;
}

//returns the index of the line added
function int AddDebugLine(vector EndA, vector EndB, color Color, optional float Lifespan)
{
    local DebugLine Line;
    local int Index;

	bHideHud=false;

    Line.EndA = EndA;
    Line.EndB = EndB;
    Line.Color = Color;
    if (Lifespan > 0)
        Line.Lifespan = Lifespan;
    else
        Line.Lifespan = 10000;

    Index = DebugLines.length;
    DebugLines[Index] = Line;

    return Index;
}

function RemoveDebugLine(int Index)
{
    DebugLines.Remove(Index, 1);
}

exec function ClearDebugLines()
{
	DebugLines.Remove(0, DebugLines.Length);
}

//AddDebugBox is implemented in terms of AddDebugLine()
function AddDebugBox(vector Center, float Diameter, color Color, optional float Lifespan)
{
    local float HalfSize;
    local vector PointA, PointB;

    HalfSize = Diameter / 2.0;
    
    //from - - -
    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y -= HalfSize; PointA.Z -= HalfSize;
    PointB.X += HalfSize; PointB.Y -= HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y -= HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y += HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y -= HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y -= HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    //from + - +

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y -= HalfSize; PointA.Z += HalfSize;
    PointB.X -= HalfSize; PointB.Y -= HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y -= HalfSize; PointA.Z += HalfSize;
    PointB.X += HalfSize; PointB.Y += HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y -= HalfSize; PointA.Z += HalfSize;
    PointB.X += HalfSize; PointB.Y -= HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    //from + + -

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y += HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X += HalfSize; PointB.Y -= HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X += HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X += HalfSize; PointB.Y += HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    //from - + -

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X += HalfSize; PointB.Y += HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y -= HalfSize; PointB.Z -= HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);

    PointA = Center; PointB = Center;
    PointA.X -= HalfSize; PointA.Y += HalfSize; PointA.Z -= HalfSize;
    PointB.X -= HalfSize; PointB.Y += HalfSize; PointB.Z += HalfSize;
    AddDebugLine(PointA, PointB, Color, Lifespan);
}

//see comments on Draw3DCone
simulated function int AddDebugCone(
        vector Origin, vector Direction, 
        float Length, float HalfAngle, 
        Color Color, float Lifespan)
{
    local DebugCone Cone;
    local int Index;

	bHideHud=false;

    Cone.Origin = Origin;
    Cone.Direction = Direction;
    Cone.Length = Length;
    Cone.HalfAngle = HalfAngle;
    Cone.Color = Color;
    if (Lifespan > 0)
        Cone.Lifespan = Lifespan;
    else
        Cone.Lifespan = 10000;

    Index = DebugCones.length;
    DebugCones[Index] = Cone;

    return Index;
}

function RemoveDebugCone(int Index)
{
    DebugCones.Remove(Index, 1);
}

exec function ClearDebugCones()
{
	DebugCones.Remove(0, DebugCones.Length);
}

defaultproperties
{
    bHideHud=True
}
