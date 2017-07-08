///////////////////////////////////////////////////////////////////////////////

class TrainerScriptActionBase extends Scripting.Action;

///////////////////////////////////////////////////////////////////////////////

var private SwatTrainer m_swatTrainer;

///////////////////////////////////////////////////////////////////////////////

function SwatTrainer GetSwatTrainer()
{
    local Pawn pawn;
    local SwatTrainer swatTrainer;

    if (m_swatTrainer == None)
    {
        // Haven't yet stored a reference to the swat trainer pawn. Find him
        // now..
        for (pawn = parentScript.Level.pawnList; pawn != None; pawn = pawn.nextPawn)
        {
            swatTrainer = SwatTrainer(pawn);
            if (swatTrainer != None)
            {
                m_swatTrainer = swatTrainer;
                break;
            }
        }
    }

    return m_swatTrainer;
}

///////////////////////////////////////

latent function WaitForGoal(AI_Goal goal)
{
    while (!goal.hasCompleted())
    {
        Sleep(0.0);
    }
}

///////////////////////////////////////////////////////////////////////////////
