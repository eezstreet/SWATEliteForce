class MaterialFactory extends Core.Object
	abstract
	hidecategories(Object)
	native;

var string Description;

const RF_Standalone = 0x00080000;

event Engine.Material CreateMaterial( Core.Object InOuter, string InPackage, string InGroup, string InName );
native function ConsoleCommand(string Cmd);
