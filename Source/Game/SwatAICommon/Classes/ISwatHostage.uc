///////////////////////////////////////////////////////////////////////////////
// ISwatHostage.uc - ISwatHostage interface
// we use this interface to be able to call functions on the SwatHostage because we
// the definition of SwatHostage has not been defined yet, but because SwatHostage implements
// ISwatHostage, we have a contract that says these functions will be implemented, and 
// we can cast any Pawn pointer to an ISwatHostage interface to call them

interface ISwatHostage extends ISwatAICharacter;

enum HostageState
{
    HostageState_Unaware,
    HostageState_Aware
};

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function HostageCommanderAction		GetHostageCommanderAction();
function HostageSpeechManagerAction GetHostageSpeechManagerAction();

///////////////////////////////////////////////////////////////////////////////
//
// Spawner

function name SpawnedFromGroup();

///////////////////////////////////////////////////////////////////////////////
//
// State

function HostageState GetCurrentState();
function SetCurrentState(HostageState NewState);