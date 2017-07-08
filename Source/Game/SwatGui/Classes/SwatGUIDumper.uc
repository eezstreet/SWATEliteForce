// ====================================================================
//  Class:  SwatGui.SwatGUIDumper
//  Parent: Object
//
//  Storage for GUI dumping.
// ====================================================================

class SwatGUIDumper extends SwatContentDumper
     config(ContentDump);

var() config array<string> ClassName "ClassNames";
var() config array<string> ObjName "object names";