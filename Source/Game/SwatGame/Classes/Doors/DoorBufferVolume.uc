///////////////////////////////////////////////////////////////////////////////
//
// Auto-generated door volume that is used to repulse and/or block players
// from getting too close. In single player, this volume will repulse once
// each time the door is closed. Once repulsed, however, the player can get
// closer to the door. This guarantees the player can not sit in the middle
// of the door's antiportal. In multiplayer, it will repulse, and block the
// `player from getting too close as long as its closed.
//

class DoorBufferVolume extends Engine.Volume
    native;

///////////////////////////////////////////////////////////////////////////////

var private SwatDoor          AssociatedDoor;
var private array<SwatPlayer> PlayersToRepulse;

///////////////////////////////////////////////////////////////////////////////

simulated function EnableRepulsion()
{
    local SwatPlayer SwatPlayer;

    if (ShouldRepulse())
    {
        // @NOTE: We get a touch event for pawns who are within the volume
        // ONLY if bBlockPlayers is false. So, we first turn on actor
        // collision but not player blocking, so we get a touch event for the
        // pawns. Then, we turn on blocking as well. [darren]
        SetCollision(true, false, false);

        // Cache each touching pawn, since we want to repulse only once, and
        // rely on blocking for any remaining repulsion.
        PlayersToRepulse.Remove(0, PlayersToRepulse.length);
        assert(PlayersToRepulse.length == 0);
        foreach TouchingActors(class'SwatPlayer', SwatPlayer)
        {
            PlayersToRepulse.Insert(PlayersToRepulse.length, 1);
            PlayersToRepulse[PlayersToRepulse.length - 1] = SwatPlayer;
        }

        if (ShouldBlock())
        {
            SetCollision(true, false, true);
            // Block traces so that we can custom-handle low-ready focus
            // traces on door buffer volumes.
            bBlockZeroExtentTraces = true;
        }
    }
}

///////////////////////////////////////

simulated function DisableRepulsion()
{
    SetCollision(false, false, false);
    bBlockZeroExtentTraces = false;
}

///////////////////////////////////////

simulated event Tick(float DeltaSeconds)
{
    local int  i, j;
    local bool isPlayerInBothArrays;
    local SwatPlayer SwatPlayer;
    local array<SwatPlayer> TouchingPlayers;
    local vector DoorDirection;
    local vector DoorDirectionPerpendicular;
    local vector PushDirection;

    Super.Tick(DeltaSeconds);

    if (ShouldRepulse())
    {
        DoorDirection = vector(AssociatedDoor.Rotation);
        DoorDirectionPerpendicular.X =  DoorDirection.Y;
        DoorDirectionPerpendicular.Y = -DoorDirection.X;
        DoorDirectionPerpendicular.Z =  0.0;

        // Only push away players that are touching AND in the
        // PlayersToRepulse array. In single player, we only want to
        // repulse on the initial collision. Here we locally cache the
        // current touching players.
        TouchingPlayers.Remove(0, TouchingPlayers.length);
        assert(TouchingPlayers.length == 0);
        foreach TouchingActors(class'SwatPlayer', SwatPlayer)
        {
            TouchingPlayers.Insert(TouchingPlayers.length, 1);
            TouchingPlayers[TouchingPlayers.length - 1] = SwatPlayer;
        }

        for (i = 0; i < PlayersToRepulse.length; ++i)
        {
            SwatPlayer = PlayersToRepulse[i];

            isPlayerInBothArrays = false;
            for (j = 0; j < TouchingPlayers.length; ++j)
            {
                if (SwatPlayer == TouchingPlayers[j])
                {
                    isPlayerInBothArrays = true;
                    break;
                }
            }

            // If the player is no longer in the TouchingPlayers array, remove him
            // from the PlayersToRepulse array
            if (!isPlayerInBothArrays)
            {
                PlayersToRepulse.Remove(i, 1);
            }
            // Otherwise, repulse player from door
            else
            {
                // In reality there are of course two perpendiculars. Use the
                // perpendicular which points toward the side of the door we are on,
                // by comparing the dot product sign.
                if ((DoorDirectionPerpendicular dot (SwatPlayer.Location - AssociatedDoor.Location)) > 0.0)
                {
                    PushDirection = DoorDirectionPerpendicular;
                }
                else
                {
                    PushDirection = -DoorDirectionPerpendicular;
                }

                SwatPlayer.SetOneFrameNudgeDirection(PushDirection);
            }
        }
    }
}

///////////////////////////////////////

simulated private function bool ShouldBlock()
{
    // Only allow blocking if we also allow repulsion, and if its multiplayer
    return ShouldRepulse() && (Level.NetMode != NM_Standalone);
}

///////////////////////////////////////

simulated private function bool ShouldRepulse()
{
    // We now allow player repulsion in all game types
    return true;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    bBlockZeroExtentTraces=false
    bWorldGeometry=false
    bCollideActors=false
    bBlockActors=false
    bBlockPlayers=false
    // So we get ticked
    bStatic=false
    BrushColor=(B=165,G=128,R=255,A=255)
}

///////////////////////////////////////////////////////////////////////////////
