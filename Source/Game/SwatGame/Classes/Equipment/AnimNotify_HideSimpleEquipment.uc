class AnimNotify_HideSimpleEquipment extends Engine.AnimNotify_Scripted;

var() class<SimpleEquipment> SimpleEquipmentClass;

simulated event Notify( Actor Owner )
{
    local SwatAICharacter AI;
    local CharacterArchetypeInstance Instance;
    local int i;

    AI = SwatAICharacter(Owner);
    AssertWithDescription(AI != None,
        "[tcohen] AnimNotify_ShowSimpleEquipment was called on "$Owner$" which cannot have SimpleEquipment.");

    Instance = CharacterArchetypeInstance(AI.GetArchetypeInstance());
    assert(Instance != None);

    for (i=0; i<Instance.Equipment.length; ++i)
        if (Instance.Equipment[i].class == SimpleEquipmentClass)
            SimpleEquipment(Instance.Equipment[i]).UnEquip();
}
