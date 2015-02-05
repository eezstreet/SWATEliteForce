class Command extends Core.Object
    PerObjectConfig
    native
    abstract;

import enum ECommand from CommandInterface;
import enum CommandInterfacePage from CommandInterface;

var int Index;  //this is the index of this Command in the CommandInterface's array of Commands

var config ECommand Command;
var config CommandInterfacePage Page;
var config CommandInterfacePage SubPage;
var config int CCIMenuPad;
var config int GCIMenuPad;
var config localized string Text;
var config name EffectEvent;
var config bool bStatic;
var config bool IsCancel;
