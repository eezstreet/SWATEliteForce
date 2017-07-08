// ====================================================================
//  Class:  Engine.FileLog
//  Parent: Engine.Info
//
//  Creates a log device.
// ====================================================================

class FileLog extends Info
		Native;

// Internal
var int LogAr; // FArchive*

// File Names
var string LogFileName;

// File Manipulation
native final function OpenLog(string FName);	// No extension, .txt is auto appended
native final function CloseLog();
native final function Logf( string LogString );

event Destroyed()
{
	CloseLog();
}

defaultproperties
{
}