class Script extends Engine.Actor
	native
	hidecategories(Advanced)
	hidecategories(Collision)
	hidecategories(Events)
	hidecategories(Force)
	hidecategories(Karma)
	hidecategories(Lighting)
	hidecategories(LightColor)
	hidecategories(Movement)
	hidecategories(Sound)
	hidecategories(Display)
	hidecategories(Object)
	hidecategories(Placement)
	hidecategories(Navigation)
	placeable;

import class Engine.Message;

#define DISALLOW_SCIPTS_IN_MP 0

var() editcombotype(enumValidMessages) editdisplay(editorDisplayMessage) class<Message> messageClass;
var() editinline editdisplay(editorDisplayFilter) deepcopy Message messageFilter;
var() editinline deepcopy Array<Action> Actions;
var() bool enabled;
var() bool CampaignObjectiveSpecific "If true, this Script will not execute unless Campaign Objectives are currently enabled.";
var() bool DisabledInMP;

var bool bIsExecuting;

var Array<WatcherBase> watchers;

var private bool bExitScript;
var private bool bExitLoop;
var private Message currentMessage;
var private Array<Message> messageQueue;
var private Array<Variable> variables;
var private Array<Variable> tempVariables; // Destoryed after script execution

// PostBeginPlay
function PostBeginPlay()
{
	local int i;

	for (i = 0; i < Actions.Length; ++i)
			Actions[i].setParentScript(self);

	if (triggeredBy != "")
		registerMessage(messageClass, triggeredBy);
}

simulated event SetInitialState()
{
}

event Timer()
{
	dispatchMessage(new class'MessageTimerExpired');
}

function Variable findVariable(Name variableName)
{
	local Name fullVariableName;
	local int i;

	fullVariableName = Name("Variable_" $ String(variableName));

	for (i = 0; i < variables.length; ++i)
	{
		if (variables[i].name == fullVariableName)
			return variables[i];
	}

	return None;
}

// newVariable
// Variables are stored with the 'owner' script object as outer, prepended with the string "Variable_" to avoid any possible name clashes
function Variable newVariable(Name variableName, class<Variable> variableType)
{
	local Variable v;

	v = findVariable(variableName);

	if (v != None)
		return v;

	variables[variables.length] = new(self, "Variable_" $ variableName) variableType(self);

	return variables[variables.length - 1];
}

// newTemporaryVariable
// Temporary variables are destroyed after a script finishes execution
function Variable newTemporaryVariable(class<Variable> variableType, optional string initValue)
{
	local Variable v;

	v = new(self) variableType(self);

	tempVariables[tempVariables.length] = v;
	
	if (initValue != "")
		v.SetPropertyText("value", initValue);

	return v;
}

function addWatcher(WatcherBase newWatcher)
{
	watchers[watchers.Length] = newWatcher;
}

function setWatcherEnabled(Name watcherName, bool enabled)
{
	local int i;

	for (i = 0; i < watchers.Length; ++i)
	{
		if (watchers[i].watcherName == watcherName)
		{
			watchers[i].enabled = enabled;
			watchers[i].GotoState('LookAtExpression');
		}
	}
}

// exit
// Ends the script when called during script execution
function exit()
{
	bExitScript = true;
}

function bool continueExecution()
{
	return !bExitScript;
}

// enterLoop
// tells the script that a loop has started
function enterLoop()
{
	bExitLoop = false;
}

// keepLooping
// true if the script should keep looping, false otherwise
function bool keepLooping()
{
	return !bExitLoop && !bExitScript;
}

// exitLoop
// Ends the currently running loop, does nothing if no loop is running
function exitLoop()
{
	bExitLoop = true;
}

// onMessage
function onMessage(Message msg)
{
	if (!enabled)
		return;

    if( DisabledInMP && Level.NetMode != NM_Standalone )
        return;

	if (msg.Class != messageClass)
		return;

	if (messageFilter != None && !msg.passesFilter(messageFilter))
		return;

	execute(msg);
}

// triggeringMessage
function Message triggeringMessage()
{
	return currentMessage;
}

// execute
function execute(Message msg)
{
	local Message msgCopy;
	local Name propName;

	assert(msg != None);

#if DISALLOW_SCIPTS_IN_MP
	if (Level.NetMode != NM_Standalone)
		return;
#endif

	bExitScript = false;

	msgCopy = new messageClass;

	ForEach AllProperties(messageClass, class'Message', propName)
	{
		msgCopy.SetPropertyText(string(propName), msg.GetPropertyText(string(propName)));
	}

	if (currentMessage == None)
	{
		currentMessage = msgCopy;
		GotoState('ExecuteScript');
	}
	else
	{
		messageQueue[messageQueue.Length] = msgCopy;
	}
}

// Used to execute a script from another script. Note that currentMessage will be None
latent function executeScriptFromScriptAction(bool blockCallingScript)
{
	if (!enabled)
		return;

	if (bIsExecuting) // Don't allow re-entry
	{
		Log("Script " $ Label $ " was denied execution because of attempted re-entry");
		return;
	}

	bExitScript = false;

	if (blockCallingScript)
		executeActions();
	else
		GotoState('ExecuteScript');
}

latent private function executeActions()
{
	local int i;

    if (CampaignObjectiveSpecific && !Level.Game.CampaignObjectivesAreInEffect())
        return;     //this Script is specific to campaign objectives, and campaign objectives are not currently in effect
    
	SLog("Starting execution of script " $ Label);
	bIsExecuting = true;

	// execute script
	for (i = 0; i < Actions.Length && !bExitScript; i++)
	{
		if (Actions[i] != None) // Some wallies put None actions in their scripts :/
			Actions[i].execute();
	}

	if (currentMessage != None)
	{
		Level.messageDispatcher.deleteMessage(currentMessage);
		currentMessage = None;
	}

	destroyTempVariables();

	bIsExecuting = false;
	SLog("Finished executing script " $ Label);
}

native function destroyTempVariables();

state ExecuteScript
{
begin:
	executeActions();

	if (messageQueue.Length > 0)
	{
		currentMessage = messageQueue[0];
		messageQueue.Remove(0, 1);
		Goto('Begin');
	}
	else
	{
		GotoState('');
	}
}

// enumValidMessages
// Enumerate the valid message classes given the type of the object specified in TriggeredBy
function enumValidMessages(Engine.LevelInfo l, out Array<class<Message> > s)
{
	local class c;
	local class base;
	local class<Message> m;
	local Actor triggeredByActor;
	local Name triggeredByActorLabel;

	if (triggeredBy == "")
		return;

	if (triggeredBy != "all" && InStr(triggeredBy, ",") == -1)
		triggeredByActor = findStaticByLabel(class'Actor', name(triggeredBy));

	if (triggeredByActor != None)
		triggeredByActorLabel = triggeredByActor.Label;

	base = class'Message';

    ForEach AllClasses(base, c)
	{
		m = class<Message>(c);

		if (m.default.specificTo != None && m.static.editorDisplay(triggeredByActorLabel, None) != "")
		{
			if (triggeredByActor == None || triggeredByActor.IsA(m.default.specificTo.name))
				s[s.Length] = m;
		}
	}
}

// editorDisplayMessage
// Define the text used to display the messageClassName field within the editor
function string editorDisplayMessage(class<Message> input)
{
	if (triggeredBy == "")
		return "'TriggeredBy' is empty";
	else if (input == None)
		return "No message specified";
	else
		return input.static.editorDisplay(Name(triggeredBy), messageFilter);
}

function string editorDisplayFilter(Message input)
{
	local String displayString;
	local Name propName;
	local String filterProp;

	if (input == None)
		return "";
	
	displayString = editorDisplayMessage(messageClass);

	ForEach AllEditableProperties(messageClass, class'Message', propName)
	{
		filterProp = messageFilter.GetPropertyText(string(propName));

		// If the property's not "empty"
		if (!(filterProp == "" || filterProp == "None" || filterProp == "0" || filterProp == "0.00"))
		{
			displayString = displayString $ ", " $ propName $ "=" $ filterProp;
		}
	}

	return displayString;
}

defaultproperties
{
	bHidden = true
	enabled = true
    Texture=Texture'EditorSprites.Sprite_Script'
    bNoDelete=true
}
