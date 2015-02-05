class PlayerInterfaceContext extends Core.Object
    perObjectConfig
    abstract
    native;

var config float Range;

var config name Type;

var config array<name> Except;
var config array<name> ExceptActiveItem;

var config bool HasSpecialConditions;

var config name HasA;
var config name DoesntHaveA;

var config bool CaresAboutTransparent;
var config bool IsTransparent;

var config name ActiveItem;
var config bool BlockTrace;
var config bool BlockTraceIfOpaque;
var config bool AddFocus;

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
