class SwatServerSetupVotingPanel extends SwatGUIPanel
	;

var SwatServerSetupMenu SwatServerSetupMenu;

// The total list of referendums that we are allowed to vote on
var() config array<class<Voting.Referendum > > ConsideredReferendums;
var() localized config array<string> ReferendumNames;
var() array<int> ReferendumSelected;

// The big, important "VOTING ENABLED" checkbox
var(SWATGui) EditInline Config GUICheckBoxButton MyVotingEnabledBox;

// Some other settings which people might find cool
var(SWATGui) EditInline Config GUISlider MyVotingTimeSlider;
var(SWATGui) EditInline Config GUICheckBoxButton MyVotingTieWinBox;
var(SWATGui) EditInline Config GUICheckBoxButton MyCallCastVoteBox;
var(SWATGui) EditInline Config GUICheckBoxButton MyAbstainNoVoteBox;

// The list of referendums
var(SWATGui) protected EditInline Config GUIListBox AvailableReferendums;
var(SWATGui) protected EditInline Config GUIListBox SelectedReferendums;
var(SWATGui) protected EditInline Config GUIButton AddReferendum;
var(SWATGui) protected EditInline Config GUIButton RemoveReferendum;

function InternalOnClick(GUIComponent Sender)
{
	switch(Sender)
	{
		case AddReferendum:
			AddSelectedReferendum();
			break;

		case RemoveReferendum:
			RemoveSelectedReferendum();
			break;
	}
}

function InternalOnChange(GUIComponent Sender)
{
	switch(Sender)
	{
		case MyVotingEnabledBox:
			VotingEnabledChanged(MyVotingEnabledBox.bChecked);
			break;
	}
}

function LoadServerSettings(optional bool bReadOnly)
{
	local int i;
	local ServerSettings Settings;

	if( bReadOnly )
        Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);
    else
        Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);

	MyVotingEnabledBox.SetChecked( Settings.bAllowReferendums );
	VotingEnabledChanged(Settings.bAllowReferendums);

	ReferendumSelected.Length = ConsideredReferendums.Length;

	AvailableReferendums.List.Clear();
	SelectedReferendums.List.Clear();

	for(i = 0; i < ConsideredReferendums.Length; i++)
	{
		if(class'Voting.ReferendumManager'.static.ReferendumTypeAllowed(ConsideredReferendums[i]))
		{
			AvailableReferendums.List.Add(ReferendumNames[i], , , i);
			ReferendumSelected[i] = 0;
		}
		else
		{
			SelectedReferendums.List.Add(ReferendumNames[i], , , i);
			ReferendumSelected[i] = 1;
		}
	}

	MyVotingTimeSlider.SetValue(class'Voting.ReferendumManager'.default.ReferendumDuration);
	MyVotingTieWinBox.SetChecked(class'Voting.ReferendumManager'.default.TiesWin);
	MyCallCastVoteBox.SetChecked(class'Voting.ReferendumManager'.default.CallCastVote);
	MyAbstainNoVoteBox.SetChecked(class'Voting.ReferendumManager'.default.NonVotersAreNo);
}

event HandleParameters(string Param1, string Param2, optional int Param3)
{
	LoadServerSettings( !SwatServerSetupMenu.bIsAdmin );
}

// Called whenever the voting checkbox has been altered
function VotingEnabledChanged(bool bNewValue)
{
	if(!bNewValue)
	{
		AvailableReferendums.DeActivate();
		SelectedReferendums.DeActivate();
		AddReferendum.DeActivate();
		RemoveReferendum.DeActivate();
		MyVotingTimeSlider.DeActivate();
		MyVotingTieWinBox.DeActivate();
		MyCallCastVoteBox.DeActivate();
		MyAbstainNoVoteBox.DeActivate();
		AvailableReferendums.SetEnabled(false);
		SelectedReferendums.SetEnabled(false);
		AddReferendum.SetEnabled(false);
		RemoveReferendum.SetEnabled(false);
		MyVotingTimeSlider.SetEnabled(false);
		MyVotingTieWinBox.SetEnabled(false);
		MyCallCastVoteBox.SetEnabled(false);
		MyAbstainNoVoteBox.SetEnabled(false);
	}
	else
	{
		AvailableReferendums.Activate();
		SelectedReferendums.Activate();
		AddReferendum.Activate();
		RemoveReferendum.Activate();
		AvailableReferendums.SetEnabled(true);
		SelectedReferendums.SetEnabled(true);
		AddReferendum.SetEnabled(true);
		RemoveReferendum.SetEnabled(true);
		MyVotingTimeSlider.SetEnabled(true);
		MyVotingTieWinBox.SetEnabled(true);
		MyCallCastVoteBox.SetEnabled(true);
		MyAbstainNoVoteBox.SetEnabled(true);
	}
}

function AddSelectedReferendum()
{
	local int Index;

	if(AvailableReferendums.List.ElementCount() <= 0)
	{
		return;
	}

	Index = AvailableReferendums.List.GetExtraIntData();
	ReferendumSelected[Index] = 1;
	AvailableReferendums.List.Remove(AvailableReferendums.List.FindExtraIntData(Index));
	SelectedReferendums.List.Add(ReferendumNames[Index], , , index);
}

function RemoveSelectedReferendum()
{
	local int Index;

	if(SelectedReferendums.List.ElementCount() <= 0)
	{
		return;
	}

	Index = SelectedReferendums.List.GetExtraIntData();
	ReferendumSelected[Index] = 0;
	SelectedReferendums.List.Remove(SelectedReferendums.List.FindExtraIntData(Index));
	AvailableReferendums.List.Add(ReferendumNames[index], , , index);
}

function SaveServerSettings()
{
	local int i;
	local int LastIndex;

	class'Voting.ReferendumManager'.default.ReferendumDuration = MyVotingTimeSlider.GetValue();
	class'Voting.ReferendumManager'.default.TiesWin = MyVotingTieWinBox.bChecked;
	class'Voting.ReferendumManager'.default.CallCastVote = MyCallCastVoteBox.bChecked;
	class'Voting.ReferendumManager'.default.NonVotersAreNo = MyAbstainNoVoteBox.bChecked;

	LastIndex = 0;

	class'Voting.ReferendumManager'.default.DisabledReferendums.Length = 0;
	for(i = 0; i < ConsideredReferendums.length; i++)
	{
		if(ReferendumSelected[i] == 1)
		{
			class'Voting.ReferendumManager'.default.DisabledReferendums[LastIndex] = ConsideredReferendums[i];
			LastIndex++;
		}
	}
	class'Voting.ReferendumManager'.static.StaticSaveConfig();
}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	AddReferendum.OnClick = InternalOnClick;
	RemoveReferendum.OnClick = InternalOnClick;
	MyVotingEnabledBox.OnChange = InternalOnChange;
}

defaultproperties
{
	ConsideredReferendums[0]=class'SwatGame.BanReferendum'
	ConsideredReferendums[1]=class'SwatGame.EndMapReferendum'
	ConsideredReferendums[2]=class'SwatGame.KickReferendum'
	ConsideredReferendums[3]=class'SwatGame.LeaderReferendum'
	ConsideredReferendums[4]=class'SwatGame.MapChangeReferendum'
	ConsideredReferendums[5]=class'SwatGame.NextMapReferendum'
	ConsideredReferendums[6]=class'SwatGame.RestartLevelReferendum'
	ConsideredReferendums[7]=class'SwatGame.StartMapReferendum'
	ReferendumNames[0]="Ban"
	ReferendumNames[1]="End Current Map"
	ReferendumNames[2]="Kick"
	ReferendumNames[3]="Promote to Leader"
	ReferendumNames[4]="Change Map"
	ReferendumNames[5]="Go to Next Map"
	ReferendumNames[6]="Restart Level"
	ReferendumNames[7]="Start Level"
}
