class BattleRoomManager extends Engine.Actor;

#if IG_BATTLEROOM

var array<Pawn>     SelectedPawns;
var ColorModifier   ColorBar;
var GUIBattleRoom   GUIParent;
var Texture         PauseTex;
var Texture         BarTex;

function Open()
{
    GUIParent = SwatGamePlayerController(Owner).GetHudPage().BattleRoom;
    GUIParent.ScreenCanvas.OnClientDraw = RenderBattleRoom;
    GUIParent.ScreenCanvas.OnMouseRelease = ClickBattleRoom;
    //GUIParent.ScreenCanvas.OnRightClick = RightClickBattleRoom;
    GUIParent.FillOwner();
    GUIParent.Open();
}

function bool IsSelected(Pawn inPawn, out int index)
{
    local int ct;

    for ( ct = 0; ct < SelectedPawns.Length; ct ++ )
    {
        if (SelectedPawns[ct] == inPawn)
        {
            index = ct;
            return true;
        }
    }
    return false;
}

function Vector GetMouseLookDir()
{
    local Vector Screen;

    Screen.X = GUIParent.Controller.MouseX;
    Screen.Y = GUIParent.Controller.MouseY;

    return GUIParent.Controller.ScreenToWorld( Screen );
}

function RightClickBattleRoom()
{
    local Vector Screen, StartDir, EndTrace, HitLoc, HitNorm;
    local Actor HitActor;

    Screen.X = GUIParent.Controller.MouseX;
    Screen.Y = GUIParent.Controller.MouseY;

    StartDir = GUIParent.Controller.ScreenToWorld( Screen );
    EndTrace = Owner.Location + StartDir * 1000;
    HitActor = Trace( HitLoc, HitNorm, EndTrace, Owner.Location, true,,,,,true );

    log(HitActor);
    if ( HitActor != None )
    {
        if ( HitActor.IsA('Pawn') )
        {
            SelectedPawns.Remove(0, SelectedPawns.Length);
            SelectedPawns[0] = Pawn(HitActor);
            GuiParent.OpenMenu(SelectedPawns[0]);
        } 
    }

}

function ClickBattleRoom(GUIComponent Sender)
{
    local Vector Screen, StartDir, EndTrace, HitLoc, HitNorm;
    local Actor HitActor;
    local int index;

    Screen.X = GUIParent.Controller.MouseX;
    Screen.Y = GUIParent.Controller.MouseY;

    StartDir = GUIParent.Controller.ScreenToWorld( Screen );
    EndTrace = Owner.Location + StartDir * 1000;
    HitActor = Trace( HitLoc, HitNorm, EndTrace, Owner.Location, true,,,,,true );

    log(HitActor);
    if ( HitActor != None )
    {
        if ( HitActor.IsA('Pawn') )
        {
            if ( SwatGamePlayerController(Owner).bBattleRoomControl != 0 )
            {  
                if (  !IsSelected( Pawn(HitActor), index) )
                {    
                    SelectedPawns[SelectedPawns.Length] = Pawn(HitActor);
                } else
                {
                    SelectedPawns.Remove(index, 1);
                }
            } else
            {
                if ( !IsSelected( Pawn(HitActor), index ) )
                {
                    SelectedPawns.Remove(0, SelectedPawns.Length);
                    SelectedPawns[0] = Pawn(HitActor);
                } else
                {
                    SelectedPawns.Remove(0, SelectedPawns.Length);
                }
            }
        } 
        else if ( HitActor.IsA('LevelInfo') )
        {
            MoveSelectedToLocation(HitLoc);
        }
    }
}

function MoveSelectedToLocation(Vector NewLocation)
{
    if ( SelectedPawns.Length == 1 )
    {
        SelectedPawns[0].SetLocation( NewLocation + (vect(0,0,1) * SelectedPawns[0].CollisionHeight));
        log("Moving pawn: "$SelectedPawns[0]$", to location: "$NewLocation);
    }
}

function SetSelectedHealth(int Health)
{
    local int ct;

    for ( ct = 0; ct < SelectedPawns.Length; ct ++ )
    { 
        SelectedPawns[ct].Health = Health;
        SelectedPawns[ct].Default.Health = Health;
    }
}


function GetActiveCharacterActionNameForPawn(Pawn inPawn, out string goal, out string action)
{
    local int i;
    local AI_Goal IterGoal;

    for(i=0; i<inPawn.CharacterAI.Goals.Length; ++i)
    {
        IterGoal = AI_Goal(inPawn.CharacterAI.Goals[i]);

        // if the goal has an achieving action, and the action has exclusive use of the character resource,
        // then we have found the current behavior
        if ((IterGoal.achievingAction != None) && (IterGoal.achievingAction.resourceUsage == 8))
        {
            action = string(IterGoal.achievingAction.Name);
            goal   = IterGoal.GoalName;
        }
    }
}

function RenderAIInfo(Canvas inCanvas, SwatAI AiPawn, Vector inPawnScreen)
{
    local int    PawnLeft, PawnTop;
    local string goal, action;
    local name anim;
    local float frame, rate;

    if ( !AiPawn.bDisplayBattleDebug )
    {
       return;
    }

    PawnLeft = inPawnScreen.X - 50;
    PawnTop  = inPawnScreen.Y - 50;

    inCanvas.SetPos( PawnLeft+5, PawnTop + 5 );
    inCanvas.SetDrawColor(200,200,200,255);
    inCanvas.DrawTextClipped("Morale: "$AiPawn.GetCommanderAction().GetCurrentMorale() );

    GetActiveCharacterActionNameForPawn(AiPawn, goal, action);

    inCanvas.SetDrawColor(200,200,200,255);
    inCanvas.SetPos( PawnLeft+5, PawnTop + 15 );
    inCanvas.DrawTextClipped(goal);
    inCanvas.SetPos( PawnLeft+5, PawnTop + 25 );
    inCanvas.DrawTextClipped(action);

    inCanvas.SetPos( PawnLeft+5, PawnTop + 35 );
    AiPawn.GetAnimParams(0, anim, frame, rate);
    inCanvas.DrawTextClipped(anim);
}

function SelectAllPawns()
{
    local Pawn NewPawn;

    SelectedPawns.Remove(0, SelectedPawns.Length);

    foreach DynamicActors(class'Pawn', NewPawn)
    { 
        SelectedPawns[SelectedPawns.Length] = NewPawn;
    }
}

function RenderSelectionReticle( Canvas inCanvas, Pawn inPawn, Vector inPawnScreen )
{
    local float  BoxXL, BoxYL, BoxX, BoxY, Distance;

    inCanvas.SetDrawColor( 255,255,255,255);
    
    Distance = VSize(inPawn.Location - Owner.Location);
    BoxXL = 30000 * (1.0f/Distance);
    BoxYL = 40000 * (1.0f/Distance);
    BoxX = inPawnScreen.X - (17000*(1.0/Distance));
    BoxY = inPawnScreen.Y - (21000*(1.0/Distance));

    inCanvas.SetPos(BoxX, BoxY);
    inCanvas.DrawBracket( BoxXL, BoxYL, 6  );

    RenderHealthInfo( inCanvas, inPawn, inPawnScreen, BoxX, BoxY + BoxYL - 20, BoxXL, BoxYL );
}

function RenderHealthInfo(Canvas inCanvas, Pawn inPawn, Vector inPawnScreen, int X, int Y, int XL, int YL )
{
    local float  TextX, TextXL, TextYL, HealthX;
    local int    PawnLeft, PawnTop;
    local float  HealthRatio;

    PawnLeft = inPawnScreen.X - 50;
    PawnTop  = inPawnScreen.Y - 50;
    
    HealthRatio = FClamp(float(inPawn.Health) / float(inPawn.Default.Health), 0.0f, 1.0f); 		       

    inCanvas.TextSize( inPawn.Name, TextXL, TextYL );
    HealthX = 86;
    TextX = PawnLeft + 5;
    
    // Draw black health bar background
    inCanvas.SetPos(X, Y);
    inCanvas.SetDrawColor(0, 0, 0, 255);
    inCanvas.DrawTile(BarTex, XL, 10, 0, 0, BarTex.USize, BarTex.VSize);

    // Draw actual foreground health bar, color scaled based on health
    inCanvas.SetPos(X, Y);
    if ( inPawn.Controller.bGodMode )
        inCanvas.SetDrawColor(0, 0, 255, 255);  
    else
        inCanvas.SetDrawColor((255.0f-(255.0f*HealthRatio)), (255.0f*HealthRatio), 0, 200);
    inCanvas.DrawTile(BarTex, (XL * HealthRatio), 10, 0, 0, BarTex.USize, BarTex.VSize);

    // Draw the name of the pawn on top of the health bar
    inCanvas.SetDrawColor(200, 200, 200, 255);
    inCanvas.SetPos(X+ 2, Y + 10);
    inCanvas.DrawTextClipped(inPawn.Name);     
}

function RenderBattleRoom(Canvas inCanvas)
{
    local Vector ScreenLoc, DirToPawn;
    local float  DotToPawn;
    local int    ct;

    inCanvas.Font = inCanvas.TinyFont;

    for ( ct = 0; ct < SelectedPawns.Length; ct ++ )
    {   
        // Don't draw selected pawns that have been killed or destroyed, and remove them from the list
        if ( SelectedPawns[ct] == None  || SelectedPawns[ct].Health <= 0 )
        {
            SelectedPawns.Remove(ct, 1);
            continue;
        }

        ScreenLoc = GUIParent.Controller.WorldToScreen( SelectedPawns[ct].Location );

        // Don't draw selected pawns that are behind you....
        DirToPawn = SelectedPawns[ct].Location - Owner.Location;
        DotToPawn = Normal(DirToPawn) Dot vector(Owner.Rotation);
        if ( DotToPawn < 0 )
            continue;

        RenderSelectionReticle( inCanvas, SelectedPawns[ct], ScreenLoc );
        if ( SelectedPawns[ct].IsA( 'SwatAI' ) )
        {
             RenderAIInfo(inCanvas, SwatAI(SelectedPawns[ct]), ScreenLoc);
        }

        if ( GUIParent.bMenuOpen )
        {
            GUIParent.MenuReposition();
        }
    }

    if ( Level.bPlayersOnly )
    {
        inCanvas.SetPos( inCanvas.ClipX - 64, inCanvas.ClipY - 80 );
        inCanvas.DrawTile( PauseTex, 48, 48, 0, 0, PauseTex.Usize, PauseTex.VSize);
    }
}

defaultproperties
{
    ColorBar=ColorModifier'ProgrammerTestObjectsTex.whitebarmod'
    BarTex=Texture'ProgrammerTestObjectsTex.ColorBar'
    PauseTex=Texture'UWindow_res.MouseWait'
    bHidden=true
    bStasis=true
    Physics=PHYS_None
    DrawType=DT_None
}

#endif // IG_BATTLEROOM