class Speakers extends Core.Object
    Config(Speakers)
    native;

struct native SpeakerInfo
{
   var config name SpeakerID;
   var config localized string SpeakerString;
   var config string PreFormatting;
   var config string PostFormatting;
   var config bool bUsePlayerNameInMP;
};

var config array<SpeakerInfo> Speaker;

var private native noexport const int SpeakerMap[5];  //Declared as a TMap<FName, FSpeakerInfo*> in ASpeakerInfo.h
