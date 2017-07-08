class GUIWeight extends GUI.GUILabel;

var() private config localized string WeightText;

function SetWeightText(float Weight) {
  SetCaption(WeightStringText(Weight));
}

private function string WeightStringText(float Weight) {
  return "" $ Weight $ "kg";
}
