class GUIWeight extends GUI.GUILabel;

var() private config localized string WeightText;

function SetWeightText(float Weight) {
  SetCaption(WeightStringText(Weight));
}

private function string WeightStringText(float Weight) {
	if(SwatGUIControllerBase(Controller).IsUsingMetricSystem())
	{
		return "" $ Weight $ "kg";
	}
  	else
  	{
  		return "" $ (Weight * 0.453592) $ " lb";
  	}
}
