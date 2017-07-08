class CustomScenarioList extends GUI.GUIMultiColumnListBox;

final function Empty()
{
    Clear();
}

final function AddRow(string ScenarioString, string Pack)
{
    local int newRow;
    
    ClearRow();

    AddNewRowElement("Scenario",,ScenarioString);

    AddNewRowElement("Pack",,Pack);

    newRow = PopulateRow();
    assert(newRow >= 0);        //what does it mean when PopulateRow() returns<0?
}

final function GetSelectedRow(out string ScenarioString, out string Pack)
{
    local GUIList List;

    List = GetColumn("Scenario");
    assert(List != None);

    ScenarioString = List.GetExtra();

    List = GetColumn("Pack");
    assert(List != None);

    Pack = List.GetExtra();
}
