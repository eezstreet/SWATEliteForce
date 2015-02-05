class GraphicCommandInterface_MP extends GraphicCommandInterface
    config(PlayerInterface_Command_MP);

simulated function CheckTeam()
{
    //in MP, the CI team should always be the Element, so the default is acceptable
}

defaultproperties
{
    CommandClass=class'Command_MP'
    StaticCommandsClass=class'CommandInterfaceStaticCommands_MP'
    MenuInfoClass=class'CommandInterfaceMenuInfo_MP'
    ContextsListClass=class'CommandInterfaceContextsList_MP'
    ContextClass=class'CommandInterfaceContext_MP'
    DoorRelatedContextClass=class'CommandInterfaceDoorRelatedContext_MP'
}
