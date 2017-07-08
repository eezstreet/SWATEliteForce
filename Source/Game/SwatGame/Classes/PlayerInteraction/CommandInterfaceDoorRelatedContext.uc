class CommandInterfaceDoorRelatedContext extends PlayerInterfaceDoorRelatedContext
    perObjectConfig
    abstract
    native;

import enum ECommand from CommandInterface;

var config bool CaresAboutPlayerOnExternalSide;
var config bool PlayerIsOnExternalSide;

var config bool CaresAboutCanIssueCommandsFromMySide;
var config bool CanIssueCommandsFromMySide;

var config ECommand DefaultCommand;
var config int DefaultCommandPriority;

var config array<ECommand> Command;

//the CommandInterface generally exhausts all contexts
//  so that it enables all appropriate commands for
//  a candidate.
defaultproperties
{
    BreakIfMatch=false
}
