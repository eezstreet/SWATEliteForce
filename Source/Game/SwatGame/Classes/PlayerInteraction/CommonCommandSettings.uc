class CommonCommandSettings extends Core.Object config(Command);

var public config bool bUseSweepDistanceFilter;	// Filter out SEARCH AND SECURE based on distance?
var public config float fMaxSweepDistance;
var public config bool bSweepFilterExpires; // Disable the filter when the mission is complete?
