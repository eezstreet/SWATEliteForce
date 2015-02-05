class TriggerRadius extends Trigger
	placeable;

var() int maxEnterCount;
var() int maxExitCount;
var() bool doLOSCheck;

var int enterCount;
var int exitCount;

// Touch
function Touch(Actor Other)
{
	local int i;

	if (IsOverlapping(Other))
	{
		if (checkLOS(Other))
		{
			SLog("Trigger " $ Label $ " entered by " $ Other.Label);
			dispatchEnter(Other);
		}
	}
	else // Not overlapping so remove each from touching lists
	{
		for (i = 0; i < Touching.Length; ++i)
		{
			if (Touching[i] == Other)
			{
				Touching.Remove(i, 1);
				break;
			}
		}

		for (i = 0; i < Other.Touching.Length; ++i)
		{
			if (Other.Touching[i] == Self)
			{
				Other.Touching.Remove(i, 1);
				break;
			}
		}
	}
}

// UnTouch
function UnTouch(Actor Other)
{
	if (checkLOS(Other))
	{
		SLog("Trigger " $ Label $ " exited by " $ Other.Label);
		dispatchExit(Other);
	}
}

function bool checkLOS(Actor triggerer)
{
	local Vector hitLocation;
	local Vector hitNormal;

    return !doLOSCheck || triggerer == Trace(hitLocation, hitNormal, triggerer.Location);
}

// dispatchEnter
private function bool dispatchEnter(Actor instigator)
{
	if (!canTrigger(instigator))
		return false;

	if (maxEnterCount > -1 && enterCount >= maxEnterCount)
		return false;

	enterCount++;
	return dispatchTrigger(instigator, new class'MessageTriggerEnter'(label, instigator.label));
}

// dispatchExit
private function bool dispatchExit(Actor instigator)
{
	if (!canTrigger(instigator))
		return false;

	if (maxExitCount > -1 && exitCount >= maxExitCount)
		return false;

	exitCount++;
	return dispatchTrigger(instigator, new class'MessageTriggerExit'(label, instigator.label));
}

defaultproperties
{
    CollisionRadius=+00040.000000
    CollisionHeight=+00040.000000
	maxEnterCount = -1
	maxExitCount = -1
}