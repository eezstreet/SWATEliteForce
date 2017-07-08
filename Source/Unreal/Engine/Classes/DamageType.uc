interface DamageType;

//tmc 3/29/2004 see comments in DamageCategory.uc

static function string GetFriendlyName();

// Returns the amount to scale the impact momentum of the killing blow
// before applying it to the ragdoll (e.g., to make more 'cinematic'
// deaths).
static function float GetRagdollDeathImpactMomentumMultiplier();