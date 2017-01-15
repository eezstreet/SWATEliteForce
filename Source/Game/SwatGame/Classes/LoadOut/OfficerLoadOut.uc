class OfficerLoadOut extends LoadOut
implements IAmAffectedByWeight
    native;

// Absolute bulk/weight - these determine how to scale weight and bulk
/*static var config float MinimumAbsoluteBulk;
static var config float MaximumAbsoluteBulk;
static var config float MinimumAbsoluteWeight;
static var config float MaximumAbsoluteWeight;

static var config float MinimumQualifyModifer;
static var config float MaximumQualifyModifier;
static var config float MinimumMovementModifier;
static var config float MaximumMovementModifier;*/

simulated function float GetMinimumQualifyModifer() {
  return /*MinimumQualifyModifer*/ 0.5;
}

simulated function float GetMaximumQualifyModifer() {
  return /*MaximumQualifyModifier*/ 2.0;
}

simulated function float GetMinimumMovementModifier() {
  return /*MinimumMovementModifier*/ 0.75;
}

simulated function float GetMaximumMovementModifier() {
  return /*MaximumMovementModifier*/ 1.3;
}

simulated function float GetMinimumBulk() {
  return /*MinimumAbsoluteBulk*/ 20.0;
}

simulated function float GetMinimumWeight() {
  return /*MinimumAbsoluteWeight*/ 5.0;
}

// Functions for getting the maximum amount of weight/bulk we can carry
simulated function float GetMaximumWeight() {
  return /*MaximumAbsoluteWeight*/ 60.0;
}

simulated function float GetMaximumBulk() {
  return /*MaximumAbsoluteBulk*/ 125.0;
}

////////////////////////////////////////////////////////////////////////////////
//
// IAmAffectedByWeight implementation

function float GetTotalWeight() {
  local int i;
  local Engine.IHaveWeight PocketItem;
  local float total;

  total = 0.0;

  for(i = 0; i < Pocket.EnumCount; i++) {
    PocketItem = IHaveWeight(PocketEquipment[i]);
    total += PocketItem.GetWeight();
  }

  return total;
}

function float GetTotalBulk() {
  local int i;
  local Engine.IHaveWeight PocketItem;
  local float total;

  total = 0.0;

  for(i = 0; i < Pocket.EnumCount; i++) {
    PocketItem = IHaveWeight(PocketEquipment[i]);
    total += PocketItem.GetBulk();
  }

  return total;
}

function float GetWeightMovementModifier() {
  local float totalWeight;
  local float maxWeight, minWeight;
  local float minMoveModifier, maxMoveModifier;

  totalWeight = GetTotalWeight();
  maxWeight = GetMaximumWeight();
  minWeight = GetMinimumWeight();
  minMoveModifier = GetMinimumMovementModifier();
  maxMoveModifier = GetMaximumMovementModifier();

  assertWithDescription(totalWeight <= maxWeight,
    "Loadout "$self$" exceeds maximum weight ("$totalWeight$" > "$maxWeight$"). Adjust the value in StaticLoadout.ini");
  assertWithDescription(totalWeight >= minWeight,
    "Loadout "$self$" doesn't meet minimum weight ("$totalWeight$" < "$minWeight$"). Adjust the value in StaticLoadout.ini");

  totalWeight -= minWeight;
  maxWeight -= minWeight;

  return ((totalWeight / maxWeight) * (maxMoveModifier - minMoveModifier)) + minMoveModifier;
}

function float GetBulkQualifyModifier() {
  local float totalBulk;
  local float maxBulk, minBulk;
  local float minQualifyModifier, maxQualifyModifier;

  totalBulk = GetTotalBulk();
  minBulk = GetMinimumBulk();
  maxBulk = GetMaximumBulk();
  minQualifyModifier = GetMinimumQualifyModifer();
  maxQualifyModifier = GetMaximumQualifyModifer();

  assertWithDescription(totalBulk <= maxBulk,
    "Loadout "$self$" exceeds maximum bulk ("$totalBulk$" > "$maxBulk$"). Adjust the value in StaticLoadout.ini");
  assertWithDescription(totalBulk >= minBulk,
    "Loadout "$self$" doesn't meet minimum bulk ("$totalBulk$" < "$minBulk$"). Adjust the value in StaticLoadout.ini");

  totalBulk -= minBulk;
  maxBulk -= minBulk;

  return ((totalBulk / maxBulk) * (maxQualifyModifier - minQualifyModifier)) + minQualifyModifier;
}

defaultproperties
{
}
