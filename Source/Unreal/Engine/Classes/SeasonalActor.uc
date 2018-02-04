class SeasonalActor extends StaticMeshActor;

var(DateTimeConfig) bool bHiddenOnDate "When true, this actor will be hidden on the set date instead of shown.";
var(DateTimeConfig) int DateMonth "If 0, this value is ignored. If non-zero, this actor will be shown only on this month.";
var(DateTimeConfig) int DateDay "If 0, this value is ignored. If non-zero, this actor will be shown only on this day.";
var(DateTimeConfig) int DateYear "If 0, this value is ignored. If non-zero, this actor will be shown only on this year.";

simulated event PostBeginPlay()
{
	if(bHiddenOnDate)
	{
		if(DateMonth != 0 && DateMonth == Level.Month)
		{	// we care about the month
			Hide();
		}
		else if(DateDay != 0 && DateDay == Level.Day)
		{
			Hide();
		}
		else if(DateYear != 0 && DateYear == Level.Year)
		{
			Hide();
		}
	}
	else
	{
		if(DateMonth != 0 && DateMonth != Level.Month)
		{
			Hide();
		}
		else if(DateDay != 0 && DateDay != Level.Day)
		{
			Hide();
		}
		else if(DateYear != 0 && DateYear != Level.Year)
		{
			Hide();
		}
	}
}
