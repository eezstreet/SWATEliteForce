///////////////////////////////////////////////////////////////////////////////
// SquadDeployLightstickGoal.uc - SquadDeployLightstickGoal class
// this goal is used to organize the Officer's DeployLightstick behavior

class SquadDeployLightstickGoal extends SquadCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var array<vector> 	DropPoints;

var bool			bPlaySpeech;

///////////////////////////////////////////////////////////////////////////////
//
// Behavior Copying

// copy the DropPoints from the template
function CopyAdditionalPropertiesFromTemplate(SquadCommandGoal Template)
{
	local int i;
	local SquadDeployLightstickGoal TemplateSquadDeployLightstickGoal;

	TemplateSquadDeployLightstickGoal = SquadDeployLightstickGoal(Template);
	assert(TemplateSquadDeployLightstickGoal != None);
	assert(DropPoints.Length == 0);

	super.CopyAdditionalPropertiesFromTemplate(Template);

	log("TemplateSquadDeployLightstickGoal.DropPoints.Length is: " $ TemplateSquadDeployLightstickGoal.DropPoints.Length);

	for(i=0; i<TemplateSquadDeployLightstickGoal.DropPoints.Length; ++i)
	{
		DropPoints[i] = TemplateSquadDeployLightstickGoal.DropPoints[i];
		log("DropPoints["$i$"] is: " $ DropPoints[i]);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Drop Points

function AddDropPoint(vector DropPoint)
{
	if (! IsADropPoint(DropPoint))
	{
		DropPoints[DropPoints.Length] = DropPoint;

		if (achievingAction != None)
		{
			SquadDeployLightstickAction(achievingAction).NotifyNewDropPoint();
		}
	}
}

function int GetNumDropPoints()
{
	return DropPoints.Length;
}

function vector GetDropPoint(int DropPointIndex)
{
	assert(DropPointIndex < DropPoints.Length);
	assert(DropPointIndex >= 0);

	return DropPoints[DropPointIndex];
}

function RemoveDropPoint(vector DropPoint)
{
	local int i;

	for(i=0; i<DropPoints.Length; ++i)
	{
		if (DropPoints[i] == DropPoint)
		{
			DropPoints.Remove(i, 1);
			break;
		}
	}
}

private function bool IsADropPoint(vector TestDropPoint)
{
	local int i;

	for(i=0; i<DropPoints.Length; ++i)
	{
		if (DropPoints[i] == TestDropPoint)
		{
			return true;
		}
	}

	return false;
}

///////////////////////////////////////////////////////////////////////////////
//
// Other

function SetPlaySpeech(bool play)
{
	bPlaySpeech = play;
}

function bool GetPlaySpeech()
{
	return bPlaySpeech;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadDeployLightstick"
	bRepostElementGoalOnSubElementSquad = true
	bPlaySpeech = true;
}