class PlayerInterfaceDoorRelatedContext extends Core.Object
    perObjectConfig
    abstract
    native;

import enum ESkeletalRegion from Engine.Actor;
import enum DoorPart from PlayerFocusInterface;

var config float Range;

var config DoorPart DoorPart;
var config name ActiveItem;
var config array<name> ExceptActiveItem;

var config ESkeletalRegion SkeletalRegion;

var config bool CaresAboutOpen;
var config bool IsOpen;

var config bool CaresAboutLocked;
var config bool IsLocked;

var config bool CaresAboutPlayerBelief;
var config bool PlayerBelievesLocked;

var config bool CaresAboutWedged;
var config bool IsWedged;

var config bool CaresAboutBroken;
var config bool IsBroken;

var config bool CaresAboutMissionExit;
var config bool IsMissionExit;

var config bool CaresAboutTransparent;
var config bool IsTransparent;

var config name HasA;
var config name DoesntHaveA;

var config bool AddFocus;
var config bool BlockTrace;
var config bool BlockTraceIfOpaque;

//if true, and this context matches, then no contexts will be considered
//  after this one for the current trace intersection (further trace
//  intersections will again look for context match(es)).
//if false, then contexts will be considered even after a matching context
//  is found.
var config bool BreakIfMatch;

defaultproperties
{
    Range=10000
    BreakIfMatch=true
}
