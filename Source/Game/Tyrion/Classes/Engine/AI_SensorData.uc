//=====================================================================
// AI_SensorData
//=====================================================================

class AI_SensorData extends Core.DeleteableObject
	native;

//=====================================================================
// Variables

enum SensorDataType
{
   SDT_FLOAT,
   SDT_INTEGER,
   SDT_CATEGORICAL,
   SDT_OBJECT
};

var SensorDataType dataType;
var float floatData;
var int integerData;
var Object objectData;

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Clear all data

function clear()
{
	floatData = 0.0;
	integerData = 0;
	objectData = None;
}

