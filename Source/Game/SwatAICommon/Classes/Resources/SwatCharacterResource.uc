///////////////////////////////////////////////////////////////////////////////

class SwatCharacterResource extends Tyrion.AI_CharacterResource;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var ThreatenedSensorAction						ThreatenedSensorAction;
var CommonSensorAction							CommonSensorAction;
var CompliantSensorAction						CompliantSensorAction;
var TargetSensorAction							TargetSensorAction;
var DistanceSensorAction						DistanceSensorAction;
var DistanceToOfficersSensorAction				DistanceToOfficersSensorAction;
var DistanceToUncomplaintCharactersSensorAction	DistanceToUncomplaintCharactersSensorAction;
var ArrestedSensorAction						ArrestedSensorAction;
var DoorSideSensorAction						DoorSideSensorAction;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization / Cleanup

event init()
{
	super.init();

	CommonSensorAction = CommonSensorAction(addSensorActionClass( class'CommonSensorAction' ));
	ThreatenedSensorAction = ThreatenedSensorAction(addSensorActionClass( class'ThreatenedSensorAction' ));
	CompliantSensorAction = CompliantSensorAction(addSensorActionClass( class'CompliantSensorAction' ));
	TargetSensorAction = TargetSensorAction(addSensorActionClass( class'TargetSensorAction' ));
	DistanceSensorAction = DistanceSensorAction(addSensorActionClass( class'DistanceSensorAction' ));
	DistanceToOfficersSensorAction = DistanceToOfficersSensorAction(addSensorActionClass( class'DistanceToOfficersSensorAction' ));
	DistanceToUncomplaintCharactersSensorAction = DistanceToUncomplaintCharactersSensorAction(addSensorActionClass( class'DistanceToUncomplaintCharactersSensorAction' ));
	ArrestedSensorAction = ArrestedSensorAction(addSensorActionClass( class'ArrestedSensorAction' ));
	DoorSideSensorAction = DoorSideSensorAction(addSensorActionClass( class'DoorSideSensorAction' ));
}

function cleanup()
{
	CommonSensorAction = None;
	ThreatenedSensorAction = None;
	CompliantSensorAction = None;
	TargetSensorAction = None;
	DistanceSensorAction = None;
	DistanceToOfficersSensorAction = None;
	DistanceToUncomplaintCharactersSensorAction = None;
	ArrestedSensorAction = None;
	DoorSideSensorAction = None;

	super.cleanup();
}