class CommandInterfaceContext extends PlayerInterfaceContext
    perObjectConfig
    abstract
    native;

import enum ECommand from CommandInterface;

var config bool CaresAboutIsActive;
var config bool IsActive;

var config ECommand DefaultCommand;
var config int DefaultCommandPriority;

var config bool CaresAboutCanBeArrestedNow;
var config bool CanBeArrestedNow;

var config bool CaresAboutCanBeUsedNow;
var config bool CanBeUsedNow;

var config bool CaresAboutCanBeReportedNow;
var config bool CanBeReportedNow;

var config array<ECommand> Command;

//the CommandInterface generally exhausts all contexts
//  so that it enables all appropriate commands for
//  a candidate.
defaultproperties
{
    BreakIfMatch=false
}
