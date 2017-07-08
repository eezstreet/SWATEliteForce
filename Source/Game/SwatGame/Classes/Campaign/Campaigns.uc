class Campaigns extends Core.Object
    config(Campaign);

var config  String  CurCampaignName;        //name of the current campaign

var private config array<Name> Campaign;    //the list of known campaign names... named for clarity of .ini file

var private array<Campaign> Campaigns;      //the list of known campaigns, each one instantiated in construct()

overloaded function Construct()
{
    local int i;

    //initialize the list of campaigns
    for (i=0; i<Campaign.length; ++i)
        Campaigns[i] = new(None, string(Campaign[i])) class'SwatGame.Campaign';
}

final function array<Campaign> GetCampaigns()
{
    return Campaigns;
}

final function Campaign GetCampaign(string inCampaign)
{
    local int i;
    local name CampaignName;

    CampaignName = CampaignStringToName(inCampaign);

    for (i=0; i<Campaign.length; ++i)
        if (Campaign[i] == CampaignName)
            return Campaigns[i];

    return None;    //no Campaign found by that name
}

final function bool CampaignExists(string inCampaign)
{
    local name CampaignName;
    local int i;

    CampaignName = CampaignStringToName(inCampaign);

    //return false if a campaign with that name already exists
    for (i=0; i<Campaign.length; ++i)
        if (Campaign[i] == CampaignName)
            return true;

    return false;
}

//it is an error to AddCampaign() with a string that maps to a Campaign name
//  that already exists.
//call CampaignExists() first to find out.
//note that more than one string may map to the same name.
//returns the newly added Campaign
final function Campaign AddCampaign(string inCampaign, int campPath, bool bPlayerPermadeath, bool bOfficerPermadeath)
{
    local name CampaignName;
    local int i;

    CampaignName = CampaignStringToName(inCampaign);

    //return false if a campaign with that name already exists
    for (i=0; i<Campaign.length; ++i)
        if( Campaign[i] == CampaignName )
            return None;
        assertWithDescription(Campaign[i] != CampaignName,
            "[tcohen] Campaigns was called to Add the Campaign named "$inCampaign
            $".  But a Campaign with that name already exists.");


    Campaign[i] = CampaignName;

    Campaigns[i] = new(None, string(CampaignName)) class'SwatGame.Campaign';
    Campaigns[i].StringName = inCampaign;
	  Campaigns[i].CampaignPath = campPath;
    Campaigns[i].PlayerPermadeath = bPlayerPermadeath;
    Campaigns[i].OfficerPermadeath = bOfficerPermadeath;

    SaveConfig();
    Campaigns[i].SaveConfig();

    return Campaigns[i];
}

//it is an error to DeleteCampaign() with a Campaign that hasn't been created with AddCampaign().
final function DeleteCampaign(string inCampaign)
{
    local name CampaignName;
    local int i;

    CampaignName = CampaignStringToName(inCampaign);

    //return false if a campaign with that name already exists
    for (i=0; i<Campaign.length; ++i)
        if (Campaign[i] == CampaignName)
            break;

    assertWithDescription(i <= Campaign.length,
        "[tcohen] Campagins was called to Delete the Campaign named "$inCampaign
        $".  But no Campaign was found with that name.");

    Campaigns[i].PreDelete();

    Campaign.Remove(i, 1);
    Campaigns.Remove(i, 1);

    SaveConfig();
}

//convert a campaign name string to an unreal name.
//note that this is a many-to-one relationship:
//  more than one string may map to a given name.
//performs mangling of the string to make it satisfy
//  name-naming rules.
private final function name CampaignStringToName(string inString)
{
    local int i;
    local int ascii;

    //
    //mangle inString so that it satisfies naming rules for an unreal name
    //

    //prepend "Campaign_" to ensure name starts with a letter
    inString = "Campaign_" $ inString;

    //convert non-alpha-numerics to underscores
    for (i=0; i<len(inString); ++i)
    {
        ascii = Asc(Mid(inString, i, 1));

        if  (   ascii < 48                  //before '0'
            ||  (ascii > 57 && ascii < 65)  //between '9' and 'A'
            ||  (ascii > 90 && ascii < 97)  //between 'Z' and 'a'
            ||  (ascii > 122)               //after 'z'
            )
            inString = Left(inString, i) $ "_" $ Right(inString, len(inString) - i - 1);
    }

    //don't let it grow too long
    if (len(inString) > 40)
        inString = Left(inString, 40);

    //if string ends in an underscore then append to it
    if (Right(inString, 1) == "_")
        inString = inString $ "end";

    return name(inString);
}
